import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/safe_content_policy.dart';

class SafeContentPolicyStorageService {
  static const String _key = 'safe_content_policy';

  Future<SafeContentPolicy> getPolicy() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return SafeContentPolicy.defaultPolicy;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return SafeContentPolicy.fromMap(decoded);
      }
      if (decoded is Map) {
        return SafeContentPolicy.fromMap(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      // Corrupt local policy should fail closed to the safe defaults.
    }
    return SafeContentPolicy.defaultPolicy;
  }

  Future<void> savePolicy(SafeContentPolicy policy) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(policy.toMap()));
  }

  Future<void> resetPolicy() => savePolicy(SafeContentPolicy.defaultPolicy);
}
