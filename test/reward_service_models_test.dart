import 'package:flutter_test/flutter_test.dart';

import 'package:mu_super_app/data/local/reward_service.dart';

void main() {
  test('reward option round-trips its local configuration', () {
    const RewardOption reward = RewardOption(id: 'reward-1', title: 'Choose the family story', enabled: true);
    final RewardOption restored = RewardOption.fromJson(reward.toJson());

    expect(restored.id, reward.id);
    expect(restored.title, reward.title);
    expect(restored.enabled, isTrue);
  });

  test('child request round-trips and keeps explicit approval status', () {
    final ChildExtraTimeRequest request = ChildExtraTimeRequest(
      id: 'request-1',
      childId: 'child-1',
      minutes: 5,
      packageName: 'com.example.game',
      createdAt: DateTime(2026, 8, 25, 12),
      status: 'pending',
    );
    final ChildExtraTimeRequest approved = ChildExtraTimeRequest.fromJson(<String, dynamic>{
      ...request.toJson(),
      'status': 'approved',
    });

    expect(approved.childId, 'child-1');
    expect(approved.minutes, 5);
    expect(approved.packageName, 'com.example.game');
    expect(approved.status, 'approved');
    expect(approved.toJson().keys, containsAll(<String>['id', 'childId', 'minutes', 'packageName', 'createdAt', 'status']));
    expect(approved.toJson().keys, isNot(contains('childName')));
    expect(approved.toJson().keys, isNot(contains('birthDate')));
  });
}
