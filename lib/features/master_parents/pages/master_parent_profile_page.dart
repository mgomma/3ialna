import 'package:flutter/material.dart';
import '../../../core/utils/app_localizations.dart';

class MasterParentProfilePage extends StatelessWidget {
  final int profileId;

  const MasterParentProfilePage({super.key, required this.profileId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.masterParentProfiles} - $profileId'),
      ),
      body: Center(
        child: Text('Master Parent Profile Page - Coming Soon\nProfile ID: $profileId'),
      ),
    );
  }
}
