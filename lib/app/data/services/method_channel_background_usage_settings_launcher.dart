import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:monamie_app/app/data/services/background_usage_settings_launcher.dart';
import 'package:monamie_app/app/data/services/method_channel_background_restriction_checker.dart';
import 'package:permission_handler/permission_handler.dart';

/// Abre a tela "Uso da bateria pelo app" através do canal registrado em
/// `MainActivity.kt`, o mesmo usado por
/// [MethodChannelBackgroundRestrictionChecker].
///
/// Quando o aparelho não oferece essa tela, ou a chamada nativa falha, abre
/// as informações do app com `openAppSettings()`.
class MethodChannelBackgroundUsageSettingsLauncher
    implements BackgroundUsageSettingsLauncher {
  @override
  Future<bool> open() async {
    if (await _openBatteryUsagePage()) return true;
    return openAppSettings();
  }

  Future<bool> _openBatteryUsagePage() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    try {
      return await MethodChannelBackgroundRestrictionChecker.channel
              .invokeMethod<bool>('openBackgroundUsageSettings') ??
          false;
    } on PlatformException catch (e) {
      debugPrint(
        '[BackgroundUsageSettingsLauncher] Erro ao abrir a tela de bateria: $e',
      );
      return false;
    } on MissingPluginException catch (e) {
      debugPrint(
        '[BackgroundUsageSettingsLauncher] Canal nativo indisponível: $e',
      );
      return false;
    }
  }
}
