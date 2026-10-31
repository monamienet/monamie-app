/// A group the person may watch on the map: its Firestore id and its name.
class MapGroup {
  const MapGroup({required this.id, required this.name});

  /// `organizations/{organizationId}/groups/{id}` (an auto id).
  final String id;
  final String name;

  @override
  bool operator ==(Object other) =>
      other is MapGroup && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}
