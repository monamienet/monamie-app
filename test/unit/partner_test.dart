import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/config/partner/partner.dart';
import 'package:monamie_app/app/config/partner/partner_config.dart';

import '../support/test_partner.dart';

const otherPartner = PartnerConfig(
  id: 'beta',
  name: 'Beta',
  primaryColor: Color(0xFF445566),
  secondaryColor: Color(0xFF000000),
);

void main() {
  group('testPartner fixture - Unit Test Suite', () {
    test('Happy Path: every test file starts with the inline acme partner', () {
      // 1. Arrange
      const expectedId = 'acme';

      // 2. Act
      final current = Partner.current;

      // 3. Assert
      expect([current.id, current.displayName], [expectedId, 'MonAmie Acme']);
    });
  });

  group('Partner - Unit Test Suite', () {
    setUp(Partner.debugReset);

    tearDown(() {
      Partner.debugReset();
      Partner.init(testPartner);
    });

    test('Happy Path: current returns the config given to init', () {
      // 1. Arrange
      Partner.init(otherPartner);

      // 2. Act
      final current = Partner.current;

      // 3. Assert
      expect(current, same(otherPartner));
    });

    test('Happy Path: init accepts a partner after debugReset', () {
      // 1. Arrange
      Partner.init(testPartner);
      Partner.debugReset();

      // 2. Act
      Partner.init(otherPartner);

      // 3. Assert
      expect(Partner.current, same(otherPartner));
    });

    test('Edge Case: debugReset without a partner set does not throw', () {
      // 1. Arrange
      // setUp left Partner without a partner.

      // 2. Act
      void action() => Partner.debugReset();

      // 3. Assert
      expect(action, returnsNormally);
    });

    test('Sad Path: current throws StateError before init', () {
      // 1. Arrange
      // setUp left Partner without a partner.

      // 2. Act
      PartnerConfig action() => Partner.current;

      // 3. Assert
      expect(action, throwsStateError);
    });

    test('Sad Path: current throws StateError after debugReset', () {
      // 1. Arrange
      Partner.init(otherPartner);
      Partner.debugReset();

      // 2. Act
      PartnerConfig action() => Partner.current;

      // 3. Assert
      expect(action, throwsStateError);
    });

    test('Sad Path: a second init without reset throws StateError', () {
      // 1. Arrange
      Partner.init(testPartner);

      // 2. Act
      void action() => Partner.init(otherPartner);

      // 3. Assert
      expect(action, throwsStateError);
    });

    test('Sad Path: a rejected second init keeps the first partner', () {
      // 1. Arrange
      Partner.init(testPartner);

      // 2. Act
      try {
        Partner.init(otherPartner);
      } on StateError {
        // Expected: the assertion checks the partner left behind.
      }

      // 3. Assert
      expect(Partner.current, same(testPartner));
    });

    test('Sad Path: a second init with the same config still throws '
        'StateError', () {
      // 1. Arrange
      Partner.init(testPartner);

      // 2. Act
      void action() => Partner.init(testPartner);

      // 3. Assert
      expect(action, throwsStateError);
    });
  });
}
