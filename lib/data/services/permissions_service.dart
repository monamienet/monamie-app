import 'package:permission_handler/permission_handler.dart';

/// The permissions the app asks for.
enum AppPermission {
  /// The location while the app is open.
  locationWhenInUse,

  /// The location at any time, also with the app closed (tracking).
  locationAlways,

  /// Showing notifications (the tracking service's notification).
  notification,
}

/// What the system answered about an [AppPermission].
enum AppPermissionStatus {
  granted,
  denied,

  /// Denied for good: only the app's settings can grant it now.
  permanentlyDenied,

  /// Restricted by the system (parental controls, iOS).
  restricted,

  /// Granted with limits (iOS).
  limited,

  /// Granted provisionally (iOS notifications).
  provisional;

  bool get isGranted => this == granted;
  bool get isPermanentlyDenied => this == permanentlyDenied;
}

/// The system's permissions, through the `permission_handler` plugin.
class PermissionsService {
  const PermissionsService();

  static Permission _of(AppPermission permission) => switch (permission) {
    AppPermission.locationWhenInUse => Permission.locationWhenInUse,
    AppPermission.locationAlways => Permission.locationAlways,
    AppPermission.notification => Permission.notification,
  };

  static AppPermissionStatus _from(PermissionStatus status) => switch (status) {
    PermissionStatus.granted => AppPermissionStatus.granted,
    PermissionStatus.denied => AppPermissionStatus.denied,
    PermissionStatus.permanentlyDenied => AppPermissionStatus.permanentlyDenied,
    PermissionStatus.restricted => AppPermissionStatus.restricted,
    PermissionStatus.limited => AppPermissionStatus.limited,
    PermissionStatus.provisional => AppPermissionStatus.provisional,
  };

  /// Whether [permission] is granted.
  Future<bool> isGranted(AppPermission permission) => _of(permission).isGranted;

  /// Whether [permission] was denied for good.
  Future<bool> isPermanentlyDenied(AppPermission permission) =>
      _of(permission).isPermanentlyDenied;

  /// Asks the person for [permission] (when the system still may) and
  /// returns the answer.
  Future<AppPermissionStatus> request(AppPermission permission) async =>
      _from(await _of(permission).request());

  /// Opens the app's settings; `false` when they could not be opened.
  Future<bool> openSettings() => openAppSettings();
}
