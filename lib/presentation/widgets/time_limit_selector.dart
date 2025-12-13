import 'package:flutter/material.dart';

/// Widget for selecting a time limit in minutes.
class TimeLimitSelector extends StatefulWidget {
  final int? initialMinutes;
  final ValueChanged<int> onTimeLimitSelected;

  const TimeLimitSelector({
    super.key,
    this.initialMinutes,
    required this.onTimeLimitSelected,
  });

  @override
  State<TimeLimitSelector> createState() => _TimeLimitSelectorState();
}

class _TimeLimitSelectorState extends State<TimeLimitSelector> {
  int? _selectedMinutes;

  final List<int> _presetMinutes = [
    15,
    30,
    60,
    90,
    120,
    180,
    240,
  ];

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
              'Set Time Limit',
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
                labelText: 'Custom (minutes)',
                hintText: 'Enter minutes',
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
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _selectedMinutes != null
                      ? () {
                          widget.onTimeLimitSelected(_selectedMinutes!);
                          Navigator.of(context).pop();
                        }
                      : null,
                  child: const Text('Set'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${remainingMinutes}m';
  }
}

