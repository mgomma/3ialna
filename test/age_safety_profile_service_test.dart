import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mu_super_app/data/local/age_safety_profile_service.dart';
import 'package:mu_super_app/domain/models/age_safety_profile.dart';
import 'package:mu_super_app/domain/models/child_profile.dart';

void main() {
  test('selects a ready-made teenage profile and persists edits', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final AgeSafetyProfileService service = AgeSafetyProfileService(prefs);

    final AgeSafetyProfilePreset preset = await service.select(AgeSafetyProfile.teenagers);
    await service.save(preset.copyWith(dailyLimitMinutes: 120));

    expect(service.load().profile, AgeSafetyProfile.teenagers);
    expect(service.load().dailyLimitMinutes, 120);
  });

  test('reset restores the selected profile defaults', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final AgeSafetyProfileService service = AgeSafetyProfileService(prefs);

    await service.select(AgeSafetyProfile.agesFiveToNine);
    await service.save(service.load().copyWith(dailyLimitMinutes: 10));
    final AgeSafetyProfilePreset reset = await service.reset();

    expect(reset.profile, AgeSafetyProfile.agesFiveToNine);
    expect(reset.dailyLimitMinutes, 45);
  });

  test('recommends profile boundaries from a child birth date', () {
    final DateTime today = DateTime(2026, 8, 24);

    expect(
      AgeSafetyProfileRecommendation.forBirthDate(
        DateTime(2021, 8, 25),
        onDate: today,
      ),
      AgeSafetyProfile.underFive,
    );
    expect(
      AgeSafetyProfileRecommendation.forBirthDate(
        DateTime(2021, 8, 24),
        onDate: today,
      ),
      AgeSafetyProfile.agesFiveToNine,
    );
    expect(
      AgeSafetyProfileRecommendation.forBirthDate(
        DateTime(2013, 8, 24),
        onDate: today,
      ),
      AgeSafetyProfile.teenagers,
    );
  });

  test('updates an automatic child profile when the saved birth date changes',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final AgeSafetyProfileService service = AgeSafetyProfileService(prefs);

    final ChildProfile child = await service.addChild(
      name: 'Child',
      birthDate: DateTime(2014, 1, 1),
      gender: ChildGender.unspecified,
    );
    expect(child.profileFollowsBirthDate, isTrue);
    expect(child.preset.profile, AgeSafetyProfile.agesNineToThirteen);

    await service.updateChild(child.copyWith(birthDate: DateTime(2010, 1, 1)));

    final ChildProfile updated = service
        .loadChildren()
        .firstWhere((ChildProfile item) => item.id == child.id);
    expect(updated.preset.profile, AgeSafetyProfile.teenagers);
  });

  test('does not overwrite a parent-selected profile during automatic refresh',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final AgeSafetyProfileService service = AgeSafetyProfileService(prefs);
    final ChildProfile child = await service.addChild(
      name: 'Child',
      birthDate: DateTime(2010, 1, 1),
      gender: ChildGender.unspecified,
    );
    await service.setActiveChild(child.id);
    await service.select(AgeSafetyProfile.underFive);

    await service.refreshAutomaticAgeProfiles(now: DateTime(2026, 8, 24));

    expect(service.load().profile, AgeSafetyProfile.underFive);
    expect(service.activeChild()!.profileFollowsBirthDate, isFalse);
  });

  test('keeps daily limits independent when the active child changes',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final AgeSafetyProfileService service = AgeSafetyProfileService(prefs);
    final ChildProfile first = await service.addChild(
      name: 'Maha',
      birthDate: DateTime(2018, 6, 4),
      gender: ChildGender.girl,
    );
    final ChildProfile second = await service.addChild(
      name: 'Omar',
      birthDate: DateTime(2012, 6, 4),
      gender: ChildGender.boy,
    );

    await service.setActiveChild(first.id);
    await service.save(service.load().copyWith(dailyLimitMinutes: 35));
    await service.setActiveChild(second.id);
    await service.save(service.load().copyWith(dailyLimitMinutes: 105));

    expect(service.activeChild()!.id, second.id);
    expect(service.load().dailyLimitMinutes, 105);
    await service.setActiveChild(first.id);
    expect(service.activeChild()!.id, first.id);
    expect(service.load().dailyLimitMinutes, 35);
  });

  test('activates Parent mode explicitly and re-enables child limits when selected',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final AgeSafetyProfileService service = AgeSafetyProfileService(prefs);

    await service.ensureDefaultChild();
    final ChildProfile child = service.activeChild()!;
    expect(service.isParentModeActive(), isFalse);

    await service.setParentModeActive(true);
    expect(service.isParentModeActive(), isTrue);
    expect(prefs.getString('active_child_id'), 'parent');
    expect(prefs.getBool('active_prayer_lock_enabled'), isFalse);

    await service.setActiveChild(child.id);
    expect(service.isParentModeActive(), isFalse);
    expect(prefs.getString('active_child_id'), child.id);
    expect(
      prefs.getInt('active_social_media_limit_minutes'),
      child.preset.socialMediaLimitMinutes,
    );
  });

  test('migrates a legacy profile as a protected parent selection', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'age_safety_profile_config':
          '{"profile":"teenagers","dailyLimitMinutes":120}',
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final AgeSafetyProfileService service = AgeSafetyProfileService(prefs);

    await service.ensureDefaultChild();

    expect(service.load().profile, AgeSafetyProfile.teenagers);
    expect(service.activeChild()!.profileFollowsBirthDate, isFalse);
  });
}
