import 'package:flutter/foundation.dart';

import 'partner_config.dart';

/// Holds the partner of this build, loaded once in `main()` before `runApp`.
abstract final class Partner {
  static PartnerConfig? _current;

  /// The partner of this build.
  ///
  /// Throws a [StateError] before [init].
  static PartnerConfig get current {
    final current = _current;
    if (current == null) {
      throw StateError('Partner.current was read before Partner.init().');
    }
    return current;
  }

  /// Sets the partner of this build. Throws a [StateError] if it is already
  /// set, so a second load can never switch partners halfway through.
  static void init(PartnerConfig config) {
    if (_current != null) {
      throw StateError('Partner.init() was already called.');
    }
    _current = config;
  }

  /// Clears the partner, so a test can [init] another one.
  @visibleForTesting
  static void debugReset() {
    _current = null;
  }
}
