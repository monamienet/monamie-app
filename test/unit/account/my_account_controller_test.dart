import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/modules/account/account_deletion.dart';
import 'package:monamie_app/app/modules/account/account_deletion_backend.dart';
import 'package:monamie_app/app/modules/account/my_account_controller.dart';

final _deletion = AccountDeletion(
  deleteAt: DateTime.utc(2026, 11, 25, 12),
  ownedOrganizationIds: const ['rotasul'],
);

/// [AccountDeletionBackend] that records `request`, optionally waits on
/// [gate] and fails with [failure].
class FakeAccountDeletionBackend implements AccountDeletionBackend {
  final requests = <List<String>>[];
  Completer<void>? gate;
  Object? failure;

  @override
  Future<AccountDeletion> request({List<String> confirmIds = const []}) async {
    requests.add(confirmIds);
    await gate?.future;
    if (failure case final failure?) throw failure;
    return _deletion;
  }

  @override
  Future<void> cancel() => throw UnimplementedError();

  @override
  Future<AccountDeletion?> pending() => throw UnimplementedError();
}

/// A `checkOwner` that counts its calls, optionally waits on [gate] and
/// fails with [failure].
class FakeOwnerCheck {
  FakeOwnerCheck(this.owner);

  final bool owner;
  int calls = 0;
  Completer<void>? gate;
  Object? failure;

  Future<bool> call() async {
    calls++;
    await gate?.future;
    if (failure case final failure?) throw failure;
    return owner;
  }
}

late FakeAccountDeletionBackend backend;
late List<AccountDeletion> deleted;

MyAccountController newController(FakeOwnerCheck check) => MyAccountController(
  backend: backend,
  organizationId: 'rotasul',
  checkOwner: check.call,
  onDeleted: (deletion) async => deleted.add(deletion),
);

/// A controller whose ownership has already been read as [isOwner].
Future<MyAccountController> controllerFor({required bool isOwner}) async {
  final controller = newController(FakeOwnerCheck(isOwner));
  await controller.loadOwnership();
  return controller;
}

