import 'package:flutter/material.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/ui/core/ui/failure_text.dart';

import 'package:monamie_app/domain/models/group.dart';
import 'package:monamie_app/domain/models/invite.dart';
import 'package:monamie_app/ui/core/ui/admin_ui.dart';
import 'package:monamie_app/ui/core/ui/domain_labels.dart';
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
    final l10n = AppLocalizations.of(context);
    final state = invites.state;
    final list = state.invites;
    if (list == null) {
      return switch (state.failure) {
        null => const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
        final failure => GroupListCard(
          rows: const [],
          empty: failure.message(l10n),
        ),
      };
    }
    return GroupListCard(
      rows: [
        for (final invite in list)
          GroupPersonRow(
            initials: initialsOf(invite.email),
            title: invite.email,
            detail: l10n.inviteStatus(invite),
            expired: invite.expired,
            roles: l10n.rolesLabel(invite.roles),
            member: false,
            actionText: invite.expired ? l10n.invitesResend : l10n.commonCancel,
            onAction: () => invite.expired
                ? _resend(context, invite)
                : _cancel(context, invite),
          ),
      ],
      empty: l10n.invitesNone,
    );
  }

  Future<void> _resend(BuildContext context, Invite invite) async {
    final l10n = AppLocalizations.of(context);
    final ok = await adminActionSheet(
      context,
      title: l10n.invitesResendTitle,
      confirmLabel: l10n.invitesResendConfirm,
      busyLabel: l10n.invitesResending,
      lines: [l10n.invitesResendEmail(invite.email), l10n.invitesResendValid],
      onConfirm: () async =>
          sheetFailureOf(l10n, await invites.resend.execute(invite)),
    );
    if (ok && context.mounted) adminToast(context, l10n.invitesResent);
  }

  Future<void> _cancel(BuildContext context, Invite invite) async {
    final l10n = AppLocalizations.of(context);
    final ok = await adminActionSheet(
      context,
      title: l10n.invitesCancelTitle,
      confirmLabel: l10n.invitesCancelConfirm,
      busyLabel: l10n.invitesCancelling,
      danger: true,
      lines: [l10n.invitesCancelLink(invite.email), l10n.invitesInviteAgain],
      onConfirm: () async =>
          sheetFailureOf(l10n, await invites.cancel.execute(invite)),
    );
    if (ok && context.mounted) adminToast(context, l10n.invitesCancelled);
  }
}
