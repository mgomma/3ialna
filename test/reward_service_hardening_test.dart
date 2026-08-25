import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mu_super_app/data/local/reward_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('reads legacy balance JSON and migrates it on the next write', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'flex_token_balances_v1': jsonEncode(<String, Object>{
        'child-1': <String, Object>{'available': 2, 'updatedAt': DateTime(2026, 1, 1).toIso8601String()},
      }),
    });
    const RewardService service = RewardService();

    expect((await service.loadTokens('child-1')).available, 2);
    await service.issueToken('child-1');
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> stored = jsonDecode(prefs.getString('flex_token_balances_v1')!) as Map<String, dynamic>;

    expect(stored['schemaVersion'], 1);
    expect(stored['balances']['child-1']['available'], 3);
  });

  test('clamps a corrupted negative balance to zero', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'flex_token_balances_v1': jsonEncode(<String, Object>{
        'child-1': <String, Object>{'available': -9, 'updatedAt': DateTime(2026, 1, 1).toIso8601String()},
      }),
    });

    final FlexTokenBalance balance = await const RewardService().loadTokens('child-1');

    expect(balance.available, 0);
  });

  test('serialized concurrent issues preserve every increment', () async {
    const RewardService service = RewardService();

    await Future.wait<void>(List<Future<void>>.generate(25, (_) async {
      await service.issueToken('child-1');
    }));

    expect((await service.loadTokens('child-1')).available, 25);
  });

  test('serialized concurrent consumes never make the balance negative', () async {
    const RewardService service = RewardService();
    await service.issueToken('child-1');
    await Future.wait<void>(List<Future<void>>.generate(10, (_) async {
      await service.consumeToken('child-1');
    }));

    expect((await service.loadTokens('child-1')).available, 0);
  });

  test('versioned request storage preserves only local-safe request fields', () async {
    const RewardService service = RewardService();
    await service.createRequest(childId: 'child-1', minutes: 5, packageName: 'com.example.game');
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> stored = jsonDecode(prefs.getString('child_extra_time_requests_v1')!) as Map<String, dynamic>;

    expect(stored['schemaVersion'], 1);
    expect(stored['requests'], hasLength(1));
    expect(stored['requests'][0].keys, isNot(contains('childName')));
    expect(stored['requests'][0].keys, isNot(contains('birthDate')));
    expect(stored['requests'][0].keys, isNot(contains('recordingPath')));
  });

  test('approval consumes one token and a second approval is rejected', () async {
    const RewardService service = RewardService();
    final ChildExtraTimeRequest request = await service.createRequest(
      childId: 'child-1',
      minutes: 5,
      packageName: 'com.example.game',
    );
    await service.issueToken('child-1');

    final ChildExtraTimeRequest? first = await service.approveRequest(request.id);
    final ChildExtraTimeRequest? second = await service.approveRequest(request.id);

    expect(first?.status, 'approved');
    expect(second, isNull);
    expect((await service.loadTokens('child-1')).available, 0);
    expect((await service.loadRequests()).single.status, 'approved');
  });

  test('approval without a token leaves a request pending', () async {
    const RewardService service = RewardService();
    final ChildExtraTimeRequest request = await service.createRequest(childId: 'child-1', minutes: 5);

    expect(await service.approveRequest(request.id), isNull);
    expect((await service.loadRequests()).single.status, 'pending');
  });

  test('request minutes are clamped to one through thirty', () async {
    const RewardService service = RewardService();
    final ChildExtraTimeRequest minimum = await service.createRequest(childId: 'child-1', minutes: 0);
    final ChildExtraTimeRequest maximum = await service.createRequest(childId: 'child-1', minutes: 90);

    expect(minimum.minutes, 1);
    expect(maximum.minutes, 30);
  });
}
