import 'package:flutter/material.dart';

/// Parent-facing reminder for a shared device. It deliberately routes through
/// Kids Management instead of switching profiles directly so Parent mode
/// remains protected by the established PIN or biometric flow.
class ActiveChildHandoverReminderCard extends StatelessWidget {
  const ActiveChildHandoverReminderCard({
    required this.isArabic,
    required this.childProfileCount,
    required this.isParentModeActive,
    required this.activeChildName,
    required this.onConfirmActiveUser,
    super.key,
  });

  final bool isArabic;
  final int childProfileCount;
  final bool isParentModeActive;
  final String? activeChildName;
  final VoidCallback onConfirmActiveUser;

  @override
  Widget build(BuildContext context) {
    if (childProfileCount < 2) return const SizedBox.shrink();

    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final String currentUser = isParentModeActive
        ? (isArabic ? 'وضع الوالدين' : 'Parent mode')
        : (activeChildName?.trim().isNotEmpty == true
            ? activeChildName!.trim()
            : (isArabic ? 'طفل محدد' : 'a child profile'));

    return Card(
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.people_outline, color: colors.onPrimaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isArabic ? 'تأكيد المستخدم قبل تسليم الجهاز' : 'Confirm the user before handover',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isParentModeActive
                  ? (isArabic
                      ? 'الجهاز الآن في وضع الوالدين. اختر ملف الطفل قبل تسليم الهاتف حتى تعود الحدود والسجل الخاص به.'
                      : 'The device is currently in Parent mode. Choose the child profile before handing it over so that child limits and local history resume.')
                  : (isArabic
                      ? 'المستخدم النشط الآن: $currentUser. تأكد من الاسم قبل تسليم الهاتف حتى تنطبق الحدود والسجل الصحيحان.'
                      : 'Current active user: $currentUser. Confirm the name before handover so the correct limits and local history apply.'),
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.onPrimaryContainer),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const Key('handover-confirm-active-user'),
              style: OutlinedButton.styleFrom(foregroundColor: colors.onPrimaryContainer),
              onPressed: onConfirmActiveUser,
              icon: const Icon(Icons.manage_accounts_outlined),
              label: Text(isArabic ? 'تأكيد أو تغيير المستخدم' : 'Confirm or switch user'),
            ),
          ],
        ),
      ),
    );
  }
}
