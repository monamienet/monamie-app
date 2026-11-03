import 'package:flutter/material.dart';

import 'package:monamie_app/domain/models/group.dart';
import 'package:monamie_app/ui/core/ui/admin_ui.dart';
import 'package:monamie_app/ui/groups/view_models/groups_view_model.dart';
import 'group_list.dart';

const _muted = AdminColors.muted;
const _cardLine = AdminColors.cardLine;
const _fieldLine = AdminColors.fieldLine;
const _error = AdminColors.error;

/// The *No grupo* tab of *Grupo*: the group's people, each with their
/// roles (tap to change them) and *Remover* when the person may remove them.
class GroupPeopleTab extends StatelessWidget {
  const GroupPeopleTab({
    super.key,
    required this.controller,
    required this.group,
  });

  final GroupsViewModel controller;
  final Group group;

  @override
  Widget build(BuildContext context) => GroupListCard(
    rows: [
      for (final person in group.people)
        GroupPersonRow(
          initials: initialsOf(person.email),
          title: person.email,
          roles: groupRolesLabel(person.roles),
          member: true,
          onEditRoles: () => _editRoles(context, person),
          // A maintainer cannot remove another *Gestor do grupo*.
          actionText: controller.canRemove(person) ? 'Remover' : null,
          onAction: controller.canRemove(person)
              ? () => _remove(context, person)
              : null,
        ),
    ],
    empty: 'Ninguém neste grupo ainda. Convide quem vai trabalhar nele.',
  );

  Future<void> _editRoles(BuildContext context, GroupPerson person) async {
    final c = controller;
    // The choice being made in the sheet, before it is saved.
    final roles = {...person.roles};
    final choices = c.assignableRoles;
    final ok = await adminActionSheet(
      context,
      title: 'O que ${person.email} faz',
      confirmLabel: 'Salvar',
      busyLabel: 'Salvando…',
      canConfirm: () => c.canSetRoles(person, roles),
      onConfirm: () async => sheetFailureOf(
        await c.setRoles.execute((
          groupId: group.id,
          email: person.email,
          roles: {...roles},
        )),
      ),
      content: (setSheet, busy) {
        final problem = c.rolesProblem(roles);
        Widget tappable(GroupRole role) => _RoleOption(
          role: role,
          on: roles.contains(role),
          onTap: busy
              ? null
              : () => setSheet(
                  () => roles.contains(role)
                      ? roles.remove(role)
                      : roles.add(role),
                ),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, role) in GroupRole.everyday.indexed) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(child: tappable(role)),
                  ],
                ],
              ),
            ),
            // Only administrators give or take *Gestor do grupo*.
            if (choices.contains(GroupRole.maintainer)) ...[
              const SizedBox(height: 10),
              tappable(GroupRole.maintainer),
            ],
            const SizedBox(height: 16),
            Text(
              problem ?? 'A mudança vale na hora.',
              style: TextStyle(
                fontSize: 13,
                height: 19 / 13,
                fontWeight: problem != null ? FontWeight.w800 : FontWeight.w500,
                color: problem != null ? _error : _muted,
              ),
            ),
          ],
        );
      },
    );
    if (ok && context.mounted) adminToast(context, 'Papel atualizado');
  }

  Future<void> _remove(BuildContext context, GroupPerson person) async {
    final ok = await adminActionSheet(
      context,
      title: 'Remover ${person.email} de ${group.name}?',
      confirmLabel: 'Remover',
      busyLabel: 'Removendo…',
      danger: true,
      lines: [
        'Se este for o único grupo da pessoa, o acesso à '
            '$adminOrganizationName acaba (a não ser que ela administre a '
            'organização).',
        'Deixa de aparecer no mapa deste grupo e de ver quem está nele.',
        'Os trajetos antigos continuam no histórico.',
      ],
      onConfirm: () async => sheetFailureOf(
        await controller.remove.execute((
          groupId: group.id,
          email: person.email,
        )),
      ),
    );
    if (ok && context.mounted) {
      adminToast(context, '${person.email} não faz mais parte do grupo');
    }
  }
}

/// One role in the role sheet, a checkbox card with the role's name and
/// what it does.
class _RoleOption extends StatelessWidget {
  const _RoleOption({required this.role, required this.on, this.onTap});

  final GroupRole role;
  final bool on;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = adminPalette;
    return Semantics(
      checked: on,
      child: Material(
        color: on ? palette.light : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: on
              ? BorderSide(color: palette.primary, width: 2)
              : const BorderSide(color: _cardLine),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    color: on ? palette.primary : null,
                    borderRadius: BorderRadius.circular(5),
                    border: on ? null : Border.all(color: _fieldLine, width: 2),
                  ),
                  child: on
                      ? Icon(Icons.check, size: 12, color: palette.onPrimary)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role.label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: palette.dark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        role.description,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 16 / 12,
                          fontWeight: FontWeight.w500,
                          color: _muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
