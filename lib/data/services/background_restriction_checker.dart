/// Interface que verifica se o sistema operacional restringe a execução do
/// aplicativo em segundo plano (modo de bateria "Restrito" no Android).
///
/// Com essa restrição ativa, o Android remove o status de foreground do
/// serviço de rastreamento assim que o app sai da tela, interrompendo o envio
/// de localização. Permite injetar implementações falsas em testes.
abstract class BackgroundRestrictionChecker {
  /// Retorna `true` somente quando o sistema confirma a restrição.
  Future<bool> isRestricted();
}
