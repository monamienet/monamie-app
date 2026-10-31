import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/config/organization/organization.dart';
import 'package:monamie_app/app/data/firebase/current_organization_firebase.dart';
import 'package:monamie_app/app/data/groups/firestore_membership_source.dart';
import 'package:monamie_app/app/data/groups/membership_source.dart';
import 'package:monamie_app/app/data/services/capabilities.dart';
import 'package:monamie_app/app/modules/login/controllers/auth_google_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/group_map_state.dart';
import 'package:monamie_app/app/modules/monamie/controller/map_groups.dart';
import 'package:monamie_app/app/modules/monamie/data/group_positions_source.dart';
import 'package:monamie_app/app/modules/monamie/data/provider/firebase_provider.dart';
import 'package:monamie_app/app/modules/monamie/models/group_member.dart';
import 'package:monamie_app/app/modules/monamie/models/map_group.dart';
import 'package:monamie_app/app/modules/monamie/models/user_model.dart';

/// [GroupMapState] over the bound organization's Firestore: listens to the
/// person's own `organizationMemberships` and `groupMemberships` documents
/// (so a change made by an administrator shows at once), to the names of
/// the groups they may read, and to the positions of the group on the map.
///
/// A missing organization membership means the person was removed: the app
/// forgets the organization ([onAccessLost]).
class GroupMapController extends GetxController implements GroupMapState {
  GroupMapController({
    MembershipSource? memberships,
    GroupPositionsSource? positions,
    Future<void> Function()? onAccessLost,
    String? Function()? organizationId,
    String? Function()? email,
  }) : _memberships = memberships ?? const FirestoreMembershipSource(),
       _positions = positions ?? FirebaseProvider(),
       _onAccessLost =
           onAccessLost ??
           (() => Get.find<AuthGoogleController>().forgetRemovedOrganization()),
       _organizationId = organizationId ?? (() => Organization.current?.id),
       _email =
           email ??
           (() => CurrentOrganizationFirebase.isSet
               ? CurrentOrganizationFirebase.instance.auth.currentUser?.email
               : null);

  final MembershipSource _memberships;
  final GroupPositionsSource _positions;
  final Future<void> Function() _onAccessLost;
  final String? Function() _organizationId;
  final String? Function() _email;

  @override
  final Rx<Capabilities> capabilities = const Capabilities().obs;
  @override
  final RxBool isLoading = true.obs;
  @override
  final RxString loadError = ''.obs;
  @override
  final RxList<MapGroup> mapGroups = <MapGroup>[].obs;
  @override
  final RxList<MapGroup> publishGroups = <MapGroup>[].obs;
  @override
  final Rxn<MapGroup> selectedGroup = Rxn<MapGroup>();
  @override
  final RxBool switchingGroup = false.obs;
  @override
  final RxList<UserModel> groupPositions = <UserModel>[].obs;
  @override
  final RxList<GroupMember> observedMembers = <GroupMember>[].obs;
  @override
  final RxList<GroupMember> historyMembers = <GroupMember>[].obs;
  @override
  final RxMap<String, int> groupSizes = <String, int>{}.obs;
  @override
  final RxList<GroupMember> highlightedObservedUsers = <GroupMember>[].obs;
  @override
  final RxnString selectedMemberEmail = RxnString();

  @override
  bool get isAdmin => capabilities.value.isAdmin;
  @override
  bool get canWatch => capabilities.value.canWatch;
  @override
  bool get canPublish => capabilities.value.canPublish;

  String? _organization;
  StreamSubscription<Map<String, Object?>?>? _organizationSubscription;
  StreamSubscription<Map<String, Object?>>? _rolesSubscription;
  StreamSubscription<Map<String, String>>? _allGroupsSubscription;
  final Map<String, StreamSubscription<String?>> _nameSubscriptions = {};
  StreamSubscription<List<UserModel>>? _positionsSubscription;

  /// The last membership documents read; `null` until known.
  Map<String, Object?>? _organizationMembership;
  Map<String, Object?>? _groupRoles;

