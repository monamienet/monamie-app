import 'package:flutter/material.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/ui/core/ui/failure_text.dart';
import 'package:monamie_app/ui/core/ui/domain_labels.dart';
import 'package:monamie_app/domain/models/organization/organization.dart';
import 'package:monamie_app/ui/core/themes/organization_palette.dart';
import 'package:monamie_app/domain/models/group.dart';

import 'package:monamie_app/domain/models/invite.dart';
import 'package:monamie_app/ui/invites/view_models/invite_view_model.dart';
import 'package:monamie_app/domain/models/invite_send_result.dart';

const _ink = Color(0xFF1B1838);
const _muted = Color(0xFF4A4858);
const _soft = Color(0xFFF1F0F4);
const _error = Color(0xFFB3261E);

/// *Convidar pessoas*: e-mails, one or both roles each, to a group (or to a
/// first group created in the same step).
class InviteScreen extends StatefulWidget {
  const InviteScreen({super.key, required this.controller});

  final InviteViewModel controller;

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  final _email = TextEditingController();

  InviteViewModel get c => widget.controller;
  OrganizationPalette get palette =>
      OrganizationPalette.fromConfig(Organization.current);

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _add() {
    if (c.add(_email.text)) _email.clear();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: palette.dark,
      foregroundColor: palette.onDark,
      title: Text(AppLocalizations.of(context).invitePeople),
      centerTitle: false,
    ),
    body: SafeArea(
      child: ListenableBuilder(
        listenable: Listenable.merge([c, c.send]),
        builder: (context, _) {
          final result = c.state.result;
          return result == null ? _form() : _sent(result);
        },
      ),
    ),
  );

  Widget _form() {
    final sending = c.send.running;
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            children: [
              if (c.firstGroupMode) ...[
                Text(
                  l10n.inviteFirstGroupTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.inviteFirstGroupBody,
                  style: const TextStyle(fontSize: 13, color: _muted),
                ),
                const SizedBox(height: 8),
                TextField(
                  enabled: !sending,
                  maxLength: 40,
                  decoration: InputDecoration(
                    hintText: l10n.groupNameHint,
                    border: const OutlineInputBorder(),
                    errorText: c.state.firstGroupName.isEmpty
                        ? null
                        : c.firstGroupProblem?.message(l10n),
                  ),
                  onChanged: c.setFirstGroupName,
                ),
              ] else ...[
                Text(
                  l10n.inviteWhichGroup,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: c.state.groupId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final group in c.state.groups)
                      DropdownMenuItem(
                        value: group.id,
                        child: Text(
                          l10n.inviteGroupOption(
                            group.name,
                            l10n.peopleCount(group.people.length),
                          ),
                        ),
                      ),
                  ],
                  onChanged: sending ? null : c.selectGroup,
                ),
              ],
              const SizedBox(height: 20),
              Text(
                l10n.inviteWho,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _email,
                      enabled: !sending,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: InputDecoration(
                        hintText: l10n.inviteEmailHint,
                        border: const OutlineInputBorder(),
                        errorText: c.state.draftFailure?.message(l10n),
                      ),
                      onSubmitted: (_) => _add(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      onPressed: sending ? null : _add,
                      child: Text(l10n.commonAdd),
                    ),
                  ),
                ],
              ),
              if (c.state.people.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  l10n.inviteRolesQuestion,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                for (final person in c.state.people)
                  _personCard(person, sending),
                const SizedBox(height: 4),
                Text(
                  l10n.inviteRolesExplained,
                  style: const TextStyle(fontSize: 12, color: _muted),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _soft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  l10n.inviteHowItWorks,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: _muted,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (c.state.failure case final failure?)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    failure.message(l10n),
                    style: const TextStyle(
                      color: _error,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              SizedBox(
                height: 56,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.primary,
                    foregroundColor: palette.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  onPressed: c.canSend ? c.send.execute : null,
                  child: sending
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: palette.onPrimary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(l10n.inviteSending),
                          ],
                        )
                      : Text(l10n.inviteSend(c.state.people.length)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _personCard(InviteDraft person, bool sending) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDD9E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  person.email,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: l10n.inviteRemovePerson(person.email),
                onPressed: sending ? null : () => c.remove(person),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: [
              for (final role in GroupRole.everyday)
                FilterChip(
                  label: Text(l10n.roleName(role)),
                  selected: person.roles.contains(role),
                  selectedColor: palette.light,
                  onSelected: sending ? null : (_) => c.toggle(person, role),
                ),
            ],
          ),
          if (person.roles.isEmpty)
            Text(
              l10n.inviteNoRole,
              style: const TextStyle(
                color: _error,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }

  Widget _sent(InviteSendResult result) {
    final sent = result.sent;
    final notEmailed = result.notEmailed;
    final skipped = result.skipped;
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      children: [
        Icon(Icons.mark_email_read_outlined, size: 56, color: palette.primary),
        const SizedBox(height: 16),
        Text(
          l10n.inviteSent(sent.length),
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.inviteSentBody(result.groupName),
          style: const TextStyle(fontSize: 15, color: _muted),
        ),
        const SizedBox(height: 16),
        for (final email in sent)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.person_outline),
            title: Text(email),
            subtitle: notEmailed.contains(email)
                ? Text(l10n.inviteNotEmailed)
                : null,
          ),
        for (final entry in skipped.entries)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.info_outline),
            title: Text(entry.key),
            subtitle: Text(entry.value),
          ),
        const SizedBox(height: 16),
        OutlinedButton(onPressed: c.again, child: Text(l10n.inviteMore)),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonBack),
        ),
      ],
    );
  }
}
