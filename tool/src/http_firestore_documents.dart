import 'dart:convert';

import 'package:http/http.dart' as http;

import 'firestore_documents.dart';
import 'organizations.dart';

/// [FirestoreDocuments] over the Firestore REST API (v1).
class HttpFirestoreDocuments implements FirestoreDocuments {
  HttpFirestoreDocuments({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String projectId, String path) => Uri.https(
    'firestore.googleapis.com',
    '/v1/projects/$projectId/databases/(default)/documents/$path',
  );

  @override
  Future<Map<String, Object?>?> get({
    required String projectId,
    required String path,
    String? accessToken,
  }) async {
    final response = await _client.get(
      _uri(projectId, path),
      headers: {'Authorization': ?_bearer(accessToken)},
    );
    if (response.statusCode == 404) return null;
    _checkStatus(response, 'read', projectId, path);
    final body = jsonDecode(response.body);
    final fields = body is Map ? body['fields'] : null;
    return fields is Map ? decodeFirestoreFields(fields) : {};
  }

  @override
  Future<void> set({
    required String projectId,
    required String path,
    required Map<String, Object?> data,
    required String accessToken,
  }) async {
    final response = await _client.patch(
      _uri(projectId, path),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'fields': encodeFirestoreFields(data)}),
    );
    _checkStatus(response, 'write', projectId, path);
  }

  @override
  Future<void> update({
    required String projectId,
    required String path,
    required Map<String, Object?> data,
    required List<String> fieldPaths,
    required String accessToken,
  }) async {
    final uri = _uri(projectId, path);
    final response = await _client.patch(
      uri.replace(
        query: [
          for (final field in fieldPaths)
            'updateMask.fieldPaths=${Uri.encodeQueryComponent(field)}',
        ].join('&'),
      ),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'fields': encodeFirestoreFields(data)}),
    );
    _checkStatus(response, 'write', projectId, path);
  }
}

String? _bearer(String? token) => token == null ? null : 'Bearer $token';

void _checkStatus(
  http.Response response,
  String action,
  String projectId,
  String path,
) {
  if (response.statusCode == 200) return;
  throw OrganizationToolException(
    "Could not $action '$path' in project '$projectId' "
    '(HTTP ${response.statusCode}). Check that the project exists, that '
    'Firestore is enabled and that your account (`gcloud auth login`) may '
    '$action it.',
  );
}

/// Encodes [data] as Firestore REST `fields` (strings, booleans, integers,
/// timestamps and nested maps; nulls are left out).
Map<String, Object?> encodeFirestoreFields(Map<String, Object?> data) => {
  for (final MapEntry(:key, :value) in data.entries)
    if (value != null) key: _encodeValue(value),
};

Map<String, Object?> _encodeValue(Object value) => switch (value) {
  String() => {'stringValue': value},
  bool() => {'booleanValue': value},
  int() => {'integerValue': '$value'},
  DateTime() => {'timestampValue': value.toUtc().toIso8601String()},
  Map<String, Object?>() => {
    'mapValue': {'fields': encodeFirestoreFields(value)},
  },
  _ => throw ArgumentError.value(value, 'value', 'unsupported Firestore type'),
};

/// Decodes Firestore REST `fields` back to plain Dart values.
Map<String, Object?> decodeFirestoreFields(Map<Object?, Object?> fields) => {
  for (final MapEntry(:key, :value) in fields.entries)
    if (key is String) key: _decodeValue(value),
};

Object? _decodeValue(Object? value) => switch (value) {
  {'stringValue': final String v} => v,
  {'booleanValue': final bool v} => v,
  {'integerValue': final String v} => int.tryParse(v),
  {'timestampValue': final String v} => DateTime.tryParse(v),
  {'mapValue': {'fields': final Map<Object?, Object?> v}} =>
    decodeFirestoreFields(v),
  {'mapValue': _} => <String, Object?>{},
  _ => null,
};
