import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/data/repositories/session/session_repository.dart';

@GenerateNiceMocks([MockSpec<SessionRepository>()])
import 'session_double.mocks.dart';

export 'session_double.mocks.dart';

/// A [MockSessionRepository] whose session, leaving, Google readiness and
/// kept ID token behave like the real repository's: [moveTo], [setLeaving]
/// and [keepIdToken] change what [session], [leaving] and `idToken` answer,
/// and the notifiers notify only on a change. Each move is also written to
/// [moves], in order. Every other method is a plain nice-mock stub, to be
/// stubbed by the test.
class SessionDouble {
  SessionDouble({
    SessionState initial = const SessionState.signedOut(),
    bool googleReady = false,
    this._idToken,
    String? signedInEmail,
    Stream<String?>? webSignIns,
  }) : session = ValueNotifier(initial),
       googleReady = ValueNotifier(googleReady) {
    when(repository.session).thenReturn(session);
    when(repository.leaving).thenReturn(leaving);
    when(repository.googleReady).thenReturn(this.googleReady);
    when(
      repository.webSignIns,
    ).thenAnswer((_) => webSignIns ?? const Stream<String?>.empty());
    when(repository.signedInEmail).thenAnswer((_) => signedInEmail);
    when(repository.idToken).thenAnswer((_) => _idToken);
    when(repository.moveTo(any)).thenAnswer((invocation) {
      final next = invocation.positionalArguments.single as SessionState;
      moves.add(next);
      session.value = next;
    });
    when(repository.setLeaving(any)).thenAnswer((invocation) {
      final exit = invocation.positionalArguments.single as SessionExit?;
      leavingHistory.add(exit);
      leaving.value = exit;
    });
    when(repository.keepIdToken(any)).thenAnswer((invocation) {
      _idToken = invocation.positionalArguments.single as String;
    });
  }

  /// The double handed to the unit under test.
  final repository = MockSessionRepository();

  /// What `repository.session` answers.
  final ValueNotifier<SessionState> session;

  /// What `repository.leaving` answers.
  final leaving = ValueNotifier<SessionExit?>(null);

  /// What `repository.googleReady` answers.
  final ValueNotifier<bool> googleReady;

  /// Every session moved to, in order.
  final moves = <SessionState>[];

  /// Every value given to `setLeaving`, in order.
  final leavingHistory = <SessionExit?>[];

  String? _idToken;

  /// The ID token `repository.idToken` answers now.
  String? get idToken => _idToken;

  /// Stops the notifiers.
  void dispose() {
    session.dispose();
    leaving.dispose();
    googleReady.dispose();
  }
}
