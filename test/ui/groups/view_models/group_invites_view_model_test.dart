import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/data/repositories/invites/invites_repository.dart';
import 'package:monamie_app/domain/models/group.dart';
import 'package:monamie_app/domain/models/invite.dart';
import 'package:monamie_app/ui/groups/view_models/group_invites_view_model.dart';
import 'package:monamie_app/utils/result.dart';

@GenerateNiceMocks([MockSpec<InvitesRepository>()])
import 'group_invites_view_model_test.mocks.dart';

Invite invite(String id, {bool expired = false}) => Invite(
  id: id,
  organizationId: 'rotasul',
  organizationName: 'Rota Sul',
  groupId: '01',
  groupName: 'Equipe Norte',
  email: '$id@x.com',
  roles: const {GroupRole.publisher},
  inviterName: 'Bia',
  expiresAt: null,
  expired: expired,
);

late MockInvitesRepository repository;

GroupInvitesViewModel newViewModel() => GroupInvitesViewModel(
  organizationId: 'rotasul',
  groupId: '01',
  repository: repository,
);

void main() {
  provideDummy<Result<List<Invite>>>(const Ok([]));
  provideDummy<Result<void>>(const Ok(null));

  final ana = invite('ana');
  final bia = invite('bia', expired: true);

  setUp(() {
    repository = MockInvitesRepository();
    when(
      repository.listForGroup(any, any),
    ).thenAnswer((_) async => Ok([ana, bia]));
    when(repository.resend(any, any)).thenAnswer((_) async => const Ok(null));
    when(repository.cancel(any, any)).thenAnswer((_) async => const Ok(null));
  });

  group('GroupInvitesViewModel.load - Unit Test Suite', () {
    test('Happy Path: loading reads the group invites', () async {
      // 1. Arrange
      final viewModel = newViewModel();

      // 2. Act
      final result = await viewModel.load.execute();

      // 3. Assert
      expect(result, isA<Ok<void>>());
      verify(repository.listForGroup('rotasul', '01')).called(1);
      expect(viewModel.state.invites, [ana, bia]);
      expect(viewModel.state.errorMessage, isEmpty);
    });

    test('Edge Case: no invites are known before the first load', () {
      // 1. Arrange & 2. Act
      final viewModel = newViewModel();

      // 3. Assert
      expect(viewModel.state, const GroupInvitesState());
      expect(viewModel.state.invites, isNull);
    });

    test('Edge Case: a reload while one runs is ignored', () async {
      // 1. Arrange
      final gate = Completer<Result<List<Invite>>>();
      when(repository.listForGroup(any, any)).thenAnswer((_) => gate.future);
      final viewModel = newViewModel();
      final first = viewModel.load.execute();

      // 2. Act
      final second = await viewModel.load.execute();
      gate.complete(Ok([ana]));
      await first;

      // 3. Assert
      expect(second, isNull);
      verify(repository.listForGroup('rotasul', '01')).called(1);
      expect(viewModel.state.invites, [ana]);
    });

    test('Edge Case: a working load clears the previous failure', () async {
      // 1. Arrange
      when(
        repository.listForGroup(any, any),
      ).thenAnswer((_) async => const Err('boom'));
      final viewModel = newViewModel();
      await viewModel.load.execute();
      when(
        repository.listForGroup(any, any),
      ).thenAnswer((_) async => Ok([ana]));

      // 2. Act
      await viewModel.load.execute();

      // 3. Assert
      expect(viewModel.state.errorMessage, isEmpty);
      expect(viewModel.state.invites, [ana]);
    });

    test('Sad Path: a failed load keeps its message and the invites '
        'already read', () async {
      // 1. Arrange
      final viewModel = newViewModel();
      await viewModel.load.execute();
      when(
        repository.listForGroup(any, any),
      ).thenAnswer((_) async => const Err('Sem conexão.'));

      // 2. Act
      final result = await viewModel.load.execute();

      // 3. Assert
      expect(
        result,
        isA<Err<void>>().having(
          (e) => e.message,
          'message',
          'Não foi possível carregar os convites.',
        ),
      );
      expect(
        viewModel.state.errorMessage,
        'Não foi possível carregar os convites.',
      );
      expect(viewModel.state.invites, [ana, bia]);
    });
  });

  group('GroupInvitesViewModel.resend - Unit Test Suite', () {
    test('Happy Path: resending sends the invite again and reloads', () async {
      // 1. Arrange
      final viewModel = newViewModel();
      await viewModel.load.execute();
      clearInteractions(repository);
      when(
        repository.listForGroup(any, any),
      ).thenAnswer((_) async => Ok([ana]));

      // 2. Act
      final result = await viewModel.resend.execute(bia);

      // 3. Assert
      expect(result, isA<Ok<void>>());
      verifyInOrder([
        repository.resend('rotasul', 'bia'),
        repository.listForGroup('rotasul', '01'),
      ]);
      expect(viewModel.state.invites, [ana]);
    });

    test('Edge Case: a failed reload does not fail the resend', () async {
      // 1. Arrange
      final viewModel = newViewModel();
      await viewModel.load.execute();
      when(
        repository.listForGroup(any, any),
      ).thenAnswer((_) async => const Err('boom'));

      // 2. Act
      final result = await viewModel.resend.execute(bia);

      // 3. Assert
      expect(result, isA<Ok<void>>());
      expect(viewModel.state.invites, [ana, bia]);
    });

    test(
      'Sad Path: a refused resend returns its Err and reads nothing',
      () async {
        // 1. Arrange
        final viewModel = newViewModel();
        await viewModel.load.execute();
        clearInteractions(repository);
        when(
          repository.resend(any, any),
        ).thenAnswer((_) async => const Err('Convite não encontrado.'));

        // 2. Act
        final result = await viewModel.resend.execute(bia);

        // 3. Assert
        expect(
          result,
          isA<Err<void>>().having(
            (e) => e.message,
            'message',
            'Convite não encontrado.',
          ),
        );
        verifyNever(repository.listForGroup(any, any));
        expect(viewModel.resend.running, isFalse);
      },
    );
  });

  group('GroupInvitesViewModel.cancel - Unit Test Suite', () {
    test('Happy Path: cancelling cancels the invite and reloads', () async {
      // 1. Arrange
      final viewModel = newViewModel();
      await viewModel.load.execute();
      clearInteractions(repository);
      when(
        repository.listForGroup(any, any),
      ).thenAnswer((_) async => Ok([bia]));

      // 2. Act
      final result = await viewModel.cancel.execute(ana);

      // 3. Assert
      expect(result, isA<Ok<void>>());
      verifyInOrder([
        repository.cancel('rotasul', 'ana'),
        repository.listForGroup('rotasul', '01'),
      ]);
      expect(viewModel.state.invites, [bia]);
    });

    test('Edge Case: cancelling runs while the call is pending', () async {
      // 1. Arrange
      final gate = Completer<Result<void>>();
      when(repository.cancel(any, any)).thenAnswer((_) => gate.future);
      final viewModel = newViewModel();

      // 2. Act
      final pending = viewModel.cancel.execute(ana);

      // 3. Assert
      expect(viewModel.cancel.running, isTrue);
      gate.complete(const Ok(null));
      await pending;
      expect(viewModel.cancel.running, isFalse);
    });

    test(
      'Sad Path: a refused cancel returns its Err and reads nothing',
      () async {
        // 1. Arrange
        final viewModel = newViewModel();
        when(
          repository.cancel(any, any),
        ).thenAnswer((_) async => const Err('Sem permissão.'));

        // 2. Act
        final result = await viewModel.cancel.execute(ana);

        // 3. Assert
        expect(result, isA<Err<void>>());
        verifyNever(repository.listForGroup(any, any));
      },
    );
  });

  group('GroupInvitesViewModel.isWorking - Unit Test Suite', () {
    test('Happy Path: isWorking is false at rest', () {
      // 1. Arrange & 2. Act
      final viewModel = newViewModel();

      // 3. Assert
      expect(viewModel.isWorking, isFalse);
    });

    test('Edge Case: a cancel while a resend runs is ignored', () async {
      // 1. Arrange
      final gate = Completer<Result<void>>();
      when(repository.resend(any, any)).thenAnswer((_) => gate.future);
      final viewModel = newViewModel();
      final pending = viewModel.resend.execute(bia);
      expect(viewModel.isWorking, isTrue);

      // 2. Act
      final ignored = await viewModel.cancel.execute(ana);
      gate.complete(const Ok(null));
      await pending;

      // 3. Assert
      expect(ignored, isNull);
      verifyNever(repository.cancel(any, any));
      expect(viewModel.isWorking, isFalse);
    });

    test('Edge Case: a second resend while one runs is ignored', () async {
      // 1. Arrange
      final gate = Completer<Result<void>>();
      when(repository.resend(any, any)).thenAnswer((_) => gate.future);
      final viewModel = newViewModel();
      final pending = viewModel.resend.execute(bia);

      // 2. Act
      final ignored = await viewModel.resend.execute(ana);
      gate.complete(const Ok(null));
      await pending;

      // 3. Assert
      expect(ignored, isNull);
      verify(repository.resend('rotasul', 'bia')).called(1);
      verifyNever(repository.resend('rotasul', 'ana'));
      expect(viewModel.isWorking, isFalse);
    });

    test('Edge Case: a resend while the list loads is ignored', () async {
      // 1. Arrange
      final gate = Completer<Result<List<Invite>>>();
      when(repository.listForGroup(any, any)).thenAnswer((_) => gate.future);
      final viewModel = newViewModel();
      final loading = viewModel.load.execute();
      expect(viewModel.isWorking, isTrue);

      // 2. Act
      final ignored = await viewModel.resend.execute(bia);
      gate.complete(Ok([ana]));
      await loading;

      // 3. Assert
      expect(ignored, isNull);
      verifyNever(repository.resend(any, any));
      expect(viewModel.isWorking, isFalse);
    });

    test('Edge Case: isWorking is true while a cancel runs', () async {
      // 1. Arrange
      final gate = Completer<Result<void>>();
      when(repository.cancel(any, any)).thenAnswer((_) => gate.future);
      final viewModel = newViewModel();

      // 2. Act
      final pending = viewModel.cancel.execute(ana);

      // 3. Assert
      expect(viewModel.isWorking, isTrue);
      gate.complete(const Ok(null));
      await pending;
      expect(viewModel.isWorking, isFalse);
    });
  });

  group('GroupInvitesViewModel (listeners) - Unit Test Suite', () {
    test('Happy Path: a load that changes the invites notifies', () async {
      // 1. Arrange
      final viewModel = newViewModel();
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      // 2. Act
      await viewModel.load.execute();

      // 3. Assert
      expect(notifications, 1);
    });

    test('Edge Case: reloading equal invites does not notify', () async {
      // 1. Arrange
      final viewModel = newViewModel();
      await viewModel.load.execute();
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      // 2. Act
      await viewModel.load.execute();

      // 3. Assert
      expect(notifications, 0);
    });

    test('Sad Path: a load finishing after dispose notifies nobody and does '
        'not throw', () async {
      // 1. Arrange
      final gate = Completer<Result<List<Invite>>>();
      when(repository.listForGroup(any, any)).thenAnswer((_) => gate.future);
      final viewModel = newViewModel();
      var notifications = 0;
      final pending = viewModel.load.execute();
      viewModel.addListener(() => notifications++);
      viewModel.dispose();

      // 2. Act
      gate.complete(Ok([ana]));

      // 3. Assert
      await expectLater(pending, completes);
      expect(notifications, 0);
    });
  });
}
