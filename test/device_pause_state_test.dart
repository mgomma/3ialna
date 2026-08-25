import 'package:flutter_test/flutter_test.dart';

import 'package:mu_super_app/data/local/device_pause_service.dart';

void main() {
  test('pause state is active before its expiry and reports remaining minutes', () {
    final DevicePauseState state = DevicePauseState(
      until: DateTime.now().add(const Duration(minutes: 30)),
      reason: 'homework',
      childId: 'child-1',
    );

    expect(state.isActive, isTrue);
    expect(state.remainingMinutes, inInclusiveRange(29, 30));
    expect(state.reason, 'homework');
    expect(state.childId, 'child-1');
  });

  test('pause state is inactive after its expiry', () {
    final DevicePauseState state = DevicePauseState(
      until: DateTime.now().subtract(const Duration(seconds: 1)),
      reason: 'family_time',
      childId: 'child-1',
    );

    expect(state.isActive, isFalse);
    expect(state.remainingMinutes, 0);
  });
}
