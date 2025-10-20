import 'package:flutter/material.dart';
import '../../../core/utils/app_localizations.dart';

class ChildDevicesPage extends StatelessWidget {
  const ChildDevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.childDevices),
      ),
      body: const Center(
        child: Text('Child Devices Page - Coming Soon'),
      ),
    );
  }
}
