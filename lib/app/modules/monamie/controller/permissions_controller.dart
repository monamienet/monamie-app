import 'package:flutter/material.dart';
import 'package:monamie_app/app/data/services/background_restriction_checker.dart';
import 'package:monamie_app/app/data/services/method_channel_background_restriction_checker.dart';
import 'package:monamie_app/app/utils/color_pallete.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsController extends GetxController with WidgetsBindingObserver {
  PermissionsController({
    BackgroundRestrictionChecker? backgroundRestrictionChecker,
  }) : _backgroundRestrictionChecker = backgroundRestrictionChecker ??
            MethodChannelBackgroundRestrictionChecker();

  final BackgroundRestrictionChecker _backgroundRestrictionChecker;

  final hasWhenInUseLocationPermission = false.obs;
  final hasAlwaysLocationPermission = false.obs;
  final hasNotificationPermission = false.obs;

  /// `true` quando o app está no modo de bateria "Restrito". Nesse modo o
  /// Android derruba o serviço de rastreamento assim que o app sai da tela.
  final isBackgroundRestricted = false.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    await _refreshStatuses();
  }

  /// Esta função realiza trabalho quando o usuário volta para o aplicativo
  /// após ter saído do mesmo (neste caso, quando ele volta das configurações).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      await _refreshStatuses();
    }
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
    isBackgroundRestricted.value =
        await _backgroundRestrictionChecker.isRestricted();
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
      bool userAgreed = await _showBackgroundDisclosure();

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

  /// Explica a restrição de bateria e abre as configurações do app, onde o
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

    final bool userAgreed = await _showBackgroundUsageDialog(
      "O seu aparelho está restringindo o MonAmie em segundo plano. "
      "Assim, o rastreamento para quando você sai do aplicativo ou "
      "desliga a tela.\n\n"
      "Como ajustar:\n"
      "1. Toque em 'Prosseguir'.\n"
      "2. Abra 'Uso da bateria pelo app' (ou 'Bateria').\n"
      "3. Ative 'Permitir o uso em segundo plano' (ou escolha 'Sem restrições').\n\n"
      "Se o interruptor já aparecer ativado, desative-o e ative-o novamente.",
    );
    if (userAgreed) await openAppSettings();
  }

  Future<bool> _showBackgroundUsageDialog(String message) async {
    return await Get.dialog<bool>(
          AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.0),
            ),
            title: Row(
              children: [
                Icon(Icons.battery_alert, color: AppColors.darkBlue()),
                const SizedBox(width: 10),
                const Text("Atenção"),
              ],
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.darkBlue(),
                ),
                child: const Text("AGORA NÃO"),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.darkBlue(),
                ),
                child: const Text("PROSSEGUIR"),
              ),
            ],
          ),
          barrierDismissible: false,
        ) ??
        false;
  }

  /// Aviso requerido pela Google Play.
  Future<bool> _showBackgroundDisclosure() async {
    return await Get.dialog<bool>(
          AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.0),
            ),
            title: Row(
              children: [
                Icon(Icons.security, color: AppColors.darkBlue()),
                const SizedBox(width: 10),
                const Text("Atenção"),
              ],
            ),
            content: const Text(
              "O MonAmie deseja coletar dados de localização mesmo quando o aplicativo estiver fechado ou não estiver em uso.\n\n"
              "Esses dados permitem que os supervisores visualizem sua posição em tempo real.\n\n"
              "Como ativar:\n"
              "1. Toque em 'Prosseguir'.\n"
              "2. Em Permissões > Localização.\n"
              "3. Selecione 'Permitir o tempo todo'.",
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.darkBlue(),
                ),
                child: Text("AGORA NÃO"),
              ),
              TextButton(
                onPressed: () async {
                  Get.back(result: true);
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.darkBlue(),
                ),
                child: const Text("PROSSEGUIR"),
              ),
            ],
          ),
          barrierDismissible: false, // Impede fechar clicando fora
        ) ??
        false;
  }

  Future<void> notifyGpsDisabled() async {
    await Get.dialog(
      AlertDialog(
        title: Text("O GPS está desativado"),
        content: Text("Por favor, ative o GPS para continuar."),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.darkBlue()),
            child: Text("ENTENDI"),
            onPressed: () {
              Get.back(); // Fecha o diálogo
            },
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
  
  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
}
