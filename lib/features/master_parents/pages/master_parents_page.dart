import 'package:flutter/material.dart';
import '../../../core/utils/app_localizations.dart';

class MasterParentsPage extends StatelessWidget {
  const MasterParentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.masterParents),
      ),
      body: const Center(
        child: Text('Master Parents Page - Coming Soon'),
      ),
    );
  }
}
