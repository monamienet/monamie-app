import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/data/organization/organization_directory.dart';
import 'package:monamie_app/app/modules/login/controllers/auth_google_controller.dart';

const _kOptions = FirebaseOptions(
  apiKey: 'api-key',
  appId: '1:111:android:abc',
  projectId: 'monamienet-rotasul',
  messagingSenderId: '111',
);

/// [OrganizationDirectory] that counts its reads, returns [organizations],
/// optionally waits on [gate] and fails with [failure].
class FakeOrganizationDirectory implements OrganizationDirectory {
  int reads = 0;
  List<OrganizationCandidate> organizations = const [
    OrganizationCandidate(id: 'rotasul', options: _kOptions, owner: true),
    OrganizationCandidate(id: 'verdemar', options: _kOptions),
  ];
  Completer<void>? gate;
  Object? failure;

  @override
  Future<List<OrganizationCandidate>> organizationsOfSignedInUser() async {
    reads++;
    await gate?.future;
    if (failure case final failure?) throw failure;
    return organizations;
  }
}

late FakeOrganizationDirectory directory;

/// Built without `Get.put`, so the real `onInit` (Google Sign-In) never runs.
AuthGoogleController newController() =>
    AuthGoogleController(organizationDirectory: directory, refreshTheme: () {});

void main() {
  setUp(() {
    Get.testMode = true;
    directory = FakeOrganizationDirectory();
  });

  group('AuthGoogleController.loadOwnership - Unit Test Suite', () {
    test(
      'Happy Path: the owner of the organization is recorded as such',
      () async {
        // 1. Arrange
        final controller = newController();

        // 2. Act
        await controller.loadOwnership('rotasul');

        // 3. Assert
        expect(controller.ownership, {'rotasul': true});
      },
    );

    test('Happy Path: a member who does not own it is recorded as not the '
        'owner', () async {
      // 1. Arrange
      final controller = newController();

      // 2. Act
      await controller.loadOwnership('verdemar');

      // 3. Assert
      expect(controller.ownership, {'verdemar': false});
    });

    test('Edge Case: an organization already read is not read again', () async {
      // 1. Arrange
      final controller = newController();
      await controller.loadOwnership('rotasul');

      // 2. Act
      await controller.loadOwnership('rotasul');

      // 3. Assert
      expect(directory.reads, 1);
    });

    test('Edge Case: another organization is read on its own', () async {
      // 1. Arrange
      final controller = newController();
      await controller.loadOwnership('rotasul');

      // 2. Act
      await controller.loadOwnership('verdemar');

      // 3. Assert
      expect(directory.reads, 2);
      expect(controller.ownership, {'rotasul': true, 'verdemar': false});
    });

    test('Edge Case: a call while one is reading reads nothing', () async {
      // 1. Arrange
      final controller = newController();
      directory.gate = Completer<void>();
      final first = controller.loadOwnership('rotasul');

      // 2. Act
      await controller.loadOwnership('rotasul');

      // 3. Assert
      expect(directory.reads, 1);
      directory.gate!.complete();
      await first;
    });

    test(
      'Sad Path: a failed read leaves the ownership unknown (hidden)',
      () async {
        // 1. Arrange
        final controller = newController();
        directory.failure = StateError('offline');

        // 2. Act
        await controller.loadOwnership('rotasul');

        // 3. Assert
        expect(controller.ownership.containsKey('rotasul'), isFalse);
      },
    );

    test('Sad Path: after a failed read the next call tries again', () async {
      // 1. Arrange
      final controller = newController();
      directory.failure = StateError('offline');
      await controller.loadOwnership('rotasul');
      directory.failure = null;

      // 2. Act
      await controller.loadOwnership('rotasul');

      // 3. Assert
      expect(directory.reads, 2);
      expect(controller.ownership, {'rotasul': true});
    });
  });
}
