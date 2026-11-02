import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:monamie_app/app/data/firebase/firestore_paths.dart';

part 'user_model.freezed.dart';

/// A person's last position in a group:
/// `organizations/{id}/groups/{groupId}/positions/{personKey}`. Immutable
/// and compared by content.
@freezed
abstract class UserModel with _$UserModel {
  const factory UserModel({
    required String email,
    String? name,
    double? lat,
    double? lng,

    /// When the device captured the position (device clock).
    DateTime? capturedAt,
    bool? isPublishing,
  }) = _UserModel;

  const UserModel._();

  factory UserModel.fromMap(Map<String, dynamic> json) => UserModel(
    email: json[PositionFields.email].toString(),
    name: json[PositionFields.name]?.toString(),
    lat: (json[PositionFields.lat] as num?)?.toDouble(),
    lng: (json[PositionFields.lng] as num?)?.toDouble(),
    capturedAt: (json[PositionFields.capturedAt] as Timestamp?)?.toDate(),
    isPublishing: json[PositionFields.isPublishing] as bool?,
  );

  Map<String, dynamic> toMap() {
    return {
      PositionFields.email: email,
      if (name != null) PositionFields.name: name,
      if (lat != null) PositionFields.lat: lat,
      if (lng != null) PositionFields.lng: lng,
      if (capturedAt != null) PositionFields.capturedAt: capturedAt,
      if (isPublishing != null) PositionFields.isPublishing: isPublishing,
    };
  }
}
