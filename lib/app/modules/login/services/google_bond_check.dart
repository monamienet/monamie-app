/// Tells whether this device still holds a usable Google sign-in, so the
/// login screen can skip straight to the map when the app is recreated.
abstract interface class GoogleBondCheck {
  /// Whether an organization is bound, its project has a signed-in user and
  /// the Google profile is stored on the device.
  Future<bool> hasActiveBond();
}
