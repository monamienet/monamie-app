import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:monamie_app/app/data/services/background_restriction_checker.dart';

/// Consulta `ActivityManager.isBackgroundRestricted()` através do canal
/// registrado em `MainActivity.kt`.
///
/// Qualquer falha na consulta resulta em `false`: uma verificação quebrada
/// nunca deve bloquear o rastreamento de um usuário sem restrição.
class MethodChannelBackgroundRestrictionChecker
    implements BackgroundRestrictionChecker {
  static const MethodChannel channel = MethodChannel(
    'monamie/background_restriction',
  );

  @override
  Future<bool> isRestricted() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    try {
      return await channel.invokeMethod<bool>('isBackgroundRestricted') ??
          false;
    } on PlatformException catch (e) {
      debugPrint(
        '[BackgroundRestrictionChecker] Erro ao consultar restrição: $e',
      );
      return false;
    } on MissingPluginException catch (e) {
      debugPrint(
        '[BackgroundRestrictionChecker] Canal nativo indisponível: $e',
      );
      return false;
    }
  }
}
