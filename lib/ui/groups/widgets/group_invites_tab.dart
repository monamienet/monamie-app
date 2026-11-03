import 'package:flutter/material.dart';

import 'package:monamie_app/domain/models/group.dart';
import 'package:monamie_app/domain/models/invite.dart';
import 'package:monamie_app/ui/core/ui/admin_ui.dart';
import 'package:monamie_app/ui/groups/view_models/group_invites_view_model.dart';
import 'group_list.dart';

/// The *Convidados* tab of *Grupo*: the group's pending invites, with
/// *Reenviar* for an expired one and *Cancelar* for the others. Its parent
/// rebuilds it when [invites] changes.
class GroupInvitesTab extends StatelessWidget {
  const GroupInvitesTab({super.key, required this.invites});

  final GroupInvitesViewModel invites;

  @override
  Widget build(BuildContext context) {
    final state = invites.state;
    final list = state.invites;
    if (list == null) {
      return state.errorMessage.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          : GroupListCard(rows: const [], empty: state.errorMessage);
    }
    return GroupListCard(
      rows: [
        for (final invite in list)
          GroupPersonRow(
            initials: initialsOf(invite.email),
            title: invite.email,
            detail: invite.statusLabel,
            expired: invite.expired,
            roles: invite.rolesLabel,
            member: false,
            actionText: invite.expired ? 'Reenviar' : 'Cancelar',
            onAction: () => invite.expired
                ? _resend(context, invite)
                : _cancel(context, invite),
          ),
      ],
      empty: 'Nenhum convite pendente.',
    );
  }

  Future<void> _resend(BuildContext context, Invite invite) async {
    final ok = await adminActionSheet(
      context,
      title: 'Reenviar o convite?',
      confirmLabel: 'Reenviar convite',
      busyLabel: 'Reenviando…',
      lines: [
        '${invite.email} recebe um novo e-mail.',
        'O novo convite vale por 14 dias.',
      ],
      onConfirm: () async =>
          sheetFailureOf(await invites.resend.execute(invite)),
    );
    if (ok && context.mounted) adminToast(context, 'Convite reenviado');
  }

  Future<void> _cancel(BuildContext context, Invite invite) async {
    final ok = await adminActionSheet(
      context,
      title: 'Cancelar o convite?',
      confirmLabel: 'Cancelar convite',
      busyLabel: 'Cancelando…',
      danger: true,
      lines: [
        'O link enviado para ${invite.email} deixa de funcionar.',
        'Você pode convidar de novo depois.',
      ],
      onConfirm: () async =>
          sheetFailureOf(await invites.cancel.execute(invite)),
    );
    if (ok && context.mounted) adminToast(context, 'Convite cancelado');
  }
}
