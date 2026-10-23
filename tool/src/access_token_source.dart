/// Supplies an OAuth access token of the person running the tool.
abstract interface class AccessTokenSource {
  Future<String> accessToken();
}
