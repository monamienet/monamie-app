import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/data/tracking/group_publisher.dart';

final position = PublishedPosition(
  email: 'ana@x.com',
  name: 'Ana',
  lat: -22.9,
  lng: -43.1,
  capturedAt: DateTime.utc(2026, 10, 31, 12),
);

FirebaseException denied() =>
    FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied');

void main() {
  group('positionData - Unit Test Suite', () {
    test('Happy Path: the position is published and not removed', () {
      // 1. Arrange
      final published = position;

      // 2. Act
      final data = positionData(published);

      // 3. Assert
      expect(
        [data['email'], data['lat'], data['lng'], data['isPublishing']],
        ['ana@x.com', -22.9, -43.1, true],
      );
    });

    test('Edge Case: removedAt is written as null, so the map query finds a '
        'person who publishes again', () {
      // 1. Arrange
      final published = position;

      // 2. Act
      final data = positionData(published);

      // 3. Assert
      expect(data.containsKey('removedAt'), isTrue);
      expect(data['removedAt'], isNull);
    });

    test('Sad Path: the device clock does not decide receivedAt', () {
      // 1. Arrange
      final published = position;

      // 2. Act
      final data = positionData(published);

      // 3. Assert
      expect(data['receivedAt'], isA<FieldValue>());
      expect(data['capturedAt'], DateTime.utc(2026, 10, 31, 12));
    });
  });

  group('publishToGroups - Unit Test Suite', () {
    test('Happy Path: every group is written once, listed sorted', () async {
      // 1. Arrange
      final written = <String>[];

      // 2. Act
      final outcome = await publishToGroups(['g2', 'g1', 'g2'], (id) async {
        written.add(id);
      });

      // 3. Assert
      expect(written..sort(), ['g1', 'g2']);
      expect(outcome.succeeded, ['g1', 'g2']);
      expect(outcome.failed, isEmpty);
    });

    test('Edge Case: a failing group does not stop the others', () async {
      // 1. Arrange
      final error = StateError('offline');

      // 2. Act
      final outcome = await publishToGroups(['g1', 'g2', 'g3'], (id) async {
        if (id == 'g2') throw error;
      });

      // 3. Assert
      expect(outcome.succeeded, ['g1', 'g3']);
      expect(outcome.failed, {'g2': error});
      expect(outcome.noneSucceeded, isFalse);
    });

    test(
      'Edge Case: a write that throws before its future is caught too',
      () async {
        // 1. Arrange
        Future<void> write(String id) =>
            id == 'g1' ? throw StateError('sync') : Future.value();

        // 2. Act
        final outcome = await publishToGroups(['g1', 'g2'], write);

        // 3. Assert
        expect(outcome.succeeded, ['g2']);
        expect(outcome.failed.keys, ['g1']);
      },
    );

    test('Sad Path: no groups means nothing succeeded', () async {
      // 1. Arrange
      final written = <String>[];

      // 2. Act
      final outcome = await publishToGroups(const [], (id) async {
        written.add(id);
      });

      // 3. Assert
      expect(written, isEmpty);
      expect(outcome.noneSucceeded, isTrue);
    });
  });

  group('PublishOutcome.anyPermissionDenied - Unit Test Suite', () {
    test('Happy Path: a permission-denied FirebaseException counts', () {
      // 1. Arrange
      final outcome = PublishOutcome(
        succeeded: const [],
        failed: {'g1': denied()},
      );

      // 2. Act
      final result = outcome.anyPermissionDenied;

      // 3. Assert
      expect(result, isTrue);
    });

    test('Edge Case: an error whose text says permission-denied counts', () {
      // 1. Arrange
      final outcome = PublishOutcome(
        succeeded: const [],
        failed: {'g1': Exception('[cloud_firestore/permission-denied] no')},
      );

      // 2. Act
      final result = outcome.anyPermissionDenied;

      // 3. Assert
      expect(result, isTrue);
    });

    test('Sad Path: other failures are not a lack of permission', () {
      // 1. Arrange
      final outcome = PublishOutcome(
        succeeded: const [],
        failed: {
          'g1': FirebaseException(
            plugin: 'cloud_firestore',
            code: 'unavailable',
          ),
          'g2': TimeoutException('slow'),
        },
      );

      // 2. Act
      final result = outcome.anyPermissionDenied;

      // 3. Assert
      expect(result, isFalse);
    });
  });
}
