import 'package:freezed_annotation/freezed_annotation.dart';

part 'map_group.freezed.dart';

/// A group the person may watch on the map: its Firestore id and its name.
/// Compared by content.
@freezed
abstract class MapGroup with _$MapGroup {
  const factory MapGroup({
    /// `organizations/{organizationId}/groups/{id}` (an auto id).
    required String id,
    required String name,
  }) = _MapGroup;
}
