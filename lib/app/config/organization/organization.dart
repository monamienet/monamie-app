import 'package:flutter/foundation.dart';

import 'organization_config.dart';

/// Holds the organization the signed-in user is bound to.
///
/// It is `null` until the app knows the organization (before sign-in, or after
/// sign-out); the app then shows the MonAmie brand.
abstract final class Organization {
  static OrganizationConfig? _current;

  /// The bound organization, or `null` when none is bound.
  static OrganizationConfig? get current => _current;

  /// Whether an organization is bound.
  static bool get isBound => _current != null;

  /// Binds [config], replacing the previous organization.
  static void bind(OrganizationConfig config) => _current = config;

  /// Forgets the bound organization.
  static void unbind() => _current = null;

  @visibleForTesting
  static void debugReset() => _current = null;
}
