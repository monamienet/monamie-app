import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:monamie_app/utils/failure.dart';

part 'user_notice.freezed.dart';

/// A message for the person using the app that is not the result of the
/// action they just took: a warning raised by a background change, a remark
/// on an action that succeeded (e.g. sharing started while the GPS has no
/// fix yet), or a failure no screen waits for. As data: the widget layer
/// chooses the words (`UserNoticeText` in `lib/ui/core/ui/failure_text.dart`).
/// Compared by content.
@freezed
sealed class UserNotice with _$UserNotice {
  /// Sharing started, but the GPS has no fix yet.
  const factory UserNotice.waitingForGps() = WaitingForGpsNotice;

  /// The device started restricting the app in the background while sharing
  /// is on: the tracking stops once the app leaves the screen.
  const factory UserNotice.trackingAtRisk() = TrackingAtRiskNotice;

  /// The tracking service did not confirm it stopped; it stops by itself
  /// shortly.
  const factory UserNotice.trackingStopUnconfirmed() =
      TrackingStopUnconfirmedNotice;

  /// Back from the battery settings, the background restriction is still
  /// on.
  const factory UserNotice.backgroundStillRestricted() =
      BackgroundStillRestrictedNotice;

  /// [failure], from an operation no screen waits for (a web sign-in, a
  /// sign-out started by a background change).
  const factory UserNotice.failure(Failure failure) = FailureNotice;
}
