/// Erro retornado pelo workspace-groups-gateway.
///
/// Carrega o status HTTP e (parte do) corpo da resposta para que a causa
/// real seja visível na interface e nos logs, em vez de ser engolida.
class GroupsApiException implements Exception {
  final String email;
  final int statusCode;
  final String body;

  GroupsApiException(this.email, this.statusCode, String body)
      : body = body.length > 200 ? '${body.substring(0, 200)}…' : body;

  @override
  String toString() => 'Erro $statusCode ao consultar $email: $body';
}

