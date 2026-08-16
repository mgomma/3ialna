import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/local_user_profile.dart';

class UserProfileStorageService {
  static const String _keyProfile = 'user_profile_data';

  Future<LocalUserProfile?> loadProfile() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_keyProfile);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final Map<String, dynamic> map = jsonDecode(raw) as Map<String, dynamic>;
      return LocalUserProfile.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProfile(LocalUserProfile profile) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProfile, jsonEncode(profile.toMap()));
  }

  Future<void> clearProfile() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyProfile);
  }
}
