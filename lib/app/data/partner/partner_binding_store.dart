import 'partner_binding.dart';

/// Where the device keeps the [PartnerBinding] between launches.
abstract interface class PartnerBindingStore {
  /// The stored binding, or `null` when there is none or it is unreadable.
  Future<PartnerBinding?> read();

  Future<void> write(PartnerBinding binding);

  Future<void> clear();
}
