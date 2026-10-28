import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/modules/account/account_deletion.dart';
import 'package:monamie_app/app/modules/account/account_deletion_backend.dart';
import 'package:monamie_app/app/modules/account/my_account_controller.dart';

final _deletion = AccountDeletion(
  deleteAt: DateTime.utc(2026, 11, 25, 12),
  ownedPartners: const ['rotasul'],
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

late FakeAccountDeletionBackend backend;
late List<AccountDeletion> deleted;

MyAccountController controllerFor({required bool isOwner}) =>
    MyAccountController(
      backend: backend,
      partnerId: 'rotasul',
      isOwner: isOwner,
      onDeleted: (deletion) async => deleted.add(deletion),
    );

void main() {
  setUp(() {
    Get.testMode = true;
    backend = FakeAccountDeletionBackend();
    deleted = [];
  });

  group('MyAccountController.canDelete - Unit Test Suite', () {
    test('Happy Path: a member can delete without typing anything', () {
      // 1. Arrange
      final controller = controllerFor(isOwner: false);

      // 2. Act
      final canDelete = controller.canDelete;

      // 3. Assert
      expect(canDelete, isTrue);
    });

    test('Happy Path: an owner can delete once the id is typed', () {
      // 1. Arrange
      final controller = controllerFor(isOwner: true);

      // 2. Act
      controller.confirmation.value = ' RotaSul ';

      // 3. Assert
      expect(controller.canDelete, isTrue);
    });

    test('Edge Case: nobody can delete while a deletion is in flight', () {
      // 1. Arrange
      final controller = controllerFor(isOwner: false);

      // 2. Act
      controller.isDeleting.value = true;

      // 3. Assert
      expect(controller.canDelete, isFalse);
    });

    test('Sad Path: an owner cannot delete before typing the id', () {
      // 1. Arrange
      final controller = controllerFor(isOwner: true);

      // 2. Act
      final canDelete = controller.canDelete;

      // 3. Assert
      expect(canDelete, isFalse);
    });

    test('Sad Path: an owner who typed another id cannot delete', () {
      // 1. Arrange
      final controller = controllerFor(isOwner: true);

      // 2. Act
      controller.confirmation.value = 'frota';

      // 3. Assert
      expect(controller.canDelete, isFalse);
    });
  });

  group('MyAccountController.deleteAccount - Unit Test Suite', () {
    test('Happy Path: a member deletes with no ids to confirm', () async {
      // 1. Arrange
      final controller = controllerFor(isOwner: false);

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
      final controller = controllerFor(isOwner: true)
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
      final controller = controllerFor(isOwner: false);
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
      final controller = controllerFor(isOwner: false);
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
      final controller = controllerFor(isOwner: true);

      // 2. Act
      await controller.deleteAccount();

      // 3. Assert
      expect(backend.requests, isEmpty);
      expect(deleted, isEmpty);
    });

    test('Sad Path: a backend refusal shows its own message', () async {
      // 1. Arrange
      final controller = controllerFor(isOwner: false);
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
      final controller = controllerFor(isOwner: false);
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
