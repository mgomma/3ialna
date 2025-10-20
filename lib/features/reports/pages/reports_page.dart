import 'package:flutter/material.dart';
import '../../../core/utils/app_localizations.dart';

class ReportsPage extends StatelessWidget {
  final int? deviceId;

  const ReportsPage({super.key, this.deviceId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reports),
      ),
      body: Center(
        child: Text('Reports Page - Coming Soon${deviceId != null ? '\nDevice ID: $deviceId' : ''}'),
      ),
    );
  }
}
