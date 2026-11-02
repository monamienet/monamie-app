// check_layers: state_contract

import 'package:monamie_app/domain/models/organization/organization_binding.dart';

/// Binds and forgets the organization in the current isolate: what the
/// sign-in flow needs from `OrganizationSession`.
abstract interface class OrganizationBinder {
  /// Binds [binding] in this isolate and, when [remember] is true, stores it
  /// so the next launch (and the background isolate) binds it too.
  Future<void> bind(OrganizationBinding binding, {bool remember = true});

  /// Forgets the bound organization, stored binding included.
  Future<void> forget();
}
