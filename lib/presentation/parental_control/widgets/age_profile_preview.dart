import 'package:flutter/material.dart';

import '../../../domain/models/age_safety_profile.dart';
import '../../../l10n/app_localizations.dart';

class AgeProfilePreview extends StatelessWidget {
  const AgeProfilePreview({required this.preset, super.key});

  final AgeSafetyProfilePreset preset;

  String _time(int minutes) {
    final int hour = (minutes ~/ 60) % 24;
    final int minute = minutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final bool isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final List<(String, String)> rows = <(String, String)>[
      (
        l10n.dailyBudget,
        '${preset.dailyLimitMinutes} ${l10n.minutesSuffix}',
      ),
      (
        l10n.socialBudget,
        '${preset.socialMediaLimitMinutes} ${l10n.minutesSuffix}',
      ),
      (
        l10n.gamesBudget,
        '${preset.gamesLimitMinutes} ${l10n.minutesSuffix}',
      ),
      (
        l10n.sleepSchedule,
        '${_time(preset.sleepLockStartMinutes)}–${_time(preset.sleepLockEndMinutes)}',
      ),
      (
        l10n.prayerLock,
        preset.prayerLockEnabled
            ? '${preset.prayerLockMinutes} ${l10n.minutesSuffix}'
            : l10n.disabled,
      ),
      (
        l10n.matureContentBlock,
        preset.blockMatureContent ? l10n.enabled : l10n.disabled,
      ),
      (
        l10n.parentApproval,
        preset.requireParentApproval ? l10n.enabled : l10n.disabled,
      ),
      (
        l10n.parentVoiceReminders,
        preset.voiceNotifications ? l10n.enabled : l10n.disabled,
      ),
    ];

    return Card(
      key: const ValueKey<String>('age-profile-preview'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.recommendedProfile,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              isArabic ? preset.nameAr : preset.nameEn,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Divider(height: 20),
            ...rows.map(
              ((String, String) row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(child: Text(row.$1)),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        row.$2,
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
