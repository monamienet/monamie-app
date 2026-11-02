import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:monamie_app/data/services/firebase/firestore_paths.dart';

part 'location_point.freezed.dart';

/// Representa um ponto geográfico registrado no histórico de trajetória
/// de um monitor. Cada ponto contém latitude, longitude e o instante
/// em que o servidor o recebeu. Compared by content.
@freezed
abstract class LocationPoint with _$LocationPoint {
  const factory LocationPoint({
    required double lat,
    required double lng,
    required DateTime receivedAt,
  }) = _LocationPoint;

  const LocationPoint._();

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
