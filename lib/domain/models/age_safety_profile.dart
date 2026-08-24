enum AgeSafetyProfile {
  underFive,
  agesFiveToNine,
  agesNineToThirteen,
  teenagers,
}

class AgeSafetyProfileRecommendation {
  const AgeSafetyProfileRecommendation._();

  static AgeSafetyProfile forBirthDate(DateTime birthDate, {DateTime? onDate}) {
    final DateTime today = onDate ?? DateTime.now();
    int age = today.year - birthDate.year;
    if (DateTime(today.year, birthDate.month, birthDate.day).isAfter(today)) {
      age -= 1;
    }
    if (age < 5) return AgeSafetyProfile.underFive;
    if (age < 9) return AgeSafetyProfile.agesFiveToNine;
    if (age < 13) return AgeSafetyProfile.agesNineToThirteen;
    return AgeSafetyProfile.teenagers;
  }
}

class AgeSafetyProfilePreset {
  const AgeSafetyProfilePreset({
    required this.profile,
    required this.nameEn,
    required this.nameAr,
    required this.descriptionEn,
    required this.descriptionAr,
    required this.dailyLimitMinutes,
    required this.socialMediaLimitMinutes,
    required this.gamesLimitMinutes,
    required this.prayerLockEnabled,
    required this.prayerLockMinutes,
    required this.sleepLockEnabled,
    required this.sleepLockStartMinutes,
    required this.sleepLockEndMinutes,
    required this.blockMatureContent,
    required this.requireParentApproval,
    required this.voiceNotifications,
  });

  final AgeSafetyProfile profile;
  final String nameEn;
  final String nameAr;
  final String descriptionEn;
  final String descriptionAr;
  final int dailyLimitMinutes;
  final int socialMediaLimitMinutes;
  final int gamesLimitMinutes;
  final bool prayerLockEnabled;
  final int prayerLockMinutes;
  final bool sleepLockEnabled;
  final int sleepLockStartMinutes;
  final int sleepLockEndMinutes;
  final bool blockMatureContent;
  final bool requireParentApproval;
  final bool voiceNotifications;

  static const Map<AgeSafetyProfile, AgeSafetyProfilePreset> defaults = {
    AgeSafetyProfile.underFive: AgeSafetyProfilePreset(
      profile: AgeSafetyProfile.underFive,
      nameEn: 'Children under 5',
      nameAr: 'الأطفال دون 5 سنوات',
      descriptionEn: 'Short sessions, strict content protection, and parent approval.',
      descriptionAr: 'جلسات قصيرة وحماية مشددة وموافقة الوالدين.',
      dailyLimitMinutes: 30,
      socialMediaLimitMinutes: 0,
      gamesLimitMinutes: 30,
      prayerLockEnabled: true,
      prayerLockMinutes: 10,
      sleepLockEnabled: true,
      sleepLockStartMinutes: 19 * 60 + 30,
      sleepLockEndMinutes: 7 * 60,
      blockMatureContent: true,
      requireParentApproval: true,
      voiceNotifications: true,
    ),
    AgeSafetyProfile.agesFiveToNine: AgeSafetyProfilePreset(
      profile: AgeSafetyProfile.agesFiveToNine,
      nameEn: 'Children 5 to 9',
      nameAr: 'الأطفال من 5 إلى 9 سنوات',
      descriptionEn: 'Guided exploration with clear daily boundaries.',
      descriptionAr: 'استكشاف موجّه مع حدود يومية واضحة.',
      dailyLimitMinutes: 45,
      socialMediaLimitMinutes: 0,
      gamesLimitMinutes: 45,
      prayerLockEnabled: true,
      prayerLockMinutes: 15,
      sleepLockEnabled: true,
      sleepLockStartMinutes: 20 * 60 + 30,
      sleepLockEndMinutes: 7 * 60,
      blockMatureContent: true,
      requireParentApproval: true,
      voiceNotifications: true,
    ),
    AgeSafetyProfile.agesNineToThirteen: AgeSafetyProfilePreset(
      profile: AgeSafetyProfile.agesNineToThirteen,
      nameEn: 'Tweens 9 to 13',
      nameAr: 'الناشئة من 9 إلى 13 سنة',
      descriptionEn: 'More independence with protected content and review prompts.',
      descriptionAr: 'استقلالية أكبر مع حماية المحتوى وتنبيهات المراجعة.',
      dailyLimitMinutes: 90,
      socialMediaLimitMinutes: 30,
      gamesLimitMinutes: 60,
      prayerLockEnabled: true,
      prayerLockMinutes: 15,
      sleepLockEnabled: true,
      sleepLockStartMinutes: 21 * 60 + 30,
      sleepLockEndMinutes: 7 * 60,
      blockMatureContent: true,
      requireParentApproval: false,
      voiceNotifications: true,
    ),
    AgeSafetyProfile.teenagers: AgeSafetyProfilePreset(
      profile: AgeSafetyProfile.teenagers,
      nameEn: 'Teenagers 13 to 18',
      nameAr: 'المراهقون من 13 إلى 18 سنة',
      descriptionEn: 'Flexible boundaries with privacy-respecting safety defaults.',
      descriptionAr: 'حدود مرنة مع إعدادات أمان تحترم الخصوصية.',
      dailyLimitMinutes: 150,
      socialMediaLimitMinutes: 60,
      gamesLimitMinutes: 90,
      prayerLockEnabled: true,
      prayerLockMinutes: 15,
      sleepLockEnabled: true,
      sleepLockStartMinutes: 22 * 60 + 30,
      sleepLockEndMinutes: 7 * 60,
      blockMatureContent: true,
      requireParentApproval: false,
      voiceNotifications: false,
    ),
  };

  AgeSafetyProfilePreset copyWith({
    int? dailyLimitMinutes,
    int? socialMediaLimitMinutes,
    int? gamesLimitMinutes,
    bool? prayerLockEnabled,
    int? prayerLockMinutes,
    bool? sleepLockEnabled,
    int? sleepLockStartMinutes,
    int? sleepLockEndMinutes,
    bool? blockMatureContent,
    bool? requireParentApproval,
    bool? voiceNotifications,
  }) {
    return AgeSafetyProfilePreset(
      profile: profile,
      nameEn: nameEn,
      nameAr: nameAr,
      descriptionEn: descriptionEn,
      descriptionAr: descriptionAr,
      dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
      socialMediaLimitMinutes: socialMediaLimitMinutes ?? this.socialMediaLimitMinutes,
      gamesLimitMinutes: gamesLimitMinutes ?? this.gamesLimitMinutes,
      prayerLockEnabled: prayerLockEnabled ?? this.prayerLockEnabled,
      prayerLockMinutes: prayerLockMinutes ?? this.prayerLockMinutes,
      sleepLockEnabled: sleepLockEnabled ?? this.sleepLockEnabled,
      sleepLockStartMinutes: sleepLockStartMinutes ?? this.sleepLockStartMinutes,
      sleepLockEndMinutes: sleepLockEndMinutes ?? this.sleepLockEndMinutes,
      blockMatureContent: blockMatureContent ?? this.blockMatureContent,
      requireParentApproval: requireParentApproval ?? this.requireParentApproval,
      voiceNotifications: voiceNotifications ?? this.voiceNotifications,
    );
  }
}
