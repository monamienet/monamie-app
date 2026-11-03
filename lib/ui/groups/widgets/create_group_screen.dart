import 'package:flutter/material.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import 'package:monamie_app/domain/models/group.dart';
import 'package:monamie_app/routing/routes.dart';
import 'package:monamie_app/ui/core/ui/admin_ui.dart';
import 'package:monamie_app/ui/groups/view_models/groups_view_model.dart';
import 'package:monamie_app/utils/result.dart';

const _ink = AdminColors.ink;
const _muted = AdminColors.muted;
const _soft = AdminColors.soft;

/// *Criar grupo*: a name, checked as it is typed; the server gives the
/// group its id. Once [GroupsViewModel.create] worked, the screen shows the
/// group it created.
class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key, required this.controller});

  final GroupsViewModel controller;

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _name = TextEditingController();

  GroupsViewModel get c => widget.controller;

  @override
  void initState() {
    super.initState();
    // The view model outlives this screen: a group created on an earlier
    // visit must not show as created now.
    c.create.clearResult();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: adminAppBar(AppLocalizations.of(context).createGroupTitle),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: ListenableBuilder(
          listenable: Listenable.merge([c, c.create, _name]),
          builder: (context, _) => switch (c.create.result) {
            Ok(value: final group) => _done(group),
            _ => _form(),
          },
        ),
      ),
    ),
  );

  Widget _form() {
    final busy = c.isWorking;
    final typed = _name.text;
    final problem = c.newNameProblem(typed);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.createGroupHeading,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _name,
          enabled: !busy,
          maxLength: 40,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l10n.groupNameLabel,
            hintText: l10n.groupNameHint,
            errorText: problem,
            helperText: l10n.groupNameHelper,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _soft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            l10n.createGroupNote,
            style: const TextStyle(fontSize: 13, height: 1.45, color: _muted),
          ),
        ),
        const Spacer(),
        adminErrorText(c.state.errorMessage),
        adminPrimaryButton(
          label: l10n.createGroupButton,
          busy: busy,
          busyLabel: l10n.commonCreating,
          onPressed: c.canCreate(typed)
              ? () => c.create.execute(typed.trim())
              : null,
        ),
      ],
    );
  }

  Widget _done(Group group) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Icon(Icons.check_circle, size: 56, color: adminPalette.primary),
        const SizedBox(height: 16),
        Text(
          l10n.createGroupDone,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.createGroupDoneBody(group.name),
          style: TextStyle(fontSize: 15, height: 1.45, color: _muted),
        ),
        const Spacer(),
        adminPrimaryButton(
          label: l10n.createGroupOpen,
          busy: false,
          busyLabel: '',
          onPressed: () =>
              context.pushReplacement(Routes.group(group.id), extra: c),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonBack),
        ),
      ],
    );
  }
}
