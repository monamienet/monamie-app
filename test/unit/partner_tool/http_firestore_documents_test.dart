import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../tool/src/http_firestore_documents.dart';
import '../../../tool/src/partners.dart';

const documentUrl =
    'https://firestore.googleapis.com/v1/projects/monamienet-acme/databases/'
    '(default)/documents/config/branding';

/// A [MockClient] that answers every request with [status] and [body], and
/// records the requests in [requests].
MockClient answering(
  List<http.Request> requests, {
  int status = 200,
  Object? body = const {},
}) => MockClient((request) async {
  requests.add(request);
  return http.Response(jsonEncode(body), status);
});

void main() {
  group('encodeFirestoreFields - Unit Test Suite', () {
    test('Happy Path: encodes every supported type', () {
      // 1. Arrange
      final data = <String, Object?>{
        'name': 'Acme',
        'active': true,
        'count': 3,
        'at': DateTime.utc(2026, 10, 20, 12, 30),
        'colors': <String, Object?>{'primary': '#0ABAB5'},
      };

      // 2. Act
      final fields = encodeFirestoreFields(data);

      // 3. Assert
      expect(fields, {
        'name': {'stringValue': 'Acme'},
        'active': {'booleanValue': true},
        'count': {'integerValue': '3'},
        'at': {'timestampValue': '2026-10-20T12:30:00.000Z'},
        'colors': {
          'mapValue': {
            'fields': {
              'primary': {'stringValue': '#0ABAB5'},
            },
          },
        },
      });
    });

    test('Edge Case: null values are left out', () {
      // 1. Arrange
      final data = <String, Object?>{'name': 'Acme', 'logoSvg': null};

      // 2. Act
      final fields = encodeFirestoreFields(data);

      // 3. Assert
      expect(fields.keys, ['name']);
    });

    test('Edge Case: a local time is written in UTC', () {
      // 1. Arrange
      final local = DateTime.utc(2026, 1, 2, 3, 4, 5).toLocal();

      // 2. Act
      final fields = encodeFirestoreFields({'at': local});

      // 3. Assert
      expect(fields['at'], {'timestampValue': '2026-01-02T03:04:05.000Z'});
    });

    test('Edge Case: an empty map is an empty mapValue', () {
      // 1. Arrange
      final data = <String, Object?>{'colors': <String, Object?>{}};

      // 2. Act
      final fields = encodeFirestoreFields(data);

      // 3. Assert
      expect(fields['colors'], {
        'mapValue': {'fields': <String, Object?>{}},
      });
    });

    test('Sad Path: an unsupported type throws an ArgumentError', () {
      // 1. Arrange
      final data = <String, Object?>{'ratio': 0.5};

      // 2. Act
      void action() => encodeFirestoreFields(data);

      // 3. Assert
      expect(action, throwsArgumentError);
    });
  });

  group('decodeFirestoreFields - Unit Test Suite', () {
    test('Happy Path: decoding undoes encoding', () {
      // 1. Arrange
      final data = <String, Object?>{
        'name': 'Acme',
        'active': false,
        'count': -7,
        'at': DateTime.utc(2026, 10, 20, 12, 30, 15),
        'colors': <String, Object?>{
          'primary': '#0ABAB5',
          'nested': <String, Object?>{'deep': true},
        },
      };
      final fields = jsonDecode(jsonEncode(encodeFirestoreFields(data))) as Map;

      // 2. Act
      final decoded = decodeFirestoreFields(fields);

      // 3. Assert
      expect(decoded, data);
    });

    test('Edge Case: a mapValue without fields is an empty map', () {
      // 1. Arrange
      final fields = {
        'colors': {'mapValue': <String, Object?>{}},
      };

      // 2. Act
      final decoded = decodeFirestoreFields(fields);

      // 3. Assert
      expect(decoded, {'colors': <String, Object?>{}});
    });

    test('Edge Case: no fields decode to an empty map', () {
      // 1. Arrange
      final fields = <String, Object?>{};

      // 2. Act
      final decoded = decodeFirestoreFields(fields);

      // 3. Assert
      expect(decoded, isEmpty);
    });

    test('Sad Path: unsupported or malformed values decode to null', () {
      // 1. Arrange
      final fields = {
        'ratio': {'doubleValue': 0.5},
        'count': {'integerValue': 'many'},
        'at': {'timestampValue': 'yesterday'},
        'name': {'stringValue': 42},
      };

      // 2. Act
      final decoded = decodeFirestoreFields(fields);

      // 3. Assert
      expect(decoded, {'ratio': null, 'count': null, 'at': null, 'name': null});
    });
  });

  group('HttpFirestoreDocuments.get - Unit Test Suite', () {
    test('Happy Path: returns the decoded fields of the document', () async {
      // 1. Arrange
      final requests = <http.Request>[];
      final documents = HttpFirestoreDocuments(
        client: answering(
          requests,
          body: {
            'name':
                'projects/monamienet-acme/databases/(default)/documents/'
                'config/branding',
            'fields': {
              'name': {'stringValue': 'Acme'},
            },
          },
        ),
      );

      // 2. Act
      final document = await documents.get(
        projectId: 'monamienet-acme',
        path: 'config/branding',
      );

      // 3. Assert
      expect(document, {'name': 'Acme'});
    });

    test('Happy Path: reads the document URL of the project', () async {
      // 1. Arrange
      final requests = <http.Request>[];
      final documents = HttpFirestoreDocuments(client: answering(requests));

      // 2. Act
      await documents.get(
        projectId: 'monamienet-acme',
        path: 'config/branding',
      );

      // 3. Assert
      expect(
        [requests.single.method, requests.single.url.toString()],
        ['GET', Uri.parse(documentUrl).toString()],
      );
    });

    test('Happy Path: sends the access token as a bearer token', () async {
      // 1. Arrange
      final requests = <http.Request>[];
      final documents = HttpFirestoreDocuments(client: answering(requests));

      // 2. Act
      await documents.get(
        projectId: 'monamienet-acme',
        path: 'config/branding',
        accessToken: 'token-123',
      );

      // 3. Assert
      expect(requests.single.headers['Authorization'], 'Bearer token-123');
    });

    test('Edge Case: without an access token the read is anonymous', () async {
      // 1. Arrange
      final requests = <http.Request>[];
      final documents = HttpFirestoreDocuments(client: answering(requests));

      // 2. Act
      await documents.get(
        projectId: 'monamienet-acme',
        path: 'config/branding',
      );

      // 3. Assert
      expect(requests.single.headers.containsKey('Authorization'), isFalse);
    });

    test('Edge Case: a document without fields is an empty map', () async {
      // 1. Arrange
      final documents = HttpFirestoreDocuments(
        client: answering([], body: {'name': 'projects/x/documents/y'}),
      );

      // 2. Act
      final document = await documents.get(
        projectId: 'monamienet-acme',
        path: 'config/branding',
      );

      // 3. Assert
      expect(document, isEmpty);
    });

    test('Edge Case: a missing document (404) is null', () async {
      // 1. Arrange
      final documents = HttpFirestoreDocuments(
        client: answering([], status: 404, body: {'error': {}}),
      );

      // 2. Act
      final document = await documents.get(
        projectId: 'monamienet-acme',
        path: 'config/branding',
      );

      // 3. Assert
      expect(document, isNull);
    });

    test('Sad Path: an error status throws a PartnerToolException', () async {
      // 1. Arrange
      final documents = HttpFirestoreDocuments(
        client: answering([], status: 403, body: {'error': {}}),
      );

      // 2. Act
      final reading = documents.get(
        projectId: 'monamienet-acme',
        path: 'config/branding',
      );

      // 3. Assert
      await expectLater(
        reading,
        throwsA(
          isA<PartnerToolException>().having(
            (e) => e.message,
            'message',
            allOf(contains('HTTP 403'), contains('monamienet-acme')),
          ),
        ),
      );
    });
  });

  group('HttpFirestoreDocuments.set - Unit Test Suite', () {
    test('Happy Path: patches the document with the encoded fields', () async {
      // 1. Arrange
      final requests = <http.Request>[];
      final documents = HttpFirestoreDocuments(client: answering(requests));
      final data = <String, Object?>{
        'name': 'Acme',
        'colors': <String, Object?>{'primary': '#0ABAB5'},
      };

      // 2. Act
      await documents.set(
        projectId: 'monamienet-acme',
        path: 'config/branding',
        data: data,
        accessToken: 'token-123',
      );

      // 3. Assert
      expect(jsonDecode(requests.single.body), {
        'fields': jsonDecode(jsonEncode(encodeFirestoreFields(data))),
      });
    });

    test(
      'Happy Path: sends PATCH to the document URL with the token',
      () async {
        // 1. Arrange
        final requests = <http.Request>[];
        final documents = HttpFirestoreDocuments(client: answering(requests));

        // 2. Act
        await documents.set(
          projectId: 'monamienet-acme',
          path: 'config/branding',
          data: {'name': 'Acme'},
          accessToken: 'token-123',
        );

        // 3. Assert
        final request = requests.single;
        expect(
          [
            request.method,
            request.url.toString(),
            request.headers['Authorization'],
          ],
          ['PATCH', Uri.parse(documentUrl).toString(), 'Bearer token-123'],
        );
      },
    );

    test('Edge Case: null values are not sent', () async {
      // 1. Arrange
      final requests = <http.Request>[];
      final documents = HttpFirestoreDocuments(client: answering(requests));

      // 2. Act
      await documents.set(
        projectId: 'monamienet-acme',
        path: 'config/branding',
        data: {'name': 'Acme', 'logoSvg': null},
        accessToken: 'token-123',
      );

      // 3. Assert
      final body = jsonDecode(requests.single.body) as Map;
      expect((body['fields'] as Map).keys, ['name']);
    });

    test('Sad Path: an error status throws a PartnerToolException', () async {
      // 1. Arrange
      final documents = HttpFirestoreDocuments(
        client: answering([], status: 500, body: {'error': {}}),
      );

      // 2. Act
      final writing = documents.set(
        projectId: 'monamienet-acme',
        path: 'config/branding',
        data: {'name': 'Acme'},
        accessToken: 'token-123',
      );

      // 3. Assert
      await expectLater(
        writing,
        throwsA(
          isA<PartnerToolException>().having(
            (e) => e.message,
            'message',
            allOf(contains('write'), contains('HTTP 500')),
          ),
        ),
      );
    });

    test('Sad Path: a missing document (404) on write throws', () async {
      // 1. Arrange
      final documents = HttpFirestoreDocuments(
        client: answering([], status: 404, body: {'error': {}}),
      );

      // 2. Act
      final writing = documents.set(
        projectId: 'monamienet-acme',
        path: 'config/branding',
        data: {'name': 'Acme'},
        accessToken: 'token-123',
      );

      // 3. Assert
      await expectLater(writing, throwsA(isA<PartnerToolException>()));
    });
  });
}
