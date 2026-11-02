// check_layers: state_contract

import 'package:flutter/foundation.dart';
import 'package:monamie_app/app/data/services/capabilities.dart';
import 'package:monamie_app/app/modules/monamie/models/group_member.dart';
import 'package:monamie_app/app/modules/monamie/models/map_group.dart';
import 'package:monamie_app/app/modules/monamie/models/user_model.dart';

/// What the home screen reads about the person's groups and the group on
/// the map. Registered under this type, so screens and the other
/// controllers depend on it and not on the Firestore-backed
/// `GroupMapController`.
///
/// Each value is its own [ValueListenable], so a reader follows only what
/// it uses (a screen merges several with `Listenable.merge`). A value only
/// notifies when it changes: lists and maps are replaced whole, never
/// changed in place, and compared by content (their items are `freezed`).
abstract interface class GroupMapState {
  /// What the person may do in the bound organization, from their
  /// membership documents; updates by itself when an administrator changes
  /// them.
  ValueListenable<Capabilities> get capabilities;

  /// Whether the person administers the bound organization.
  bool get isAdmin;

  /// Whether the person sees some group's map.
  bool get canWatch;

  /// Whether the person shares their location in some group.
  bool get canPublish;

  /// Until the person's memberships are first known.
  ValueListenable<bool> get isLoading;

  /// Why the memberships could not be read, or empty.
  ValueListenable<String> get loadError;

  /// The groups whose map the person sees, by name.
  ValueListenable<List<MapGroup>> get mapGroups;

  /// The groups where the person shares their location, by name.
  ValueListenable<List<MapGroup>> get publishGroups;

  /// The group on the map, or `null` when the person sees none.
  ValueListenable<MapGroup?> get selectedGroup;

  /// Whether the map is loading a group the person just picked.
  ValueListenable<bool> get switchingGroup;

  /// The positions of the observed group's people who publish there now.
  ValueListenable<List<UserModel>> get groupPositions;

  /// The people of [groupPositions], by name.
  ValueListenable<List<GroupMember>> get observedMembers;

  /// Everyone who ever published in the observed group, as last read by
  /// [loadHistoryMembers].
  ValueListenable<List<GroupMember>> get historyMembers;

  /// People publishing in each group of [mapGroups], by group id, once
  /// counted by [loadGroupSizes].
  ValueListenable<Map<String, int>> get groupSizes;

  /// The people whose trail is drawn on the map.
  ValueListenable<List<GroupMember>> get highlightedObservedUsers;

  /// E-mail of the person whose map marker was pressed, or `null`.
  ValueListenable<String?> get selectedMemberEmail;

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
