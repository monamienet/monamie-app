import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/config/partner/partner.dart';
import 'package:monamie_app/app/config/partner/partner_config.dart';
import 'package:monamie_app/app/data/firebase/current_partner_firebase.dart';
import 'package:monamie_app/app/data/firebase/partner_firebase.dart';
import 'package:monamie_app/app/data/partner/partner_binding.dart';
import 'package:monamie_app/app/data/partner/partner_binding_store.dart';
import 'package:monamie_app/app/data/partner/partner_session.dart';

import '../../support/test_partner.dart';

const options = FirebaseOptions(
  apiKey: 'api-key',
  appId: '1:111:android:abc',
  projectId: 'monamienet-acme',
  messagingSenderId: '111',
);

const storedAcme = PartnerBinding(
  partner: PartnerConfig(id: 'acme', name: 'Acme'),
  options: options,
);

/// In-memory [PartnerBindingStore] that records every call.
class InMemoryPartnerBindingStore implements PartnerBindingStore {
  InMemoryPartnerBindingStore([this.binding]);

  PartnerBinding? binding;
  final written = <PartnerBinding>[];
  int clearCount = 0;

  @override
  Future<PartnerBinding?> read() async => binding;

  @override
  Future<void> write(PartnerBinding binding) async {
    written.add(binding);
    this.binding = binding;
  }

  @override
  Future<void> clear() async {
    clearCount++;
    binding = null;
  }
}

/// [PartnerFirebase] that is only ever set and cleared, never used.
class UnusedPartnerFirebase implements PartnerFirebase {
  @override
  FirebaseAuth get auth => throw UnimplementedError();

  @override
  FirebaseFirestore get firestore => throw UnimplementedError();

  @override
  FirebaseFunctions get functions => throw UnimplementedError();
}

void main() {
  setUp(() {
    Partner.bind(testPartner);
    CurrentPartnerFirebase.set(UnusedPartnerFirebase());
  });

  tearDown(() {
    Partner.bind(testPartner);
    CurrentPartnerFirebase.debugReset();
  });

  group('PartnerSession.storeBranding - Unit Test Suite', () {
    test('Happy Path: stores the new branding of the stored partner', () async {
      // 1. Arrange
      final store = InMemoryPartnerBindingStore(storedAcme);
      final session = PartnerSession(store: store);
      const newer = PartnerConfig(
        id: 'acme',
        name: 'Acme Tours',
        logoSvg: '<svg/>',
      );

      // 2. Act
      await session.storeBranding(newer);

      // 3. Assert
      expect(
        [store.binding?.partner.name, store.binding?.partner.logoSvg],
        ['Acme Tours', '<svg/>'],
      );
    });

    test('Happy Path: keeps the stored Firebase options', () async {
      // 1. Arrange
      final store = InMemoryPartnerBindingStore(storedAcme);
      final session = PartnerSession(store: store);
      const newer = PartnerConfig(id: 'acme', name: 'Acme Tours');

      // 2. Act
      await session.storeBranding(newer);

      // 3. Assert
      expect(store.binding?.options, options);
    });

    test('Edge Case: does not change the running partner', () async {
      // 1. Arrange
      final store = InMemoryPartnerBindingStore(storedAcme);
      final session = PartnerSession(store: store);
      const newer = PartnerConfig(id: 'acme', name: 'Acme Tours');

      // 2. Act
      await session.storeBranding(newer);

      // 3. Assert
      expect(Partner.current, same(testPartner));
    });

    test('Edge Case: writes nothing when no binding is stored', () async {
      // 1. Arrange
      final store = InMemoryPartnerBindingStore();
      final session = PartnerSession(store: store);
      const newer = PartnerConfig(id: 'acme', name: 'Acme Tours');

      // 2. Act
      await session.storeBranding(newer);

      // 3. Assert
      expect(store.written, isEmpty);
    });

    test('Sad Path: ignores the branding of another partner', () async {
      // 1. Arrange
      final store = InMemoryPartnerBindingStore(storedAcme);
      final session = PartnerSession(store: store);
      const other = PartnerConfig(id: 'beta', name: 'Beta');

      // 2. Act
      await session.storeBranding(other);

      // 3. Assert
      expect([store.written, store.binding?.partner.id], [isEmpty, 'acme']);
    });
  });

  group('PartnerSession.forget - Unit Test Suite', () {
    test('Happy Path: clears the stored binding', () async {
      // 1. Arrange
      final store = InMemoryPartnerBindingStore(storedAcme);
      final session = PartnerSession(store: store);

      // 2. Act
      await session.forget();

      // 3. Assert
      expect([store.clearCount, store.binding], [1, null]);
    });

    test('Happy Path: unbinds Partner.current', () async {
      // 1. Arrange
      final session = PartnerSession(
        store: InMemoryPartnerBindingStore(storedAcme),
      );

      // 2. Act
      await session.forget();

      // 3. Assert
      expect([Partner.current, Partner.isBound], [null, false]);
    });

    test('Happy Path: clears CurrentPartnerFirebase', () async {
      // 1. Arrange
      final session = PartnerSession(
        store: InMemoryPartnerBindingStore(storedAcme),
      );

      // 2. Act
      await session.forget();

      // 3. Assert
      expect(CurrentPartnerFirebase.isSet, isFalse);
    });

    test(
      'Edge Case: forgetting with nothing bound or stored completes',
      () async {
        // 1. Arrange
        Partner.unbind();
        CurrentPartnerFirebase.clear();
        final session = PartnerSession(store: InMemoryPartnerBindingStore());

        // 2. Act
        final forgetting = session.forget();

        // 3. Assert
        await expectLater(forgetting, completes);
      },
    );

    test(
      'Sad Path: CurrentPartnerFirebase.instance throws after forget',
      () async {
        // 1. Arrange
        final session = PartnerSession(
          store: InMemoryPartnerBindingStore(storedAcme),
        );

        // 2. Act
        await session.forget();

        // 3. Assert
        expect(() => CurrentPartnerFirebase.instance, throwsStateError);
      },
    );
  });
}
