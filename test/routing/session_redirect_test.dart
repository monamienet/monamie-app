import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/domain/models/organization/organization_config.dart';
import 'package:monamie_app/domain/models/organization/organization_binding.dart';
import 'package:monamie_app/ui/auth/view_models/session_state.dart';
import 'package:monamie_app/routing/session_redirect.dart';

/// Every session, by the name used in the test descriptions.
const _sessions = <String, SessionState>{
  'signedOut': SessionState.signedOut(),
  'noOrganization': SessionState.noOrganization(),
  'picking': SessionState.picking([]),
  'deletionPending': SessionState.deletionPending(),
  'welcome': SessionState.welcome(),
  'bound': SessionState.bound(),
};

/// The screen each session belongs on, written out (not derived from the
/// code under test).
const _home = <String, String>{
  'signedOut': '/login',
  'noOrganization': '/sem-organizacao',
  'picking': '/organization',
  'deletionPending': '/em-exclusao',
  'welcome': '/boas-vindas',
  'bound': '/monamie',
};

/// Each location asked for, with the sessions allowed to stay on it; every
/// other session is sent to its own screen.
const _allowed = <String, Set<String>>{
  // MonAmie's entry screens, each one for its own session only.
  '/login': {'signedOut'},
  '/login/': {'signedOut'},
  '/sem-organizacao': {'noOrganization'},
  '/sem-organizacao/': {'noOrganization'},
  '/organization': {'picking'},
  '/organization/': {'picking'},
  '/em-exclusao': {'deletionPending'},
  '/em-exclusao/': {'deletionPending'},
  '/boas-vindas': {'welcome'},
  '/boas-vindas/': {'welcome'},
  // *Criar organização*, only over the screen of the session.
  '/sem-organizacao/nova-organizacao': {'noOrganization'},
  '/sem-organizacao/nova-organizacao/': {'noOrganization'},
  '/organization/nova-organizacao': {'picking'},
  '/organization/nova-organizacao/': {'picking'},
  '/login/nova-organizacao': {},
  '/em-exclusao/nova-organizacao': {},
  '/boas-vindas/nova-organizacao': {},
  '/monamie/nova-organizacao': {},
  '/sem-organizacao/outra': {},
  '/organization/outra': {},
  // The organization's shell: the bound session only.
  '/monamie': {'bound'},
  '/monamie/': {'bound'},
  '/minha-conta': {'bound'},
  '/minha-conta/': {'bound'},
  '/admin/groups': {'bound'},
  '/admin/groups/': {'bound'},
  '/admin/groups/new': {'bound'},
  '/admin/groups/invite': {'bound'},
  '/admin/groups/Xk3pQ9vL2mN7': {'bound'},
  '/admin/administrators': {'bound'},
  '/admin/appearance': {'bound'},
  '/admin/tracking': {'bound'},
  '/admin/qualquer-coisa': {'bound'},
  '/admin/a/b/c': {'bound'},
  '/monamie/extra': {},
  '/minha-conta/extra': {},
  // The admin prefix alone is no screen.
  '/admin': {},
  '/admin/': {},
  // The root and unknown paths.
  '/': {},
  '/nao-existe': {},
  '/LOGIN': {},
  '/administrators': {},
};

void main() {
  group('sessionLocation - Unit Test Suite', () {
    for (final MapEntry(key: name, value: session) in _sessions.entries) {
      test('Happy Path: $name belongs on ${_home[name]}', () {
        // 1. Arrange
        final expected = _home[name];

        // 2. Act
        final location = sessionLocation(session);

        // 3. Assert
        expect(location, expected);
      });
    }
  });

  group('sessionRedirect - Unit Test Suite', () {
    for (final MapEntry(key: location, value: allowed) in _allowed.entries) {
      for (final MapEntry(key: name, value: session) in _sessions.entries) {
        final stays = allowed.contains(name);
        final expected = stays ? null : _home[name];
        final kind = location.length > 1 && location.endsWith('/')
            ? 'Edge Case'
            : stays
            ? 'Happy Path'
            : 'Sad Path';
        test('$kind: $name asking for "$location" '
            '${stays ? 'stays' : 'goes to $expected'}', () {
          // 1. Arrange
          final asked = location;

          // 2. Act
          final redirect = sessionRedirect(session, asked);

          // 3. Assert
          expect(redirect, expected);
        });
      }
    }

    /// A picker session with a choice to make (the table's has none).
    final pickingRotaSul = SessionState.picking([
      OrganizationBinding(
        organization: const OrganizationConfig(id: 'rotasul', name: 'Rota Sul'),
        options: const FirebaseOptions(
          apiKey: 'api-key',
          appId: '1:111:android:abc',
          projectId: 'monamienet-rotasul',
          messagingSenderId: '111',
        ),
      ),
    ]);

    test('Edge Case: picking with choices may open Criar organização over '
        'the picker', () {
      // 1. Arrange
      const asked = '/organization/nova-organizacao';

      // 2. Act
      final redirect = sessionRedirect(pickingRotaSul, asked);

      // 3. Assert
      expect(redirect, isNull);
    });

    test('Sad Path: picking with choices asking for the map goes to the '
        'picker', () {
      // 1. Arrange
      const asked = '/monamie';

      // 2. Act
      final redirect = sessionRedirect(pickingRotaSul, asked);

      // 3. Assert
      expect(redirect, '/organization');
    });
  });
}
