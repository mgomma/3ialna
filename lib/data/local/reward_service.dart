import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class RewardOption {
  const RewardOption({required this.id, required this.title, required this.enabled});

  final String id;
  final String title;
  final bool enabled;

  factory RewardOption.fromJson(Map<String, dynamic> json) => RewardOption(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        enabled: json['enabled'] as bool? ?? true,
      );

  Map<String, Object> toJson() => <String, Object>{'id': id, 'title': title, 'enabled': enabled};
}

class FlexTokenBalance {
  const FlexTokenBalance({required this.childId, required this.available, required this.updatedAt});

  final String childId;
  final int available;
  final DateTime updatedAt;

  FlexTokenBalance copyWith({int? available, DateTime? updatedAt}) => FlexTokenBalance(
        childId: childId,
        available: available ?? this.available,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

class ChildExtraTimeRequest {
  const ChildExtraTimeRequest({
    required this.id,
    required this.childId,
    required this.minutes,
    required this.packageName,
    required this.createdAt,
    required this.status,
  });

  final String id;
  final String childId;
  final int minutes;
  final String packageName;
  final DateTime createdAt;
  final String status;

  factory ChildExtraTimeRequest.fromJson(Map<String, dynamic> json) => ChildExtraTimeRequest(
        id: json['id'] as String? ?? '',
        childId: json['childId'] as String? ?? '',
        minutes: (json['minutes'] as num?)?.toInt() ?? 5,
        packageName: json['packageName'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        status: json['status'] as String? ?? 'pending',
      );

  Map<String, Object> toJson() => <String, Object>{
        'id': id,
        'childId': childId,
        'minutes': minutes,
        'packageName': packageName,
        'createdAt': createdAt.toIso8601String(),
        'status': status,
      };
}

class RewardService {
  const RewardService();

  static const String _rewardsKey = 'reward_options_v1';
  static const String _tokensKey = 'flex_token_balances_v1';
  static const String _requestsKey = 'child_extra_time_requests_v1';

  // SharedPreferences has no compare-and-swap operation. This in-process queue
  // prevents concurrent read-modify-write calls from losing updates.
  static Future<void> _writeQueue = Future<void>.value();

  Future<List<RewardOption>> loadRewards() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      return (jsonDecode(prefs.getString(_rewardsKey) ?? '[]') as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(RewardOption.fromJson)
          .where((RewardOption item) => item.title.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return <RewardOption>[];
    }
  }

  Future<void> saveRewards(List<RewardOption> rewards) async {
    await _serialized<void>(() async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_rewardsKey, jsonEncode(rewards.map((RewardOption item) => item.toJson()).toList()));
    });
  }

  Future<FlexTokenBalance> loadTokens(String childId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return _readBalance(_decodeMap(prefs.getString(_tokensKey)), childId);
  }

  Future<FlexTokenBalance> issueToken(String childId) async {
    return _serialized<FlexTokenBalance>(() async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> raw = _decodeMap(prefs.getString(_tokensKey));
      final FlexTokenBalance current = _readBalance(raw, childId);
      final FlexTokenBalance updated = current.copyWith(available: current.available + 1, updatedAt: DateTime.now());
      await _writeBalance(prefs, raw, updated);
      return updated;
    });
  }

