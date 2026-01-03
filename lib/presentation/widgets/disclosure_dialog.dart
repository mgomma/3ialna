import 'package:flutter/material.dart';

/// A reusable dialog for showing prominent disclosures as required by Google Play Policy.
///
/// This dialog explains "What data is accessed" and "How it is used" before
/// requesting sensitive permissions.
class DisclosureDialog extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback onAgree;
  final String agreeLabel;
  final String cancelLabel;
  final Color? iconColor;

  const DisclosureDialog({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.onAgree,
    this.agreeLabel = 'Agree',
    this.cancelLabel = 'No thanks',
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(icon, size: 48, color: iconColor ?? Theme.of(context).colorScheme.primary),
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [Text(message, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.start)],
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(cancelLabel)),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            onAgree();
          },
          child: Text(agreeLabel),
        ),
      ],
    );
  }

  /// Helper to show the dialog and wait for result.
  /// Returns locally [true] if user agreed, [false] otherwise.
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    required IconData icon,
    required VoidCallback onAgree,
    Color? iconColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DisclosureDialog(title: title, message: message, icon: icon, onAgree: onAgree, iconColor: iconColor),
    );
    return result ?? false;
  }
}
