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
        createdAt:
 DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
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

  Future<List<RewardOption>> loadRewards() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String raw = prefs.getString(_rewardsKey) ?? '[]';
    try {
      return (jsonDecode(raw) as List<dynamic>).whereType<Map<String, dynamic>>().map(RewardOption.fromJson).where((RewardOption item) => item.title.trim().isNotEmpty).toList();
    } catch (_) {
      return <RewardOption>[];
    }
  }

  Future<void> saveRewards(List<RewardOption> rewards) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_rewardsKey, jsonEncode(rewards.map((RewardOption item) => item.toJson()).toList()));
  }

  Future<FlexTokenBalance> loadTokens(String childId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> raw = _decodeMap(prefs.getString(_tokensKey));
    final Map<String, dynamic> value = raw[childId] is Map<String, dynamic> ? raw[childId] as Map<String, dynamic> : <String, dynamic>{};
    return FlexTokenBalance(childId: childId, available: (value['available'] as num?)?.toInt() ?? 0, updatedAt: DateTime.tryParse(value['updatedAt'] as String? ?? '') ?? DateTime.now());
  }

  Future<FlexTokenBalance> issueToken(String childId) async {
    final FlexTokenBalance current = await loadTokens(childId);
    return _saveTokens(current.copyWith(available: current.available + 1, updatedAt: DateTime.now()));
  }

  Future<FlexTokenBalance> consumeToken(String childId) async {
    final FlexTokenBalance current = await loadTokens(childId);
    if (current.available <= 0) return current;
    return _saveTokens(current.copyWith(available: current.available - 1, updatedAt: DateTime.now()));
  }

  Future<FlexTokenBalance> _saveTokens(FlexTokenBalance balance) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> raw = _decodeMap(prefs.getString(_tokensKey));
    raw[balance.childId] = <String, Object>{'available': balance.available, 'updatedAt': balance.updatedAt.toIso8601String()};
    await prefs.setString(_tokensKey, jsonEncode(raw));
    return balance;
  }

  Future<ChildExtraTimeRequest> createRequest({required String childId, required int minutes, String packageName = ''}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<ChildExtraTimeRequest> requests = await loadRequests();
    final ChildExtraTimeRequest request = ChildExtraTimeRequest(id: 'request-${DateTime.now().microsecondsSinceEpoch}',       childId: childId,
      minutes: minutes.clamp(1, 30),
      packageName: packageName,
      createdAt: DateTime.now(),
 status: 'pending');
    requests.add(request);
    await prefs.setString(_requestsKey, jsonEncode(requests.map((ChildExtraTimeRequest item) => item.toJson()).toList()));
    return request;
  }

  Future<List<ChildExtraTimeRequest>> loadRequests() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      return (jsonDecode(prefs.getString(_requestsKey) ?? '[]') as List<dynamic>).whereType<Map<String, dynamic>>().map(ChildExtraTimeRequest.fromJson).toList();
    } catch (_) {
      return <ChildExtraTimeRequest>[];
    }
  }

  Future<void> updateRequestStatus(String requestId, String status) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<ChildExtraTimeRequest> updated = (await loadRequests()).map((ChildExtraTimeRequest item) => item.id == requestId
        ? ChildExtraTimeRequest(
            id: item.id,
            childId: item.childId,
            minutes: item.minutes,
            packageName: item.packageName,
            createdAt: item.createdAt,
            status: status,
          )
        : item).toList();
    await prefs.setString(_requestsKey, jsonEncode(updated.map((ChildExtraTimeRequest item) => item.toJson()).toList()));
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
