// check_layers: state_contract

/// The questions `PermissionsRepository` asks in the middle of a permission
/// flow. The widget layer implements them with dialogs
/// (`DialogPermissionPrompts`); tests replace them with mocks.
abstract class PermissionPrompts {
  /// The Play-required disclosure before asking for the location "all the
  /// time". Completes with whether the person chose to proceed.
  Future<bool> confirmBackgroundLocation();

  /// Explains the battery restriction before opening the battery settings.
  /// Completes with whether the person chose to proceed.
  Future<bool> confirmBackgroundUsageSettings();

  /// Says the GPS is off; completes when the person dismisses it.
  Future<void> notifyGpsDisabled();
}
