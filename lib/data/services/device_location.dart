// check_layers: state_contract

import 'package:latlong2/latlong.dart';

/// Reads this device's location hardware, so the code that decides what to
/// do with a fix (or the lack of one) can be tested without the plugin.
abstract interface class DeviceLocation {
  /// Whether the device's location (GPS) is turned on.
  Future<bool> isServiceEnabled();

  /// The device's current position. It may never complete on a cold start
  /// or with a weak signal: callers guard it with a timeout.
  Future<LatLng> currentPosition();
}
