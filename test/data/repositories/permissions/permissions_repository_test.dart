import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/data/services/app_lifecycle_events.dart';
import 'package:monamie_app/data/services/background_restriction_checker.dart';
import 'package:monamie_app/data/services/background_usage_settings_launcher.dart';
import 'package:monamie_app/data/services/permissions_service.dart';
import 'package:monamie_app/utils/permission_prompts.dart';
import 'package:monamie_app/data/repositories/permissions/permissions_repository.dart';
import 'package:monamie_app/utils/notice_presenter.dart';
import 'package:monamie_app/utils/user_notice.dart';

@GenerateNiceMocks([
  MockSpec<AppLifecycleEvents>(),
  MockSpec<BackgroundRestrictionChecker>(),
  MockSpec<BackgroundUsageSettingsLauncher>(),
  MockSpec<PermissionPrompts>(),
  MockSpec<NoticePresenter>(),
  MockSpec<PermissionsService>(),
])
import 'permissions_repository_test.mocks.dart';

/// Um [MockBackgroundRestrictionChecker] que responde [result] (ou lança
/// [error]) a cada consulta.
MockBackgroundRestrictionChecker mockChecker({
  bool result = false,
  Object? error,
}) {
  final checker = MockBackgroundRestrictionChecker();
  if (error != null) {
    when(checker.isRestricted()).thenAnswer((_) async => throw error);
  } else {
    setRestricted(checker, result);
  }
  return checker;
}

/// Passa a responder [restricted] às consultas de [checker], como depois de
/// o usuário mudar a restrição nas configurações.
void setRestricted(MockBackgroundRestrictionChecker checker, bool restricted) {
  when(checker.isRestricted()).thenAnswer((_) async => restricted);
}

/// Um [MockBackgroundUsageSettingsLauncher] que não acessa nenhum canal
/// nativo e responde [result] ao abrir as configurações.
MockBackgroundUsageSettingsLauncher mockLauncher({bool result = true}) {
  final launcher = MockBackgroundUsageSettingsLauncher();
  when(launcher.open()).thenAnswer((_) async => result);
  return launcher;
}

/// Um [MockPermissionPrompts] em que a pessoa responde [agree] às duas
/// perguntas de confirmação.
MockPermissionPrompts mockPrompts({bool agree = false}) {
  final prompts = MockPermissionPrompts();
  when(prompts.confirmBackgroundUsageSettings()).thenAnswer((_) async => agree);
  when(prompts.confirmBackgroundLocation()).thenAnswer((_) async => agree);
  return prompts;
}

/// A [MockPermissionsService] in which every permission has [status]:
/// asking answers it, and the checks follow it. Opening the settings works.
MockPermissionsService mockPermissions({
  AppPermissionStatus status = AppPermissionStatus.denied,
}) {
  final permissions = MockPermissionsService();
  answerAll(permissions, status);
  when(permissions.openSettings()).thenAnswer((_) async => true);
  return permissions;
}

/// Makes [permissions] answer [status] for every permission, as after the
/// person changes them in the settings.
void answerAll(MockPermissionsService permissions, AppPermissionStatus status) {
  when(permissions.request(any)).thenAnswer((_) async => status);
  when(permissions.isGranted(any)).thenAnswer((_) async => status.isGranted);
  when(
    permissions.isPermanentlyDenied(any),
  ).thenAnswer((_) async => status.isPermanentlyDenied);
}

/// The permissions [_build] gives a controller when a test passes none;
/// a fresh one for each test.
late MockPermissionsService _permissions;

PermissionsRepository _build({
  required BackgroundRestrictionChecker backgroundRestrictionChecker,
  PermissionsService? permissions,
  BackgroundUsageSettingsLauncher? backgroundUsageSettingsLauncher,
  PermissionPrompts? prompts,
  NoticePresenter? notices,
  AppLifecycleEvents? lifecycle,
}) => PermissionsRepository(
  permissions: permissions ?? _permissions,
  prompts: prompts ?? mockPrompts(),
  notices: notices ?? MockNoticePresenter(),
  lifecycle: lifecycle ?? MockAppLifecycleEvents(),
  backgroundRestrictionChecker: backgroundRestrictionChecker,
  backgroundUsageSettingsLauncher:
      backgroundUsageSettingsLauncher ?? mockLauncher(),
);