  /// Group names by id: every group for an administrator, the person's own
  /// groups otherwise.
  final Map<String, String> _names = {};
  bool _accessLost = false;
  bool _countingSizes = false;

  @override
  void onInit() {
    super.onInit();
    _start();
  }

  void _start() {
    final organizationId = _organizationId();
    final email = _email();
    if (organizationId == null || email == null) {
      debugPrint('[GroupMap] No organization or no signed-in person.');
      loadError.value = 'not_authenticated';
      isLoading.value = false;
      return;
    }
    _organization = organizationId;
    _organizationSubscription = _memberships
        .organizationMembership(organizationId, email)
        .listen(_onOrganizationMembership, onError: _onLoadError);
    _rolesSubscription = _memberships
        .groupRoles(organizationId, email)
        .listen(
          (roles) {
            _groupRoles = roles;
            _recompute();
          },
          onError: (Object e) {
            // Without the groups an administrator still sees every group.
            _onLoadError(e);
            _groupRoles ??= const {};
            _recompute();
          },
        );
  }

  void _onLoadError(Object e) {
    debugPrint('[GroupMap] Could not read the memberships: $e');
    loadError.value = '$e';
    isLoading.value = false;
  }

  Future<void> _onOrganizationMembership(Map<String, Object?>? data) async {
    if (data == null) {
      // Removed from the organization: forget it, once.
      if (_accessLost) return;
      _accessLost = true;
      await _cancelAll();
      await _onAccessLost();
      return;
    }
    _organizationMembership = data;
    _recompute();
  }

  void _recompute() {
    final membership = _organizationMembership;
    final roles = _groupRoles;
    if (membership == null || roles == null || _accessLost) return;
    final next = Capabilities.fromMemberships(
      organizationMembership: membership,
      groupRoles: roles,
    );
    if (next != capabilities.value) capabilities.value = next;
    isLoading.value = false;
    _followNames(next);
    _refreshGroups();
  }

  /// Follows the names of every group (administrators may list them) or of
  /// the person's own groups.
  void _followNames(Capabilities caps) {
    final organizationId = _organization;
    if (organizationId == null) return;
    if (caps.isAdmin) {
      _cancelNameSubscriptions();
      _allGroupsSubscription ??= _memberships
          .allGroupNames(organizationId)
          .listen(
            (names) {
              _names
                ..clear()
                ..addAll(names);
              _refreshGroups();
            },
            onError: (Object e) =>
                debugPrint('[GroupMap] Could not list the groups: $e'),
          );
      return;
    }
    if (_allGroupsSubscription != null) {
      _allGroupsSubscription?.cancel();
      _allGroupsSubscription = null;
      _names.clear();
    }
    final wanted = caps.rolesByGroup.keys.toSet();
    for (final id in _nameSubscriptions.keys.toList()) {
      if (!wanted.contains(id)) {
        _nameSubscriptions.remove(id)?.cancel();
        _names.remove(id);
      }
    }
    for (final id in wanted) {
      _nameSubscriptions[id] ??= _memberships
          .groupName(organizationId, id)
          .listen(
            (name) {
              name == null ? _names.remove(id) : _names[id] = name;
              _refreshGroups();
            },
            onError: (Object e) {
              // Lost access to the group in the meantime.
              debugPrint('[GroupMap] Could not read group $id: $e');
              _names.remove(id);
              _refreshGroups();
            },
          );
    }
  }

  void _cancelNameSubscriptions() {
    for (final subscription in _nameSubscriptions.values) {
      subscription.cancel();
    }
    _nameSubscriptions.clear();
  }

