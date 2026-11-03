import 'package:flutter/foundation.dart';
import 'package:monamie_app/utils/command.dart';
import 'package:monamie_app/utils/result.dart';
import 'package:monamie_app/utils/user_notice.dart';

/// What the sharing switch needs from the tracking controller.
///
/// Decouples the widget from the concrete tracking service, so a widget test
/// can inject a fake. Each value is its own [Listenable] and notifies only
/// when it changes.
abstract class TrackingToggleViewModel {
  /// Whether the tracking service is running.
  ValueListenable<bool> get isTrackingEnabled;

  /// Starts or stops sharing; [Command.running] while a start or stop is in
  /// flight. [Ok] may hold a [UserNotice] to show (sharing started, with a
  /// remark); [Err] says why sharing did not start.
  Command0<UserNotice?> get toggleService;
}
