import 'package:flutter/material.dart';
import 'package:monamie_app/app/modules/monamie/controller/permission_prompts.dart';
import 'package:monamie_app/app/utils/app_messenger.dart';
import 'package:monamie_app/app/utils/color_pallete.dart';

/// [PermissionPrompts] as dialogs on the root navigator
/// ([rootNavigatorKey]): the questions come from a controller in the middle
/// of a flow, with no `BuildContext` of its own.
class DialogPermissionPrompts implements PermissionPrompts {
  const DialogPermissionPrompts();

  static const _backgroundUsageMessage =
      "O seu aparelho está restringindo o aplicativo em segundo plano. "
      "Assim, o rastreamento é desabilitado quando você sai do aplicativo ou "
      "desliga a tela.\n\n"
      "Como ajustar:\n"
      "1. Toque em 'Prosseguir'.\n"
      "2. Ative 'Permitir o uso em segundo plano' (ou escolha 'Sem restrições').\n"
      "3. Volte para o aplicativo.\n\n"
      "Se abrir a tela de informações do app, toque antes em 'Uso da "
      "bateria pelo app' (ou 'Bateria'). "
      "Se o interruptor já aparecer ativado, desative-o e ative-o novamente.";

  static const _backgroundLocationMessage =
      "O app deseja coletar dados de localização mesmo quando o aplicativo estiver fechado ou não estiver em uso.\n\n"
      "Esses dados permitem que um grupo de pessoas, determinado e gerenciado pela sua empresa, visualize sua posição em tempo real.\n\n"
      "Como ativar:\n"
      "1. Toque em 'Prosseguir'.\n"
      "2. Em Permissões > Localização.\n"
      "3. Selecione 'Permitir o tempo todo'.";

  @override
  Future<bool> confirmBackgroundUsageSettings() =>
      _confirm(icon: Icons.battery_alert, message: _backgroundUsageMessage);

  /// Required by Google Play.
  @override
  Future<bool> confirmBackgroundLocation() =>
      _confirm(icon: Icons.security, message: _backgroundLocationMessage);

  @override
  Future<void> notifyGpsDisabled() async {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text("O GPS está desativado"),
        content: const Text("Por favor, ative o GPS para continuar."),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.darkBlue()),
            child: const Text("ENTENDI"),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      ),
    );
  }

  /// An "Atenção" dialog with [icon] and [message]; completes with whether
  /// the person tapped "PROSSEGUIR". It cannot be dismissed by tapping
  /// outside.
  Future<bool> _confirm({
    required IconData icon,
    required String message,
  }) async {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return false;
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.0),
            ),
            title: Row(
              children: [
                Icon(icon, color: AppColors.darkBlue()),
                const SizedBox(width: 10),
                const Text("Atenção"),
              ],
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.darkBlue(),
                ),
                child: const Text("AGORA NÃO"),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.darkBlue(),
                ),
                child: const Text("PROSSEGUIR"),
              ),
            ],
          ),
        ) ??
        false;
  }
}
