import 'package:flutter/material.dart';
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
    appBar: adminAppBar('Novo grupo'),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Criar um grupo',
          style: TextStyle(
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
            labelText: 'Nome do grupo',
            hintText: 'Ex.: Motoristas',
            errorText: problem,
            helperText: 'É assim que o grupo aparece no mapa e nos convites.',
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
          child: const Text(
            'Você administra a organização, então já vê todos os grupos no '
            'mapa. O grupo nasce vazio: depois de criar, convide quem vai '
            'fazer parte dele.',
            style: TextStyle(fontSize: 13, height: 1.45, color: _muted),
          ),
        ),
        const Spacer(),
        adminErrorText(c.state.errorMessage),
        adminPrimaryButton(
          label: 'Criar grupo',
          busy: busy,
          busyLabel: 'Criando…',
          onPressed: c.canCreate(typed)
              ? () => c.create.execute(typed.trim())
              : null,
        ),
      ],
    );
  }

  Widget _done(Group group) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Spacer(),
      Icon(Icons.check_circle, size: 56, color: adminPalette.primary),
      const SizedBox(height: 16),
      Text(
        'Grupo criado',
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: _ink,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        '${group.name} ainda não tem ninguém. Convide as pessoas que vão '
        'trabalhar nele e escolha o que cada uma faz no app.',
        style: TextStyle(fontSize: 15, height: 1.45, color: _muted),
      ),
      const Spacer(),
      adminPrimaryButton(
        label: 'Ver o grupo',
        busy: false,
        busyLabel: '',
        onPressed: () =>
            context.pushReplacement(Routes.group(group.id), extra: c),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Voltar'),
      ),
    ],
  );
}
