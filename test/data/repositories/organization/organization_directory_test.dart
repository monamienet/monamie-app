import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/data/repositories/organization/organization_directory.dart';

@GenerateNiceMocks([MockSpec<OrganizationDirectory>()])
import 'organization_directory_test.mocks.dart';

const _kOptions = FirebaseOptions(
  apiKey: 'api-key',
  appId: '1:111:android:abc',
  projectId: 'monamienet-rotasul',
  messagingSenderId: '111',
);

const _kRotaSul = OrganizationCandidate(id: 'rotasul', options: _kOptions);

const _kVerdeMar = OrganizationCandidate(id: 'verdemar', options: _kOptions);

/// A [MockOrganizationDirectory] answering [organizations].
MockOrganizationDirectory _directory(
  List<OrganizationCandidate> organizations,
) {
  final directory = MockOrganizationDirectory();
  when(
    directory.organizationsOfSignedInUser(),
  ).thenAnswer((_) async => organizations);
  return directory;
}

void main() {
  group('OrganizationOwnership.ownsOrganization - Unit Test Suite', () {
    test('Happy Path: true when the directory marks the organization as the '
        "user's", () async {
      // 1. Arrange
      final directory = _directory(const [
        OrganizationCandidate(id: 'rotasul', options: _kOptions, owner: true),
      ]);

      // 2. Act
      final owns = await directory.ownsOrganization('rotasul');

      // 3. Assert
      expect(owns, isTrue);
    });

    test('Edge Case: false when the user is only a member', () async {
      // 1. Arrange
      final directory = _directory(const [_kRotaSul, _kVerdeMar]);

      // 2. Act
      final owns = await directory.ownsOrganization('rotasul');

      // 3. Assert
      expect(owns, isFalse);
    });

    test('Edge Case: false when the user owns another organization', () async {
      // 1. Arrange
      final directory = _directory(const [
        _kRotaSul,
        OrganizationCandidate(id: 'verdemar', options: _kOptions, owner: true),
      ]);

      // 2. Act
      final owns = await directory.ownsOrganization('rotasul');

      // 3. Assert
      expect(owns, isFalse);
    });

    test('Sad Path: false when the organization is not listed', () async {
      // 1. Arrange
      final directory = _directory(const [_kVerdeMar]);

      // 2. Act
      final owns = await directory.ownsOrganization('rotasul');

      // 3. Assert
      expect(owns, isFalse);
    });

    test('Sad Path: a failing directory throws instead of answering '
        'false', () async {
      // 1. Arrange
      final directory = MockOrganizationDirectory();
      when(
        directory.organizationsOfSignedInUser(),
      ).thenAnswer((_) async => throw StateError('offline'));

      // 2. Act
      final owns = directory.ownsOrganization('rotasul');

      // 3. Assert
      await expectLater(owns, throwsStateError);
    });
  });
}
