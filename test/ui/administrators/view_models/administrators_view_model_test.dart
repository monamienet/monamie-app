import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/domain/models/administrators.dart';
import 'package:monamie_app/data/repositories/administrators/administrators_repository.dart';
import 'package:monamie_app/ui/administrators/view_models/administrators_view_model.dart';
import 'package:monamie_app/utils/result.dart';

@GenerateNiceMocks([MockSpec<AdministratorsRepository>()])
import 'administrators_view_model_test.mocks.dart';

const _before = OrganizationAdministrators(
  administrators: [Administrator(email: 'olga@x.com', owner: true)],
  members: ['caio@x.com'],
);

const _after = OrganizationAdministrators(
  administrators: [
    Administrator(email: 'olga@x.com', owner: true),
    Administrator(email: 'caio@x.com'),
  ],
);

/// Makes `list` wait on [gate] before returning [people].
void listWaitsOn(
  Completer<void> gate, [
  OrganizationAdministrators people = _before,
]) {
  when(repository.list(any)).thenAnswer((_) async {
    await gate.future;
    return Ok(people);
  });
}

/// Makes `setAdministrator` wait on [gate].
void setWaitsOn(Completer<void> gate) {
  when(
    repository.setAdministrator(any, any, admin: anyNamed('admin')),
  ).thenAnswer((_) async {
    await gate.future;
    return const Ok(null);
  });
}

late MockAdministratorsRepository repository;

AdministratorsViewModel newController() =>
    AdministratorsViewModel(organizationId: 'rotasul', repository: repository);

/// A started controller with [_before] loaded and the repository's
/// interactions cleared.
Future<AdministratorsViewModel> loadedController() async {
  final controller = newController();
  controller.load();
  await pumpEventQueue();
  clearInteractions(repository);
  return controller;
}

