import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/data/repositories/session/session_repository.dart';
import 'package:monamie_app/domain/models/group.dart';
import 'package:monamie_app/domain/models/invite.dart';
import 'package:monamie_app/ui/invites/view_models/welcome_view_model.dart';

import '../../../support/session_double.dart';

final _kInvite = Invite(
  id: 'inv1',
  organizationId: 'rotasul',
  organizationName: 'Rota Sul',
  groupId: '01',
  groupName: 'Equipe Norte',
  email: 'ana.souza@monamie.net',
  roles: const {GroupRole.publisher},
  inviterName: 'Rita Lima',
  expiresAt: DateTime.utc(2026, 11, 9, 12),
);

void main() {
  group('WelcomeViewModel.invite - Unit Test Suite', () {
    test('Happy Path: opens with the invite of the welcome session', () {
      // 1. Arrange
      final session = SessionDouble(initial: SessionState.welcome(_kInvite));

      // 2. Act
      final controller = WelcomeViewModel(session: session.repository);

      // 3. Assert
      expect(controller.invite, _kInvite);
    });

    test('Edge Case: the invite is read once, when the screen opens', () {
      // 1. Arrange
      final session = SessionDouble(initial: SessionState.welcome(_kInvite));
      final controller = WelcomeViewModel(session: session.repository);

      // 2. Act
      session.session.value = const SessionState.bound();

      // 3. Assert
      expect(controller.invite, _kInvite);
    });

    test('Sad Path: a session that already moved on gives no invite', () {
      // 1. Arrange
      final session = SessionDouble(initial: const SessionState.bound());

      // 2. Act
      final controller = WelcomeViewModel(session: session.repository);

      // 3. Assert
      expect(controller.invite, isNull);
    });
  });

  group('WelcomeViewModel.finishWelcome - Unit Test Suite', () {
    test('Happy Path: closing the welcome ends bound', () {
      // 1. Arrange
      final session = SessionDouble(initial: SessionState.welcome(_kInvite));
      final controller = WelcomeViewModel(session: session.repository);

      // 2. Act
      controller.finishWelcome();

      // 3. Assert
      expect(session.moves, [const SessionState.bound()]);
    });

    test('Sad Path: with no welcome pending it still ends bound', () {
      // 1. Arrange
      final session = SessionDouble();
      final controller = WelcomeViewModel(session: session.repository);

      // 2. Act
      controller.finishWelcome();

      // 3. Assert
      expect(session.session.value, const SessionState.bound());
    });
  });
}
