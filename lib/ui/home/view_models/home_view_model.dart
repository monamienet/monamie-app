import 'package:flutter/foundation.dart';

import 'package:monamie_app/data/repositories/membership/membership_repository.dart';
import 'package:monamie_app/data/repositories/permissions/permissions_repository.dart';
import 'package:monamie_app/data/services/call_service.dart';
import 'package:monamie_app/domain/models/capabilities.dart';
import 'package:monamie_app/domain/models/group_member.dart';
import 'package:monamie_app/domain/models/map_group.dart';

/// What the map screen (`HomeScreen`, its header, menu, sheet and lists)
/// reads from the organization's shared state, the person's memberships
/// and the group on the map ([MembershipRepository]) and the permissions
/// ([PermissionsRepository]), and the call it places. Created by the map's
/// route, so the screens receive view models only.
///
/// It keeps no state of its own and never notifies: each value is the
/// repository's own [ValueListenable], so a widget still rebuilds only for
/// the values it reads (merged with `Listenable.merge`).
class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required this._membership,
    required this._permissions,
    required this._calls,
  });

  final MembershipRepository _membership;
  final PermissionsRepository _permissions;
  final CallService _calls;

  // The memberships and the group on the map.

  /// What the person may do in the bound organization.
  ValueListenable<Capabilities> get capabilities => _membership.capabilities;

  /// Whether the person administers the bound organization.
  bool get isAdmin => _membership.isAdmin;

  /// Whether the person sees some group's map.
  bool get canWatch => _membership.canWatch;

  /// Whether the person shares their location in some group.
  bool get canPublish => _membership.canPublish;

  /// The groups whose map the person sees, by name.
  ValueListenable<List<MapGroup>> get mapGroups => _membership.mapGroups;

  /// The groups where the person shares their location, by name.
  ValueListenable<List<MapGroup>> get publishGroups =>
      _membership.publishGroups;

  /// The group on the map, or `null` when the person sees none.
  ValueListenable<MapGroup?> get selectedGroup => _membership.selectedGroup;

  /// Whether the map is loading a group the person just picked.
  ValueListenable<bool> get switchingGroup => _membership.switchingGroup;

  /// The people of the observed group who publish there now, by name.
  ValueListenable<List<GroupMember>> get observedMembers =>
      _membership.observedMembers;

  /// Everyone who ever published in the observed group, once read.
  ValueListenable<List<GroupMember>> get historyMembers =>
      _membership.historyMembers;

  /// People publishing in each group of [mapGroups], by group id.
  ValueListenable<Map<String, int>> get groupSizes => _membership.groupSizes;

  /// The people whose trail is drawn on the map.
  ValueListenable<List<GroupMember>> get highlightedObservedUsers =>
      _membership.highlightedObservedUsers;

  /// E-mail of the person whose map marker was pressed, or `null`.
  ValueListenable<String?> get selectedMemberEmail =>
      _membership.selectedMemberEmail;

  /// The people the group list shows: those publishing today, or on a past
  /// day everyone who ever published there (once read for the history).
  List<GroupMember> listedMembers({required bool observingToday}) =>
      observingToday || historyMembers.value.isEmpty
      ? observedMembers.value
      : historyMembers.value;

  /// Switches the map to [group].
  Future<void> pickGroup(MapGroup group) => _membership.pickGroup(group);

  /// Counts the people publishing in every group of [mapGroups].
  Future<void> loadGroupSizes() => _membership.loadGroupSizes();

  void toggleHighlight(GroupMember member) =>
      _membership.toggleHighlight(member);
  bool isHighlighted(GroupMember member) => _membership.isHighlighted(member);

  /// Pressing the selected marker again clears the selection.
  void toggleSelected(String email) => _membership.toggleSelected(email);
  void clearSelected() => _membership.clearSelected();

  // The permissions.

  ValueListenable<bool> get hasWhenInUseLocationPermission =>
      _permissions.hasWhenInUseLocationPermission;
  ValueListenable<bool> get hasAlwaysLocationPermission =>
      _permissions.hasAlwaysLocationPermission;
  ValueListenable<bool> get hasNotificationPermission =>
      _permissions.hasNotificationPermission;

  /// Whether the battery mode is "Restrito" (the system stops the tracking
  /// service once the app leaves the screen).
  ValueListenable<bool> get isBackgroundRestricted =>
      _permissions.isBackgroundRestricted;

  /// Whether everything the tracking needs is granted (see
  /// [PermissionsRepository.arePermissionsGranted]).
  bool arePermissionsGranted() => _permissions.arePermissionsGranted();

  Future<void> requestNotificationPermission() =>
      _permissions.requestNotificationPermission();
  Future<void> requestWhenInUsePermission() =>
      _permissions.requestWhenInUsePermission();
  Future<void> requestAlwaysPermission() =>
      _permissions.requestAlwaysPermission();
  Future<void> openBackgroundUsageSettings() =>
      _permissions.openBackgroundUsageSettings();

  // Calls.

  /// Opens Google Meet to call [email] (copied to the clipboard first).
  Future<void> call(String email) => _calls.launchGoogleMeet(email);
}
