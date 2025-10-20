import 'package:flutter/material.dart';
import '../../../core/utils/app_localizations.dart';

class DeviceDetailsPage extends StatelessWidget {
  final int deviceId;

  const DeviceDetailsPage({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.deviceName} - $deviceId'),
      ),
      body: Center(
        child: Text('Device Details Page - Coming Soon\nDevice ID: $deviceId'),
      ),
    );
  }
}
