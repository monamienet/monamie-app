/// Interface que abre a tela do sistema onde o usuário remove a restrição de
/// uso em segundo plano do aplicativo (modo de bateria "Restrito" no
/// Android). Permite injetar implementações falsas em testes.
abstract class BackgroundUsageSettingsLauncher {
  /// Retorna `true` quando alguma tela de configurações foi aberta.
  Future<bool> open();
}
