import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';

class PrivacyAccountScreen extends StatelessWidget {
  const PrivacyAccountScreen({super.key});

  static const String privacyPolicyUrl =
      'https://mgomma.github.io/3ialna/privacy.html';
  static const String accountDeletionUrl =
      'https://mgomma.github.io/3ialna/account-deletion.html';
  static const String supportEmail = '3ialna.app@gmail.com';

  static Uri accountDeletionRequestUri({
    required String subject,
    required String body,
  }) {
    return Uri(
      scheme: 'mailto',
      path: supportEmail,
      queryParameters: <String, String>{
        'subject': subject,
        'body': body,
      },
    );
  }

  Future<void> _openLink(BuildContext context, Uri uri) async {
    final bool opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.externalLinkFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyAccountTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(l10n.privacyAccountSummary),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.policy_outlined),
              title: Text(l10n.privacyPolicy),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _openLink(
                context,
                Uri.parse(privacyPolicyUrl),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.accountDeletionTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.accountDeletionBody),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    key: const ValueKey<String>('request-account-deletion'),
                    onPressed: () => _openLink(
                      context,
                      accountDeletionRequestUri(
                        subject: l10n.accountDeletionEmailSubject,
                        body: l10n.accountDeletionEmailBody,
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline),
                    label: Text(l10n.requestAccountDeletion),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(supportEmail),
                  TextButton(
                    onPressed: () => _openLink(
                      context,
                      Uri.parse(accountDeletionUrl),
                    ),
                    child: Text(l10n.accountDeletionTitle),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
