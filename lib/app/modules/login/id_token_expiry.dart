import 'dart:convert';

/// Whether a Google ID token is still good for signing in: it carries an
/// `exp` (seconds since the epoch) later than [now] plus [margin].
///
/// A token that cannot be read counts as not fresh, so the caller asks for a
/// new one instead of trusting it.
bool idTokenIsFresh(
  String? token,
  DateTime now, {
  Duration margin = const Duration(minutes: 5),
}) {
  if (token == null) return false;
  final parts = token.split('.');
  if (parts.length != 3) return false;
  try {
    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    final exp = payload is Map ? payload['exp'] : null;
    if (exp is! num) return false;
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(
      (exp * 1000).round(),
      isUtc: true,
    );
    return expiresAt.isAfter(now.toUtc().add(margin));
  } on FormatException {
    return false;
  }
}
