import 'package:get/get.dart';
import 'package:monamie_app/app/data/services/capabilities.dart';
import 'package:monamie_app/app/modules/monamie/models/group_member.dart';
import 'package:monamie_app/app/modules/monamie/models/map_group.dart';
import 'package:monamie_app/app/modules/monamie/models/user_model.dart';

/// What the home screen reads about the person's groups and the group on
/// the map. Registered with GetX under this type, so screens and the other
/// controllers depend on it and not on the Firestore-backed
/// `GroupMapController`.
abstract interface class GroupMapState {
  /// What the person may do in the bound organization, from their
  /// membership documents; updates by itself when an administrator changes
  /// them.
  Rx<Capabilities> get capabilities;

  /// Whether the person administers the bound organization.
  bool get isAdmin;

  /// Whether the person sees some group's map.
  bool get canWatch;

  /// Whether the person shares their location in some group.
  bool get canPublish;

  /// Until the person's memberships are first known.
  RxBool get isLoading;

  /// Why the memberships could not be read, or empty.
  RxString get loadError;

  /// The groups whose map the person sees, by name.
  RxList<MapGroup> get mapGroups;

  /// The groups where the person shares their location, by name.
  RxList<MapGroup> get publishGroups;

  /// The group on the map, or `null` when the person sees none.
  Rxn<MapGroup> get selectedGroup;

  /// Whether the map is loading a group the person just picked.
  RxBool get switchingGroup;

  /// The positions of the observed group's people who publish there now.
  RxList<UserModel> get groupPositions;

  /// The people of [groupPositions], by name.
  RxList<GroupMember> get observedMembers;

  /// Everyone who ever published in the observed group, as last read by
  /// [loadHistoryMembers].
  RxList<GroupMember> get historyMembers;

  /// People publishing in each group of [mapGroups], by group id, once
  /// counted by [loadGroupSizes].
  RxMap<String, int> get groupSizes;

  /// The people whose trail is drawn on the map.
  RxList<GroupMember> get highlightedObservedUsers;

  /// E-mail of the person whose map marker was pressed, or `null`.
  RxnString get selectedMemberEmail;

  /// Switches the map to [group]. Picking the observed group again does
  /// nothing.
  Future<void> pickGroup(MapGroup group);

  /// Counts the people publishing in every group of [mapGroups].
  Future<void> loadGroupSizes();

  /// Reads everyone who ever published in the observed group (for the
  /// history), stores it in [historyMembers] and returns it.
  Future<List<GroupMember>> loadHistoryMembers();

  void toggleHighlight(GroupMember member);
  bool isHighlighted(GroupMember member);

  /// Pressing the selected marker again clears the selection.
  void toggleSelected(String email);
  void clearSelected();
}
