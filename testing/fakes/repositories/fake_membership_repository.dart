import 'package:flutter/foundation.dart';
import 'package:monamie_app/data/repositories/membership/membership_repository.dart';
import 'package:monamie_app/domain/models/capabilities.dart';
import 'package:monamie_app/domain/models/group_member.dart';
import 'package:monamie_app/domain/models/map_group.dart';
import 'package:monamie_app/domain/models/user_model.dart';

import 'fake_outcomes.dart';

/// [MembershipRepository] whose values are plain [ValueNotifier]s a test
/// sets to drive the widgets (`fake.mapGroups.value = [...]`), as the
/// Firestore listeners would. The actions behave like the real
/// repository's in memory: [pickGroup] switches [selectedGroup] and clears
/// the highlights and the selected marker, the highlight and selection
/// toggles change their values, and the loads record the call and keep
/// what the test set ([groupSizes], [historyMembers]).
class FakeMembershipRepository
    with FakeOutcomes
    implements MembershipRepository {
  @override
  final ValueNotifier<Capabilities> capabilities = ValueNotifier(
    const Capabilities(),
  );

  @override
  bool get isAdmin => capabilities.value.isAdmin;

  @override
  bool get canWatch => capabilities.value.canWatch;

  @override
  bool get canPublish => capabilities.value.canPublish;

  @override
  final ValueNotifier<bool> isLoading = ValueNotifier(false);

  @override
  final ValueNotifier<String> loadError = ValueNotifier('');

  @override
  final ValueNotifier<List<MapGroup>> mapGroups = ValueNotifier(const []);

  @override
  final ValueNotifier<List<MapGroup>> publishGroups = ValueNotifier(const []);

  @override
  final ValueNotifier<MapGroup?> selectedGroup = ValueNotifier(null);

  @override
  final ValueNotifier<bool> switchingGroup = ValueNotifier(false);

  @override
  final ValueNotifier<List<UserModel>> groupPositions = ValueNotifier(const []);

  @override
  final ValueNotifier<List<GroupMember>> observedMembers = ValueNotifier(
    const [],
  );

  @override
  final ValueNotifier<List<GroupMember>> historyMembers = ValueNotifier(
    const [],
  );

  @override
  final ValueNotifier<Map<String, int>> groupSizes = ValueNotifier(const {});

  @override
  final ValueNotifier<List<GroupMember>> highlightedObservedUsers =
      ValueNotifier(const []);

  @override
  final ValueNotifier<String?> selectedMemberEmail = ValueNotifier(null);

  /// Picking the observed group again (or while switching) does nothing.
  @override
  Future<void> pickGroup(MapGroup group) => run('pickGroup', [group], () {
    if (switchingGroup.value || group.id == selectedGroup.value?.id) return;
    selectedGroup.value = group;
    highlightedObservedUsers.value = const [];
    selectedMemberEmail.value = null;
  });

  @override
  Future<void> loadGroupSizes() => run('loadGroupSizes', const [], () {});

  @override
  Future<List<GroupMember>> loadHistoryMembers() =>
      run('loadHistoryMembers', const [], () => historyMembers.value);

  @override
  void toggleHighlight(GroupMember member) {
    calls.add((method: 'toggleHighlight', arguments: [member]));
    final current = highlightedObservedUsers.value;
    highlightedObservedUsers.value = isHighlighted(member)
        ? [...current.where((m) => m.email != member.email)]
        : [...current, member];
  }

  @override
  bool isHighlighted(GroupMember member) =>
      highlightedObservedUsers.value.any((m) => m.email == member.email);

  @override
  void toggleSelected(String email) {
    calls.add((method: 'toggleSelected', arguments: [email]));
    selectedMemberEmail.value = selectedMemberEmail.value == email
        ? null
        : email;
  }

  @override
  void clearSelected() {
    calls.add((method: 'clearSelected', arguments: const []));
    selectedMemberEmail.value = null;
  }

  /// Releases the values.
  void dispose() {
    for (final notifier in <ChangeNotifier>[
      capabilities,
      isLoading,
      loadError,
      mapGroups,
      publishGroups,
      selectedGroup,
      switchingGroup,
      groupPositions,
      observedMembers,
      historyMembers,
      groupSizes,
      highlightedObservedUsers,
      selectedMemberEmail,
    ]) {
      notifier.dispose();
    }
  }
}
