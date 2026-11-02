import 'package:flutter/widgets.dart';
import 'package:monamie_app/data/services/app_lifecycle_events.dart';

/// [AppLifecycleEvents] from Flutter's [WidgetsBinding].
class WidgetsBindingAppLifecycleEvents
    with WidgetsBindingObserver
    implements AppLifecycleEvents {
  void Function(AppLifecycleState state)? _onChange;

  @override
  void start(void Function(AppLifecycleState state) onChange) {
    _onChange = onChange;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void stop() {
    WidgetsBinding.instance.removeObserver(this);
    _onChange = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      _onChange?.call(state);
}
