import 'package:flutter/material.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/ui/core/ui/failure_text.dart';

import 'package:monamie_app/domain/models/group.dart';
import 'package:monamie_app/ui/core/ui/admin_ui.dart';
import 'package:monamie_app/ui/core/ui/domain_labels.dart';
import 'package:monamie_app/ui/groups/view_models/group_invites_view_model.dart';
import 'package:monamie_app/ui/groups/view_models/groups_view_model.dart';
import 'package:monamie_app/utils/result.dart';
import 'group_invites_tab.dart';
import 'group_people_tab.dart';
import 'open_invite.dart';

const _ink = AdminColors.ink;
const _muted = AdminColors.muted;
const _soft = AdminColors.soft;
const _fieldLine = AdminColors.fieldLine;
const _dangerLine = AdminColors.dangerLine;
const _error = AdminColors.error;

/// *Grupo*: the group's people ([GroupPeopleTab]) and pending invites
/// ([GroupInvitesTab]) in two tabs; rename, change roles, remove, resend or
/// cancel invites, and (administrators only) delete the group. Once it is
/// deleted ([GroupsState.deleted]) the screen says so.
class GroupScreen extends StatefulWidget {
  const GroupScreen({
    super.key,
    required this.controller,
    required this.groupId,
    required this.invites,
  });

  final GroupsViewModel controller;
  final String groupId;

  /// The group's invites, owned by this screen's route.
  final GroupInvitesViewModel invites;

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  bool _onInvites = false;

  GroupsViewModel get c => widget.controller;
  GroupInvitesViewModel get invites => widget.invites;