  void _refreshGroups() {
    final caps = capabilities.value;
    final visible = mapGroupsFor(
      caps,
      names: _names,
      allGroupIds: caps.isAdmin ? _names.keys : const [],
    );
    if (!listEquals(visible, mapGroups)) mapGroups.assignAll(visible);
    final publishing = namedGroups(caps.publisherGroupIds, _names);
    if (!listEquals(publishing, publishGroups)) {
      publishGroups.assignAll(publishing);
    }

    final current = selectedGroup.value;
    if (visible.isEmpty) {
      if (current != null) _observe(null);
    } else if (renamedSelection(visible, current) case final renamed?) {
      selectedGroup.value = renamed;
    } else if (groupToObserve(visible, current) case final next?) {
      // Someone who watches opens straight onto a group, not an empty panel.
      _observe(next);
    }
  }

  /// Puts [group] on the map; completes when its first positions arrive (or
  /// fail).
  Future<void> _observe(MapGroup? group) {
    _positionsSubscription?.cancel();
    _positionsSubscription = null;
    selectedGroup.value = group;
    groupPositions.clear();
    observedMembers.clear();
    historyMembers.clear();
    highlightedObservedUsers.clear();
    selectedMemberEmail.value = null;
    if (group == null) return Future.value();

    final first = Completer<void>();
    _positionsSubscription = _positions
        .streamGroupPositions(group.id)
        .listen(
          (users) {
            groupPositions.assignAll(users);
            observedMembers.assignAll(membersOf(users));
            groupSizes[group.id] = users.length;
            if (!first.isCompleted) first.complete();
          },
          onError: (Object e) {
            debugPrint('[GroupMap] Could not read group ${group.id}: $e');
            groupPositions.clear();
            observedMembers.clear();
            if (!first.isCompleted) first.complete();
          },
        );
    return first.future;
  }

  @override
  Future<void> pickGroup(MapGroup group) async {
    if (switchingGroup.value || group.id == selectedGroup.value?.id) return;
    switchingGroup.value = true;
    try {
      await _observe(
        group,
      ).timeout(const Duration(seconds: 15), onTimeout: () {});
    } finally {
      switchingGroup.value = false;
    }
  }

  @override
  Future<void> loadGroupSizes() async {
    if (_countingSizes) return;
    _countingSizes = true;
    try {
      await Future.wait([
        for (final group in mapGroups.toList())
          _positions
              .countPublishers(group.id)
              .then((count) => groupSizes[group.id] = count)
              .catchError((Object e) {
                // The menu then shows only the group's name.
                debugPrint('[GroupMap] Could not count ${group.id}: $e');
                return 0;
              }),
      ]);
    } finally {
      _countingSizes = false;
    }
  }

  @override
  Future<List<GroupMember>> loadHistoryMembers() async {
    final group = selectedGroup.value;
    if (group == null) return const [];
    try {
      final members = membersOf(await _positions.groupHistoryPeople(group.id));
      // The person may have switched groups while it loaded.
      if (selectedGroup.value?.id == group.id) {
        historyMembers.assignAll(members);
      }
      return members;
    } catch (e) {
      debugPrint('[GroupMap] Could not read the history of ${group.id}: $e');
      return historyMembers.isEmpty ? observedMembers.toList() : historyMembers;
    }
  }

  @override
  void toggleHighlight(GroupMember member) {
    if (isHighlighted(member)) {
      highlightedObservedUsers.removeWhere((m) => m.email == member.email);
    } else {
      highlightedObservedUsers.add(member);
    }
  }

  @override
  bool isHighlighted(GroupMember member) =>
      highlightedObservedUsers.any((m) => m.email == member.email);

  @override
  void toggleSelected(String email) {
    selectedMemberEmail.value = selectedMemberEmail.value == email
        ? null
        : email;
  }

  @override
  void clearSelected() => selectedMemberEmail.value = null;

  Future<void> _cancelAll() async {
    await _organizationSubscription?.cancel();
    await _rolesSubscription?.cancel();
    await _allGroupsSubscription?.cancel();
    await _positionsSubscription?.cancel();
    _organizationSubscription = null;
    _rolesSubscription = null;
    _allGroupsSubscription = null;
    _positionsSubscription = null;
    _cancelNameSubscriptions();
  }

  @override
  void onClose() {
    _cancelAll();
    super.onClose();
  }
}
