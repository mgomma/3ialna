import 'package:flutter/material.dart';

import '../../features/auth/pages/login_page.dart';
import '../../features/auth/pages/register_page.dart';
import '../../features/home/pages/home_page.dart';
import '../../features/child_devices/pages/child_devices_page.dart';
import '../../features/child_devices/pages/device_details_page.dart';
import '../../features/reports/pages/reports_page.dart';
import '../../features/settings/pages/settings_page.dart';
import '../../features/master_parents/pages/master_parents_page.dart';
import '../../features/master_parents/pages/master_parent_profile_page.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String childDevices = '/child-devices';
  static const String deviceDetails = '/device-details';
  static const String reports = '/reports';
  static const String settings = '/settings';
  static const String masterParents = '/master-parents';
  static const String masterParentProfile = '/master-parent-profile';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
          settings: settings,
        );

      case register:
        return MaterialPageRoute(
          builder: (_) => const RegisterPage(),
          settings: settings,
        );

      case home:
        return MaterialPageRoute(
          builder: (_) => const HomePage(),
          settings: settings,
        );

      case childDevices:
        return MaterialPageRoute(
          builder: (_) => const ChildDevicesPage(),
          settings: settings,
        );

      case deviceDetails:
        final args = settings.arguments as Map<String, dynamic>?;
        final deviceId = args?['deviceId'] as int?;
        if (deviceId == null) {
          return _errorRoute('Device ID is required');
        }
        return MaterialPageRoute(
          builder: (_) => DeviceDetailsPage(deviceId: deviceId),
          settings: settings,
        );

      case reports:
        final args = settings.arguments as Map<String, dynamic>?;
        final deviceId = args?['deviceId'] as int?;
        return MaterialPageRoute(
          builder: (_) => ReportsPage(deviceId: deviceId),
          settings: settings,
        );

      case settings:
        return MaterialPageRoute(
          builder: (_) => const SettingsPage(),
          settings: settings,
        );

      case masterParents:
        return MaterialPageRoute(
          builder: (_) => const MasterParentsPage(),
          settings: settings,
        );

      case masterParentProfile:
        final args = settings.arguments as Map<String, dynamic>?;
        final profileId = args?['profileId'] as int?;
        if (profileId == null) {
          return _errorRoute('Profile ID is required');
        }
        return MaterialPageRoute(
          builder: (_) => MasterParentProfilePage(profileId: profileId),
          settings: settings,
        );

      default:
        return _errorRoute('Route not found');
    }
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: Center(
          child: Text(message),
        ),
      ),
    );
  }
}
