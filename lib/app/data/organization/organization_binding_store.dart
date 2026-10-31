import 'organization_binding.dart';

/// Where the device keeps the [OrganizationBinding] between launches.
abstract interface class OrganizationBindingStore {
  /// The stored binding, or `null` when there is none or it is unreadable.
  Future<OrganizationBinding?> read();

  Future<void> write(OrganizationBinding binding);

  Future<void> clear();
}
