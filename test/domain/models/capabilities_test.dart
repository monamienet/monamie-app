import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/domain/models/capabilities.dart';

void main() {
  group('Capabilities (what the roles allow) - Unit Test Suite', () {
    const caps = Capabilities(
      isMember: true,
      rolesByGroup: {
        'recepcao': {'publisher'},
        'guias': {'publisher', 'subscriber'},
        'bar': {'subscriber'},
      },
    );

    test('Happy Path: publisher and subscriber groups come sorted', () {
      // 1. Arrange
      const subject = caps;

      // 2. Act
      final groups = [subject.publisherGroupIds, subject.subscriberGroupIds];

      // 3. Assert
      expect(groups, [
        ['guias', 'recepcao'],
        ['bar', 'guias'],
      ]);
    });

    test('Happy Path: a subscriber watches only their own groups', () {
      // 1. Arrange
      const subject = caps;

      // 2. Act
      final watches = [
        for (final id in ['guias', 'bar', 'recepcao', 'outro'])
          subject.canWatchGroup(id),
      ];

      // 3. Assert
      expect(watches, [true, true, false, false]);
    });

    test('Edge Case: an administrator in no group watches every group and '
        'publishes in none', () {
      // 1. Arrange
      const subject = Capabilities(isMember: true, isAdmin: true);

      // 2. Act
      final result = [
        subject.canWatch,
        subject.canWatchGroup('any'),
        subject.canPublish,
      ];

      // 3. Assert
      expect(result, [true, true, false]);
    });

    test('Sad Path: someone who only publishes watches no map', () {
      // 1. Arrange
      const subject = Capabilities(
        isMember: true,
        rolesByGroup: {
          'guias': {'publisher'},
        },
      );

      // 2. Act
      final result = [subject.canPublish, subject.canWatch];

      // 3. Assert
      expect(result, [true, false]);
    });
  });

  group('Capabilities (group maintainers) - Unit Test Suite', () {
    test(
      'Happy Path: the maintained groups come sorted and allow managing',
      () {
        // 1. Arrange
        const caps = Capabilities(
          isMember: true,
          rolesByGroup: {
            'recepcao': {'maintainer', 'publisher'},
            'guias': {'subscriber'},
            'bar': {'maintainer'},
          },
        );

        // 2. Act
        final result = [caps.maintainerGroupIds, caps.canManageGroups];

        // 3. Assert
        expect(result, [
          ['bar', 'recepcao'],
          isTrue,
        ]);
      },
    );

    test('Edge Case: an administrator in no group manages groups', () {
      // 1. Arrange
      const caps = Capabilities(isMember: true, isAdmin: true);

      // 2. Act
      final result = [caps.maintainerGroupIds, caps.canManageGroups];

      // 3. Assert
      expect(result, [isEmpty, isTrue]);
    });

    test('Sad Path: publishing and watching do not allow managing', () {
      // 1. Arrange
      const caps = Capabilities(
        isMember: true,
        rolesByGroup: {
          'guias': {'publisher', 'subscriber'},
        },
      );

      // 2. Act
      final result = caps.canManageGroups;

      // 3. Assert
      expect(result, isFalse);
    });

    test('Sad Path: Gestor do grupo alone shows no map', () {
      // 1. Arrange
      const caps = Capabilities(
        isMember: true,
        rolesByGroup: {
          'guias': {'maintainer'},
        },
      );

      // 2. Act
      final result = [caps.canWatch, caps.canWatchGroup('guias')];

      // 3. Assert
      expect(result, [isFalse, isFalse]);
    });
  });

  group('Capabilities equality - Unit Test Suite', () {
    test('Happy Path: the same roles in another order are equal', () {
      // 1. Arrange
      const a = Capabilities(
        isMember: true,
        rolesByGroup: {
          'g1': {'publisher', 'subscriber'},
          'g2': {'subscriber'},
        },
      );
      const b = Capabilities(
        isMember: true,
        rolesByGroup: {
          'g2': {'subscriber'},
          'g1': {'subscriber', 'publisher'},
        },
      );

      // 2. Act
      final equal = a == b;

      // 3. Assert
      expect(equal, isTrue);
    });

    test('Edge Case: the same groups with another role differ', () {
      // 1. Arrange
      const a = Capabilities(
        isMember: true,
        rolesByGroup: {
          'g1': {'publisher'},
        },
      );
      const b = Capabilities(
        isMember: true,
        rolesByGroup: {
          'g1': {'subscriber'},
        },
      );

      // 2. Act
      final equal = a == b;

      // 3. Assert
      expect(equal, isFalse);
    });

    test('Sad Path: becoming an administrator is a change', () {
      // 1. Arrange
      const a = Capabilities(isMember: true);
      const b = Capabilities(isMember: true, isAdmin: true);

      // 2. Act
      final equal = a == b;

      // 3. Assert
      expect(equal, isFalse);
    });
  });
}
