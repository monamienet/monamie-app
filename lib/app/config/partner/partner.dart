import 'package:flutter/foundation.dart';

import 'partner_config.dart';

/// Holds the partner the signed-in user is bound to.
///
/// It is `null` until the app knows the partner (before sign-in, or after
/// sign-out); the app then shows the MonAmie brand.
abstract final class Partner {
  static PartnerConfig? _current;

  /// The bound partner, or `null` when none is bound.
  static PartnerConfig? get current => _current;

  /// Whether a partner is bound.
  static bool get isBound => _current != null;

  /// Binds [config], replacing the previous partner.
  static void bind(PartnerConfig config) => _current = config;

  /// Forgets the bound partner.
  static void unbind() => _current = null;

  @visibleForTesting
  static void debugReset() => _current = null;
}
