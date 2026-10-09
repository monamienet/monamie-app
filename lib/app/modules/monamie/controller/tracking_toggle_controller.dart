import 'package:get/get.dart';

/// Interface que define as operações e estados necessários para o botão de alternância de rastreamento.
///
/// Permite o desacoplamento entre componentes visuais (UI) e a implementação
/// concreta do serviço de rastreamento, facilitando testes e injeção de dependências.
abstract class TrackingToggleController {
  RxBool get isTrackingEnabled;
  RxBool get isTrackingLoading;
  Future<void> toggleService();
}

