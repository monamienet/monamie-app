import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/domain/models/account_deletion.dart';
import 'package:monamie_app/data/repositories/account/account_deletion_repository.dart';
import 'package:monamie_app/ui/account/view_models/my_account_view_model.dart';
import 'package:monamie_app/utils/result.dart';

@GenerateNiceMocks([MockSpec<AccountDeletionRepository>()])
import 'my_account_view_model_test.mocks.dart';

final _deletion = AccountDeletion(
  deleteAt: DateTime.utc(2026, 11, 25, 12),
  ownedOrganizationIds: const ['rotasul'],
);

/// Makes `request` wait on [wait] before returning [_deletion] or, with
/// [failure], an [Err] with that message.
void stubRequest(Future<void> Function() wait, {String? failure}) {
  when(repository.request(confirmIds: anyNamed('confirmIds'))).thenAnswer((
    _,
  ) async {
    await wait();
    return failure == null ? Ok(_deletion) : Err(failure);
  });
}

/// The `confirmIds` of every `request` call, verifying there was at least
/// one.
List<Object?> requestedConfirmIds() => verify(
  repository.request(confirmIds: captureAnyNamed('confirmIds')),
).captured;

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

late MockAccountDeletionRepository repository;
late List<AccountDeletion> deleted;

MyAccountViewModel newController(FakeOwnerCheck check) => MyAccountViewModel(
  repository: repository,
  organizationId: 'rotasul',
  checkOwner: check.call,
  onDeleted: (deletion) async => deleted.add(deletion),
);

/// A controller whose ownership has already been read as [isOwner].
Future<MyAccountViewModel> controllerFor({required bool isOwner}) async {
  final controller = newController(FakeOwnerCheck(isOwner));
  await controller.loadOwnership();
  return controller;
}

