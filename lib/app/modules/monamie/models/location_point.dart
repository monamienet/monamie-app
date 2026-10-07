import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa um ponto geográfico registrado no histórico de trajetória
/// de um monitor. Cada ponto contém latitude, longitude e o instante
/// em que foi captado.
class LocationPoint {
  final double lat;
  final double lng;
  final DateTime timestamp;

  LocationPoint({
    required this.lat,
    required this.lng,
    required this.timestamp,
  });

  factory LocationPoint.fromMap(Map<String, dynamic> json) {
    return LocationPoint(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      timestamp: (json['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lat': lat,
      'lng': lng,
      'timestamp': timestamp,
    };
  }
}
