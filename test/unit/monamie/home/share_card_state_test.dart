import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/share_card_state.dart';

void main() {
  group('shareCardState - Unit Test Suite', () {
    // (label, enabled, loading, phase, busy, isOn)
    final cases = <(String, bool, bool, SharePhase, bool, bool)>[
      (
        'Happy Path: enabled and idle is on',
        true,
        false,
        SharePhase.on,
        false,
        true,
      ),
      (
        'Happy Path: disabled and idle is off',
        false,
        false,
        SharePhase.off,
        false,
        false,
      ),
      (
        'Edge Case: loading while disabled is starting',
        false,
        true,
        SharePhase.starting,
        true,
        false,
      ),
      (
        'Edge Case: loading while enabled is stopping and still reads on',
        true,
        true,
        SharePhase.stopping,
        true,
        true,
      ),
    ];
    for (final (label, enabled, loading, phase, busy, isOn) in cases) {
      test(label, () {
        // 1. Arrange
        final flags = (enabled: enabled, loading: loading);

        // 2. Act
        final state = shareCardState(
          enabled: flags.enabled,
          loading: flags.loading,
        );

        // 3. Assert
        expect((state.phase, state.busy, state.isOn), (phase, busy, isOn));
      });
    }
  });
}
