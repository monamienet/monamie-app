/// Google endpoints used by the app. The OAuth client ids come from the
/// central Firebase project's config, fetched at build time.
///
/// None of these values is a secret: they are compiled into the app binary and
/// sent over the network, so anyone can read them. Access is protected by the
/// user's Google `Bearer` token, validated by the groups gateway.
class GoogleConfig {
  static const String gdiGoogleHost =
      'workspace-groups-gateway-952379262353.southamerica-east1.run.app';
  static const String gdiUserGoogleGroupsPath = '/groups';
  static const String gdiGroupMembers = '/members';
}
