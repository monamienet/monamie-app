import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/data/model/user_google_model.dart';
import 'package:monamie_app/data/repositories/session/session_repository.dart';
import 'package:monamie_app/data/repositories/session/session_repository_google.dart';
import 'package:monamie_app/data/services/auth/auth_google_service.dart';

@GenerateNiceMocks([MockSpec<AuthGoogleService>()])
import 'session_repository_google_test.mocks.dart';

const _kIdToken = 'google-id-token';

const _kCentralEmail = 'ana.souza@monamie.net';

/// A JWT-shaped token whose `exp` is [fromNow] from the real clock (the
/// repository reads `DateTime.now()`); the signature is not checked.
String _jwtExpiringIn(Duration fromNow) {
  String part(Map<String, Object?> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  final exp = DateTime.now().add(fromNow).millisecondsSinceEpoch ~/ 1000;
  return '${part({'alg': 'none'})}.${part({'exp': exp})}.sig';
}

/// The `onAccountChosen` callback passed to `signInGoogle`.
void Function()? _onAccountChosen(Invocation invocation) =>
    invocation.namedArguments[#onAccountChosen] as void Function()?;

/// A [MockAuthGoogleService] whose `signInGoogle` calls `onAccountChosen`
/// and answers [idToken] (or fails with [signInError]), whose
/// `refreshGoogleIdToken` answers [refreshedToken], whose central e-mail is
/// [_kCentralEmail] and whose `logoutGoogle` fails with [logoutError].
MockAuthGoogleService _auth({
  String? idToken = _kIdToken,
  String? refreshedToken = 'refreshed-token',
  Object? signInError,
  Object? logoutError,
}) {
  final auth = MockAuthGoogleService();
  when(
    auth.signInGoogle(onAccountChosen: anyNamed('onAccountChosen')),
  ).thenAnswer((invocation) async {
    _onAccountChosen(invocation)?.call();
    if (signInError != null) throw signInError;
    return idToken;
  });
  when(auth.refreshGoogleIdToken()).thenAnswer((_) async => refreshedToken);
  when(auth.centralEmail()).thenAnswer((_) async => _kCentralEmail);
  when(auth.logoutGoogle()).thenAnswer((_) async {
    if (logoutError != null) throw logoutError;
  });
  return auth;
}

void main() {
  group('SessionRepositoryGoogle.start - Unit Test Suite', () {
    test(
      'Happy Path: start initializes Google and then marks it ready',
      () async {
        // 1. Arrange
        final auth = _auth();
        when(auth.ensureInitialized()).thenAnswer((_) async {});
        final session = SessionRepositoryGoogle(auth: auth);

        // 2. Act
        session.start();
        await pumpEventQueue();

        // 3. Assert
        expect(session.googleReady.value, isTrue);
        verify(auth.ensureInitialized()).called(1);
      },
    );

    test('Edge Case: Google is not ready before start', () {
      // 1. Arrange
      final auth = _auth();

      // 2. Act
      final session = SessionRepositoryGoogle(auth: auth);

      // 3. Assert
      expect(session.googleReady.value, isFalse);
      verifyNever(auth.ensureInitialized());
    });

    test('Edge Case: a second start does nothing', () async {
      // 1. Arrange
      final auth = _auth();
      when(auth.ensureInitialized()).thenAnswer((_) async {});
      final session = SessionRepositoryGoogle(auth: auth);

      // 2. Act
      session
        ..start()
        ..start();
      await pumpEventQueue();

      // 3. Assert
      verify(auth.ensureInitialized()).called(1);
    });

    test(
      'Sad Path: a failing initialization still marks Google ready',
      () async {
        // 1. Arrange
        final auth = _auth();
        when(
          auth.ensureInitialized(),
        ).thenAnswer((_) async => throw StateError('no Play services'));
        final session = SessionRepositoryGoogle(auth: auth);

        // 2. Act
        session.start();
        await pumpEventQueue();

        // 3. Assert
        expect(session.googleReady.value, isTrue);
      },
    );
  });

  group('SessionRepositoryGoogle.dispose - Unit Test Suite', () {
    test('Happy Path: dispose stops the notifiers', () {
      // 1. Arrange
      final session = SessionRepositoryGoogle(auth: _auth());

      // 2. Act
      session.dispose();

      // 3. Assert
      expect(() => session.session.addListener(() {}), throwsFlutterError);
    });

    test('Edge Case: dispose without start never touches the Google '
        'service', () {
      // 1. Arrange
      final auth = MockAuthGoogleService();
      final session = SessionRepositoryGoogle(auth: auth);

      // 2. Act
      session.dispose();

      // 3. Assert
      verifyZeroInteractions(auth);
    });

    test('Sad Path: an initialization finishing after dispose does not '
        'throw', () async {
      // 1. Arrange
      final auth = _auth();
      final init = Completer<void>();
      when(auth.ensureInitialized()).thenAnswer((_) => init.future);
      final session = SessionRepositoryGoogle(auth: auth)..start();
      session.dispose();

      // 2. Act
      init.complete();
      await pumpEventQueue();

      // 3. Assert
      verify(auth.ensureInitialized()).called(1);
    });

    test('Sad Path: moving or leaving after dispose does not throw', () {
      // 1. Arrange
      final session = SessionRepositoryGoogle(auth: _auth())..dispose();

      // 2. Act
      void act() => session
        ..moveTo(const SessionState.bound())
        ..setLeaving(SessionExit.signOut);

      // 3. Assert
      expect(act, returnsNormally);
    });
  });

  group('SessionRepositoryGoogle.moveTo - Unit Test Suite', () {
    test('Happy Path: a new session notifies the session listeners once', () {
      // 1. Arrange
      final session = SessionRepositoryGoogle(auth: _auth());
      var notifications = 0;
      session.session.addListener(() => notifications++);

      // 2. Act
      session.moveTo(const SessionState.bound());

      // 3. Assert
      expect(notifications, 1);
      expect(session.session.value, const SessionState.bound());
    });

    test('Edge Case: the session starts signed out', () {
      // 1. Arrange
      // 2. Act
      final session = SessionRepositoryGoogle(auth: _auth());

      // 3. Assert
      expect(session.session.value, const SessionState.signedOut());
      expect(session.leaving.value, isNull);
    });

    test('Edge Case: the same session again does not notify', () {
      // 1. Arrange
      final session = SessionRepositoryGoogle(auth: _auth())
        ..moveTo(const SessionState.bound());
      var notifications = 0;
      session.session.addListener(() => notifications++);

      // 2. Act
      session.moveTo(const SessionState.bound());

      // 3. Assert
      expect(notifications, 0);
    });

    test('Sad Path: an equal session with the same data does not notify', () {
      // 1. Arrange
      final session = SessionRepositoryGoogle(auth: _auth())
        ..moveTo(const SessionState.noOrganization(reason: 'Saiu.'));
      var notifications = 0;
      session.session.addListener(() => notifications++);

      // 2. Act
      session.moveTo(const SessionState.noOrganization(reason: 'Saiu.'));

      // 3. Assert
      expect(notifications, 0);
    });
  });

  group('SessionRepositoryGoogle.setLeaving - Unit Test Suite', () {
    test('Happy Path: leaving is set and cleared', () {
      // 1. Arrange
      final session = SessionRepositoryGoogle(auth: _auth());
      final seen = <SessionExit?>[];
      session.leaving.addListener(() => seen.add(session.leaving.value));

      // 2. Act
      session
        ..setLeaving(SessionExit.switchOrganization)
        ..setLeaving(null);

      // 3. Assert
      expect(seen, [SessionExit.switchOrganization, null]);
    });

    test('Edge Case: the same exit again does not notify', () {
      // 1. Arrange
      final session = SessionRepositoryGoogle(auth: _auth())
        ..setLeaving(SessionExit.signOut);
      var notifications = 0;
      session.leaving.addListener(() => notifications++);

      // 2. Act
      session.setLeaving(SessionExit.signOut);

      // 3. Assert
      expect(notifications, 0);
    });

    test('Sad Path: leaving does not move the session', () {
      // 1. Arrange
      final session = SessionRepositoryGoogle(auth: _auth());
      var notifications = 0;
      session.session.addListener(() => notifications++);

      // 2. Act
      session.setLeaving(SessionExit.signOut);

      // 3. Assert
      expect(notifications, 0);
      expect(session.session.value, const SessionState.signedOut());
    });
  });

  group('SessionRepositoryGoogle.webSignIns - Unit Test Suite', () {
    test("Happy Path: forwards the service's web sign-ins", () async {
      // 1. Arrange
      final auth = _auth();
      when(
        auth.onWebSignIn,
      ).thenAnswer((_) => Stream<String?>.fromIterable([_kIdToken, null]));
      final session = SessionRepositoryGoogle(auth: auth);

      // 2. Act
      final tokens = await session.webSignIns.toList();

      // 3. Assert
      expect(tokens, [_kIdToken, null]);
    });
  });

  group('SessionRepositoryGoogle.signInGoogle - Unit Test Suite', () {
    test('Happy Path: returns and keeps the Google ID token', () async {
      // 1. Arrange
      final session = SessionRepositoryGoogle(auth: _auth());

      // 2. Act
      final token = await session.signInGoogle();

      // 3. Assert
      expect(token, _kIdToken);
      expect(session.idToken, _kIdToken);
    });

    test(
      'Happy Path: calls onAccountChosen once an account is chosen',
      () async {
        // 1. Arrange
        final session = SessionRepositoryGoogle(auth: _auth());
        var chosen = 0;

        // 2. Act
        await session.signInGoogle(onAccountChosen: () => chosen++);

        // 3. Assert
        expect(chosen, 1);
      },
    );

    test('Edge Case: a sign-in with no token (the web) keeps the previous '
        'token', () async {
      // 1. Arrange
      final session = SessionRepositoryGoogle(auth: _auth(idToken: null))
        ..keepIdToken('earlier');

      // 2. Act
      final token = await session.signInGoogle();

      // 3. Assert
      expect(token, isNull);
      expect(session.idToken, 'earlier');
    });

    test('Sad Path: a failing sign-in throws and keeps nothing', () async {
      // 1. Arrange
      final session = SessionRepositoryGoogle(
        auth: _auth(signInError: Exception('cancelled')),
      );

      // 2. Act
      final signIn = session.signInGoogle();

      // 3. Assert
      await expectLater(signIn, throwsException);
      expect(session.idToken, isNull);
    });
  });

  group('SessionRepositoryGoogle.keptOrSignIn - Unit Test Suite', () {
    test('Happy Path: reuses the kept token without asking Google', () async {
      // 1. Arrange
      final auth = _auth();
      final session = SessionRepositoryGoogle(auth: auth)..keepIdToken('kept');

      // 2. Act
      final token = await session.keptOrSignIn();

      // 3. Assert
      expect(token, 'kept');
      verifyNever(
        auth.signInGoogle(onAccountChosen: anyNamed('onAccountChosen')),
      );
    });

    test('Edge Case: with no kept token it signs in with Google', () async {
      // 1. Arrange
      final auth = _auth();
      final session = SessionRepositoryGoogle(auth: auth);

      // 2. Act
      final token = await session.keptOrSignIn();

      // 3. Assert
      expect(token, _kIdToken);
      expect(session.idToken, _kIdToken);
      verify(
        auth.signInGoogle(onAccountChosen: anyNamed('onAccountChosen')),
      ).called(1);
    });

    test('Sad Path: a sign-in with no token answers null', () async {
      // 1. Arrange
      final session = SessionRepositoryGoogle(auth: _auth(idToken: null));

      // 2. Act
      final token = await session.keptOrSignIn();

      // 3. Assert
      expect(token, isNull);
    });
  });

  group('SessionRepositoryGoogle.freshIdToken - Unit Test Suite', () {
    test('Happy Path: uses the kept token, without asking Google, while it '
        'is valid', () async {
      // 1. Arrange
      final auth = _auth();
      final kept = _jwtExpiringIn(const Duration(hours: 1));
      final session = SessionRepositoryGoogle(auth: auth)..keepIdToken(kept);

      // 2. Act
      final token = await session.freshIdToken();

      // 3. Assert
      expect(token, kept);
      verifyNever(auth.refreshGoogleIdToken());
    });

    test('Edge Case: asks for a new token when the kept one is not a valid '
        'JWT, without keeping it', () async {
      // 1. Arrange
      final auth = _auth();
      final session = SessionRepositoryGoogle(auth: auth)
        ..keepIdToken(_kIdToken);

      // 2. Act
      final token = await session.freshIdToken();

      // 3. Assert
      expect(token, 'refreshed-token');
      expect(session.idToken, _kIdToken);
      verify(auth.refreshGoogleIdToken()).called(1);
    });

    test('Edge Case: asks for a new token when the kept one expired', () async {
      // 1. Arrange
      final auth = _auth();
      final session = SessionRepositoryGoogle(auth: auth)
        ..keepIdToken(_jwtExpiringIn(const Duration(hours: -1)));

      // 2. Act
      final token = await session.freshIdToken();

      // 3. Assert
      expect(token, 'refreshed-token');
      verify(auth.refreshGoogleIdToken()).called(1);
    });

    test('Edge Case: asks for a new token when none is kept', () async {
      // 1. Arrange
      final auth = _auth();
      final session = SessionRepositoryGoogle(auth: auth);

      // 2. Act
      final token = await session.freshIdToken();

      // 3. Assert
      expect(token, 'refreshed-token');
    });

    test('Sad Path: answers null when Google gives no new token', () async {
      // 1. Arrange
      final session = SessionRepositoryGoogle(
        auth: _auth(refreshedToken: null),
      );

      // 2. Act
      final token = await session.freshIdToken();

      // 3. Assert
      expect(token, isNull);
    });
  });

  group('SessionRepositoryGoogle.readSignedInEmail - Unit Test Suite', () {
    test('Happy Path: keeps the e-mail of the central account', () async {
      // 1. Arrange
      final session = SessionRepositoryGoogle(auth: _auth());

      // 2. Act
      await session.readSignedInEmail();

      // 3. Assert
      expect(session.signedInEmail, _kCentralEmail);
    });

    test('Edge Case: no e-mail before it is read', () {
      // 1. Arrange
      // 2. Act
      final session = SessionRepositoryGoogle(auth: _auth());

      // 3. Assert
      expect(session.signedInEmail, isNull);
    });

    test('Sad Path: a central project with nobody signed in keeps no '
        'e-mail', () async {
      // 1. Arrange
      final auth = _auth();
      when(auth.centralEmail()).thenAnswer((_) async => null);
      final session = SessionRepositoryGoogle(auth: auth);

      // 2. Act
      await session.readSignedInEmail();

      // 3. Assert
      expect(session.signedInEmail, isNull);
    });
  });

  group('SessionRepositoryGoogle organization sign-in - Unit Test Suite', () {
    test(
      'Happy Path: signs in to the organization with the given token',
      () async {
        // 1. Arrange
        final auth = _auth();
        final session = SessionRepositoryGoogle(auth: auth);

        // 2. Act
        await session.signInToOrganization(_kIdToken);

        // 3. Assert
        verify(auth.signInToOrganization(_kIdToken)).called(1);
      },
    );

    test("Happy Path: saves the organization's Google profile", () async {
      // 1. Arrange
      final auth = _auth();
      final user = UserGoogleModel(
        id: 'uid-123',
        name: 'Ana Souza',
        email: _kCentralEmail,
      );
      when(auth.saveOrganizationProfile()).thenAnswer((_) async => user);
      final session = SessionRepositoryGoogle(auth: auth);

      // 2. Act
      final saved = await session.saveOrganizationProfile();

      // 3. Assert
      expect(saved, same(user));
    });

    test('Edge Case: signing out of the organization keeps the MonAmie '
        'sign-in', () async {
      // 1. Arrange
      final auth = _auth();
      final session = SessionRepositoryGoogle(auth: auth)
        ..keepIdToken(_kIdToken);
      await session.readSignedInEmail();

      // 2. Act
      await session.signOutOfOrganization();

      // 3. Assert
      verify(auth.signOutOfOrganization()).called(1);
      verifyNever(auth.logoutGoogle());
      expect(session.idToken, _kIdToken);
      expect(session.signedInEmail, _kCentralEmail);
    });

    test('Sad Path: a failing organization sign-in throws', () async {
      // 1. Arrange
      final auth = _auth();
      when(
        auth.signInToOrganization(any),
      ).thenAnswer((_) async => throw StateError('offline'));
      final session = SessionRepositoryGoogle(auth: auth);

      // 2. Act
      final signIn = session.signInToOrganization(_kIdToken);

      // 3. Assert
      await expectLater(signIn, throwsStateError);
    });
  });

  group('SessionRepositoryGoogle.signOut - Unit Test Suite', () {
    test('Happy Path: signs out of Google and forgets the token and the '
        'e-mail', () async {
      // 1. Arrange
      final auth = _auth();
      final session = SessionRepositoryGoogle(auth: auth);
      await session.signInGoogle();
      await session.readSignedInEmail();

      // 2. Act
      await session.signOut();

      // 3. Assert
      verify(auth.logoutGoogle()).called(1);
      expect(session.idToken, isNull);
      expect(session.signedInEmail, isNull);
    });

    test('Edge Case: signing out does not move the session', () async {
      // 1. Arrange
      final session = SessionRepositoryGoogle(auth: _auth())
        ..moveTo(const SessionState.bound());

      // 2. Act
      await session.signOut();

      // 3. Assert
      expect(session.session.value, const SessionState.bound());
    });

    test('Sad Path: a failing sign-out throws and keeps the token and the '
        'e-mail', () async {
      // 1. Arrange
      final session = SessionRepositoryGoogle(
        auth: _auth(logoutError: Exception('offline')),
      );
      await session.signInGoogle();
      await session.readSignedInEmail();

      // 2. Act
      final signOut = session.signOut();

      // 3. Assert
      await expectLater(signOut, throwsException);
      expect(session.idToken, _kIdToken);
      expect(session.signedInEmail, _kCentralEmail);
    });
  });
}
