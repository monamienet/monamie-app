// check_layers: state_contract

import 'dart:ui' show AppLifecycleState;

/// Reports the app's lifecycle changes (e.g. coming back from the system
/// settings), so a controller can react to them without depending on the
/// widgets layer.
abstract interface class AppLifecycleEvents {
  /// Starts calling [onChange] with each new lifecycle state.
  void start(void Function(AppLifecycleState state) onChange);

  /// Stops the calls started by [start].
  void stop();
}
