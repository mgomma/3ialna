import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mu_super_app/data/local/user_profile_storage_service.dart';
import 'package:mu_super_app/domain/models/local_user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('loads a legacy profile when newer optional fields are absent', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'user_profile_data': jsonEncode(<String, Object>{
        'email': 'parent@example.com',
        'firstName': 'Parent',
        'lastName': 'Name',
        'phone': '+201000000000',
        'country': 'Egypt',
        'language': 'ar',
      }),
    });

    final LocalUserProfile? profile =
        await UserProfileStorageService().loadProfile();

    expect(profile, isNotNull);
    expect(profile!.email, 'parent@example.com');
    expect(profile.firstName, 'Parent');
    expect(profile.country, 'Egypt');
    expect(profile.language, 'ar');
    expect(profile.isRegistered, isFalse);
    expect(profile.accessToken, isNull);
  });

  test('preserves profile fields across a save and reload', () async {
    const LocalUserProfile original = LocalUserProfile(
      email: 'parent@example.com',
      firstName: 'Parent',
      lastName: 'Name',
      phone: '+201000000000',
      country: 'Egypt',
      language: 'ar',
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      childDeviceId: 'child-device',
      deviceToken: 'device-token',
      authProvider: 'manual',
      providerUserId: 'parent-id',
      isRegistered: true,
    );
    final UserProfileStorageService storage = UserProfileStorageService();

    await storage.saveProfile(original);
    final LocalUserProfile? restored = await storage.loadProfile();

    expect(restored?.toMap(), original.toMap());
  });
}