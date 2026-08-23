import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../domain/models/app_info.dart';

/// Widget displaying an app card with icon, name, and control options.
class AppCard extends StatelessWidget {
  final AppInfo appInfo;
  final bool isBlocked;
  final int? timeLimitMinutes;
  final int? currentUsageMinutes;
  final VoidCallback? onToggleBlock;
  final VoidCallback? onSetTimeLimit;
  final String? categoryLabel;
  final VoidCallback? onSetCategory;

  const AppCard({
    super.key,
    required this.appInfo,
    this.isBlocked = false,
    this.timeLimitMinutes,
    this.currentUsageMinutes,
    this.onToggleBlock,
    this.onSetTimeLimit,
    this.categoryLabel,
    this.onSetCategory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // App icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: colorScheme.surfaceContainerHighest,
                  ),
                      child: appInfo.iconBase64 != null && appInfo.iconBase64!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildAppIcon(appInfo.iconBase64!, colorScheme),
                        )
                      : Icon(
                          Icons.android,
                          color: colorScheme.onSurfaceVariant,
                        ),
                ),
                const SizedBox(width: 12),
                // App name and package
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appInfo.appName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appInfo.packageName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Block toggle
                Switch(
                  value: isBlocked,
                  onChanged: onToggleBlock != null
                      ? (_) => onToggleBlock!()
                      : null,
                ),
              ],
            ],
            if (onSetCategory != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onSetCategory,
                  icon: const Icon(Icons.category_outlined),
                  label: Text('Category: ${categoryLabel ?? 'Not assigned'}'),
                ),
              ),
            ],
            // Usage info and time limit
            if (timeLimitMinutes != null || currentUsageMinutes != null) ...[
              const SizedBox(height: 12),
              if (timeLimitMinutes != null)
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Limit: ${timeLimitMinutes}m/day',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              if (currentUsageMinutes != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Used: ${currentUsageMinutes}m',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: timeLimitMinutes != null && timeLimitMinutes! > 0
                      ? (currentUsageMinutes! / timeLimitMinutes!).clamp(0.0, 1.0)
                      : null,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    currentUsageMinutes != null &&
                            timeLimitMinutes != null &&
                            currentUsageMinutes! >= timeLimitMinutes!
                        ? colorScheme.error
                        : colorScheme.primary,
                  ),
                ),
              ],
            ],
            // Set time limit button
            if (onSetTimeLimit != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onSetTimeLimit,
                  icon: const Icon(Icons.schedule),
                  label: const Text('Set Time Limit'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Safely decodes Base64 string to image bytes.
  List<int> _decodeBase64(String base64String) {
    try {
      if (base64String.isEmpty) return [];
      // Remove any whitespace or newlines
      final cleaned = base64String.trim().replaceAll(RegExp(r'\s+'), '');
      if (cleaned.isEmpty) return [];
      return base64Decode(cleaned);
    } catch (e) {
      debugPrint('Error decoding Base64 image: $e');
      return [];
    }
  }

  /// Builds app icon widget with proper error handling.
  Widget _buildAppIcon(String iconBase64, ColorScheme colorScheme) {
    final decodedBytes = _decodeBase64(iconBase64);
    if (decodedBytes.isEmpty) {
      return Icon(
        Icons.android,
        color: colorScheme.onSurfaceVariant,
      );
    }

    return Image.memory(
      Uint8List.fromList(decodedBytes),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Error loading app icon: $error');
        return Icon(
          Icons.android,
          color: colorScheme.onSurfaceVariant,
        );
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (frame == null) {
          // Show placeholder while loading
          return Icon(
            Icons.android,
            color: colorScheme.onSurfaceVariant,
          );
        }
        return child;
      },
    );
  }
}
