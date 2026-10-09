import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/modules/monamie/controller/tracking_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/tracking_toggle_controller.dart';

/// Botão flutuante para ativar/desativar o compartilhamento de localização em tempo real.
///
/// Apresenta feedback visual imediato ao usuário:
/// - Desativado: Vermelho (`Colors.red`) com ícone [Icons.location_off].
/// - Em processamento: Laranja (`Colors.orange.shade800`) com [CircularProgressIndicator] branco e clique desabilitado.
/// - Ativado: Verde (`Colors.green`) com ícone [Icons.location_on].
class TrackingToggleButton extends StatelessWidget {
  /// Permite injeção explícita de [TrackingToggleController], útil em testes de widget.
  final TrackingToggleController? controller;

  const TrackingToggleButton({
    super.key,
    this.controller,
  });

  TrackingToggleController get _trackingCtrl =>
      controller ?? Get.find<TrackingController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isEnabled = _trackingCtrl.isTrackingEnabled.value;
      final isLoading = _trackingCtrl.isTrackingLoading.value;

      final Color backgroundColor;
      if (isLoading) {
        backgroundColor = Colors.orange.shade800;
      } else if (isEnabled) {
        backgroundColor = Colors.green;
      } else {
        backgroundColor = Colors.red;
      }

      final String tooltip;
      if (isLoading) {
        tooltip = isEnabled
            ? 'Desativando compartilhamento de localização...'
            : 'Ativando compartilhamento de localização...';
      } else if (isEnabled) {
        tooltip = 'Desativar compartilhamento de localização';
      } else {
        tooltip = 'Ativar compartilhamento de localização';
      }

      return FloatingActionButton(
        heroTag: "btnToggleTracking",
        tooltip: tooltip,
        onPressed: isLoading ? null : _trackingCtrl.toggleService,
        backgroundColor: backgroundColor,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading
              ? const SizedBox(
                  key: ValueKey('tracking_toggle_loading'),
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(
                  isEnabled ? Icons.location_on : Icons.location_off,
                  key: ValueKey(
                    isEnabled
                        ? 'tracking_toggle_on'
                        : 'tracking_toggle_off',
                  ),
                  color: Colors.white,
                ),
        ),
      );
    });
  }
}
