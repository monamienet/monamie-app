import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/config/organization/organization.dart';
import 'package:monamie_app/app/config/organization/organization_config.dart';
import 'package:monamie_app/app/data/firebase/current_organization_firebase.dart';
import 'package:monamie_app/app/data/firebase/organization_firebase.dart';
import 'package:monamie_app/app/data/organization/organization_binding.dart';
import 'package:monamie_app/app/data/organization/organization_binding_store.dart';
import 'package:monamie_app/app/data/organization/organization_session.dart';

import '../../support/test_organization.dart';

const options = FirebaseOptions(
  apiKey: 'api-key',
  appId: '1:111:android:abc',
  projectId: 'monamienet-acme',
  messagingSenderId: '111',
);

const storedAcme = OrganizationBinding(
  organization: OrganizationConfig(id: 'acme', name: 'Acme'),
  options: options,
);

/// In-memory [OrganizationBindingStore] that records every call.
class InMemoryOrganizationBindingStore implements OrganizationBindingStore {
  InMemoryOrganizationBindingStore([this.binding]);

  OrganizationBinding? binding;
  final written = <OrganizationBinding>[];
  int clearCount = 0;

  @override
  Future<OrganizationBinding?> read() async => binding;

  @override
  Future<void> write(OrganizationBinding binding) async {
    written.add(binding);
    this.binding = binding;
  }

  @override
  Future<void> clear() async {
    clearCount++;
    binding = null;
  }
}

/// [OrganizationFirebase] that is only ever set and cleared, never used.
class UnusedOrganizationFirebase implements OrganizationFirebase {
  @override
  FirebaseAuth get auth => throw UnimplementedError();

  @override
  FirebaseFirestore get firestore => throw UnimplementedError();

  @override
  FirebaseFunctions get functions => throw UnimplementedError();

  @override
  FirebaseStorage get storage => throw UnimplementedError();

  @override
  DocumentReference<Map<String, dynamic>> get organizationData =>
      throw UnimplementedError();
}

void main() {
  setUp(() {
    Organization.bind(testOrganization);
    CurrentOrganizationFirebase.set(UnusedOrganizationFirebase());
  });

  tearDown(() {
    Organization.bind(testOrganization);
    CurrentOrganizationFirebase.debugReset();
  });

  group('OrganizationSession.storeBranding - Unit Test Suite', () {
    test(
      'Happy Path: stores the new branding of the stored organization',
      () async {
        // 1. Arrange
        final store = InMemoryOrganizationBindingStore(storedAcme);
        final session = OrganizationSession(store: store);
        const newer = OrganizationConfig(
          id: 'acme',
          name: 'Acme Tours',
          themeId: 'oceano',
        );

        // 2. Act
        await session.storeBranding(newer);

        // 3. Assert
        expect(
          [
            store.binding?.organization.name,
            store.binding?.organization.themeId,
          ],
          ['Acme Tours', 'oceano'],
        );
      },
    );

    test('Happy Path: keeps the stored Firebase options', () async {
      // 1. Arrange
      final store = InMemoryOrganizationBindingStore(storedAcme);
      final session = OrganizationSession(store: store);
      const newer = OrganizationConfig(id: 'acme', name: 'Acme Tours');

      // 2. Act
      await session.storeBranding(newer);

      // 3. Assert
      expect(store.binding?.options, options);
    });

    test('Edge Case: does not change the running organization', () async {
      // 1. Arrange
      final store = InMemoryOrganizationBindingStore(storedAcme);
      final session = OrganizationSession(store: store);
      const newer = OrganizationConfig(id: 'acme', name: 'Acme Tours');

      // 2. Act
      await session.storeBranding(newer);

      // 3. Assert
      expect(Organization.current, same(testOrganization));
    });

    test('Edge Case: writes nothing when no binding is stored', () async {
      // 1. Arrange
      final store = InMemoryOrganizationBindingStore();
      final session = OrganizationSession(store: store);
      const newer = OrganizationConfig(id: 'acme', name: 'Acme Tours');

      // 2. Act
      await session.storeBranding(newer);

      // 3. Assert
      expect(store.written, isEmpty);
    });

    test('Sad Path: ignores the branding of another organization', () async {
      // 1. Arrange
      final store = InMemoryOrganizationBindingStore(storedAcme);
      final session = OrganizationSession(store: store);
      const other = OrganizationConfig(id: 'beta', name: 'Beta');

      // 2. Act
      await session.storeBranding(other);

      // 3. Assert
      expect(
        [store.written, store.binding?.organization.id],
        [isEmpty, 'acme'],
      );
    });
  });

  group('OrganizationSession.forget - Unit Test Suite', () {
    test('Happy Path: clears the stored binding', () async {
      // 1. Arrange
      final store = InMemoryOrganizationBindingStore(storedAcme);
      final session = OrganizationSession(store: store);

      // 2. Act
      await session.forget();

      // 3. Assert
      expect([store.clearCount, store.binding], [1, null]);
    });

    test('Happy Path: unbinds Organization.current', () async {
      // 1. Arrange
      final session = OrganizationSession(
        store: InMemoryOrganizationBindingStore(storedAcme),
      );

      // 2. Act
      await session.forget();

      // 3. Assert
      expect([Organization.current, Organization.isBound], [null, false]);
    });

    test('Happy Path: clears CurrentOrganizationFirebase', () async {
      // 1. Arrange
      final session = OrganizationSession(
        store: InMemoryOrganizationBindingStore(storedAcme),
      );

      // 2. Act
      await session.forget();

      // 3. Assert
      expect(CurrentOrganizationFirebase.isSet, isFalse);
    });

    test(
      'Edge Case: forgetting with nothing bound or stored completes',
      () async {
        // 1. Arrange
        Organization.unbind();
        CurrentOrganizationFirebase.clear();
        final session = OrganizationSession(
          store: InMemoryOrganizationBindingStore(),
        );

        // 2. Act
        final forgetting = session.forget();

        // 3. Assert
        await expectLater(forgetting, completes);
      },
    );

    test(
      'Sad Path: CurrentOrganizationFirebase.instance throws after forget',
      () async {
        // 1. Arrange
        final session = OrganizationSession(
          store: InMemoryOrganizationBindingStore(storedAcme),
        );

        // 2. Act
        await session.forget();

        // 3. Assert
        expect(() => CurrentOrganizationFirebase.instance, throwsStateError);
      },
    );
  });
}
