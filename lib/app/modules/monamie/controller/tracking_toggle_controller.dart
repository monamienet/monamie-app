import 'package:flutter/foundation.dart';
import 'package:monamie_app/app/utils/result.dart';
import 'package:monamie_app/app/utils/user_notice.dart';

/// What the sharing switch needs from the tracking controller.
///
/// Decouples the widget from the concrete tracking service, so a widget test
/// can inject a fake. Each value is its own [ValueListenable] and notifies
/// only when it changes.
abstract class TrackingToggleController {
  /// Whether the tracking service is running.
  ValueListenable<bool> get isTrackingEnabled;

  /// Whether a start or stop is in flight.
  ValueListenable<bool> get isTrackingLoading;

  /// Starts or stops sharing. [Ok] may hold a [UserNotice] to show (sharing
  /// started, with a remark); [Err] says why sharing did not start.
  Future<Result<UserNotice?>> toggleService();
}
