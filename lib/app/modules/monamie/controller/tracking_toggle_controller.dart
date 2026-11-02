import 'package:get/get.dart';
import 'package:monamie_app/app/utils/result.dart';
import 'package:monamie_app/app/utils/user_notice.dart';

/// Interface que define as operações e estados necessários para o botão de alternância de rastreamento.
///
/// Permite o desacoplamento entre componentes visuais (UI) e a implementação
/// concreta do serviço de rastreamento, facilitando testes e injeção de dependências.
abstract class TrackingToggleController {
  RxBool get isTrackingEnabled;
  RxBool get isTrackingLoading;

  /// Starts or stops sharing. [Ok] may hold a [UserNotice] to show (sharing
  /// started, with a remark); [Err] says why sharing did not start.
  Future<Result<UserNotice?>> toggleService();
}
