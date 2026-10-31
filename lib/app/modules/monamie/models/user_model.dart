import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:monamie_app/app/data/firebase/firestore_paths.dart';

/// A person's last position: `organizations/{id}/positions/{email}`.
class UserModel {
  String email;
  String? name;
  double? lat;
  double? lng;

  /// When the device captured the position (device clock).
  DateTime? capturedAt;
  bool? isPublishing;

  /// The team group's e-mail the person shares with.
  String? groupId;

  UserModel({
    required this.email,
    this.name,
    this.lat,
    this.lng,
    this.capturedAt,
    this.isPublishing,
    this.groupId,
  });

  UserModel.fromMap(Map<String, dynamic> json)
    : email = json[PositionFields.email].toString(),
      name = json[PositionFields.name]?.toString(),
      lat = (json[PositionFields.lat] as num?)?.toDouble(),
      lng = (json[PositionFields.lng] as num?)?.toDouble(),
      capturedAt = (json[PositionFields.capturedAt] as Timestamp?)?.toDate(),
      isPublishing = json[PositionFields.isPublishing] as bool?,
      groupId = json[PositionFields.groupId]?.toString();

  Map<String, dynamic> toMap() {
    return {
      PositionFields.email: email,
      if (name != null) PositionFields.name: name,
      if (lat != null) PositionFields.lat: lat,
      if (lng != null) PositionFields.lng: lng,
      if (capturedAt != null) PositionFields.capturedAt: capturedAt,
      if (isPublishing != null) PositionFields.isPublishing: isPublishing,
      if (groupId != null) PositionFields.groupId: groupId,
    };
  }
}
