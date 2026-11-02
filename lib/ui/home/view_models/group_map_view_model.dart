import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:monamie_app/domain/models/organization/organization.dart';
import 'package:monamie_app/data/services/firebase/current_organization_firebase.dart';
import 'package:monamie_app/data/repositories/membership/firestore_membership_source.dart';
import 'package:monamie_app/data/repositories/membership/membership_source.dart';
import 'package:monamie_app/domain/models/capabilities.dart';
import 'package:monamie_app/ui/home/view_models/group_map_state.dart';
import 'package:monamie_app/ui/home/view_models/map_groups.dart';
import 'package:monamie_app/data/repositories/positions/group_positions_source.dart';
import 'package:monamie_app/data/repositories/positions/firebase_provider.dart';
import 'package:monamie_app/domain/models/group_member.dart';
import 'package:monamie_app/domain/models/map_group.dart';
import 'package:monamie_app/domain/models/user_model.dart';

/// [GroupMapState] over the bound organization's Firestore: listens to the
/// person's own `organizationMemberships` and `groupMemberships` documents
/// (so a change made by an administrator shows at once), to the names of
/// the groups they may read, and to the positions of the group on the map.
///
/// A missing organization membership means the person was removed: the app
/// forgets the organization ([onAccessLost]).
///
/// Whoever creates it calls [start] once, to begin listening, and [dispose]
/// once, which cancels every Firestore subscription.
class GroupMapViewModel implements GroupMapState {
  GroupMapViewModel({
    required this._onAccessLost,
    MembershipSource? memberships,
    GroupPositionsSource? positions,
    String? Function()? organizationId,
    String? Function()? email,
  }) : _memberships = memberships ?? const FirestoreMembershipSource(),
       _positions = positions ?? FirebaseProvider(),
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

  final _capabilities = ValueNotifier<Capabilities>(const Capabilities());
  final _isLoading = ValueNotifier<bool>(true);
  final _loadError = ValueNotifier<String>('');
  final _mapGroups = ValueNotifier<List<MapGroup>>(const []);
  final _publishGroups = ValueNotifier<List<MapGroup>>(const []);
  final _selectedGroup = ValueNotifier<MapGroup?>(null);
  final _switchingGroup = ValueNotifier<bool>(false);
  final _groupPositions = ValueNotifier<List<UserModel>>(const []);
  final _observedMembers = ValueNotifier<List<GroupMember>>(const []);
  final _historyMembers = ValueNotifier<List<GroupMember>>(const []);
  final _groupSizes = ValueNotifier<Map<String, int>>(const {});
  final _highlightedObservedUsers = ValueNotifier<List<GroupMember>>(const []);
  final _selectedMemberEmail = ValueNotifier<String?>(null);

  @override
  ValueListenable<Capabilities> get capabilities => _capabilities;
  @override
  ValueListenable<bool> get isLoading => _isLoading;
  @override
  ValueListenable<String> get loadError => _loadError;
  @override
  ValueListenable<List<MapGroup>> get mapGroups => _mapGroups;
  @override
  ValueListenable<List<MapGroup>> get publishGroups => _publishGroups;
  @override
  ValueListenable<MapGroup?> get selectedGroup => _selectedGroup;
  @override
  ValueListenable<bool> get switchingGroup => _switchingGroup;
  @override
  ValueListenable<List<UserModel>> get groupPositions => _groupPositions;
  @override
  ValueListenable<List<GroupMember>> get observedMembers => _observedMembers;
  @override
  ValueListenable<List<GroupMember>> get historyMembers => _historyMembers;
  @override
  ValueListenable<Map<String, int>> get groupSizes => _groupSizes;
  @override
  ValueListenable<List<GroupMember>> get highlightedObservedUsers =>
      _highlightedObservedUsers;
  @override
  ValueListenable<String?> get selectedMemberEmail => _selectedMemberEmail;

  @override
  bool get isAdmin => _capabilities.value.isAdmin;
  @override
  bool get canWatch => _capabilities.value.canWatch;
  @override
  bool get canPublish => _capabilities.value.canPublish;

  bool _started = false;
  bool _disposed = false;

  /// Sets [notifier] (which notifies only when the value differs), unless
  /// disposed: a Firestore answer or a timeout may land after [dispose].
  void _set<T>(ValueNotifier<T> notifier, T value) {
    if (!_disposed) notifier.value = value;
  }

  /// Replaces [notifier]'s list with an unmodifiable copy of [value] when
  /// their content differs (the items compare by content).
  void _setList<T>(ValueNotifier<List<T>> notifier, List<T> value) {
    if (_disposed || listEquals(notifier.value, value)) return;
    notifier.value = List.unmodifiable(value);
  }

