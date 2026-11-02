import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/app/config/organization/organization.dart';
import 'package:monamie_app/app/config/organization/organization_config.dart';
import 'package:monamie_app/app/data/firebase/current_organization_firebase.dart';
import 'package:monamie_app/app/data/firebase/organization_firebase.dart';
import 'package:monamie_app/app/data/organization/organization_binding.dart';
import 'package:monamie_app/app/data/organization/organization_binding_store.dart';
import 'package:monamie_app/app/data/organization/organization_session.dart';

import '../../../support/test_organization.dart';

@GenerateNiceMocks([
  MockSpec<OrganizationBindingStore>(),
  MockSpec<OrganizationFirebase>(),
])
import 'organization_session_test.mocks.dart';

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

/// A [MockOrganizationBindingStore] holding [binding].
MockOrganizationBindingStore mockStore([OrganizationBinding? binding]) {
  final store = MockOrganizationBindingStore();
  when(store.read()).thenAnswer((_) async => binding);
  return store;
}

/// The binding written to [store], verifying it was written exactly once.
OrganizationBinding writtenTo(MockOrganizationBindingStore store) =>
    verify(store.write(captureAny)).captured.single as OrganizationBinding;

void main() {
  setUp(() {
    Organization.bind(testOrganization);
    CurrentOrganizationFirebase.set(MockOrganizationFirebase());
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
        final store = mockStore(storedAcme);
        final session = OrganizationSession(store: store);
        const newer = OrganizationConfig(
          id: 'acme',
          name: 'Acme Tours',
          themeId: 'oceano',
        );

        // 2. Act
        await session.storeBranding(newer);

        // 3. Assert
        final written = writtenTo(store);
        expect(
          [written.organization.name, written.organization.themeId],
          ['Acme Tours', 'oceano'],
        );
      },
    );

    test('Happy Path: keeps the stored Firebase options', () async {
      // 1. Arrange
      final store = mockStore(storedAcme);
      final session = OrganizationSession(store: store);
      const newer = OrganizationConfig(id: 'acme', name: 'Acme Tours');

      // 2. Act
      await session.storeBranding(newer);

      // 3. Assert
      expect(writtenTo(store).options, options);
    });

    test('Edge Case: does not change the running organization', () async {
      // 1. Arrange
      final store = mockStore(storedAcme);
      final session = OrganizationSession(store: store);
      const newer = OrganizationConfig(id: 'acme', name: 'Acme Tours');

      // 2. Act
      await session.storeBranding(newer);

      // 3. Assert
      expect(Organization.current, same(testOrganization));
    });

    test('Edge Case: writes nothing when no binding is stored', () async {
      // 1. Arrange
      final store = mockStore();
      final session = OrganizationSession(store: store);
      const newer = OrganizationConfig(id: 'acme', name: 'Acme Tours');

      // 2. Act
      await session.storeBranding(newer);

      // 3. Assert
      verifyNever(store.write(any));
    });

    test('Sad Path: ignores the branding of another organization', () async {
      // 1. Arrange
      final store = mockStore(storedAcme);
      final session = OrganizationSession(store: store);
      const other = OrganizationConfig(id: 'beta', name: 'Beta');

      // 2. Act
      await session.storeBranding(other);

      // 3. Assert
      verifyNever(store.write(any));
      verifyNever(store.clear());
    });
  });

  group('OrganizationSession.forget - Unit Test Suite', () {
    test('Happy Path: clears the stored binding', () async {
      // 1. Arrange
      final store = mockStore(storedAcme);
      final session = OrganizationSession(store: store);

      // 2. Act
      await session.forget();

      // 3. Assert
      verify(store.clear()).called(1);
    });

    test('Happy Path: unbinds Organization.current', () async {
      // 1. Arrange
      final session = OrganizationSession(store: mockStore(storedAcme));

      // 2. Act
      await session.forget();

      // 3. Assert
      expect([Organization.current, Organization.isBound], [null, false]);
    });

    test('Happy Path: clears CurrentOrganizationFirebase', () async {
      // 1. Arrange
      final session = OrganizationSession(store: mockStore(storedAcme));

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
        final session = OrganizationSession(store: mockStore());

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
        final session = OrganizationSession(store: mockStore(storedAcme));

        // 2. Act
        await session.forget();

        // 3. Assert
        expect(() => CurrentOrganizationFirebase.instance, throwsStateError);
      },
    );
  });
}
