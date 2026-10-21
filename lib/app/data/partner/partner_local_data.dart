/// The data the device keeps about the bound partner besides the binding
/// itself: cached groups and the user's local data.
abstract interface class PartnerLocalData {
  /// Deletes it, so the next partner (or the next person on a shared device)
  /// starts clean.
  Future<void> clear();
}