  Future<FlexTokenBalance> consumeToken(String childId) async {
    return _serialized<FlexTokenBalance>(() async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> raw = _decodeMap(prefs.getString(_tokensKey));
      final FlexTokenBalance current = _readBalance(raw, childId);
      if (current.available <= 0) return current;
      final FlexTokenBalance updated = current.copyWith(available: current.available - 1, updatedAt: DateTime.now());
      await _writeBalance(prefs, raw, updated);
      return updated;
    });
  }

  Future<ChildExtraTimeRequest> createRequest({required String childId, required int minutes, String packageName = ''}) async {
    return _serialized<ChildExtraTimeRequest>(() async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<ChildExtraTimeRequest> requests = _readRequests(prefs);
      final ChildExtraTimeRequest request = ChildExtraTimeRequest(
        id: 'request-${DateTime.now().microsecondsSinceEpoch}',
        childId: childId,
        minutes: minutes.clamp(1, 30),
        packageName: packageName,
        createdAt: DateTime.now(),
        status: 'pending',
      );
      requests.add(request);
      await _writeRequests(prefs, requests);
      return request;
    });
  }

  Future<List<ChildExtraTimeRequest>> loadRequests() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return _readRequests(prefs);
  }

  /// Atomically consumes one token and changes a request from pending to
  /// approved. A second approval returns null and changes nothing.
  Future<ChildExtraTimeRequest?> approveRequest(String requestId) async {
    return _serialized<ChildExtraTimeRequest?>(() async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<ChildExtraTimeRequest> requests = _readRequests(prefs);
      final int index = requests.indexWhere((ChildExtraTimeRequest item) => item.id == requestId);
      if (index < 0 || requests[index].status != 'pending') return null;
      final ChildExtraTimeRequest request = requests[index];
      final Map<String, dynamic> rawTokens = _decodeMap(prefs.getString(_tokensKey));
      final FlexTokenBalance balance = _readBalance(rawTokens, request.childId);
      if (balance.available <= 0) return null;
      final FlexTokenBalance updatedBalance = balance.copyWith(available: balance.available - 1, updatedAt: DateTime.now());
      final ChildExtraTimeRequest approved = ChildExtraTimeRequest(
        id: request.id,
        childId: request.childId,
        minutes: request.minutes,
        packageName: request.packageName,
        createdAt: request.createdAt,
        status: 'approved',
      );
      requests[index] = approved;
      await _writeBalance(prefs, rawTokens, updatedBalance);
      await _writeRequests(prefs, requests);
      return approved;
    });
  }

  Future<void> updateRequestStatus(String requestId, String status) async {
    await _serialized<void>(() async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<ChildExtraTimeRequest> requests = _readRequests(prefs);
      final int index = requests.indexWhere((ChildExtraTimeRequest item) => item.id == requestId);
      if (index < 0 || requests[index].status != 'pending') return;
      final ChildExtraTimeRequest item = requests[index];
      requests[index] = ChildExtraTimeRequest(
        id: item.id,
        childId: item.childId,
        minutes: item.minutes,
        packageName: item.packageName,
        createdAt: item.createdAt,
        status: status,
      );
      await _writeRequests(prefs, requests);
    });
  }

  Future<T> _serialized<T>(Future<T> Function() action) {
    final Future<T> operation = _writeQueue.then<T>((_) => action());
    _writeQueue = operation.then<void>((_) {}, onError: (_, Object __) {});
    return operation;
  }

  FlexTokenBalance _readBalance(Map<String, dynamic> raw, String childId) {
    final dynamic candidate = raw[childId];
    final Map<String, dynamic> value = candidate is Map<String, dynamic> ? candidate : <String, dynamic>{};
    final int stored = (value['available'] as num?)?.toInt() ?? 0;
    return FlexTokenBalance(
      childId: childId,
      available: stored.clamp(0, 1 << 30),
      updatedAt: DateTime.tryParse(value['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Future<void> _writeBalance(SharedPreferences prefs, Map<String, dynamic> raw, FlexTokenBalance balance) async {
    raw[balance.childId] = <String, Object>{'available': balance.available, 'updatedAt': balance.updatedAt.toIso8601String()};
    await prefs.setString(_tokensKey, jsonEncode(raw));
  }

  List<ChildExtraTimeRequest> _readRequests(SharedPreferences prefs) {
    try {
      return (jsonDecode(prefs.getString(_requestsKey) ?? '[]') as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(ChildExtraTimeRequest.fromJson)
          .where((ChildExtraTimeRequest item) => item.id.isNotEmpty && item.childId.isNotEmpty)
          .toList();
    } catch (_) {
      return <ChildExtraTimeRequest>[];
    }
  }

  Future<void> _writeRequests(SharedPreferences prefs, List<ChildExtraTimeRequest> requests) async {
    await prefs.setString(_requestsKey, jsonEncode(requests.map((ChildExtraTimeRequest item) => item.toJson()).toList()));
  }

  Map<String, dynamic> _decodeMap(String? raw) {
    try {
      final dynamic value = jsonDecode(raw ?? '{}');
      return value is Map<String, dynamic> ? Map<String, dynamic>.from(value) : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }
}
