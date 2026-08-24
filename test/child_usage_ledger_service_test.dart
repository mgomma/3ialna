import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mu_super_app/data/local/child_usage_ledger_service.dart';
import 'package:mu_super_app/data/system/app_usage_service.dart';

void main() {
  const ChildUsageLedgerService ledger = ChildUsageLedgerService();
  final DateTime observedAt = DateTime(2026, 8, 24, 10);

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('attributes observed deltas to the child selected at the observation',
      () async {
    await ledger.recordObservedUsage(
      childId: 'child-a',
      observedAt: observedAt,
      observedUsage: const AppUsageSummary(
        totalMinutes: 12,
        perAppMinutes: <String, int>{'com.instagram.android': 7},
      ),
    );
    final ChildUsageLedgerEntry childA = await ledger.recordObservedUsage(
      childId: 'child-a',
      observedAt: observedAt.add(const Duration(minutes: 5)),
      observedUsage: const AppUsageSummary(
        totalMinutes: 17,
        perAppMinutes: <String, int>{'com.instagram.android': 10},
      ),
    );
    final ChildUsageLedgerEntry childB = await ledger.recordObservedUsage(
      childId: 'child-b',
      observedAt: observedAt.add(const Duration(minutes: 10)),
      observedUsage: const AppUsageSummary(
        totalMinutes: 21,
        perAppMinutes: <String, int>{'com.instagram.android': 12},
      ),
    );

    expect(childA.totalMinutes, 5);
    expect(childA.appUsageMinutes['com.instagram.android'], 3);
    expect(childB.totalMinutes, 4);
    expect(childB.appUsageMinutes['com.instagram.android'], 2);
  });

  test('keeps child report aggregates separate while allowing an all-child view',
      () async {
    await ledger.recordObservedUsage(
      childId: 'child-a',
      observedAt: observedAt,
      observedUsage: const AppUsageSummary(
        totalMinutes: 0,
        perAppMinutes: <String, int>{},
      ),
    );
    await ledger.recordObservedUsage(
      childId: 'child-a',
      observedAt: observedAt.add(const Duration(minutes: 4)),
      observedUsage: const AppUsageSummary(
        totalMinutes: 4,
        perAppMinutes: <String, int>{'com.instagram.android': 4},
      ),
    );
    await ledger.recordObservedUsage(
      childId: 'child-b',
      observedAt: observedAt.add(const Duration(minutes: 7)),
      observedUsage: const AppUsageSummary(
        totalMinutes: 7,
        perAppMinutes: <String, int>{'com.instagram.android': 5},
      ),
    );

    final ChildUsageLedgerAggregate childA = await ledger.loadAggregate(
      childId: 'child-a',
      start: observedAt,
      end: observedAt,
    );
    final ChildUsageLedgerAggregate allChildren = await ledger.loadAggregate(
      start: observedAt,
      end: observedAt,
    );

    expect(childA.totalMinutes, 4);
    expect(allChildren.totalMinutes, 7);
    expect(allChildren.appUsageMinutes['com.instagram.android'], 5);
  });
}
