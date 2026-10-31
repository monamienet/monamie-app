import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:monamie_app/app/data/firebase/firestore_paths.dart';

/// Representa um ponto geográfico registrado no histórico de trajetória
/// de um monitor. Cada ponto contém latitude, longitude e o instante
/// em que o servidor o recebeu.
class LocationPoint {
  final double lat;
  final double lng;
  final DateTime receivedAt;

  LocationPoint({
    required this.lat,
    required this.lng,
    required this.receivedAt,
  });

  factory LocationPoint.fromMap(Map<String, dynamic> json) {
    return LocationPoint(
      lat: (json[TrailPointFields.lat] as num).toDouble(),
      lng: (json[TrailPointFields.lng] as num).toDouble(),
      receivedAt: (json[TrailPointFields.receivedAt] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      TrailPointFields.lat: lat,
      TrailPointFields.lng: lng,
      TrailPointFields.receivedAt: receivedAt,
    };
  }
}
