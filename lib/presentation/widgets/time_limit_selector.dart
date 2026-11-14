import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Widget for selecting a time limit in minutes.
class TimeLimitSelector extends StatefulWidget {
  final int? initialMinutes;
  final ValueChanged<int> onTimeLimitSelected;
  final Future<void> Function()? onTimeLimitRemoved;

  const TimeLimitSelector({
    super.key,
    this.initialMinutes,
    required this.onTimeLimitSelected,
    this.onTimeLimitRemoved,
  });

  @override
  State<TimeLimitSelector> createState() => _TimeLimitSelectorState();
}

class _TimeLimitSelectorState extends State<TimeLimitSelector> {
  int? _selectedMinutes;
  bool _isRemoving = false;

  final List<int> _presetMinutes = [15, 30, 60, 90, 120, 180, 240];

  @override
  void initState() {
    super.initState();
    _selectedMinutes = widget.initialMinutes;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.setTimeLimitTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            // Preset buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presetMinutes.map((minutes) {
                final isSelected = _selectedMinutes == minutes;
                return FilterChip(
                  label: Text(_formatMinutes(minutes)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedMinutes = selected ? minutes : null;
                    });
                  },
                  selectedColor: colorScheme.primaryContainer,
                  checkmarkColor: colorScheme.onPrimaryContainer,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Custom input
            TextField(
              decoration: InputDecoration(
                labelText: context.l10n.customTimeLimitMinutes,
                hintText: context.l10n.enterTimeLimitMinutes,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final minutes = int.tryParse(value);
                if (minutes != null && minutes > 0) {
                  setState(() {
                    _selectedMinutes = minutes;
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            // Action buttons
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                if (widget.initialMinutes != null &&
                    widget.onTimeLimitRemoved != null)
                  TextButton(
                    onPressed: _isRemoving ? null : _removeTimeLimit,
                    child: Text(context.l10n.removeTimeLimit),
                  ),
                TextButton(
                  onPressed: _isRemoving
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text(context.l10n.cancel),
                ),
                FilledButton(
                  onPressed: _selectedMinutes != null && !_isRemoving
                      ? () {
                          widget.onTimeLimitSelected(_selectedMinutes!);
                          Navigator.of(context).pop();
                        }
                      : null,
                  child: Text(context.l10n.save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeTimeLimit() async {
    setState(() => _isRemoving = true);
    try {
      await widget.onTimeLimitRemoved!();
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isRemoving = false);
    }
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) {
      return context.l10n.shortMinutes(minutes);
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) {
      return context.l10n.shortHours(hours);
    }
    return '${context.l10n.shortHours(hours)} ${context.l10n.shortMinutes(remainingMinutes)}';
  }
}