/// Puts [value] in one of the controller's values, as if the system had
/// answered it (the controller exposes them read-only).
void _seed(ValueListenable<bool> listenable, bool value) =>
    (listenable as ValueNotifier<bool>).value = value;

/// O aviso de que a restrição de bateria continua.
final Matcher _stillRestrictedNotice = equals(
  const UserNotice.backgroundStillRestricted(),
);

/// Leva o usuário às configurações pelo fluxo do controller (a pergunta
/// precisa ser confirmada e o checker indicar restrição).
Future<void> _goToSettings(PermissionsRepository controller) =>
    controller.openBackgroundUsageSettings();

/// Simula o retorno ao app e conclui o trabalho assíncrono que ele dispara
/// (`didChangeAppLifecycleState` não devolve o `Future`).
Future<void> _returnToApp(PermissionsRepository controller) async {
  controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
  await pumpEventQueue();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => _permissions = mockPermissions());

  group('background restriction', () {
    group('PermissionsRepository - Restrição de Segundo Plano', () {
      test('Happy Path: Deve iniciar isBackgroundRestricted como false', () {
        // 1. Arrange
        final checker = mockChecker(result: true);

        // 2. Act
        final controller = _build(backgroundRestrictionChecker: checker);

        // 3. Assert
        expect(controller.isBackgroundRestricted.value, isFalse);
      });

      test(
        'Happy Path: Deve retornar true e atualizar o estado quando o checker confirma a restrição',
        () async {
          // 1. Arrange
          final checker = mockChecker(result: true);
          final controller = _build(backgroundRestrictionChecker: checker);

          // 2. Act
          final resultado = await controller.refreshBackgroundRestriction();

          // 3. Assert
          expect(resultado, isTrue);
          expect(controller.isBackgroundRestricted.value, isTrue);
          verify(checker.isRestricted()).called(1);
        },
      );

      test(
        'Happy Path: Deve retornar false e manter o estado quando o checker não detecta restrição',
        () async {
          // 1. Arrange
          final checker = mockChecker(result: false);
          final controller = _build(backgroundRestrictionChecker: checker);

          // 2. Act
          final resultado = await controller.refreshBackgroundRestriction();

          // 3. Assert
          expect(resultado, isFalse);
          expect(controller.isBackgroundRestricted.value, isFalse);
        },
      );

      test(
        'Edge Case: Deve limpar a restrição previamente registrada quando o usuário a remove nas configurações',
        () async {
          // 1. Arrange
          final checker = mockChecker(result: false);
          final controller = _build(backgroundRestrictionChecker: checker);
          _seed(controller.isBackgroundRestricted, true);

          // 2. Act
          final resultado = await controller.refreshBackgroundRestriction();

          // 3. Assert
          expect(resultado, isFalse);
          expect(controller.isBackgroundRestricted.value, isFalse);
        },
      );

      test(
        'Sad Path: Deve propagar a exceção do checker e preservar o estado anterior',
        () async {
          // 1. Arrange
          final checker = mockChecker(error: StateError('falha nativa'));
          final controller = _build(backgroundRestrictionChecker: checker);
          _seed(controller.isBackgroundRestricted, true);

          // 2. Act
          final future = controller.refreshBackgroundRestriction();

          // 3. Assert
          await expectLater(future, throwsA(isA<StateError>()));
          expect(controller.isBackgroundRestricted.value, isTrue);
        },
      );
    });

    group('PermissionsRepository - arePermissionsGranted', () {
      PermissionsRepository buildController({
        required bool always,
        required bool notification,
        required bool restricted,
      }) {
        final controller = _build(backgroundRestrictionChecker: mockChecker());
        _seed(controller.hasAlwaysLocationPermission, always);
        _seed(controller.hasNotificationPermission, notification);
        _seed(controller.isBackgroundRestricted, restricted);
        return controller;
      }

      test(
        'Happy Path: Deve retornar true com localização sempre, notificação concedida e sem restrição',
        () {
          // 1. Arrange
          final controller = buildController(
            always: true,
            notification: true,
            restricted: false,
          );

          // 2. Act
          final concedidas = controller.arePermissionsGranted();

          // 3. Assert
          expect(concedidas, isTrue);
        },
      );

      test(
        'Edge Case: Deve retornar false no estado inicial do controller (nada concedido)',
        () {
          // 1. Arrange
          final controller = _build(
            backgroundRestrictionChecker: mockChecker(),
          );

          // 2. Act
          final concedidas = controller.arePermissionsGranted();

          // 3. Assert
          expect(concedidas, isFalse);
        },
      );

      test(
        'Edge Case: Deve ignorar a permissão "durante o uso" quando todas as obrigatórias estão concedidas',
        () {
          // 1. Arrange
          final controller = buildController(
            always: true,
            notification: true,
            restricted: false,
          );
          _seed(controller.hasWhenInUseLocationPermission, false);

          // 2. Act
          final concedidas = controller.arePermissionsGranted();

          // 3. Assert
          expect(concedidas, isTrue);
        },
      );

      test(
        'Sad Path: Deve retornar false quando o app está restrito em segundo plano mesmo com permissões concedidas',
        () {
          // 1. Arrange
          final controller = buildController(
            always: true,
            notification: true,
            restricted: true,
          );

          // 2. Act
          final concedidas = controller.arePermissionsGranted();

          // 3. Assert
          expect(concedidas, isFalse);
        },
      );

      test(
        'Sad Path: Deve retornar false quando falta a permissão de localização "sempre"',
        () {
          // 1. Arrange
          final controller = buildController(
            always: false,
            notification: true,
            restricted: false,
          );

          // 2. Act
          final concedidas = controller.arePermissionsGranted();

          // 3. Assert
          expect(concedidas, isFalse);
        },
      );

      test(
        'Sad Path: Deve retornar false quando falta a permissão de notificação',
        () {
          // 1. Arrange
          final controller = buildController(
            always: true,
            notification: false,
            restricted: false,
          );

          // 2. Act
          final concedidas = controller.arePermissionsGranted();

          // 3. Assert
          expect(concedidas, isFalse);
        },
      );

      test(
        'Sad Path: Deve retornar false quando o refresh detecta restrição após permissões concedidas',
        () async {
          // 1. Arrange
          final controller = _build(
            backgroundRestrictionChecker: mockChecker(result: true),
          );
          _seed(controller.hasAlwaysLocationPermission, true);
          _seed(controller.hasNotificationPermission, true);
          await controller.refreshBackgroundRestriction();

          // 2. Act
          final concedidas = controller.arePermissionsGranted();

          // 3. Assert
          expect(concedidas, isFalse);
        },
      );
    });
  });

  group('open background usage settings', () {
    group('PermissionsRepository - openBackgroundUsageSettings', () {
      test(
        'Happy Path: Deve retornar sem perguntar nem abrir configurações quando o app não está restrito',
        () async {
          // 1. Arrange
          final checker = mockChecker(result: false);
          final launcher = mockLauncher();
          final prompts = mockPrompts(agree: true);
          final controller = _build(
            backgroundRestrictionChecker: checker,
            backgroundUsageSettingsLauncher: launcher,
            prompts: prompts,
          );

          // 2. Act
          await controller.openBackgroundUsageSettings();

          // 3. Assert
          verifyNever(prompts.confirmBackgroundUsageSettings());
          expect(controller.isBackgroundRestricted.value, isFalse);
          verify(checker.isRestricted()).called(1);
          verifyNever(launcher.open());
          verifyZeroInteractions(_permissions);
        },
      );

      test(
        'Edge Case: Deve limpar a restrição registrada sem perguntar quando o usuário já a removeu',
        () async {
          // 1. Arrange
          final checker = mockChecker(result: false);
          final launcher = mockLauncher();
          final prompts = mockPrompts(agree: true);
          final controller = _build(
            backgroundRestrictionChecker: checker,
            backgroundUsageSettingsLauncher: launcher,
            prompts: prompts,
          );
          _seed(controller.isBackgroundRestricted, true);

          // 2. Act
          await controller.openBackgroundUsageSettings();

          // 3. Assert
          verifyNever(prompts.confirmBackgroundUsageSettings());
          expect(controller.isBackgroundRestricted.value, isFalse);
          verifyNever(launcher.open());
          verifyZeroInteractions(_permissions);
        },
      );

      test(
        'Sad Path: Deve perguntar uma vez antes de abrir as configurações quando o app está restrito',
        () async {
          // 1. Arrange
          final checker = mockChecker(result: true);
          final prompts = mockPrompts(agree: false);
          final controller = _build(
            backgroundRestrictionChecker: checker,
            prompts: prompts,
          );

          // 2. Act
          await controller.openBackgroundUsageSettings();

          // 3. Assert
          verify(prompts.confirmBackgroundUsageSettings()).called(1);
          verifyNever(prompts.confirmBackgroundLocation());
          expect(controller.isBackgroundRestricted.value, isTrue);
        },
      );

      test(
        'Sad Path: Deve parar sem abrir as configurações quando o usuário recusa ("AGORA NÃO")',
        () async {
          // 1. Arrange
          final launcher = mockLauncher();
          final controller = _build(
            backgroundRestrictionChecker: mockChecker(result: true),
            backgroundUsageSettingsLauncher: launcher,
            prompts: mockPrompts(agree: false),
          );

          // 2. Act
          await controller.openBackgroundUsageSettings();

          // 3. Assert
          verifyNever(launcher.open());
          verifyZeroInteractions(_permissions);
          expect(controller.isBackgroundRestricted.value, isTrue);
        },
      );

      test(
        'Happy Path: Deve acionar o launcher injetado uma única vez, sem chamar openAppSettings, quando o usuário confirma ("PROSSEGUIR")',
        () async {
          // 1. Arrange
          final launcher = mockLauncher(result: true);
          final controller = _build(
            backgroundRestrictionChecker: mockChecker(result: true),
            backgroundUsageSettingsLauncher: launcher,
            prompts: mockPrompts(agree: true),
          );

          // 2. Act
          await controller.openBackgroundUsageSettings();

          // 3. Assert
          verify(launcher.open()).called(1);
          verifyZeroInteractions(_permissions);
        },
      );

      test(
        'Sad Path: Deve concluir sem erro e sem recorrer ao openAppSettings quando o launcher não consegue abrir nenhuma tela',
        () async {
          // 1. Arrange
          final launcher = mockLauncher(result: false);
          final controller = _build(
            backgroundRestrictionChecker: mockChecker(result: true),
            backgroundUsageSettingsLauncher: launcher,
            prompts: mockPrompts(agree: true),
          );

          // 2. Act
          final future = controller.openBackgroundUsageSettings();

          // 3. Assert
          await expectLater(future, completes);
          verify(launcher.open()).called(1);
          verifyZeroInteractions(_permissions);
        },
      );

      test(
        'Edge Case: Deve perguntar uma única vez e acionar o launcher uma única vez quando a ação é disparada duas vezes seguidas',
        () async {
          // 1. Arrange
          final launcher = mockLauncher();
          final answer = Completer<bool>();
          final prompts = MockPermissionPrompts();
          when(
            prompts.confirmBackgroundUsageSettings(),
          ).thenAnswer((_) => answer.future);
          final controller = _build(
            backgroundRestrictionChecker: mockChecker(result: true),
            backgroundUsageSettingsLauncher: launcher,
            prompts: prompts,
          );
          // Primeiro toque: a pergunta fica aberta.
          final first = controller.openBackgroundUsageSettings();
          await pumpEventQueue();

          // 2. Act
          await controller.openBackgroundUsageSettings();

          // 3. Assert
          answer.complete(true);
          await first;
          verify(prompts.confirmBackgroundUsageSettings()).called(1);
          verify(launcher.open()).called(1);
        },
      );

      test(
        'Sad Path: Deve propagar a exceção do checker sem perguntar nem abrir configurações',
        () async {
          // 1. Arrange
          final checker = mockChecker(error: StateError('falha nativa'));
          final launcher = mockLauncher();
          final prompts = mockPrompts(agree: true);
          final controller = _build(
            backgroundRestrictionChecker: checker,
            backgroundUsageSettingsLauncher: launcher,
            prompts: prompts,
          );

          // 2. Act
          final future = controller.openBackgroundUsageSettings();

          // 3. Assert
          await expectLater(future, throwsA(isA<StateError>()));
          verifyNever(prompts.confirmBackgroundUsageSettings());
          verifyNever(launcher.open());
          verifyZeroInteractions(_permissions);
        },
      );

      test(
        'Edge Case: Deve aceitar uma nova tentativa depois de uma falha do checker',
        () async {
          // 1. Arrange
          final checker = mockChecker(error: StateError('falha nativa'));
          final prompts = mockPrompts(agree: false);
          final controller = _build(
            backgroundRestrictionChecker: checker,
            prompts: prompts,
          );
          await expectLater(
            controller.openBackgroundUsageSettings(),
            throwsA(isA<StateError>()),
          );
          setRestricted(checker, true);

          // 2. Act
          await controller.openBackgroundUsageSettings();

          // 3. Assert
          verify(prompts.confirmBackgroundUsageSettings()).called(1);
        },
      );
    });
  });

  group('return from settings', () {
    group('PermissionsRepository - Aviso ao retornar das configurações de bateria', () {
      setUp(() => answerAll(_permissions, AppPermissionStatus.granted));

      test(
        'Happy Path: Deve avisar "Uso em segundo plano ainda restrito" quando o usuário volta das configurações e a restrição continua',
        () async {
          // 1. Arrange
          final notices = MockNoticePresenter();
          final controller = _build(
            backgroundRestrictionChecker: mockChecker(result: true),
            backgroundUsageSettingsLauncher: mockLauncher(result: true),
            prompts: mockPrompts(agree: true),
            notices: notices,
          );
          await _goToSettings(controller);

          // 2. Act
          await _returnToApp(controller);

          // 3. Assert
          verify(notices.show(argThat(_stillRestrictedNotice))).called(1);
          expect(controller.isBackgroundRestricted.value, isTrue);
        },
      );

      test(
        'Happy Path: Deve limpar a restrição sem avisar quando o usuário a remove nas configurações',
        () async {
          // 1. Arrange
          final notices = MockNoticePresenter();
          final checker = mockChecker(result: true);
          final controller = _build(
            backgroundRestrictionChecker: checker,
            backgroundUsageSettingsLauncher: mockLauncher(result: true),
            prompts: mockPrompts(agree: true),
            notices: notices,
          );
          await _goToSettings(controller);
          setRestricted(checker, false); // O usuário removeu a restrição.

          // 2. Act
          await _returnToApp(controller);

          // 3. Assert
          verifyNever(notices.show(any));
          expect(controller.isBackgroundRestricted.value, isFalse);
        },
      );

      test(
        'Edge Case: Deve avisar apenas uma vez por ida às configurações, ignorando um segundo retorno ao app',
        () async {
          // 1. Arrange
          final notices = MockNoticePresenter();
          final controller = _build(
            backgroundRestrictionChecker: mockChecker(result: true),
            backgroundUsageSettingsLauncher: mockLauncher(result: true),
            prompts: mockPrompts(agree: true),
            notices: notices,
          );
          await _goToSettings(controller);
          await _returnToApp(controller); // Primeiro retorno: avisa.
          clearInteractions(notices);

          // 2. Act
          await _returnToApp(controller);

          // 3. Assert
          verifyNever(notices.show(any));
        },
      );

      test(
        'Edge Case: Deve avisar novamente quando o usuário volta às configurações por uma nova confirmação',
        () async {
          // 1. Arrange
          final notices = MockNoticePresenter();
          final controller = _build(
            backgroundRestrictionChecker: mockChecker(result: true),
            backgroundUsageSettingsLauncher: mockLauncher(result: true),
            prompts: mockPrompts(agree: true),
            notices: notices,
          );
          await _goToSettings(controller);
          await _returnToApp(controller); // Primeira ida: avisa.
          clearInteractions(notices);
          await _goToSettings(controller);

          // 2. Act
          await _returnToApp(controller);

          // 3. Assert
          verify(notices.show(argThat(_stillRestrictedNotice))).called(1);
        },
      );

      test(
        'Edge Case: Deve ignorar um retorno posterior em que a restrição reaparece depois de um retorno já sem restrição',
        () async {
          // 1. Arrange
          final notices = MockNoticePresenter();
          final checker = mockChecker(result: true);
          final controller = _build(
            backgroundRestrictionChecker: checker,
            backgroundUsageSettingsLauncher: mockLauncher(result: true),
            prompts: mockPrompts(agree: true),
            notices: notices,
          );
          await _goToSettings(controller);
          // Retorno da ida às configurações sem restrição.
          setRestricted(checker, false);
          await _returnToApp(controller);
          // A restrição reaparece depois, fora da ida.
          setRestricted(checker, true);

          // 2. Act
          await _returnToApp(controller);

          // 3. Assert
          verifyNever(notices.show(any));
          expect(controller.isBackgroundRestricted.value, isTrue);
        },
      );

      test(
        'Edge Case: Deve ignorar o retorno ao app sem ida às configurações pelo controller, mesmo com a restrição ativa',
        () async {
          // 1. Arrange
          final notices = MockNoticePresenter();
          final launcher = mockLauncher(result: true);
          final controller = _build(
            backgroundRestrictionChecker: mockChecker(result: true),
            backgroundUsageSettingsLauncher: launcher,
            notices: notices,
          );

          // 2. Act
          await _returnToApp(controller);

          // 3. Assert
          verifyNever(notices.show(any));
          expect(controller.isBackgroundRestricted.value, isTrue);
          verifyNever(launcher.open());
        },
      );

      test(
        'Edge Case: Deve ignorar o retorno ao app quando o usuário recusou a pergunta ("AGORA NÃO")',
        () async {
          // 1. Arrange
          final notices = MockNoticePresenter();
          final controller = _build(
            backgroundRestrictionChecker: mockChecker(result: true),
            backgroundUsageSettingsLauncher: mockLauncher(result: true),
            prompts: mockPrompts(agree: false),
            notices: notices,
          );
          await _goToSettings(controller);

          // 2. Act
          await _returnToApp(controller);

          // 3. Assert
          verifyNever(notices.show(any));
        },
      );

      test(
        'Sad Path: Deve ignorar o retorno ao app quando o launcher não conseguiu abrir nenhuma tela de configurações',
        () async {
          // 1. Arrange
          final notices = MockNoticePresenter();
          final controller = _build(
            backgroundRestrictionChecker: mockChecker(result: true),
            backgroundUsageSettingsLauncher: mockLauncher(result: false),
            prompts: mockPrompts(agree: true),
            notices: notices,
          );
          await _goToSettings(controller);

          // 2. Act
          await _returnToApp(controller);

          // 3. Assert
          verifyNever(notices.show(any));
          expect(controller.isBackgroundRestricted.value, isTrue);
        },
      );
    });
  });

  group('PermissionsRepository - requestAlwaysPermission', () {
    /// Answers the permission requests: "durante o uso" with [whenInUse],
    /// "sempre" with [always]; the status checks answer [always].
    void answerPermissions({
      required AppPermissionStatus whenInUse,
      AppPermissionStatus always = AppPermissionStatus.granted,
    }) {
      answerAll(_permissions, always);
      when(
        _permissions.request(AppPermission.locationWhenInUse),
      ).thenAnswer((_) async => whenInUse);
    }

    /// The permissions asked for, in order.
    List<AppPermission> requested() =>
        verify(_permissions.request(captureAny)).captured.cast<AppPermission>();

    test(
      'Happy Path: Deve pedir a localização "sempre" quando o usuário confirma o aviso',
      () async {
        // 1. Arrange
        answerPermissions(whenInUse: AppPermissionStatus.granted);
        final prompts = mockPrompts(agree: true);
        final controller = _build(
          backgroundRestrictionChecker: mockChecker(),
          prompts: prompts,
        );

        // 2. Act
        await controller.requestAlwaysPermission();

        // 3. Assert
        verify(prompts.confirmBackgroundLocation()).called(1);
        expect(requested(), [
          AppPermission.locationWhenInUse,
          AppPermission.locationAlways,
        ]);
        expect(controller.hasAlwaysLocationPermission.value, isTrue);
      },
    );

    test(
      'Sad Path: Deve parar sem pedir a localização "sempre" quando o usuário recusa o aviso',
      () async {
        // 1. Arrange
        answerPermissions(
          whenInUse: AppPermissionStatus.granted,
          always: AppPermissionStatus.denied,
        );
        final prompts = mockPrompts(agree: false);
        final controller = _build(
          backgroundRestrictionChecker: mockChecker(),
          prompts: prompts,
        );

        // 2. Act
        await controller.requestAlwaysPermission();

        // 3. Assert
        verify(prompts.confirmBackgroundLocation()).called(1);
        expect(requested(), [AppPermission.locationWhenInUse]);
        expect(controller.hasAlwaysLocationPermission.value, isFalse);
      },
    );

    test(
      'Edge Case: Deve abrir as configurações do app quando a localização "sempre" foi negada de vez',
      () async {
        // 1. Arrange
        answerPermissions(
          whenInUse: AppPermissionStatus.granted,
          always: AppPermissionStatus.permanentlyDenied,
        );
        final controller = _build(
          backgroundRestrictionChecker: mockChecker(),
          prompts: mockPrompts(agree: true),
        );

        // 2. Act
        await controller.requestAlwaysPermission();

        // 3. Assert
        verify(_permissions.openSettings()).called(1);
      },
    );

    test(
      'Sad Path: Deve não exibir o aviso quando a localização "durante o uso" é negada',
      () async {
        // 1. Arrange
        answerPermissions(
          whenInUse: AppPermissionStatus.denied,
          always: AppPermissionStatus.denied,
        );
        final prompts = mockPrompts(agree: true);
        final controller = _build(
          backgroundRestrictionChecker: mockChecker(),
          prompts: prompts,
        );

        // 2. Act
        await controller.requestAlwaysPermission();

        // 3. Assert
        verifyNever(prompts.confirmBackgroundLocation());
        expect(requested(), [AppPermission.locationWhenInUse]);
      },
    );
  });

  group('PermissionsRepository - notifyGpsDisabled', () {
    test(
      'Happy Path: Deve delegar o aviso de GPS desligado às perguntas',
      () async {
        // 1. Arrange
        final prompts = mockPrompts();
        final controller = _build(
          backgroundRestrictionChecker: mockChecker(),
          prompts: prompts,
        );

        // 2. Act
        await controller.notifyGpsDisabled();

        // 3. Assert
        verify(prompts.notifyGpsDisabled()).called(1);
      },
    );
  });

  group('PermissionsRepository - start e dispose', () {
    test(
      'Happy Path: Deve passar a seguir o ciclo de vida do app ao começar',
      () async {
        // 1. Arrange
        final lifecycle = MockAppLifecycleEvents();
        final controller = _build(
          backgroundRestrictionChecker: mockChecker(),
          lifecycle: lifecycle,
        );

        // 2. Act
        await controller.start();

        // 3. Assert
        verify(lifecycle.start(any)).called(1);
        controller.dispose();
      },
    );

    test(
      'Edge Case: Deve seguir o ciclo de vida uma vez só quando start() é chamado duas vezes',
      () async {
        // 1. Arrange
        final lifecycle = MockAppLifecycleEvents();
        final checker = mockChecker();
        final controller = _build(
          backgroundRestrictionChecker: checker,
          lifecycle: lifecycle,
        );
        await controller.start();

        // 2. Act
        await controller.start();

        // 3. Assert
        verify(lifecycle.start(any)).called(1);
        verify(checker.isRestricted()).called(1);
        controller.dispose();
      },
    );

    test(
      'Happy Path: Deve deixar de seguir o ciclo de vida ao fechar',
      () async {
        // 1. Arrange
        final lifecycle = MockAppLifecycleEvents();
        final controller = _build(
          backgroundRestrictionChecker: mockChecker(),
          lifecycle: lifecycle,
        );
        await controller.start();

        // 2. Act
        controller.dispose();

        // 3. Assert
        verify(lifecycle.stop()).called(1);
      },
    );

    test(
      'Edge Case: Deve aceitar um segundo dispose() sem repetir o fim',
      () async {
        // 1. Arrange
        final lifecycle = MockAppLifecycleEvents();
        final controller = _build(
          backgroundRestrictionChecker: mockChecker(),
          lifecycle: lifecycle,
        );
        await controller.start();
        controller.dispose();

        // 2. Act
        controller.dispose();

        // 3. Assert
        verify(lifecycle.stop()).called(1);
      },
    );

    test(
      'Sad Path: Não deve seguir o ciclo de vida com start() depois de dispose()',
      () async {
        // 1. Arrange
        final lifecycle = MockAppLifecycleEvents();
        final controller = _build(
          backgroundRestrictionChecker: mockChecker(),
          lifecycle: lifecycle,
        );
        controller.dispose();

        // 2. Act
        await controller.start();

        // 3. Assert
        verifyNever(lifecycle.start(any));
      },
    );

    test(
      'Happy Path: Deve avisar a permissão de localização quando ela é concedida',
      () async {
        // 1. Arrange
        final controller = _build(
          backgroundRestrictionChecker: mockChecker(),
          lifecycle: MockAppLifecycleEvents(),
        );
        await controller.start();
        var notified = 0;
        controller.hasWhenInUseLocationPermission.addListener(() => notified++);
        answerAll(_permissions, AppPermissionStatus.granted);

        // 2. Act
        await _returnToApp(controller);

        // 3. Assert
        expect(notified, 1);
        expect(controller.hasWhenInUseLocationPermission.value, isTrue);
        controller.dispose();
      },
    );

    test(
      'Edge Case: Não deve avisar nenhuma permissão quando o sistema responde o mesmo ao voltar ao app',
      () async {
        // 1. Arrange
        answerAll(_permissions, AppPermissionStatus.granted);
        final controller = _build(
          backgroundRestrictionChecker: mockChecker(result: true),
          lifecycle: MockAppLifecycleEvents(),
        );
        await controller.start();
        var notified = 0;
        void count() => notified++;
        controller.hasWhenInUseLocationPermission.addListener(count);
        controller.hasAlwaysLocationPermission.addListener(count);
        controller.hasNotificationPermission.addListener(count);
        controller.isBackgroundRestricted.addListener(count);

        // 2. Act
        await _returnToApp(controller);

        // 3. Assert
        expect(notified, 0);
        controller.dispose();
      },
    );

    test(
      'Sad Path: Deve ignorar sem erro a restrição que o sistema responde depois de fechar',
      () async {
        // 1. Arrange
        final answer = Completer<bool>();
        final checker = MockBackgroundRestrictionChecker();
        when(checker.isRestricted()).thenAnswer((_) => answer.future);
        final controller = _build(
          backgroundRestrictionChecker: checker,
          lifecycle: MockAppLifecycleEvents(),
        );
        final pending = controller.refreshBackgroundRestriction();
        controller.dispose();

        // 2. Act
        answer.complete(true);

        // 3. Assert
        await expectLater(pending, completion(isTrue));
        expect(controller.isBackgroundRestricted.value, isFalse);
      },
    );
  });
}
