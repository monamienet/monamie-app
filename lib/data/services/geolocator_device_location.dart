import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'device_location.dart';

/// [DeviceLocation] through the `geolocator` plugin.
class GeolocatorDeviceLocation implements DeviceLocation {
  const GeolocatorDeviceLocation();

  @override
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<LatLng> currentPosition() async {
    final position = await Geolocator.getCurrentPosition();
    return LatLng(position.latitude, position.longitude);
  }
}
