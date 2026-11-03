import 'package:flutter/material.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/ui/core/ui/failure_text.dart';
import 'package:monamie_app/utils/notice_presenter.dart';
import 'package:monamie_app/utils/result.dart';
import 'package:monamie_app/utils/user_notice.dart';

/// The app's one [ScaffoldMessenger], given to the root app widget: it sits
/// above the navigator, so a message shown through it survives the route that
/// asked for it being replaced.
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// The app's root navigator, given to the root app widget, for the dialogs
/// asked for in the middle of a controller's flow (see
/// `DialogPermissionPrompts`).
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// How long a message stays: the texts are long, often two sentences.
const _noticeDuration = Duration(seconds: 6);

/// A default Material [SnackBar] with an optional bold [title] above
/// [message].
SnackBar noticeSnackBar(String message, {String? title}) => SnackBar(
  duration: _noticeDuration,
  content: title == null
      ? Text(message)
      : Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(message),
          ],
        ),
);

/// Shows [notice] at the bottom of the screen through [messenger], in the
/// language of the messenger's context.
void showNotice(ScaffoldMessengerState messenger, UserNotice notice) {
  final l10n = AppLocalizations.of(messenger.context);
  messenger.showSnackBar(
    noticeSnackBar(notice.message(l10n), title: notice.title(l10n)),
  );
}

/// Shows [result]'s failure through [messenger] when it failed, in the
/// language of the messenger's context; nothing when it succeeded.
void showErrorOf(ScaffoldMessengerState messenger, Result<Object?> result) {
  if (result case Err(:final failure)) {
    final l10n = AppLocalizations.of(messenger.context);
    messenger.showSnackBar(
      noticeSnackBar(failure.message(l10n), title: failure.title(l10n)),
    );
  }
}

/// Runs [action] for a screen and shows its failure when it fails.
///
/// The messenger is looked up before [action] starts, so the message still
/// shows when the action replaces the screen (e.g. a sign-out). Returns the
/// value of an [Ok], `null` after an [Err] or when [action] gave no result
/// (a command that ignored the call while another one ran, see `Command`).
Future<T?> runReportingErrors<T>(
  BuildContext context,
  Future<Result<T>?> Function() action,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final result = await action();
  if (result == null) return null;
  showErrorOf(messenger, result);
  return switch (result) {
    Ok(:final value) => value,
    Err() => null,
  };
}

/// Shows notices through [rootScaffoldMessengerKey], for the controllers'
/// messages that no screen is waiting for.
class ScaffoldNoticePresenter implements NoticePresenter {
  const ScaffoldNoticePresenter();

  @override
  void show(UserNotice notice) {
    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger == null) {
      debugPrint('[Notice] No messenger to show $notice.');
      return;
    }
    showNotice(messenger, notice);
  }
}