void main() {
  provideDummy<Result<AccountDeletion>>(Ok(_deletion));

  setUp(() {
    repository = MockAccountDeletionRepository();
    stubRequest(() async {});
    deleted = [];
  });

  group('MyAccountViewModel.loadOwnership - Unit Test Suite', () {
    for (final owner in [true, false]) {
      test('Happy Path: the ownership read ($owner) is kept', () async {
        // 1. Arrange
        final controller = newController(FakeOwnerCheck(owner));

        // 2. Act
        await controller.loadOwnership();

        // 3. Assert
        expect(controller.state.isOwner, owner);
        expect(controller.state.isCheckingOwner, isFalse);
        expect(controller.state.errorMessage, isEmpty);
      });
    }

    test('Happy Path: starting the controller reads the ownership', () async {
      // 1. Arrange
      final check = FakeOwnerCheck(true);
      final controller = newController(check);

      // 2. Act
      controller.loadOwnership();
      await pumpEventQueue();

      // 3. Assert
      expect(check.calls, 1);
      expect(controller.state.isOwner, isTrue);
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
        expect(controller.state.isOwner, isNull);
        expect(controller.state.isCheckingOwner, isTrue);
        check.gate!.complete();
        await pending;
        expect(controller.state.isCheckingOwner, isFalse);
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
      expect(controller.state.isOwner, isFalse);
      expect(controller.state.errorMessage, isEmpty);
    });

    test('Sad Path: a failed read leaves the ownership unknown with a '
        'message', () async {
      // 1. Arrange
      final check = FakeOwnerCheck(true)..failure = StateError('offline');
      final controller = newController(check);

      // 2. Act
      await controller.loadOwnership();

      // 3. Assert
      expect(controller.state.isOwner, isNull);
      expect(controller.state.errorMessage, isNotEmpty);
      expect(controller.state.errorMessage, isNot(contains('offline')));
      expect(controller.state.isCheckingOwner, isFalse);
    });
  });

  group('MyAccountViewModel.canDelete - Unit Test Suite', () {
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
      controller.setConfirmation(' RotaSul ');

      // 3. Assert
      expect(controller.canDelete, isTrue);
    });

    test('Edge Case: an owner who typed the id cannot delete again while the '
        'deletion is in flight', () async {
      // 1. Arrange
      final controller = await controllerFor(isOwner: true)
        ..setConfirmation('rotasul');
      final gate = Completer<void>();
      stubRequest(() => gate.future);
      final pending = controller.deleteAccount();

      // 2. Act
      final canDelete = controller.canDelete;

      // 3. Assert
      expect(canDelete, isFalse);
      gate.complete();
      await pending;
    });

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
      controller.setConfirmation('frota');

      // 3. Assert
      expect(controller.canDelete, isFalse);
    });
  });

  group('MyAccountViewModel.deleteAccount - Unit Test Suite', () {
    test('Happy Path: a member deletes with no ids to confirm', () async {
      // 1. Arrange
      final controller = await controllerFor(isOwner: false);

      // 2. Act
      await controller.deleteAccount();

      // 3. Assert
      expect(requestedConfirmIds(), [<String>[]]);
      expect(deleted, [_deletion]);
      expect(controller.state.errorMessage, isEmpty);
      expect(controller.state.isDeleting, isFalse);
    });

    test('Happy Path: an owner confirms the bound organization', () async {
      // 1. Arrange
      final controller = await controllerFor(isOwner: true)
        ..setConfirmation('rotasul');

      // 2. Act
      await controller.deleteAccount();

      // 3. Assert
      expect(requestedConfirmIds(), [
        ['rotasul'],
      ]);
      expect(deleted, [_deletion]);
    });

    test('Edge Case: isDeleting is set while the request runs', () async {
      // 1. Arrange
      final controller = await controllerFor(isOwner: false);
      final gate = Completer<void>();
      stubRequest(() => gate.future);

      // 2. Act
      final pending = controller.deleteAccount();

      // 3. Assert
      expect(controller.state.isDeleting, isTrue);
      expect(controller.canDelete, isFalse);
      gate.complete();
      await pending;
      expect(controller.state.isDeleting, isFalse);
    });

    test('Edge Case: a second tap while in flight sends nothing', () async {
      // 1. Arrange
      final controller = await controllerFor(isOwner: false);
      final gate = Completer<void>();
      stubRequest(() => gate.future);
      final first = controller.deleteAccount();

      // 2. Act
      await controller.deleteAccount();

      // 3. Assert
      verify(repository.request(confirmIds: anyNamed('confirmIds'))).called(1);
      gate.complete();
      await first;
    });

    test('Edge Case: an owner without the id typed sends nothing', () async {
      // 1. Arrange
      final controller = await controllerFor(isOwner: true);

      // 2. Act
      await controller.deleteAccount();

      // 3. Assert
      verifyNever(repository.request(confirmIds: anyNamed('confirmIds')));
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
      verifyNever(repository.request(confirmIds: anyNamed('confirmIds')));
      expect(deleted, isEmpty);
    });

    test('Sad Path: a refusal shows its own message', () async {
      // 1. Arrange
      final controller = await controllerFor(isOwner: false);
      stubRequest(() async {}, failure: 'Recusado.');

      // 2. Act
      await controller.deleteAccount();

      // 3. Assert
      expect(controller.state.errorMessage, 'Recusado.');
      expect(deleted, isEmpty);
      expect(controller.state.isDeleting, isFalse);
    });

    test('Sad Path: the repository\'s generic message for an unexpected '
        'error is shown as it came', () async {
      // 1. Arrange
      const generic =
          'Não foi possível excluir agora. Verifique a conexão e tente de '
          'novo.';
      final controller = await controllerFor(isOwner: false);
      stubRequest(() async {}, failure: generic);

      // 2. Act
      await controller.deleteAccount();

      // 3. Assert
      expect(controller.state.errorMessage, generic);
      expect(deleted, isEmpty);
      expect(controller.state.isDeleting, isFalse);
    });

    test('Sad Path: a failure after the deletion was scheduled (onDeleted '
        'throws) shows a generic message', () async {
      // 1. Arrange
      final controller = MyAccountViewModel(
        repository: repository,
        organizationId: 'rotasul',
        checkOwner: FakeOwnerCheck(false).call,
        onDeleted: (_) async => throw StateError('offline'),
      );
      await controller.loadOwnership();

      // 2. Act
      await controller.deleteAccount();

      // 3. Assert
      expect(controller.state.errorMessage, isNotEmpty);
      expect(controller.state.errorMessage, isNot(contains('offline')));
      expect(controller.state.isDeleting, isFalse);
    });
  });

  group('MyAccountViewModel (listeners) - Unit Test Suite', () {
    test('Happy Path: typing the confirmation notifies the listeners', () {
      // 1. Arrange
      final controller = newController(FakeOwnerCheck(true));
      var notifications = 0;
      controller.addListener(() => notifications++);

      // 2. Act
      controller.setConfirmation('rotasul');

      // 3. Assert
      expect(notifications, 1);
    });

    test('Edge Case: typing the same confirmation again notifies nobody', () {
      // 1. Arrange
      final controller = newController(FakeOwnerCheck(true))
        ..setConfirmation('rotasul');
      var notifications = 0;
      controller.addListener(() => notifications++);

      // 2. Act
      controller.setConfirmation('rotasul');

      // 3. Assert
      expect(notifications, 0);
    });

    test(
      'Edge Case: reading the ownership notifies when the read starts, with the result '
      'and when it ends',
      () async {
        // 1. Arrange
        final controller = newController(FakeOwnerCheck(false));
        var notifications = 0;
        controller.addListener(() => notifications++);

        // 2. Act
        await controller.loadOwnership();

        // 3. Assert
        expect(notifications, 3);
      },
    );

    test('Sad Path: a read finishing after dispose notifies nobody and does '
        'not throw', () async {
      // 1. Arrange
      final check = FakeOwnerCheck(true)..gate = Completer<void>();
      final controller = newController(check);
      var notifications = 0;
      final pending = controller.loadOwnership();
      controller.addListener(() => notifications++);
      controller.dispose();

      // 2. Act
      check.gate!.complete();

      // 3. Assert
      await expectLater(pending, completes);
      expect(notifications, 0);
    });

    test('Sad Path: a deletion finishing after dispose notifies nobody and '
        'does not throw', () async {
      // 1. Arrange
      final controller = await controllerFor(isOwner: false);
      final gate = Completer<void>();
      stubRequest(() => gate.future);
      var notifications = 0;
      final pending = controller.deleteAccount();
      controller.addListener(() => notifications++);
      controller.dispose();

      // 2. Act
      gate.complete();

      // 3. Assert
      await expectLater(pending, completes);
      expect(notifications, 0);
    });
  });
}
