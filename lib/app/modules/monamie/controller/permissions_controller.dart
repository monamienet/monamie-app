import 'dart:ui' show AppLifecycleState;

import 'package:monamie_app/app/data/services/app_lifecycle_events.dart';
import 'package:monamie_app/app/data/services/background_restriction_checker.dart';
import 'package:monamie_app/app/data/services/background_usage_settings_launcher.dart';
import 'package:monamie_app/app/data/services/method_channel_background_restriction_checker.dart';
import 'package:monamie_app/app/data/services/method_channel_background_usage_settings_launcher.dart';
import 'package:monamie_app/app/data/services/widgets_binding_app_lifecycle_events.dart';
import 'package:monamie_app/app/modules/monamie/controller/permission_prompts.dart';
import 'package:monamie_app/app/utils/notice_presenter.dart';
import 'package:monamie_app/app/utils/user_notice.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsController extends GetxController {
  /// [prompts] asks the questions in the middle of the permission flows;
  /// [notices] shows the warning given on returning from the battery
  /// settings, when no screen is waiting for it; [lifecycle] tells when the
  /// app comes back to the foreground ([WidgetsBindingAppLifecycleEvents] by
  /// default).
  PermissionsController({
    required this._prompts,
    required this._notices,
    BackgroundRestrictionChecker? backgroundRestrictionChecker,
    BackgroundUsageSettingsLauncher? backgroundUsageSettingsLauncher,
    AppLifecycleEvents? lifecycle,
  }) : _lifecycle = lifecycle ?? WidgetsBindingAppLifecycleEvents(),
       _backgroundRestrictionChecker =
           backgroundRestrictionChecker ??
           MethodChannelBackgroundRestrictionChecker(),
       _backgroundUsageSettingsLauncher =
           backgroundUsageSettingsLauncher ??
           MethodChannelBackgroundUsageSettingsLauncher();

  final PermissionPrompts _prompts;
  final AppLifecycleEvents _lifecycle;
  final NoticePresenter _notices;
  final BackgroundRestrictionChecker _backgroundRestrictionChecker;
  final BackgroundUsageSettingsLauncher _backgroundUsageSettingsLauncher;

  final hasWhenInUseLocationPermission = false.obs;
  final hasAlwaysLocationPermission = false.obs;
  final hasNotificationPermission = false.obs;

  /// `true` quando o app está no modo de bateria "Restrito". Nesse modo o
  /// Android derruba o serviço de rastreamento assim que o app sai da tela.
  final isBackgroundRestricted = false.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    _lifecycle.start(didChangeAppLifecycleState);
    await _refreshStatuses();
  }

  /// Esta função realiza trabalho quando o usuário volta para o aplicativo
  /// após ter saído do mesmo (neste caso, quando ele volta das configurações).
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      await _refreshStatuses();
      _warnIfStillRestrictedAfterSettings();
    }
  }

  /// `true` entre abrir as configurações de bateria e o retorno ao app.
  bool _awaitingBackgroundUsageReturn = false;

  /// Avisa quando o usuário volta das configurações de bateria e a restrição
  /// continua: sem isso, ele fica na tela de permissões sem entender o motivo.
  void _warnIfStillRestrictedAfterSettings() {
    if (!_awaitingBackgroundUsageReturn) return;
    _awaitingBackgroundUsageReturn = false;
    if (!isBackgroundRestricted.value) return;

    _notices.show(
      const UserNotice(
        "A alteração não foi aplicada. Toque em 'Permitir uso em segundo "
        "plano' e, se o interruptor já estiver ativado, desative-o e "
        "ative-o novamente.",
        title: 'Uso em segundo plano ainda restrito',
      ),
    );
  }

  Future<void> _refreshStatuses() async {
    hasWhenInUseLocationPermission.value =
        await Permission.locationWhenInUse.isGranted;
    hasAlwaysLocationPermission.value =
        await Permission.locationAlways.isGranted;
    hasNotificationPermission.value = await Permission.notification.isGranted;
    await refreshBackgroundRestriction();
  }

  /// Reconsulta o sistema e atualiza [isBackgroundRestricted].
  Future<bool> refreshBackgroundRestriction() async {
    isBackgroundRestricted.value = await _backgroundRestrictionChecker
        .isRestricted();
    return isBackgroundRestricted.value;
  }

  Future<void> requestWhenInUsePermission() async {
    if (await Permission.locationWhenInUse.isPermanentlyDenied) {
      await openAppSettings();
    } else {
      await Permission.locationWhenInUse.request();
    }

    hasWhenInUseLocationPermission.value =
        await Permission.locationWhenInUse.isGranted;
  }

  Future<void> requestAlwaysPermission() async {
    PermissionStatus locationWhenInUseStatus = await Permission
        .locationWhenInUse
        .request();

    if (locationWhenInUseStatus.isGranted) {
      bool userAgreed = await _prompts.confirmBackgroundLocation();

      if (userAgreed) {
        PermissionStatus locationAlwaysStatus = await Permission.locationAlways
            .request();

        if (locationAlwaysStatus.isPermanentlyDenied) await openAppSettings();
      }
    } else if (locationWhenInUseStatus.isPermanentlyDenied) {
      await openAppSettings();
    }

    hasAlwaysLocationPermission.value =
        await Permission.locationAlways.isGranted;
  }

  /// Precisamos de permissão para exibibir notificações pois serviços de
  /// localização em segundo plano são críticos tanto para a privacidade do
  /// usuário quanto para o consumo de bateria. Sem notificações, o SO pode
  /// matar esses serviços.
  Future<void> requestNotificationPermission() async {
    if (await Permission.notification.isPermanentlyDenied) {
      await openAppSettings();
    } else {
      await Permission.notification.request();
    }

    hasNotificationPermission.value = await Permission.notification.isGranted;
  }

  /// Verifica se todas as permissões necessárias para o MonAmie funcionar
  /// adequadamente já foram concedidas ao aplicativo pelo usuário.
  bool arePermissionsGranted() {
    return hasAlwaysLocationPermission.value &&
        hasNotificationPermission.value &&
        !isBackgroundRestricted.value;
  }

  /// Explica a restrição de bateria e abre a tela de bateria do app, onde o
  /// usuário pode trocar o modo de bateria de "Restrito" para outro.
  /// O status é reavaliado em [didChangeAppLifecycleState] ao retornar.
  ///
  /// Não usa `ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`: testado no Moto
  /// g35 (Android 15), o diálogo só adiciona o app à lista de isenção de
  /// otimização de bateria, sem remover a restrição.
  Future<void> openBackgroundUsageSettings() async {
    // Evita dois diálogos empilhados em toques rápidos repetidos.
    if (_isOpeningBackgroundUsageSettings) return;
    _isOpeningBackgroundUsageSettings = true;
    try {
      await _openBackgroundUsageSettings();
    } finally {
      _isOpeningBackgroundUsageSettings = false;
    }
  }

  bool _isOpeningBackgroundUsageSettings = false;

  Future<void> _openBackgroundUsageSettings() async {
    // Assim como os outros pedidos de permissão, não faz nada se a
    // restrição já foi removida.
    if (!await refreshBackgroundRestriction()) return;

    final bool userAgreed = await _prompts.confirmBackgroundUsageSettings();
    if (userAgreed) {
      _awaitingBackgroundUsageReturn = await _backgroundUsageSettingsLauncher
          .open();
    }
  }

  /// Says the GPS is off (see [PermissionPrompts.notifyGpsDisabled]).
  Future<void> notifyGpsDisabled() => _prompts.notifyGpsDisabled();

  @override
  void onClose() {
    _lifecycle.stop();
    super.onClose();
  }
}
