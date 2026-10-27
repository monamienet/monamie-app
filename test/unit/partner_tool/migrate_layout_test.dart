import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../tool/src/migrate_layout_command.dart';
import '../../../tool/src/partners.dart';

const documentsRoot =
    'projects/monamienet-rotasul/databases/(default)/documents';

/// A [MockClient] that answers the requests in order with [responses]
/// (`(status, body)`), recording them in [requests].
MockClient answeringInOrder(
  List<http.Request> requests,
  List<(int, Object?)> responses,
) => MockClient((request) async {
  final (status, body) = responses[requests.length];
  requests.add(request);
  return http.Response(jsonEncode(body), status);
});

/// [count] documents `usuarios/u<i>@x.com` with one string field each.
List<(String, Object?)> documents(int count) => [
  for (var i = 0; i < count; i++)
    (
      'usuarios/u$i@x.com',
      {
        'nome': {'stringValue': 'u$i'},
      },
    ),
];

void main() {
  group('firebaseProjectId - Unit Test Suite', () {
    final cases = [
      (
        'Happy Path: a Community partner lives in the shared project',
        'community',
        'monamienet-community',
      ),
      (
        'Happy Path: a Standard partner has its own project',
        'standard',
        'monamienet-rotasul',
      ),
      ('Edge Case: no plan means its own project', null, 'monamienet-rotasul'),
    ];
    for (final (label, plan, expected) in cases) {
      test('$label (plan: $plan)', () {
        // 1. Arrange
        const id = 'rotasul';

        // 2. Act
        final projectId = firebaseProjectId(id, plan: plan);

        // 3. Assert
        expect(projectId, expected);
      });
    }
  });

  group('scopedDocumentPath - Unit Test Suite', () {
    final cases = [
      (
        'Happy Path: a root document moves under the partner',
        'usuarios/a@b.com',
        'partners/rotasul/usuarios/a@b.com',
      ),
      (
        'Happy Path: a trail point keeps its subcollection',
        'usuarios/a@b.com/historico_posicoes/p1',
        'partners/rotasul/usuarios/a@b.com/historico_posicoes/p1',
      ),
      (
        'Edge Case: a path already under partners/ is unchanged',
        'partners/rotasul/users/u1',
        'partners/rotasul/users/u1',
      ),
      (
        'Edge Case: config/branding moves under the partner',
        'config/branding',
        'partners/rotasul/config/branding',
      ),
    ];
    for (final (label, legacy, expected) in cases) {
      test('$label ($legacy)', () {
        // 1. Arrange
        const id = 'rotasul';

        // 2. Act
        final path = scopedDocumentPath(id, legacy);

        // 3. Assert
        expect(path, expected);
      });
    }
  });

  group('RawFirestore.list - Unit Test Suite', () {
    test('Happy Path: returns paths relative to documents with their raw '
        'fields', () async {
      // 1. Arrange
      final requests = <http.Request>[];
      final client = answeringInOrder(requests, [
        (
          200,
          {
            'documents': [
              {
                'name': '$documentsRoot/usuarios/a@b.com',
                'fields': {
                  'lat': {'doubleValue': -22.9},
                },
              },
            ],
          },
        ),
      ]);
      final firestore = RawFirestore(client, 'monamienet-rotasul', 'token');

      // 2. Act
      final listed = await firestore.list('usuarios');

      // 3. Assert
      expect(
        [
          for (final (path, fields) in listed) [path, fields],
        ],
        [
          [
            'usuarios/a@b.com',
            {
              'lat': {'doubleValue': -22.9},
            },
          ],
        ],
      );
    });

    test('Edge Case: follows nextPageToken until it is absent', () async {
      // 1. Arrange
      final requests = <http.Request>[];
      final client = answeringInOrder(requests, [
        (
          200,
          {
            'documents': [
              {'name': '$documentsRoot/users/u1', 'fields': {}},
            ],
            'nextPageToken': 'page2',
          },
        ),
        (
          200,
          {
            'documents': [
              {'name': '$documentsRoot/users/u2', 'fields': {}},
            ],
          },
        ),
      ]);
      final firestore = RawFirestore(client, 'monamienet-rotasul', 'token');

      // 2. Act
      final listed = await firestore.list('users');

      // 3. Assert
      expect(
        [
          [for (final (path, _) in listed) path],
          [for (final r in requests) r.url.queryParameters['pageToken']],
        ],
        [
          ['users/u1', 'users/u2'],
          [null, 'page2'],
        ],
      );
    });

    test('Edge Case: an empty collection gives no documents', () async {
      // 1. Arrange
      final requests = <http.Request>[];
      final client = answeringInOrder(requests, [(200, <String, Object?>{})]);
      final firestore = RawFirestore(client, 'monamienet-rotasul', 'token');

      // 2. Act
      final listed = await firestore.list('config');

      // 3. Assert
      expect(listed, isEmpty);
    });

    test('Sad Path: a non-200 answer throws PartnerToolException', () async {
      // 1. Arrange
      final requests = <http.Request>[];
      final client = answeringInOrder(requests, [
        (403, {'error': 'denied'}),
      ]);
      final firestore = RawFirestore(client, 'monamienet-rotasul', 'token');

      // 2. Act
      final listing = firestore.list('usuarios');

      // 3. Assert
      await expectLater(listing, throwsA(isA<PartnerToolException>()));
    });
  });

  group('RawFirestore.write - Unit Test Suite', () {
    test('Happy Path: each document becomes an update with its full name '
        'and fields', () async {
      // 1. Arrange
      final requests = <http.Request>[];
      final client = answeringInOrder(requests, [(200, {})]);
      final firestore = RawFirestore(client, 'monamienet-rotasul', 'token');

      // 2. Act
      await firestore.write(documents(1));

      // 3. Assert
      expect(
        [requests.single.url.path, jsonDecode(requests.single.body)],
        [
          '/v1/projects/monamienet-rotasul/databases/(default)/documents:batchWrite',
          {
            'writes': [
              {
                'update': {
                  'name': '$documentsRoot/usuarios/u0@x.com',
                  'fields': {
                    'nome': {'stringValue': 'u0'},
                  },
                },
              },
            ],
          },
        ],
      );
    });

    final batches = [
      ('Edge Case: exactly 500 documents fit in one request', 500, [500]),
      ('Edge Case: 501 documents take two requests', 501, [500, 1]),
      ('Edge Case: no documents send nothing', 0, <int>[]),
    ];
    for (final (label, count, expected) in batches) {
      test('$label ($count)', () async {
        // 1. Arrange
        final requests = <http.Request>[];
        final client = answeringInOrder(requests, [(200, {}), (200, {})]);
        final firestore = RawFirestore(client, 'monamienet-rotasul', 'token');

        // 2. Act
        await firestore.write(documents(count));

        // 3. Assert
        expect([
          for (final r in requests)
            ((jsonDecode(r.body) as Map)['writes'] as List).length,
        ], expected);
      });
    }

    test('Sad Path: a non-200 answer throws PartnerToolException', () async {
      // 1. Arrange
      final requests = <http.Request>[];
      final client = answeringInOrder(requests, [
        (400, {'error': 'bad'}),
      ]);
      final firestore = RawFirestore(client, 'monamienet-rotasul', 'token');

      // 2. Act
      final writing = firestore.write(documents(1));

      // 3. Assert
      await expectLater(writing, throwsA(isA<PartnerToolException>()));
    });
  });
}
