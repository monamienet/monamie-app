import 'package:freezed_annotation/freezed_annotation.dart';

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

  /// What [publishedName] says for a person without a name.
  static const noName = 'Nome não informado';

  /// The name the tracking service publishes: [name] trimmed, or [noName]
  /// when there is none.
  String get publishedName {
    final trimmed = name?.trim();
    return trimmed == null || trimmed.isEmpty ? noName : trimmed;
  }
}