  @override
  void initState() {
    super.initState();
    invites.load.execute();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([c, c.deletionImpact, invites]),
    builder: (context, _) {
      final l10n = AppLocalizations.of(context);
      final deleted = c.state.deleted;
      if (deleted != null && deleted.id == widget.groupId) {
        return _deletedScreen(deleted);
      }
      final group = c.byId(widget.groupId);
      if (group == null) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: adminAppBar(l10n.groupTitle),
          body: Center(child: Text(l10n.groupNotFound)),
        );
      }
      final invited = invites.state.invites?.length;
      final pending = l10n.pendingInvitesLabel(invited ?? 0);
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: adminAppBar(l10n.groupTitle),
        // Only the list scrolls: header, tabs and the two buttons stay put.
        body: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(
                  group,
                  [
                    l10n.peopleCount(group.people.length),
                    if (pending.isNotEmpty) pending,
                  ].join(' · '),
                ),
                const SizedBox(height: 20),
                _tabs(group.people.length, invited),
                const SizedBox(height: 20),
                // Loose height: a short list keeps its size, a long one
                // scrolls inside the card.
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: _onInvites
                        ? GroupInvitesTab(invites: invites)
                        : GroupPeopleTab(controller: c, group: group),
                  ),
                ),
                const SizedBox(height: 20),
                _inviteButton(),
                if (c.isAdmin) ...[
                  const SizedBox(height: 12),
                  _deleteButton(group),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );

  Widget _header(Group group, String summary) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group.name,
              style: const TextStyle(
                fontSize: 28,
                height: 1.1,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.84,
                color: _ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              summary,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _muted,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 12),
      SizedBox(
        height: 44,
        child: TextButton(
          style: TextButton.styleFrom(
            backgroundColor: _soft,
            foregroundColor: _ink,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          onPressed: () => _rename(group),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.edit_outlined, size: 16),
              const SizedBox(width: 6),
              Text(AppLocalizations.of(context).groupRename),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _tabs(int members, int? invited) {
    final l10n = AppLocalizations.of(context);
    Widget tab(String label, bool selected, bool invitesTab) => Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        child: GestureDetector(
          onTap: () => setState(() => _onInvites = invitesTab),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: selected
                  ? const [
                      BoxShadow(
                        color: Color(0x261B1838),
                        offset: Offset(0, 1),
                        blurRadius: 3,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: selected ? _ink : _muted,
              ),
            ),
          ),
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _soft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          tab(l10n.groupTabPeople(members), !_onInvites, false),
          tab(l10n.groupTabInvited('${invited ?? '…'}'), _onInvites, true),
        ],
      ),
    );
  }

  Widget _inviteButton() {
    final palette = adminPalette;
    return SizedBox(
      height: 52,
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: palette.light,
          foregroundColor: palette.dark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        onPressed: () async {
          await openInvite(context, c, groupId: widget.groupId);
          await invites.load.execute();
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_add_alt, size: 20),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context).groupInvite),
          ],
        ),
      ),
    );
  }

  Widget _deleteButton(Group group) => SizedBox(
    height: 52,
    child: OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: _error,
        side: const BorderSide(color: _dangerLine, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      ),
      onPressed: c.deletionImpact.running ? null : () => _delete(group),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (c.deletionImpact.running)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: _error),
            )
          else
            const Icon(Icons.delete_outline, size: 18),
          const SizedBox(width: 8),
          Text(AppLocalizations.of(context).groupDelete),
        ],
      ),
    ),
  );

  Widget _deletedScreen(DeletedGroup deleted) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: adminAppBar(l10n.groupTitle),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _soft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    size: 30,
                    color: _ink,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.groupDeleted,
                style: const TextStyle(
                  fontSize: 30,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.9,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.deletedGroupText(
                  loses: deleted.loses,
                  organization: adminOrganizationName(l10n),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  height: 24 / 16,
                  fontWeight: FontWeight.w500,
                  color: _muted,
                ),
              ),
              const Spacer(),
              adminPrimaryButton(
                label: l10n.groupSeeGroups,
                busy: false,
                busyLabel: '',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _rename(Group group) async {
    final field = TextEditingController(text: group.name);
    final l10n = AppLocalizations.of(context);
    final ok = await adminActionSheet(
      context,
      title: l10n.groupRenameTitle,
      confirmLabel: l10n.groupRenameConfirm,
      busyLabel: l10n.commonSaving,
      canConfirm: () => c.canRename(group, field.text),
      onConfirm: () async => sheetFailureOf(
        l10n,
        await c.rename.execute((
          groupId: group.id,
          name: c.tidyName(field.text),
        )),
      ),
      content: (setSheet, busy) {
        final problem = c.renameProblem(group, field.text)?.message(l10n);
        final invalid = problem != null;
        OutlineInputBorder border(Color color, double width) =>
            OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: color, width: width),
            );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.groupNameLabel,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: field,
              enabled: !busy,
              autofocus: true,
              maxLength: 40,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: _ink,
              ),
              decoration: InputDecoration(
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 15,
                ),
                enabledBorder: invalid
                    ? border(_error, 2)
                    : border(_fieldLine, 1.5),
                focusedBorder: invalid
                    ? border(_error, 2)
                    : border(_fieldLine, 1.5),
                disabledBorder: border(_fieldLine, 1.5),
              ),
              onChanged: (_) => setSheet(() {}),
            ),
            const SizedBox(height: 8),
            Text(
              problem ?? l10n.groupRenameNote,
              style: TextStyle(
                fontSize: 13,
                height: 19 / 13,
                fontWeight: invalid ? FontWeight.w800 : FontWeight.w500,
                color: invalid ? _error : _muted,
              ),
            ),
          ],
        );
      },
    );
    field.dispose();
    if (ok && mounted) adminToast(context, l10n.groupRenamed);
  }

  /// Reads who loses access, then asks; once deleted, the view model's
  /// [GroupsState.deleted] turns this screen into *Grupo excluído*.
  Future<void> _delete(Group group) async {
    final l10n = AppLocalizations.of(context);
    final read = await c.deletionImpact.execute(group.id);
    if (!mounted) return;
    if (read is! Ok<({List<String> loses, List<String> stays})>) {
      adminToast(context, sheetFailureOf(l10n, read)!);
      return;
    }
    final impact = read.value;
    await adminActionSheet(
      context,
      title: l10n.groupDeleteTitle(group.name),
      confirmLabel: l10n.groupDelete,
      busyLabel: l10n.groupDeleting,
      danger: true,
      lines: l10n.groupDeletionLines(
        loses: impact.loses.length,
        stays: impact.stays.length,
        invites: invites.state.invites?.length ?? 0,
        organization: adminOrganizationName(l10n),
      ),
      onConfirm: () async =>
          sheetFailureOf(l10n, await c.delete.execute(group.id)),
    );
  }
}
