import 'package:flutter_test/flutter_test.dart';

import '../../../tool/src/activate_command.dart';

void main() {
  group('activationProblem - Unit Test Suite', () {
    final allowed = <(String, Map<String, Object?>?)>[
      ('Edge Case: an organization without a registry entry', null),
      ('Edge Case: a legacy entry without status', {'active': true}),
      ('Happy Path: a provisioning organization', {'status': 'provisioning'}),
      ('Happy Path: a failed organization', {'status': 'failed'}),
      ('Happy Path: an active organization', {'status': 'active'}),
    ];
    for (final (label, registry) in allowed) {
      test('$label may be activated', () {
        // 1. Arrange
        const retired = false;

        // 2. Act
        final problem = activationProblem('acme', registry, retired: retired);

        // 3. Assert
        expect(problem, isNull);
      });
    }

    final refused = <(String, Map<String, Object?>?)>[
      ('a reserved organization', {'status': 'reserved'}),
      ('an organization awaiting billing', {'status': 'awaiting_billing'}),
      ('a migrating organization', {'status': 'migrating'}),
      ('a deleting organization', {'status': 'deleting'}),
      ('an unknown status', {'status': 'archived'}),
      ('a non-String status', {'status': 42}),
    ];
    for (final (label, registry) in refused) {
      test('Sad Path: $label is refused with a message', () {
        // 1. Arrange
        const retired = false;

        // 2. Act
        final problem = activationProblem('acme', registry, retired: retired);

        // 3. Assert
        expect(problem, allOf(isNotNull, isNotEmpty, contains('acme')));
      });
    }

    final retiredCases = <(String, Map<String, Object?>?)>[
      ('without a registry entry', null),
      ('with an active status', {'status': 'active'}),
      ('with a legacy entry', {'active': true}),
    ];
    for (final (label, registry) in retiredCases) {
      test('Sad Path: a retired id $label is refused', () {
        // 1. Arrange
        const retired = true;

        // 2. Act
        final problem = activationProblem('acme', registry, retired: retired);

        // 3. Assert
        expect(problem, allOf(isNotNull, contains('retired')));
      });
    }
  });
}
