import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en', 'US'),
    Locale('ar', 'SA'),
  ];

  // Common
  String get appName => _localizedValues[locale.languageCode]!['appName']!;
  String get loading => _localizedValues[locale.languageCode]!['loading']!;
  String get error => _localizedValues[locale.languageCode]!['error']!;
  String get success => _localizedValues[locale.languageCode]!['success']!;
  String get cancel => _localizedValues[locale.languageCode]!['cancel']!;
  String get save => _localizedValues[locale.languageCode]!['save']!;
  String get delete => _localizedValues[locale.languageCode]!['delete']!;
  String get edit => _localizedValues[locale.languageCode]!['edit']!;
  String get add => _localizedValues[locale.languageCode]!['add']!;
  String get search => _localizedValues[locale.languageCode]!['search']!;
  String get settings => _localizedValues[locale.languageCode]!['settings']!;
  String get profile => _localizedValues[locale.languageCode]!['profile']!;
  String get logout => _localizedValues[locale.languageCode]!['logout']!;

  // Authentication
  String get login => _localizedValues[locale.languageCode]!['login']!;
  String get register => _localizedValues[locale.languageCode]!['register']!;
  String get email => _localizedValues[locale.languageCode]!['email']!;
  String get password => _localizedValues[locale.languageCode]!['password']!;
  String get confirmPassword => _localizedValues[locale.languageCode]!['confirmPassword']!;
  String get firstName => _localizedValues[locale.languageCode]!['firstName']!;
  String get lastName => _localizedValues[locale.languageCode]!['lastName']!;
  String get phone => _localizedValues[locale.languageCode]!['phone']!;
  String get forgotPassword => _localizedValues[locale.languageCode]!['forgotPassword']!;
  String get resetPassword => _localizedValues[locale.languageCode]!['resetPassword']!;

  // Navigation
  String get home => _localizedValues[locale.languageCode]!['home']!;
  String get childDevices => _localizedValues[locale.languageCode]!['childDevices']!;
  String get reports => _localizedValues[locale.languageCode]!['reports']!;
  String get masterParents => _localizedValues[locale.languageCode]!['masterParents']!;

  // Child Devices
  String get deviceName => _localizedValues[locale.languageCode]!['deviceName']!;
  String get childName => _localizedValues[locale.languageCode]!['childName']!;
  String get childAge => _localizedValues[locale.languageCode]!['childAge']!;
  String get childGender => _localizedValues[locale.languageCode]!['childGender']!;
  String get deviceStatus => _localizedValues[locale.languageCode]!['deviceStatus']!;
  String get deviceLocked => _localizedValues[locale.languageCode]!['deviceLocked']!;
  String get deviceUnlocked => _localizedValues[locale.languageCode]!['deviceUnlocked']!;
  String get lockDevice => _localizedValues[locale.languageCode]!['lockDevice']!;
  String get unlockDevice => _localizedValues[locale.languageCode]!['unlockDevice']!;

  // Prayer Times
  String get prayerTimes => _localizedValues[locale.languageCode]!['prayerTimes']!;
  String get fajr => _localizedValues[locale.languageCode]!['fajr']!;
  String get dhuhr => _localizedValues[locale.languageCode]!['dhuhr']!;
  String get asr => _localizedValues[locale.languageCode]!['asr']!;
  String get maghrib => _localizedValues[locale.languageCode]!['maghrib']!;
  String get isha => _localizedValues[locale.languageCode]!['isha']!;
  String get nextPrayer => _localizedValues[locale.languageCode]!['nextPrayer']!;
  String get prayerLock => _localizedValues[locale.languageCode]!['prayerLock']!;
  String get prayerNotification => _localizedValues[locale.languageCode]!['prayerNotification']!;

  // App Usage
  String get appUsage => _localizedValues[locale.languageCode]!['appUsage']!;
  String get topApps => _localizedValues[locale.languageCode]!['topApps']!;
  String get appLimits => _localizedValues[locale.languageCode]!['appLimits']!;
  String get usageTime => _localizedValues[locale.languageCode]!['usageTime']!;
  String get limitReached => _localizedValues[locale.languageCode]!['limitReached']!;
  String get timeRemaining => _localizedValues[locale.languageCode]!['timeRemaining']!;

  // Reports
  String get dailyReport => _localizedValues[locale.languageCode]!['dailyReport']!;
  String get weeklyReport => _localizedValues[locale.languageCode]!['weeklyReport']!;
  String get monthlyReport => _localizedValues[locale.languageCode]!['monthlyReport']!;
  String get totalUsage => _localizedValues[locale.languageCode]!['totalUsage']!;
  String get averageUsage => _localizedValues[locale.languageCode]!['averageUsage']!;
  String get mostUsedApps => _localizedValues[locale.languageCode]!['mostUsedApps']!;

  // Master Parents
  String get masterParentProfiles => _localizedValues[locale.languageCode]!['masterParentProfiles']!;
  String get defaultProfiles => _localizedValues[locale.languageCode]!['defaultProfiles']!;
  String get applyProfile => _localizedValues[locale.languageCode]!['applyProfile']!;
  String get profileDescription => _localizedValues[locale.languageCode]!['profileDescription']!;
  String get yearsOfExperience => _localizedValues[locale.languageCode]!['yearsOfExperience']!;

  // Settings
  String get language => _localizedValues[locale.languageCode]!['language']!;
  String get theme => _localizedValues[locale.languageCode]!['theme']!;
  String get notifications => _localizedValues[locale.languageCode]!['notifications']!;
  String get privacy => _localizedValues[locale.languageCode]!['privacy']!;
  String get about => _localizedValues[locale.languageCode]!['about']!;

  // Gender
  String get male => _localizedValues[locale.languageCode]!['male']!;
  String get female => _localizedValues[locale.languageCode]!['female']!;

  // Age Groups
  String get ageGroup2to3 => _localizedValues[locale.languageCode]!['ageGroup2to3']!;
  String get ageGroup4to6 => _localizedValues[locale.languageCode]!['ageGroup4to6']!;
  String get ageGroup7to10 => _localizedValues[locale.languageCode]!['ageGroup7to10']!;
  String get ageGroup11to14 => _localizedValues[locale.languageCode]!['ageGroup11to14']!;

  // Languages
  String get arabic => _localizedValues[locale.languageCode]!['arabic']!;
  String get english => _localizedValues[locale.languageCode]!['english']!;

  // Themes
  String get lightTheme => _localizedValues[locale.languageCode]!['lightTheme']!;
  String get darkTheme => _localizedValues[locale.languageCode]!['darkTheme']!;
  String get systemTheme => _localizedValues[locale.languageCode]!['systemTheme']!;

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appName': '3ialna Parental Control',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'add': 'Add',
      'search': 'Search',
      'settings': 'Settings',
      'profile': 'Profile',
      'logout': 'Logout',
      'login': 'Login',
      'register': 'Register',
      'email': 'Email',
      'password': 'Password',
      'confirmPassword': 'Confirm Password',
      'firstName': 'First Name',
      'lastName': 'Last Name',
      'phone': 'Phone',
      'forgotPassword': 'Forgot Password?',
      'resetPassword': 'Reset Password',
      'home': 'Home',
      'childDevices': 'Child Devices',
      'reports': 'Reports',
      'masterParents': 'Master Parents',
      'deviceName': 'Device Name',
      'childName': 'Child Name',
      'childAge': 'Child Age',
      'childGender': 'Child Gender',
      'deviceStatus': 'Device Status',
      'deviceLocked': 'Device Locked',
      'deviceUnlocked': 'Device Unlocked',
      'lockDevice': 'Lock Device',
      'unlockDevice': 'Unlock Device',
      'prayerTimes': 'Prayer Times',
      'fajr': 'Fajr',
      'dhuhr': 'Dhuhr',
      'asr': 'Asr',
      'maghrib': 'Maghrib',
      'isha': 'Isha',
      'nextPrayer': 'Next Prayer',
      'prayerLock': 'Prayer Lock',
      'prayerNotification': 'Prayer Notification',
      'appUsage': 'App Usage',
      'topApps': 'Top Apps',
      'appLimits': 'App Limits',
      'usageTime': 'Usage Time',
      'limitReached': 'Limit Reached',
      'timeRemaining': 'Time Remaining',
      'dailyReport': 'Daily Report',
      'weeklyReport': 'Weekly Report',
      'monthlyReport': 'Monthly Report',
      'totalUsage': 'Total Usage',
      'averageUsage': 'Average Usage',
      'mostUsedApps': 'Most Used Apps',
      'masterParentProfiles': 'Master Parent Profiles',
      'defaultProfiles': 'Default Profiles',
      'applyProfile': 'Apply Profile',
      'profileDescription': 'Profile Description',
      'yearsOfExperience': 'Years of Experience',
      'language': 'Language',
      'theme': 'Theme',
      'notifications': 'Notifications',
      'privacy': 'Privacy',
      'about': 'About',
      'male': 'Male',
      'female': 'Female',
      'ageGroup2to3': '2-3 Years',
      'ageGroup4to6': '4-6 Years',
      'ageGroup7to10': '7-10 Years',
      'ageGroup11to14': '11-14 Years',
      'arabic': 'Arabic',
      'english': 'English',
      'lightTheme': 'Light',
      'darkTheme': 'Dark',
      'systemTheme': 'System',
    },
    'ar': {
      'appName': 'عيالنا - الرقابة الأبوية',
      'loading': 'جاري التحميل...',
      'error': 'خطأ',
      'success': 'نجح',
      'cancel': 'إلغاء',
      'save': 'حفظ',
      'delete': 'حذف',
      'edit': 'تعديل',
      'add': 'إضافة',
      'search': 'بحث',
      'settings': 'الإعدادات',
      'profile': 'الملف الشخصي',
      'logout': 'تسجيل الخروج',
      'login': 'تسجيل الدخول',
      'register': 'إنشاء حساب',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'confirmPassword': 'تأكيد كلمة المرور',
      'firstName': 'الاسم الأول',
      'lastName': 'اسم العائلة',
      'phone': 'رقم الهاتف',
      'forgotPassword': 'نسيت كلمة المرور؟',
      'resetPassword': 'إعادة تعيين كلمة المرور',
      'home': 'الرئيسية',
      'childDevices': 'أجهزة الأطفال',
      'reports': 'التقارير',
      'masterParents': 'الآباء المختصين',
      'deviceName': 'اسم الجهاز',
      'childName': 'اسم الطفل',
      'childAge': 'عمر الطفل',
      'childGender': 'جنس الطفل',
      'deviceStatus': 'حالة الجهاز',
      'deviceLocked': 'الجهاز مقفل',
      'deviceUnlocked': 'الجهاز مفتوح',
      'lockDevice': 'قفل الجهاز',
      'unlockDevice': 'فتح الجهاز',
      'prayerTimes': 'أوقات الصلاة',
      'fajr': 'الفجر',
      'dhuhr': 'الظهر',
      'asr': 'العصر',
      'maghrib': 'المغرب',
      'isha': 'العشاء',
      'nextPrayer': 'الصلاة التالية',
      'prayerLock': 'قفل الصلاة',
      'prayerNotification': 'إشعار الصلاة',
      'appUsage': 'استخدام التطبيقات',
      'topApps': 'أكثر التطبيقات استخداماً',
      'appLimits': 'حدود التطبيقات',
      'usageTime': 'وقت الاستخدام',
      'limitReached': 'تم الوصول للحد الأقصى',
      'timeRemaining': 'الوقت المتبقي',
      'dailyReport': 'التقرير اليومي',
      'weeklyReport': 'التقرير الأسبوعي',
      'monthlyReport': 'التقرير الشهري',
      'totalUsage': 'إجمالي الاستخدام',
      'averageUsage': 'متوسط الاستخدام',
      'mostUsedApps': 'أكثر التطبيقات استخداماً',
      'masterParentProfiles': 'ملفات الآباء المختصين',
      'defaultProfiles': 'الملفات الافتراضية',
      'applyProfile': 'تطبيق الملف',
      'profileDescription': 'وصف الملف',
      'yearsOfExperience': 'سنوات الخبرة',
      'language': 'اللغة',
      'theme': 'المظهر',
      'notifications': 'الإشعارات',
      'privacy': 'الخصوصية',
      'about': 'حول التطبيق',
      'male': 'ذكر',
      'female': 'أنثى',
      'ageGroup2to3': '2-3 سنوات',
      'ageGroup4to6': '4-6 سنوات',
      'ageGroup7to10': '7-10 سنوات',
      'ageGroup11to14': '11-14 سنة',
      'arabic': 'العربية',
      'english': 'الإنجليزية',
      'lightTheme': 'فاتح',
      'darkTheme': 'داكن',
      'systemTheme': 'النظام',
    },
  };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
