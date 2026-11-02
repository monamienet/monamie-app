import 'dart:ui' show AppLifecycleState;

import 'package:flutter/foundation.dart';

import 'package:monamie_app/app/data/services/app_lifecycle_events.dart';
import 'package:monamie_app/app/data/services/background_restriction_checker.dart';
import 'package:monamie_app/app/data/services/background_usage_settings_launcher.dart';
import 'package:monamie_app/app/data/services/method_channel_background_restriction_checker.dart';
import 'package:monamie_app/app/data/services/method_channel_background_usage_settings_launcher.dart';
import 'package:monamie_app/app/data/services/widgets_binding_app_lifecycle_events.dart';
import 'package:monamie_app/app/modules/monamie/controller/permission_prompts.dart';
import 'package:monamie_app/app/utils/notice_presenter.dart';
import 'package:monamie_app/app/utils/user_notice.dart';
import 'package:permission_handler/permission_handler.dart';

/// The permissions the tracking needs and the battery restriction, read
/// from the system. Each one is its own [ValueListenable], so the tracking
/// controller reacts to the one it needs.
///
/// Whoever creates it calls [start] once, which follows the app's return to
/// the foreground and reads the statuses, and [dispose] once.
class PermissionsController {
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

  final _hasWhenInUseLocationPermission = ValueNotifier<bool>(false);
  final _hasAlwaysLocationPermission = ValueNotifier<bool>(false);
  final _hasNotificationPermission = ValueNotifier<bool>(false);
  final _isBackgroundRestricted = ValueNotifier<bool>(false);

  bool _started = false;
  bool _disposed = false;

  ValueListenable<bool> get hasWhenInUseLocationPermission =>
      _hasWhenInUseLocationPermission;
  ValueListenable<bool> get hasAlwaysLocationPermission =>
      _hasAlwaysLocationPermission;
  ValueListenable<bool> get hasNotificationPermission =>
      _hasNotificationPermission;

  /// `true` quando o app está no modo de bateria "Restrito". Nesse modo o
  /// Android derruba o serviço de rastreamento assim que o app sai da tela.
  ValueListenable<bool> get isBackgroundRestricted => _isBackgroundRestricted;

  /// Sets [notifier] (which notifies only when the value differs), unless
  /// disposed: a system answer may land after [dispose].
  void _set(ValueNotifier<bool> notifier, bool value) {
    if (!_disposed) notifier.value = value;
  }

  /// Follows the app's return to the foreground and reads the statuses.
  /// Only the first call does anything.
  Future<void> start() async {
    if (_started || _disposed) return;
    _started = true;
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
    if (!_isBackgroundRestricted.value) return;

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
    _set(
      _hasWhenInUseLocationPermission,
      await Permission.locationWhenInUse.isGranted,
    );
    _set(
      _hasAlwaysLocationPermission,
      await Permission.locationAlways.isGranted,
    );
    _set(_hasNotificationPermission, await Permission.notification.isGranted);
    await refreshBackgroundRestriction();
  }

  /// Reconsulta o sistema e atualiza [isBackgroundRestricted].
  Future<bool> refreshBackgroundRestriction() async {
    final restricted = await _backgroundRestrictionChecker.isRestricted();
    _set(_isBackgroundRestricted, restricted);
    return restricted;
  }

  Future<void> requestWhenInUsePermission() async {
    if (await Permission.locationWhenInUse.isPermanentlyDenied) {
      await openAppSettings();
    } else {
      await Permission.locationWhenInUse.request();
    }

    _set(
      _hasWhenInUseLocationPermission,
      await Permission.locationWhenInUse.isGranted,
    );
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

    _set(
      _hasAlwaysLocationPermission,
      await Permission.locationAlways.isGranted,
    );
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

    _set(_hasNotificationPermission, await Permission.notification.isGranted);
  }

  /// Verifica se todas as permissões necessárias para o MonAmie funcionar
  /// adequadamente já foram concedidas ao aplicativo pelo usuário.
  bool arePermissionsGranted() {
    return _hasAlwaysLocationPermission.value &&
        _hasNotificationPermission.value &&
        !_isBackgroundRestricted.value;
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

  /// Stops following the app's lifecycle and releases the values. Only the
  /// first call does anything.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _lifecycle.stop();
    for (final notifier in [
      _hasWhenInUseLocationPermission,
      _hasAlwaysLocationPermission,
      _hasNotificationPermission,
      _isBackgroundRestricted,
    ]) {
      notifier.dispose();
    }
  }
}
