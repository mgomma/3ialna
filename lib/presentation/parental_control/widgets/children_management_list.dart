import 'package:flutter/material.dart';

import '../../../domain/models/child_profile.dart';

/// Lists the children configured on this device and exposes parent-only actions.
///
/// The empty state is deliberately explicit, even though the profile service
/// normally creates a default child for a newly configured device.
class ChildrenManagementList extends StatelessWidget {
  const ChildrenManagementList({
    super.key,
    required this.children,
    required this.activeChildId,
    required this.isArabic,
    required this.detailsFor,
    required this.onSelect,
    required this.onEdit,
    required this.onAdd,
    required this.onDelete,
  });

  final List<ChildProfile> children;
  final String? activeChildId;
  final bool isArabic;
  final String Function(ChildProfile child) detailsFor;
  final ValueChanged<ChildProfile> onSelect;
  final ValueChanged<ChildProfile> onEdit;
  final VoidCallback onAdd;
  final ValueChanged<ChildProfile> onDelete;

  @override
  Widget build(BuildContext context) {
    final String addLabel = isArabic ? 'إضافة طفل' : 'Add child';
    if (children.isEmpty) {
      return Column(
        key: const ValueKey<String>('kids-management-empty-state'),
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(height: 24),
          const Icon(Icons.child_care_outlined, size: 42),
          const SizedBox(height: 12),
          Text(isArabic ? 'لا يوجد أطفال مضافون بعد' : 'No children have been added yet'),
          const SizedBox(height: 8),
          Text(
            isArabic ? 'أضف طفلاً لبدء إعداد الحماية.' : 'Add a child to begin configuring protection.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const ValueKey<String>('add-child-button'),
            icon: const Icon(Icons.person_add_alt_1),
            label: Text(addLabel),
            onPressed: onAdd,
          ),
        ],
      );
    }

    return Column(
      key: const ValueKey<String>('kids-management-list'),
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ...children.map(
          (ChildProfile child) => ListTile(
            key: ValueKey<String>('child-row-${child.id}'),
            selected: child.id == activeChildId,
            leading: CircleAvatar(
              child: Text(child.name.isEmpty ? '?' : child.name.substring(0, 1).toUpperCase()),
            ),
            title: Text(child.name.isEmpty ? (isArabic ? 'طفل بلا اسم' : 'Unnamed child') : child.name),
            subtitle: Text(detailsFor(child)),
            onTap: () => onSelect(child),
            trailing: Wrap(
              children: <Widget>[
                IconButton(
                  tooltip: isArabic ? 'تعديل الطفل' : 'Edit child',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => onEdit(child),
                ),
                if (children.length > 1)
                  IconButton(
                    tooltip: isArabic ? 'حذف الطفل' : 'Delete child',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => onDelete(child),
                  ),
              ],
            ),
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: const ValueKey<String>('add-child-button'),
            icon: const Icon(Icons.person_add_alt_1),
            label: Text(addLabel),
            onPressed: onAdd,
          ),
        ),
      ],
    );
  }
}
