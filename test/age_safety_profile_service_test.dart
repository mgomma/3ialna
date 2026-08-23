import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mu_super_app/data/local/age_safety_profile_service.dart';
import 'package:mu_super_app/domain/models/age_safety_profile.dart';

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
}
