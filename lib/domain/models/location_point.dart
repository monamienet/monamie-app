import 'package:freezed_annotation/freezed_annotation.dart';

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
}
