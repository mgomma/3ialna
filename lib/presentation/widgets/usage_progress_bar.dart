import 'package:flutter/material.dart';

/// Widget displaying a progress bar for app usage vs time limit.
class UsageProgressBar extends StatelessWidget {
  final int usedMinutes;
  final int limitMinutes;
  final String? label;

  const UsageProgressBar({
    super.key,
    required this.usedMinutes,
    required this.limitMinutes,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final progress = limitMinutes > 0
        ? (usedMinutes / limitMinutes).clamp(0.0, 1.0)
        : 0.0;
    final isOverLimit = usedMinutes >= limitMinutes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOverLimit ? colorScheme.error : colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$usedMinutes / $limitMinutes min',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isOverLimit
                    ? colorScheme.error
                    : colorScheme.onSurface,
              ),
            ),
          ],
        ),
        if (isOverLimit) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 16,
                color: colorScheme.error,
              ),
              const SizedBox(width: 4),
              Text(
                'Time limit exceeded',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

