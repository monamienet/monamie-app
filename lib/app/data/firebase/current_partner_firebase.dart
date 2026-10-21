import 'package:flutter/foundation.dart';

import 'partner_firebase.dart';

/// Holds the [PartnerFirebase] of the current isolate.
///
/// The UI isolate and the background tracking isolate each set it after
/// initializing Firebase.
abstract final class CurrentPartnerFirebase {
  static PartnerFirebase? _value;

  /// Throws a [StateError] before [set].
  static PartnerFirebase get instance {
    final value = _value;
    if (value == null) {
      throw StateError('CurrentPartnerFirebase.instance read before set().');
    }
    return value;
  }

  /// Whether a partner's Firebase is bound in this isolate.
  static bool get isSet => _value != null;

  static void set(PartnerFirebase value) => _value = value;

  static void clear() => _value = null;

  @visibleForTesting
  static void debugReset() => _value = null;
}
