import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'partner_config.dart';

/// Paths, relative to the web app's base URL, staged by
/// `dart run tool/partner.dart web <id>`.
const webPartnerIdPath = 'partner/id.txt';
const webPartnerConfigPath = 'partner/partner.json';

/// How long the web app waits for each staged partner file.
const webPartnerFetchTimeout = Duration(seconds: 10);

/// Thrown when the partner of this build cannot be loaded. The message says
/// how to fix the build.
class PartnerLoadException implements Exception {
  PartnerLoadException(this.message);

  final String message;

  @override
  String toString() => 'PartnerLoadException: $message';
}

/// Loads `partners/<flavor>/partner.json` from [bundle] (Android and other
/// platforms built with `--flavor <id>`; pass `appFlavor` as [flavor]).
///
/// The file is a flavor-only asset, so each build bundles only its own
/// partner. Throws a [PartnerLoadException] on failure.
Future<PartnerConfig> loadPartnerConfig({
  required AssetBundle bundle,
  required String? flavor,
}) async {
  if (flavor == null) {
    throw PartnerLoadException(
      'No partner selected: run or build with --flavor <id>, where <id> is a '
      'folder under partners/.',
    );
  }
  final flavorProblem = partnerIdProblem(flavor);
  if (flavorProblem != null) {
    throw PartnerLoadException('--flavor $flavor: $flavorProblem.');
  }
  final key = 'partners/$flavor/partner.json';
  final String source;
  try {
    source = await bundle.loadString(key, cache: false);
  } on FlutterError {
    throw PartnerLoadException(
      '$key is not in this build. Add "- path: partners/$flavor/" with '
      '"flavors: [$flavor]" to the assets in pubspec.yaml.',
    );
  } on FormatException {
    throw PartnerLoadException('$key is not valid UTF-8.');
  }
  return _parse(flavor, source, key);
}

/// Loads the partner staged in `web/partner/`: its id from
/// [webPartnerIdPath] and its config from [webPartnerConfigPath], both
/// resolved against [base] (the page's URL, `Uri.base`).
///
/// Throws a [PartnerLoadException] on failure.
Future<PartnerConfig> loadWebPartner({
  required http.Client client,
  required Uri base,
}) async {
  final id = (await _fetch(client, base.resolve(webPartnerIdPath))).trim();
  // A server that answers unknown paths with index.html also lands here.
  final idProblem = partnerIdProblem(id);
  if (idProblem != null) {
    throw PartnerLoadException('$webPartnerIdPath: $idProblem. $_webFix');
  }
  final source = await _fetch(client, base.resolve(webPartnerConfigPath));
  return _parse(id, source, webPartnerConfigPath);
}

const _webFix =
    'Run "dart run tool/partner.dart web <id>" before building or running '
    'the web app.';

Future<String> _fetch(http.Client client, Uri uri) async {
  final http.Response response;
  try {
    response = await client.get(uri).timeout(webPartnerFetchTimeout);
  } on TimeoutException {
    throw PartnerLoadException(
      'Timed out after ${webPartnerFetchTimeout.inSeconds} s fetching $uri.',
    );
  } on http.ClientException catch (error) {
    throw PartnerLoadException(
      'Could not fetch $uri: ${error.message}. $_webFix',
    );
  }
  if (response.statusCode != 200) {
    throw PartnerLoadException(
      'Could not fetch $uri (HTTP ${response.statusCode}). $_webFix',
    );
  }
  try {
    // Static servers often send JSON without a charset, and package:http
    // then falls back to Latin-1; the staged files are UTF-8.
    return utf8.decode(response.bodyBytes);
  } on FormatException {
    throw PartnerLoadException('$uri is not valid UTF-8.');
  }
}

PartnerConfig _parse(String id, String source, String path) {
  try {
    return PartnerConfig.fromJson(id, jsonDecode(source));
  } on FormatException catch (error) {
    throw PartnerLoadException('$path: ${error.message}.');
  }
}