  /// Replaces [notifier]'s map with an unmodifiable copy of [value] when
  /// their content differs.
  void _setMap<K, V>(ValueNotifier<Map<K, V>> notifier, Map<K, V> value) {
    if (_disposed || mapEquals(notifier.value, value)) return;
    notifier.value = Map.unmodifiable(value);
  }

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

  /// Starts listening to the person's memberships. Only the first call
  /// does anything.
  void start() {
    if (_started || _disposed) return;
    _started = true;
    final organizationId = _organizationId();
    final email = _email();
    if (organizationId == null || email == null) {
      debugPrint('[GroupMap] No organization or no signed-in person.');
      _set(_loadError, 'not_authenticated');
      _set(_isLoading, false);
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
    _set(_loadError, '$e');
    _set(_isLoading, false);
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
    _set(_capabilities, next);
    _set(_isLoading, false);
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
    final caps = _capabilities.value;
    final visible = mapGroupsFor(
      caps,
      names: _names,
      allGroupIds: caps.isAdmin ? _names.keys : const [],
    );
    _setList(_mapGroups, visible);
    _setList(_publishGroups, namedGroups(caps.publisherGroupIds, _names));

    final current = _selectedGroup.value;
    if (visible.isEmpty) {
      if (current != null) _observe(null);
    } else if (renamedSelection(visible, current) case final renamed?) {
      _set(_selectedGroup, renamed);
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
    _set(_selectedGroup, group);
    _setList(_groupPositions, const <UserModel>[]);
    _setList(_observedMembers, const <GroupMember>[]);
    _setList(_historyMembers, const <GroupMember>[]);
    _setList(_highlightedObservedUsers, const <GroupMember>[]);
    _set(_selectedMemberEmail, null);
    if (group == null || _disposed) return Future.value();

    final first = Completer<void>();
    _positionsSubscription = _positions
        .streamGroupPositions(group.id)
        .listen(
          (users) {
            _setList(_groupPositions, users);
            _setList(_observedMembers, membersOf(users));
            _setMap(_groupSizes, {
              ..._groupSizes.value,
              group.id: users.length,
            });
            if (!first.isCompleted) first.complete();
          },
          onError: (Object e) {
            debugPrint('[GroupMap] Could not read group ${group.id}: $e');
            _setList(_groupPositions, const <UserModel>[]);
            _setList(_observedMembers, const <GroupMember>[]);
            if (!first.isCompleted) first.complete();
          },
        );
    return first.future;
  }

  @override
  Future<void> pickGroup(MapGroup group) async {
    if (_disposed ||
        _switchingGroup.value ||
        group.id == _selectedGroup.value?.id) {
      return;
    }
    _set(_switchingGroup, true);
    try {
      await _observe(
        group,
      ).timeout(const Duration(seconds: 15), onTimeout: () {});
    } finally {
      _set(_switchingGroup, false);
    }
  }

  @override
  Future<void> loadGroupSizes() async {
    if (_countingSizes) return;
    _countingSizes = true;
    try {
      await Future.wait([
        for (final group in _mapGroups.value)
          _positions
              .countPublishers(group.id)
              .then((count) {
                _setMap(_groupSizes, {..._groupSizes.value, group.id: count});
                return count;
              })
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
    final group = _selectedGroup.value;
    if (group == null) return const [];
    try {
      final members = membersOf(await _positions.groupHistoryPeople(group.id));
      // The person may have switched groups while it loaded.
      if (_selectedGroup.value?.id == group.id) {
        _setList(_historyMembers, members);
      }
      return members;
    } catch (e) {
      debugPrint('[GroupMap] Could not read the history of ${group.id}: $e');
      final history = _historyMembers.value;
      return history.isEmpty ? _observedMembers.value : history;
    }
  }

  @override
  void toggleHighlight(GroupMember member) {
    final current = _highlightedObservedUsers.value;
    _setList(
      _highlightedObservedUsers,
      isHighlighted(member)
          ? [
              for (final m in current)
                if (m.email != member.email) m,
            ]
          : [...current, member],
    );
  }

  @override
  bool isHighlighted(GroupMember member) =>
      _highlightedObservedUsers.value.any((m) => m.email == member.email);

  @override
  void toggleSelected(String email) {
    _set(
      _selectedMemberEmail,
      _selectedMemberEmail.value == email ? null : email,
    );
  }

  @override
  void clearSelected() => _set(_selectedMemberEmail, null);

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

  /// Cancels every Firestore subscription and releases the values. Only
  /// the first call does anything.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _cancelAll();
    for (final notifier in <ChangeNotifier>[
      _capabilities,
      _isLoading,
      _loadError,
      _mapGroups,
      _publishGroups,
      _selectedGroup,
      _switchingGroup,
      _groupPositions,
      _observedMembers,
      _historyMembers,
      _groupSizes,
      _highlightedObservedUsers,
      _selectedMemberEmail,
    ]) {
      notifier.dispose();
    }
  }
}
