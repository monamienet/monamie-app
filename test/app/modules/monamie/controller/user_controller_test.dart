import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/app/data/models/user_google_model.dart';
import 'package:monamie_app/app/data/repository/user_google_repository.dart';
import 'package:monamie_app/app/modules/monamie/controller/group_map_state.dart';
import 'package:monamie_app/app/modules/monamie/controller/user_controller.dart';

@GenerateNiceMocks([
  MockSpec<GroupMapState>(),
  MockSpec<UserGoogleRepository>(),
])
import 'user_controller_test.mocks.dart';

/// A [UserController] whose repository answers [stored] (or throws
/// [error]) and whose person publishes in some group when [canPublish].
UserController _controller({
  UserGoogleModel? stored,
  Object? error,
  bool canPublish = true,
}) {
  final groupMap = MockGroupMapState();
  when(groupMap.canPublish).thenReturn(canPublish);
  final repository = MockUserGoogleRepository();
  when(repository.getUserGoogleModel()).thenAnswer((_) async {
    if (error != null) throw error;
    return stored;
  });
  return UserController(groupMap: groupMap, repository: repository);
}

void main() {
  setUp(() {
    Get.testMode = true;
  });

  group('UserController.loadCurrentUser', () {
    test(
      'Happy Path: Deve carregar a pessoa com e-mail e nome do perfil salvo',
      () async {
        // 1. Arrange
        final controller = _controller(
          stored: UserGoogleModel(email: 'ana@example.com', name: 'Ana'),
        );

        // 2. Act
        await controller.loadCurrentUser();

        // 3. Assert
        expect(controller.user?.email, 'ana@example.com');
        expect(controller.user?.name, 'Ana');
        expect(controller.googleUser?.email, 'ana@example.com');
        expect(controller.isLoading.value, isFalse);
      },
    );

    test(
      'Edge Case: Deve deixar a pessoa vazia quando não há perfil salvo',
      () async {
        // 1. Arrange
        final controller = _controller();

        // 2. Act
        await controller.loadCurrentUser();

        // 3. Assert
        expect(controller.user, isNull);
        expect(controller.isLoading.value, isFalse);
      },
    );

    test(
      'Edge Case: Deve deixar a pessoa vazia quando o perfil salvo tem e-mail vazio',
      () async {
        // 1. Arrange
        final controller = _controller(stored: UserGoogleModel(email: ''));

        // 2. Act
        await controller.loadCurrentUser();

        // 3. Assert
        expect(controller.user, isNull);
      },
    );

    test(
      'Sad Path: Deve liberar isLoading e repassar o erro quando ler o perfil falha',
      () async {
        // 1. Arrange
        final controller = _controller(error: StateError('Hive fechado'));

        // 2. Act
        final load = controller.loadCurrentUser();

        // 3. Assert
        await expectLater(load, throwsStateError);
        expect(controller.isLoading.value, isFalse);
      },
    );
  });

  group('UserController.isTrackable', () {
    test(
      'Happy Path: Deve ser verdadeiro quando há pessoa e ela publica em algum grupo',
      () async {
        // 1. Arrange
        final controller = _controller(
          stored: UserGoogleModel(email: 'ana@example.com'),
        );
        await controller.loadCurrentUser();

        // 2. Act
        final trackable = controller.isTrackable();

        // 3. Assert
        expect(trackable, isTrue);
      },
    );

    test('Edge Case: Deve ser falso antes de a pessoa ser carregada', () {
      // 1. Arrange
      final controller = _controller();

      // 2. Act
      final trackable = controller.isTrackable();

      // 3. Assert
      expect(trackable, isFalse);
    });

    test(
      'Sad Path: Deve ser falso quando a pessoa não publica em nenhum grupo',
      () async {
        // 1. Arrange
        final controller = _controller(
          stored: UserGoogleModel(email: 'ana@example.com'),
          canPublish: false,
        );
        await controller.loadCurrentUser();

        // 2. Act
        final trackable = controller.isTrackable();

        // 3. Assert
        expect(trackable, isFalse);
      },
    );
  });

  group('UserController.getUserName', () {
    test('Happy Path: Deve devolver o nome sem espaços nas pontas', () async {
      // 1. Arrange
      final controller = _controller(
        stored: UserGoogleModel(email: 'ana@example.com', name: '  Ana  '),
      );
      await controller.loadCurrentUser();

      // 2. Act
      final name = controller.getUserName();

      // 3. Assert
      expect(name, 'Ana');
    });

    test(
      'Edge Case: Deve devolver "Nome não informado" quando o nome está em branco',
      () async {
        // 1. Arrange
        final controller = _controller(
          stored: UserGoogleModel(email: 'ana@example.com', name: '   '),
        );
        await controller.loadCurrentUser();

        // 2. Act
        final name = controller.getUserName();

        // 3. Assert
        expect(name, 'Nome não informado');
      },
    );
  });
}
