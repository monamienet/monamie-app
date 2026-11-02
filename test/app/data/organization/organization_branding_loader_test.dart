import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/data/organization/organization_branding_loader.dart';

const withBucket = FirebaseOptions(
  apiKey: 'api-key',
  appId: '1:111:android:abc',
  projectId: 'monamienet-rotasul',
  messagingSenderId: '111',
  storageBucket: 'custom-bucket.appspot.com',
);

const withoutBucket = FirebaseOptions(
  apiKey: 'api-key',
  appId: '1:111:android:abc',
  projectId: 'monamienet-rotasul',
  messagingSenderId: '111',
);

void main() {
  group('organizationLogoUri - Unit Test Suite', () {
    test('Happy Path: points at the logo in the project bucket', () {
      // 1. Arrange
      const options = withBucket;

      // 2. Act
      final uri = organizationLogoUri(options, 'rotasul', 42);

      // 3. Assert
      expect(
        uri.toString(),
        'https://firebasestorage.googleapis.com/v0/b/custom-bucket.appspot.com'
        '/o/organizations%2Frotasul%2Flogo.png?alt=media&v=42',
      );
    });

    test('Edge Case: without storageBucket uses '
        '<projectId>.firebasestorage.app', () {
      // 1. Arrange
      const options = withoutBucket;

      // 2. Act
      final uri = organizationLogoUri(options, 'rotasul', 1700000000000);

      // 3. Assert
      expect(
        uri.toString(),
        'https://firebasestorage.googleapis.com/v0/b/'
        'monamienet-rotasul.firebasestorage.app'
        '/o/organizations%2Frotasul%2Flogo.png?alt=media&v=1700000000000',
      );
    });

    test('Sad Path: another version gives another URL, so caches miss', () {
      // 1. Arrange
      final first = organizationLogoUri(withBucket, 'rotasul', 1);

      // 2. Act
      final second = organizationLogoUri(withBucket, 'rotasul', 2);

      // 3. Assert
      expect(second, isNot(first));
    });
  });

  group('organizationLogoPath - Unit Test Suite', () {
    test('Happy Path: the logo lives under the organization', () {
      // 1. Arrange
      const id = 'rotasul';

      // 2. Act
      final path = organizationLogoPath(id);

      // 3. Assert
      expect(path, 'organizations/rotasul/logo.png');
    });
  });
}