void main() {
  provideDummy<Result<OrganizationAdministrators>>(
    const Ok(OrganizationAdministrators()),
  );
  provideDummy<Result<void>>(const Ok(null));

  setUp(() {
    repository = MockAdministratorsRepository();
    when(repository.list(any)).thenAnswer((_) async => const Ok(_before));
  });

  group('AdministratorsViewModel.load - Unit Test Suite', () {
    test('Happy Path: starting reads the administrators and members', () async {
      // 1. Arrange
      final controller = newController();

      // 2. Act
      controller.load();
      await pumpEventQueue();

      // 3. Assert
      verify(repository.list('rotasul')).called(1);
      verifyNoMoreInteractions(repository);
      expect(controller.state.people, same(_before));
      expect(controller.state.isLoading, isFalse);
    });

    test('Edge Case: isLoading is true while the list is read', () async {
      // 1. Arrange
      final controller = await loadedController();
      final gate = Completer<void>();
      listWaitsOn(gate);

      // 2. Act
      final pending = controller.load();

      // 3. Assert
      expect(controller.state.isLoading, isTrue);
      gate.complete();
      await pending;
      expect(controller.state.isLoading, isFalse);
    });

    test('Edge Case: a second load while one runs reads nothing', () async {
      // 1. Arrange
      final controller = await loadedController();
      final gate = Completer<void>();
      listWaitsOn(gate);
      final first = controller.load();

      // 2. Act
      await controller.load();

      // 3. Assert
      verify(repository.list('rotasul')).called(1);
      verifyNoMoreInteractions(repository);
      gate.complete();
      await first;
    });

    test('Sad Path: an Err from the repository shows its message and stops '
        'loading', () async {
      // 1. Arrange
      final controller = await loadedController();
      when(
        repository.list(any),
      ).thenAnswer((_) async => const Err('Sem permissão.'));

      // 2. Act
      await controller.load();

      // 3. Assert
      expect(controller.state.errorMessage, 'Sem permissão.');
      expect(controller.state.isLoading, isFalse);
    });

    test('Sad Path: the repository\'s generic message for an unexpected '
        'error is shown as it came', () async {
      // 1. Arrange
      final controller = await loadedController();
      when(repository.list(any)).thenAnswer(
        (_) async => Err(
          'Não foi possível carregar os administradores.',
          error: StateError('offline'),
        ),
      );

      // 2. Act
      await controller.load();

      // 3. Assert
      expect(
        controller.state.errorMessage,
        'Não foi possível carregar os administradores.',
      );
      expect(controller.state.isLoading, isFalse);
    });
  });

  group('AdministratorsViewModel.setAdministrator - Unit Test Suite', () {
    test('Happy Path: the change is sent and the list read again', () async {
      // 1. Arrange
      final controller = await loadedController();
      when(repository.list(any)).thenAnswer((_) async => const Ok(_after));

      // 2. Act
      final ok = await controller.setAdministrator('caio@x.com', admin: true);

      // 3. Assert
      expect(ok, isTrue);
      verifyInOrder([
        repository.setAdministrator('rotasul', 'caio@x.com', admin: true),
        repository.list('rotasul'),
      ]);
      verifyNoMoreInteractions(repository);
      expect(controller.state.people, same(_after));
    });

    test('Edge Case: the row in flight is marked and then cleared', () async {
      // 1. Arrange
      final controller = await loadedController();
      final gate = Completer<void>();
      setWaitsOn(gate);

      // 2. Act
      final pending = controller.setAdministrator('ana@x.com', admin: false);

      // 3. Assert
      expect(controller.state.workingEmail, 'ana@x.com');
      gate.complete();
      await pending;
      expect(controller.state.workingEmail, isNull);
    });

    test('Edge Case: a second change while one runs returns false', () async {
      // 1. Arrange
      final controller = await loadedController();
      final gate = Completer<void>();
      setWaitsOn(gate);
      final first = controller.setAdministrator('ana@x.com', admin: false);

      // 2. Act
      final ok = await controller.setAdministrator('caio@x.com', admin: true);

      // 3. Assert
      expect(ok, isFalse);
      verify(repository.setAdministrator('rotasul', 'ana@x.com', admin: false));
      verifyNoMoreInteractions(repository);
      gate.complete();
      await first;
    });

    test('Edge Case: no change starts while the list is loading', () async {
      // 1. Arrange
      final controller = await loadedController();
      final gate = Completer<void>();
      listWaitsOn(gate);
      final loading = controller.load();

      // 2. Act
      final ok = await controller.setAdministrator('caio@x.com', admin: true);

      // 3. Assert
      expect(ok, isFalse);
      verify(repository.list('rotasul')).called(1);
      verifyNoMoreInteractions(repository);
      gate.complete();
      await loading;
    });

    test('Sad Path: an Err from the change returns false with its '
        'message and clears the row', () async {
      // 1. Arrange
      final controller = await loadedController();
      when(
        repository.setAdministrator(any, any, admin: anyNamed('admin')),
      ).thenAnswer(
        (_) async => const Err('Essa pessoa não faz parte da organização.'),
      );

      // 2. Act
      final ok = await controller.setAdministrator('rui@x.com', admin: true);

      // 3. Assert
      expect(ok, isFalse);
      expect(
        controller.state.errorMessage,
        'Essa pessoa não faz parte da organização.',
      );
      expect(controller.state.workingEmail, isNull);
      expect(controller.state.people, same(_before));
    });

    test('Sad Path: the repository\'s generic message for an unexpected '
        'error is shown as it came', () async {
      // 1. Arrange
      final controller = await loadedController();
      when(
        repository.setAdministrator(any, any, admin: anyNamed('admin')),
      ).thenAnswer(
        (_) async => Err(
          'Não foi possível concluir agora. Verifique a conexão e tente de '
          'novo.',
          error: StateError('offline'),
        ),
      );

      // 2. Act
      final ok = await controller.setAdministrator('caio@x.com', admin: true);

      // 3. Assert
      expect(ok, isFalse);
      expect(
        controller.state.errorMessage,
        'Não foi possível concluir agora. Verifique a conexão e tente de '
        'novo.',
      );
      expect(controller.state.workingEmail, isNull);
    });

    test('Sad Path: a change made but whose reload fails returns false with '
        'the reload\'s message and keeps the old people', () async {
      // 1. Arrange
      final controller = await loadedController();
      when(repository.list(any)).thenAnswer(
        (_) async => const Err('Não foi possível carregar os administradores.'),
      );

      // 2. Act
      final ok = await controller.setAdministrator('caio@x.com', admin: true);

      // 3. Assert
      expect(ok, isFalse);
      verifyInOrder([
        repository.setAdministrator('rotasul', 'caio@x.com', admin: true),
        repository.list('rotasul'),
      ]);
      expect(
        controller.state.errorMessage,
        'Não foi possível carregar os administradores.',
      );
      expect(controller.state.people, same(_before));
      expect(controller.state.workingEmail, isNull);
    });
  });

  group('AdministratorsViewModel (load and listeners) - Unit Test Suite', () {
    test('Edge Case: an organization with nobody to list loads empty '
        'lists', () async {
      // 1. Arrange
      when(
        repository.list(any),
      ).thenAnswer((_) async => const Ok(OrganizationAdministrators()));
      final controller = newController();

      // 2. Act
      await controller.load();

      // 3. Assert
      expect(controller.state.people.administrators, isEmpty);
      expect(controller.state.people.members, isEmpty);
      expect(controller.state.errorMessage, isEmpty);
    });

    test('Happy Path: a load that changes the people notifies three times: '
        'loading, people, loaded', () async {
      // 1. Arrange
      final controller = newController();
      var notifications = 0;
      controller.addListener(() => notifications++);

      // 2. Act
      await controller.load();

      // 3. Assert
      expect(notifications, 3);
    });

    test('Edge Case: reloading people equal by content notifies only for '
        'the loading flag', () async {
      // 1. Arrange
      // Fresh objects on every read, as the repository builds them from
      // JSON.
      when(repository.list(any)).thenAnswer(
        (_) async => Ok(
          OrganizationAdministrators(
            administrators: [Administrator(email: 'olga@x.com', owner: true)],
            members: ['caio@x.com'],
          ),
        ),
      );
      final controller = newController();
      await controller.load();
      var notifications = 0;
      controller.addListener(() => notifications++);

      // 2. Act
      await controller.load();

      // 3. Assert
      expect(notifications, 2);
    });

    test('Sad Path: a change finishing after dispose notifies nobody and '
        'does not throw', () async {
      // 1. Arrange
      final controller = await loadedController();
      final gate = Completer<void>();
      setWaitsOn(gate);
      var notifications = 0;
      final pending = controller.setAdministrator('caio@x.com', admin: true);
      controller.addListener(() => notifications++);
      controller.dispose();

      // 2. Act
      gate.complete();

      // 3. Assert
      await expectLater(pending, completion(isTrue));
      expect(notifications, 0);
    });
  });
}
