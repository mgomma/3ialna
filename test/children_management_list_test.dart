import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mu_super_app/domain/models/age_safety_profile.dart';
import 'package:mu_super_app/domain/models/child_profile.dart';
import 'package:mu_super_app/presentation/parental_control/widgets/children_management_list.dart';

ChildProfile _child({required String id, required String name}) => ChildProfile(
      id: id,
      name: name,
      birthDate: DateTime(2018, 1, 1),
      gender: ChildGender.unspecified,
      preset: AgeSafetyProfilePreset.defaults[AgeSafetyProfile.underFive]!,
    );

Widget _testApp(Widget child) => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  testWidgets('shows an actionable empty state when no children are supplied', (WidgetTester tester) async {
    var addPressed = false;
    await tester.pumpWidget(
      _testApp(
        ChildrenManagementList(
          children: const <ChildProfile>[],
          activeChildId: null,
          isArabic: false,
          detailsFor: (_) => '',
          onSelect: (_) {},
          onEdit: (_) {},
          onAdd: () => addPressed = true,
          onDelete: (_) {},
        ),
      ),
    );

    expect(find.byKey(const ValueKey<String>('kids-management-empty-state')), findsOneWidget);
    expect(find.text('No children have been added yet'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('add-child-button')));
    expect(addPressed, isTrue);
  });

  testWidgets('shows a newly added child and selects that child', (WidgetTester tester) async {
    final List<ChildProfile> children = <ChildProfile>[];
    String? selectedId;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) => _testApp(
          ChildrenManagementList(
            children: children,
            activeChildId: selectedId,
            isArabic: false,
            detailsFor: (_) => '6 years · Not specified',
            onSelect: (ChildProfile child) => setState(() => selectedId = child.id),
            onEdit: (_) {},
            onAdd: () => setState(() => children.add(_child(id: 'mariam', name: 'Mariam'))),
            onDelete: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('add-child-button')));
    await tester.pump();

    expect(find.byKey(const ValueKey<String>('kids-management-list')), findsOneWidget);
    expect(find.text('Mariam'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('child-row-mariam')));
    await tester.pump();
    expect(selectedId, 'mariam');
  });
}
