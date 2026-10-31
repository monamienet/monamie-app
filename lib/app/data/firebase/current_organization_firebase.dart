import 'package:flutter/foundation.dart';

import 'organization_firebase.dart';

/// Holds the [OrganizationFirebase] of the current isolate.
///
/// The UI isolate and the background tracking isolate each set it after
/// initializing Firebase.
abstract final class CurrentOrganizationFirebase {
  static OrganizationFirebase? _value;

  /// Throws a [StateError] before [set].
  static OrganizationFirebase get instance {
    final value = _value;
    if (value == null) {
      throw StateError(
        'CurrentOrganizationFirebase.instance read before set().',
      );
    }
    return value;
  }

  /// Whether an organization's Firebase is bound in this isolate.
  static bool get isSet => _value != null;

  static void set(OrganizationFirebase value) => _value = value;

  static void clear() => _value = null;

  @visibleForTesting
  static void debugReset() => _value = null;
}
