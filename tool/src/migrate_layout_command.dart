import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:http/http.dart' as http;

import 'access_token_source.dart';
import 'partners.dart';

/// Root collections of the layout before #94, copied under `partners/{id}`.
/// `usuarios` documents keep their `historico_posicoes` subcollection.
const legacyRootCollections = ['usuarios', 'users', 'config'];

/// Subcollections copied together with their parent document.
const legacySubcollections = {'usuarios': 'historico_posicoes'};

/// The new path of a document of the old layout: `usuarios/a@b.com` →
/// `partners/<id>/usuarios/a@b.com`. Paths already under `partners/` are
/// returned unchanged, so running the copy twice is harmless.
String scopedDocumentPath(String partnerId, String legacyPath) =>
    legacyPath.startsWith('partners/')
    ? legacyPath
    : '${partnerDataPath(partnerId)}/$legacyPath';

/// Lists and writes raw Firestore REST documents, keeping their `fields`
/// exactly (types included) instead of decoding them.
class RawFirestore {
  RawFirestore(this._client, this._projectId, this._accessToken);

  final http.Client _client;
  final String _projectId;
  final String _accessToken;

  String get _root => 'projects/$_projectId/databases/(default)/documents';

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_accessToken',
    'Content-Type': 'application/json',
  };

  /// Every document of the collection at [path], as `(path, fields)`.
  Future<List<(String, Object?)>> list(String path) async {
    final documents = <(String, Object?)>[];
    String? pageToken;
    do {
      final uri = Uri.https('firestore.googleapis.com', '/v1/$_root/$path', {
        'pageSize': '300',
        'pageToken': ?pageToken,
      });
      final response = await _client.get(uri, headers: _headers);
      if (response.statusCode != 200) {
        throw PartnerToolException(
          "Could not list '$path' in '$_projectId' "
          '(HTTP ${response.statusCode}).',
        );
      }
      final body = jsonDecode(response.body) as Map<String, Object?>;
      for (final doc in (body['documents'] as List?) ?? const []) {
        final name = (doc as Map)['name'] as String;
        documents.add((name.substring('$_root/'.length), doc['fields']));
      }
      pageToken = body['nextPageToken'] as String?;
    } while (pageToken != null);
    return documents;
  }

  /// Writes [documents] (`(path, fields)`) in batches of 500.
  Future<void> write(List<(String, Object?)> documents) async {
    for (var start = 0; start < documents.length; start += 500) {
      final chunk = documents.skip(start).take(500);
      final response = await _client.post(
        Uri.https(
          'firestore.googleapis.com',
          '/v1/projects/$_projectId/databases/(default)/documents:batchWrite',
        ),
        headers: _headers,
        body: jsonEncode({
          'writes': [
            for (final (path, fields) in chunk)
              {
                'update': {'name': '$_root/$path', 'fields': fields ?? {}},
              },
          ],
        }),
      );
      if (response.statusCode != 200) {
        throw PartnerToolException(
          "Could not write to '$_projectId' (HTTP ${response.statusCode}): "
          '${response.body}',
        );
      }
    }
  }
}

/// `migrate-layout <id>`: copies a Standard partner's data from the root of
/// its project (the layout before #94) to `partners/<id>/…`. The old
/// documents are left in place; delete them once the new app version is
/// everywhere. Prints counts; `--apply` writes.
class MigrateLayoutCommand extends Command<void> {
  MigrateLayoutCommand(this._tokens, {http.Client? client})
    : _client = client ?? http.Client() {
    argParser.addFlag(
      'apply',
      negatable: false,
      help: 'Write the copies (without it, only count them).',
    );
  }

  final AccessTokenSource _tokens;
  final http.Client _client;

  @override
  String get name => 'migrate-layout';

  @override
  String get description =>
      'Copy a partner\'s root collections (usuarios, users, config) to '
      'partners/<id>/ in its own project.';

  @override
  String get invocation => '${runner!.executableName} $name <id>';

  @override
  Future<void> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) usageException('Expected exactly one partner id.');
    final id = rest.single;
    checkPartnerId(id);
    final projectId = firebaseProjectId(id);
    final firestore = RawFirestore(
      _client,
      projectId,
      await _tokens.accessToken(),
    );

    final copies = <(String, Object?)>[];
    for (final collection in legacyRootCollections) {
      final documents = await firestore.list(collection);
      stdout.writeln('$collection: ${documents.length} documents');
      for (final (path, fields) in documents) {
        copies.add((scopedDocumentPath(id, path), fields));
        final sub = legacySubcollections[collection];
        if (sub == null) continue;
        final points = await firestore.list('$path/$sub');
        copies.addAll([
          for (final (pointPath, pointFields) in points)
            (scopedDocumentPath(id, pointPath), pointFields),
        ]);
      }
    }
    stdout.writeln('${copies.length} documents to copy into $projectId.');
    if (!argResults!.flag('apply')) {
      stdout.writeln('Nothing written. Run again with --apply.');
      return;
    }
    await firestore.write(copies);
    stdout.writeln('Copied. The old root documents are still there.');
  }
}
