/// The data the device keeps about the bound organization besides the binding
/// itself: cached groups and the user's local data.
abstract interface class OrganizationLocalData {
  /// Deletes it, so the next organization (or the next person on a shared device)
  /// starts clean.
  Future<void> clear();
}
