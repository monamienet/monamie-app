import 'package:flutter/material.dart';

/// Camada que cobre a tela enquanto o logout está em andamento: o
/// rastreamento é encerrado antes da saída, o que pode levar alguns segundos.
///
/// Bloqueia toques (inclusive no botão de rastreamento), evitando que o
/// serviço seja religado no meio do logout.
class LogoutProgressOverlay extends StatelessWidget {
  const LogoutProgressOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const ModalBarrier(dismissible: false, color: Colors.black45),
        Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  SizedBox(width: 16),
                  Text('Encerrando sessão…'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
