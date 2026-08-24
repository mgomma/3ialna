import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mu_super_app/data/local/shareable_profile_pack_service.dart';
import 'package:mu_super_app/domain/models/age_safety_profile.dart';
import 'package:mu_super_app/domain/models/managed_app_category.dart';
import 'package:mu_super_app/domain/models/schedule.dart';

void main() {
  ShareableProfilePack pack() => ShareableProfilePack(
        profileName: 'Calm evening routine',
        creatorName: 'A parent',
        preset: AgeSafetyProfilePreset.defaults[AgeSafetyProfile.agesFiveToNine]!,
        blockedApps: const <String>['com.example.unsuitable'],
        appTimeLimits: const <String, int>{'com.example.game': 30},
        appCategories: const <String, ManagedAppCategory>{'com.example.game': ManagedAppCategory.games},
        schedule: const Schedule(enabled: true, startTime: '20:30', endTime: '07:00', activeDays: <int>[0, 1, 2, 3, 4, 5, 6]),
      );

  group('ShareableProfilePack privacy boundary', () {
    test('exports an allowlisted reusable payload without child identity or private device data', () {
      final Map<String, dynamic> exported = jsonDecode(jsonEncode(pack().toJson())) as Map<String, dynamic>;
      final String encoded = jsonEncode(exported).toLowerCase();

      expect(exported.keys, containsAll(<String>['format', 'version', 'profileName', 'creatorName', 'preset', 'appRules', 'schedule']));
      expect(exported.keys, isNot(containsAny(<String>['children', 'childName', 'birthDate', 'gender', 'pin', 'usage', 'recording'])));
      expect(encoded, isNot(contains('layla')));
      expect(encoded, isNot(contains('2017-04-12')));
      expect(encoded, isNot(contains('female')));
      expect(encoded, isNot(contains('parent-pin')));
      expect(encoded, isNot(contains('voice-recording')));
      expect(encoded, isNot(contains('usage-stats')));
    });

    test('round-trips reusable rules while preserving only the voluntary setup and creator names', () {
      final ShareableProfilePack restored = ShareableProfilePack.fromJson(
        jsonDecode(jsonEncode(pack().toJson())) as Map<String, dynamic>,
      );

      expect(restored.profileName, 'Calm evening routine');
      expect(restored.creatorName, 'A parent');
      expect(restored.preset.profile, AgeSafetyProfile.agesFiveToNine);
      expect(restored.appCategories['com.example.game'], ManagedAppCategory.games);
      expect(restored.schedule.startTime, '20:30');
    });

    test('rejects direct, normalized, and nested child identity or private-data keys on import', () {
      const List<String> prohibitedKeys = <String>[
        'children',
        'childName',
        'child_name',
        'birthDate',
        'birth_date',
        'date-of-birth',
        'dob',
        'gender',
        'activeChildId',
        'parentPin',
        'voice_recording',
        'usageStats',
      ];

      for (final String key in prohibitedKeys) {
        final Map<String, dynamic> hostile = jsonDecode(jsonEncode(pack().toJson())) as Map<String, dynamic>;
        hostile['appRules'] = Map<String, dynamic>.from(hostile['appRules'] as Map<dynamic, dynamic>)..[key] = 'private-value';
        expect(
          () => ShareableProfilePack.fromJson(hostile),
          throwsA(isA<FormatException>()),
          reason: 'Expected $key to be rejected.',
        );
      }
    });
  });
}
