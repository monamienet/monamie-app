import 'package:flutter/material.dart';

/// Camada que cobre a tela enquanto o logout, ou a troca de organização, está
/// em andamento: o rastreamento é encerrado antes, o que pode levar alguns
/// segundos. [message] diz qual dos dois está acontecendo.
///
/// Bloqueia toques (inclusive no botão de rastreamento), evitando que o
/// serviço seja religado no meio do logout.
class LogoutProgressOverlay extends StatelessWidget {
  const LogoutProgressOverlay({super.key, this.message = 'Encerrando sessão…'});

  final String message;

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
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  const SizedBox(width: 16),
                  Text(message),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
