import 'package:geolocator/geolocator.dart';

import 'device_location.dart';

/// [DeviceLocation] through the `geolocator` plugin.
class GeolocatorDeviceLocation implements DeviceLocation {
  const GeolocatorDeviceLocation();

  @override
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<Position> currentPosition() => Geolocator.getCurrentPosition();
}
