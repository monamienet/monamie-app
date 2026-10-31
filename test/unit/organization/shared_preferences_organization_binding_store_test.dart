import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/config/organization/organization_config.dart';
import 'package:monamie_app/app/data/organization/organization_binding.dart';
import 'package:monamie_app/app/data/organization/shared_preferences_organization_binding_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
// The platform interface is a transitive dependency of shared_preferences
// and provides its official in-memory backend for tests.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

const options = FirebaseOptions(
  apiKey: 'api-key',
  appId: '1:111:android:abc',
  projectId: 'monamienet-acme',
  messagingSenderId: '111',
  storageBucket: 'monamienet-acme.firebasestorage.app',
);

const binding = OrganizationBinding(
  organization: OrganizationConfig(id: 'acme', name: 'Acme', themeId: 'oceano'),
  options: options,
);

/// Stores [value] under the binding key, as another writer (or a corrupted
/// file) would.
Future<void> storeRaw(String value) => SharedPreferencesAsync().setString(
  organizationBindingPreferencesKey,
  value,
);

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('SharedPreferencesOrganizationBindingStore - Unit Test Suite', () {
    test('Happy Path: read returns the binding that was written', () async {
      // 1. Arrange
      final store = SharedPreferencesOrganizationBindingStore();
      await store.write(binding);

      // 2. Act
      final read = await store.read();

      // 3. Assert
      expect(
        [
          read?.organization.id,
          read?.organization.name,
          read?.organization.themeId,
          read?.options,
        ],
        ['acme', 'Acme', 'oceano', options],
      );
    });

    test(
      'Happy Path: write stores the binding JSON under the native key',
      () async {
        // 1. Arrange
        final store = SharedPreferencesOrganizationBindingStore();

        // 2. Act
        await store.write(binding);

        // 3. Assert
        final raw = await SharedPreferencesAsync().getString(
          organizationBindingPreferencesKey,
        );
        expect(jsonDecode(raw!), jsonDecode(jsonEncode(binding.toJson())));
      },
    );

    test(
      'Happy Path: a second store instance reads what the first wrote',
      () async {
        // 1. Arrange
        await SharedPreferencesOrganizationBindingStore().write(binding);
        final otherStore = SharedPreferencesOrganizationBindingStore();

        // 2. Act
        final read = await otherStore.read();

        // 3. Assert
        expect(read?.organization.id, 'acme');
      },
    );

    test('Happy Path: clear removes the stored binding', () async {
      // 1. Arrange
      final store = SharedPreferencesOrganizationBindingStore();
      await store.write(binding);

      // 2. Act
      await store.clear();

      // 3. Assert
      expect(await store.read(), isNull);
    });

    test('Edge Case: read with nothing stored returns null', () async {
      // 1. Arrange
      final store = SharedPreferencesOrganizationBindingStore();

      // 2. Act
      final read = await store.read();

      // 3. Assert
      expect(read, isNull);
    });

    test('Edge Case: clear with nothing stored completes', () async {
      // 1. Arrange
      final store = SharedPreferencesOrganizationBindingStore();

      // 2. Act
      final clearing = store.clear();

      // 3. Assert
      await expectLater(clearing, completes);
    });

    test('Edge Case: a second write replaces the first binding', () async {
      // 1. Arrange
      final store = SharedPreferencesOrganizationBindingStore();
      await store.write(binding);
      const other = OrganizationBinding(
        organization: OrganizationConfig(id: 'beta', name: 'Beta'),
        options: options,
      );

      // 2. Act
      await store.write(other);

      // 3. Assert
      expect((await store.read())?.organization.id, 'beta');
    });

    test('Sad Path: unreadable JSON is read as null', () async {
      // 1. Arrange
      await storeRaw('{not json');
      final store = SharedPreferencesOrganizationBindingStore();

      // 2. Act
      final read = await store.read();

      // 3. Assert
      expect(read, isNull);
    });

    test('Sad Path: JSON without options is read as null', () async {
      // 1. Arrange
      await storeRaw(jsonEncode({'id': 'acme'}));
      final store = SharedPreferencesOrganizationBindingStore();

      // 2. Act
      final read = await store.read();

      // 3. Assert
      expect(read, isNull);
    });

    test(
      'Sad Path: a stored invalid organization id is read as null',
      () async {
        // 1. Arrange
        final json = binding.toJson()..['id'] = 'App';
        await storeRaw(jsonEncode(json));
        final store = SharedPreferencesOrganizationBindingStore();

        // 2. Act
        final read = await store.read();

        // 3. Assert
        expect(read, isNull);
      },
    );

    test(
      'Sad Path: a JSON value that is not an object is read as null',
      () async {
        // 1. Arrange
        await storeRaw('"acme"');
        final store = SharedPreferencesOrganizationBindingStore();

        // 2. Act
        final read = await store.read();

        // 3. Assert
        expect(read, isNull);
      },
    );
  });
}