void main() {
  setUp(() {
    Get.testMode = true;
    backend = FakeAccountDeletionBackend();
    deleted = [];
  });

  group('MyAccountController.loadOwnership - Unit Test Suite', () {
    for (final owner in [true, false]) {
      test('Happy Path: the ownership read ($owner) is kept', () async {
        // 1. Arrange
        final controller = newController(FakeOwnerCheck(owner));

        // 2. Act
        await controller.loadOwnership();

        // 3. Assert
        expect(controller.isOwner.value, owner);
        expect(controller.isCheckingOwner.value, isFalse);
        expect(controller.errorMessage.value, isEmpty);
      });
    }

    test('Happy Path: starting the controller reads the ownership', () async {
      // 1. Arrange
      final check = FakeOwnerCheck(true);
      final controller = newController(check);

      // 2. Act
      controller.onStart();
      await pumpEventQueue();

      // 3. Assert
      expect(check.calls, 1);
      expect(controller.isOwner.value, isTrue);
    });

    test(
      'Edge Case: the ownership is unknown while it is being read',
      () async {
        // 1. Arrange
        final check = FakeOwnerCheck(true)..gate = Completer<void>();
        final controller = newController(check);

        // 2. Act
        final pending = controller.loadOwnership();

        // 3. Assert
        expect(controller.isOwner.value, isNull);
        expect(controller.isCheckingOwner.value, isTrue);
        check.gate!.complete();
        await pending;
        expect(controller.isCheckingOwner.value, isFalse);
      },
    );

    test(
      'Edge Case: a second read while one is in flight asks nothing',
      () async {
        // 1. Arrange
        final check = FakeOwnerCheck(true)..gate = Completer<void>();
        final controller = newController(check);
        final first = controller.loadOwnership();

        // 2. Act
        await controller.loadOwnership();

        // 3. Assert
        expect(check.calls, 1);
        check.gate!.complete();
        await first;
      },
    );

    test('Edge Case: a retry after a failure clears the error', () async {
      // 1. Arrange
      final check = FakeOwnerCheck(false)..failure = StateError('offline');
      final controller = newController(check);
      await controller.loadOwnership();
      check.failure = null;

      // 2. Act
      await controller.loadOwnership();

      // 3. Assert
      expect(controller.isOwner.value, isFalse);
      expect(controller.errorMessage.value, isEmpty);
    });

    test('Sad Path: a failed read leaves the ownership unknown with a '
        'message', () async {
      // 1. Arrange
      final check = FakeOwnerCheck(true)..failure = StateError('offline');
      final controller = newController(check);

      // 2. Act
      await controller.loadOwnership();

      // 3. Assert
      expect(controller.isOwner.value, isNull);
      expect(controller.errorMessage.value, isNotEmpty);
      expect(controller.errorMessage.value, isNot(contains('offline')));
      expect(controller.isCheckingOwner.value, isFalse);
    });
  });

  group('MyAccountController.canDelete - Unit Test Suite', () {
    test('Happy Path: a member can delete without typing anything', () async {
      // 1. Arrange
      final controller = await controllerFor(isOwner: false);

      // 2. Act
      final canDelete = controller.canDelete;

      // 3. Assert
      expect(canDelete, isTrue);
    });

    test('Happy Path: an owner can delete once the id is typed', () async {
      // 1. Arrange
      final controller = await controllerFor(isOwner: true);

      // 2. Act
      controller.confirmation.value = ' RotaSul ';

      // 3. Assert
      expect(controller.canDelete, isTrue);
    });

    test(
      'Edge Case: nobody can delete while a deletion is in flight',
      () async {
        // 1. Arrange
        final controller = await controllerFor(isOwner: false);

        // 2. Act
        controller.isDeleting.value = true;

        // 3. Assert
        expect(controller.canDelete, isFalse);
      },
    );

    test('Edge Case: nobody can delete while the ownership is being read', () {
      // 1. Arrange
      final controller = newController(
        FakeOwnerCheck(false)..gate = Completer<void>(),
      );
      unawaited(controller.loadOwnership());

      // 2. Act
      final canDelete = controller.canDelete;

      // 3. Assert
      expect(canDelete, isFalse);
    });

    test('Sad Path: nobody can delete when the ownership could not be '
        'read', () async {
      // 1. Arrange
      final controller = newController(
        FakeOwnerCheck(false)..failure = StateError('offline'),
      );
      await controller.loadOwnership();

      // 2. Act
      final canDelete = controller.canDelete;

      // 3. Assert
      expect(canDelete, isFalse);
    });

    test('Sad Path: an owner cannot delete before typing the id', () async {
      // 1. Arrange
      final controller = await controllerFor(isOwner: true);

      // 2. Act
      final canDelete = controller.canDelete;

      // 3. Assert
      expect(canDelete, isFalse);
    });

    test('Sad Path: an owner who typed another id cannot delete', () async {
      // 1. Arrange
      final controller = await controllerFor(isOwner: true);

      // 2. Act
      controller.confirmation.value = 'frota';

      // 3. Assert
      expect(controller.canDelete, isFalse);
    });
  });

  group('MyAccountController.deleteAccount - Unit Test Suite', () {
    test('Happy Path: a member deletes with no ids to confirm', () async {
      // 1. Arrange
      final controller = await controllerFor(isOwner: false);

      // 2. Act
      await controller.deleteAccount();

      // 3. Assert
      expect(backend.requests, [<String>[]]);
      expect(deleted, [_deletion]);
      expect(controller.errorMessage.value, isEmpty);
      expect(controller.isDeleting.value, isFalse);
    });

    test('Happy Path: an owner confirms the bound organization', () async {
      // 1. Arrange
      final controller = await controllerFor(isOwner: true)
        ..confirmation.value = 'rotasul';

      // 2. Act
      await controller.deleteAccount();

      // 3. Assert
      expect(backend.requests, [
        ['rotasul'],
      ]);
      expect(deleted, [_deletion]);
    });

    test('Edge Case: isDeleting is set while the request runs', () async {
      // 1. Arrange
      final controller = await controllerFor(isOwner: false);
      backend.gate = Completer<void>();

      // 2. Act
      final pending = controller.deleteAccount();

      // 3. Assert
      expect(controller.isDeleting.value, isTrue);
      expect(controller.canDelete, isFalse);
      backend.gate!.complete();
      await pending;
      expect(controller.isDeleting.value, isFalse);
    });

    test('Edge Case: a second tap while in flight sends nothing', () async {
      // 1. Arrange
      final controller = await controllerFor(isOwner: false);
      backend.gate = Completer<void>();
      final first = controller.deleteAccount();

      // 2. Act
      await controller.deleteAccount();

      // 3. Assert
      expect(backend.requests, hasLength(1));
      backend.gate!.complete();
      await first;
    });

    test('Edge Case: an owner without the id typed sends nothing', () async {
      // 1. Arrange
      final controller = await controllerFor(isOwner: true);

      // 2. Act
      await controller.deleteAccount();

      // 3. Assert
      expect(backend.requests, isEmpty);
      expect(deleted, isEmpty);
    });

    test('Edge Case: with the ownership unknown nothing is sent', () async {
      // 1. Arrange
      final controller = newController(
        FakeOwnerCheck(false)..failure = StateError('offline'),
      );
      await controller.loadOwnership();

      // 2. Act
      await controller.deleteAccount();

      // 3. Assert
      expect(backend.requests, isEmpty);
      expect(deleted, isEmpty);
    });

    test('Sad Path: a backend refusal shows its own message', () async {
      // 1. Arrange
      final controller = await controllerFor(isOwner: false);
      backend.failure = const AccountDeletionException('Recusado.');

      // 2. Act
      await controller.deleteAccount();

      // 3. Assert
      expect(controller.errorMessage.value, 'Recusado.');
      expect(deleted, isEmpty);
      expect(controller.isDeleting.value, isFalse);
    });

    test('Sad Path: an unexpected error shows a generic message', () async {
      // 1. Arrange
      final controller = await controllerFor(isOwner: false);
      backend.failure = StateError('offline');

      // 2. Act
      await controller.deleteAccount();

      // 3. Assert
      expect(controller.errorMessage.value, isNotEmpty);
      expect(controller.errorMessage.value, isNot(contains('offline')));
      expect(deleted, isEmpty);
      expect(controller.isDeleting.value, isFalse);
    });
  });
}
