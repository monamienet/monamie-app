/// Interface que encerra o serviço de rastreamento em segundo plano e confirma
/// que ele realmente parou. Usada no logout, que precisa parar o serviço antes
/// de desconectar o usuário. Permite injetar implementações falsas em testes.
abstract class BackgroundTrackingStopper {
  /// Para o serviço (se estiver rodando) e aguarda a confirmação de que ele
  /// parou. Quando [email] é informado e o serviço estava rodando, marca
  /// `isPublishing = false` no documento desse usuário.
  ///
  /// Deve ser chamado enquanto o usuário ainda está autenticado: depois do
  /// logout as regras do Firestore recusam a escrita.
  ///
  /// Retorna `true` quando o serviço não está (mais) em execução.
  Future<bool> stop({String? email});
}
