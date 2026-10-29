import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/config/partner/partner.dart';
import 'package:monamie_app/app/config/partner/partner_palette.dart';

import 'package:monamie_app/app/modules/invites/firebase_invites_backend.dart';
import 'package:monamie_app/app/modules/invites/invite.dart';
import 'package:monamie_app/app/modules/invites/invite_controller.dart';
import 'package:monamie_app/app/modules/invites/invite_view.dart';
import 'package:monamie_app/app/modules/invites/invites_backend.dart';

import 'team.dart';
import 'teams_controller.dart';

const _ink = Color(0xFF1B1838);
const _muted = Color(0xFF4A4858);
const _soft = Color(0xFFF1F0F4);
const _line = Color(0xFFECEAF0);
const _error = Color(0xFFB3261E);

PartnerPalette get _palette => PartnerPalette.fromConfig(Partner.current);

AppBar _bar(String title, {List<Widget>? actions}) => AppBar(
  backgroundColor: _palette.dark,
  foregroundColor: _palette.onDark,
  toolbarHeight: 64,
  title: Text(title),
  titleTextStyle: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: _palette.onDark,
  ),
  centerTitle: false,
  actions: actions,
);

Widget _primaryButton({
  required String label,
  required bool busy,
  required String busyLabel,
  required VoidCallback? onPressed,
  IconData? icon,
}) => SizedBox(
  height: 56,
  child: FilledButton(
    style: FilledButton.styleFrom(
      backgroundColor: _palette.primary,
      foregroundColor: _palette.onPrimary,
      disabledBackgroundColor: _line,
      disabledForegroundColor: _muted,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
    ),
    onPressed: busy ? null : onPressed,
    child: busy
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: _palette.onPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Text(busyLabel),
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          ),
  ),
);

Widget _errorText(String message) => message.isEmpty
    ? const SizedBox.shrink()
    : Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          message,
          style: const TextStyle(color: _error, fontWeight: FontWeight.w800),
        ),
      );

Widget _initialTile(String name, {double size = 44, double? fontSize}) {
  final initial = name.replaceFirst(RegExp(r'^Equipe\s+'), '');
  return Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: _palette.light,
      borderRadius: BorderRadius.circular(size == 40 ? 12 : size * 0.3),
    ),
    child: Text(
      initial.isEmpty ? '?' : initial[0].toUpperCase(),
      style: TextStyle(
        fontSize: fontSize ?? size * 0.42,
        fontWeight: FontWeight.w800,
        color: _palette.dark,
      ),
    ),
  );
}

/// *Equipes*: every team of the organization (owner only).
class TeamsView extends StatelessWidget {
  const TeamsView({super.key, required this.controller});

  final TeamsController controller;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: _bar(
      'Equipes',
      actions: [
        Obx(
          () => Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: Text(
                controller.countLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _palette.light,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
    body: Column(
      children: [
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value && controller.teams.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            return RefreshIndicator(
              onRefresh: controller.load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                children: [
                  if (controller.errorMessage.value.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _errorText(controller.errorMessage.value),
                    ),
                  if (controller.teams.isEmpty)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(12, 8, 12, 24),
                      child: Text(
                        'Sua organização ainda não tem equipes. Crie a '
                        'primeira e convide quem vai trabalhar nela.',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.45,
                          color: _muted,
                        ),
                      ),
                    ),
                  for (final team in controller.teams) _teamRow(team),
                ],
              ),
            );
          }),
        ),
        Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: _line)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 32),
            child: Obx(
              () => _primaryButton(
                label: 'Criar equipe',
                busy: false,
                busyLabel: '',
                icon: Icons.add,
                onPressed: controller.teams.length >= 99
                    ? null
                    : () =>
                          Get.to(() => CreateTeamView(controller: controller)),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _teamRow(Team team) => InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: () =>
        Get.to(() => TeamView(controller: controller, number: team.number)),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            _initialTile(team.name, size: 40, fontSize: 15),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    team.peopleLabel,
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
            const Icon(Icons.chevron_right, size: 20, color: _muted),
          ],
        ),
      ),
    ),
  );
}

/// *Criar equipe*: a name, checked as it is typed; the server picks the
/// next free number.
class CreateTeamView extends StatefulWidget {
  const CreateTeamView({super.key, required this.controller});

  final TeamsController controller;

  @override
  State<CreateTeamView> createState() => _CreateTeamViewState();
}

class _CreateTeamViewState extends State<CreateTeamView> {
  final _name = TextEditingController();
  Team? _created;

  TeamsController get c => widget.controller;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: _bar('Nova equipe'),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: _created == null ? _form() : _done(_created!),
      ),
    ),
  );

  Widget _form() => Obx(() {
    final busy = c.isWorking.value;
    final typed = _name.text.trim();
    final problem = typed.isEmpty ? null : c.nameProblem(typed);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Criar uma equipe',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Uma equipe junta quem trabalha junto. Quem vê o mapa de uma equipe '
          'acompanha só as pessoas dela.',
          style: TextStyle(fontSize: 15, height: 1.45, color: _muted),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _name,
          enabled: !busy,
          maxLength: 40,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: 'Nome da equipe',
            hintText: 'Ex.: Equipe Serra',
            errorText: problem,
            helperText: 'É assim que a equipe aparece no mapa e nos convites.',
            border: const OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _soft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Text(
            'Como responsável, você já vê todas as equipes no mapa. A equipe '
            'nasce vazia: depois de criar, convide quem vai fazer parte dela.',
            style: TextStyle(fontSize: 13, height: 1.45, color: _muted),
          ),
        ),
        const Spacer(),
        _errorText(c.errorMessage.value),
        _primaryButton(
          label: 'Criar equipe',
          busy: busy,
          busyLabel: 'Criando…',
          onPressed: typed.isEmpty || problem != null
              ? null
              : () async {
                  final team = await c.create(typed);
                  if (team != null && mounted) setState(() => _created = team);
                },
        ),
      ],
    );
  });

  Widget _done(Team team) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Spacer(),
      Icon(Icons.check_circle, size: 56, color: _palette.primary),
      const SizedBox(height: 16),
      Text(
        '${team.name} criada',
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: _ink,
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'Ela ainda não tem ninguém. Convide as pessoas que vão trabalhar nela '
        'e escolha o que cada uma faz no app.',
        style: TextStyle(fontSize: 15, height: 1.45, color: _muted),
      ),
      const Spacer(),
      _primaryButton(
        label: 'Ver a equipe',
        busy: false,
        busyLabel: '',
        onPressed: () =>
            Get.off(() => TeamView(controller: c, number: team.number)),
      ),
      TextButton(onPressed: Get.back, child: const Text('Voltar')),
    ],
  );
}

/// *Equipe*: the team's people and their roles; rename and delete.
class TeamView extends StatelessWidget {
  const TeamView({super.key, required this.controller, required this.number});

  final TeamsController controller;
  final String number;

  @override
  Widget build(BuildContext context) => Obx(() {
    final team = controller.byNumber(number);
    final busy = controller.isWorking.value;
    if (team == null) {
      return Scaffold(
        appBar: _bar('Equipe'),
        body: const Center(child: Text('Equipe não encontrada.')),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _bar(
        team.name,
        actions: [
          PopupMenuButton<String>(
            enabled: !busy,
            onSelected: (value) => value == 'rename'
                ? _rename(context, team)
                : _delete(context, team),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'rename', child: Text('Renomear')),
              PopupMenuItem(value: 'delete', child: Text('Excluir equipe')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          if (busy) const LinearProgressIndicator(),
          _errorText(controller.errorMessage.value),
          Text(
            'Na equipe · ${team.peopleLabel}',
            style: const TextStyle(fontWeight: FontWeight.w800, color: _ink),
          ),
          const SizedBox(height: 8),
          if (team.people.isEmpty)
            const Text(
              'Ninguém nesta equipe ainda. Convide quem vai trabalhar nela.',
              style: TextStyle(color: _muted),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: busy
                ? null
                : () => openInvite(controller, team: team.number),
            icon: const Icon(Icons.person_add_alt),
            label: const Text('Convidar para esta equipe'),
          ),
          for (final person in team.people)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(person.email),
              subtitle: Text(
                [
                  for (final r in TeamRole.values)
                    if (person.roles.contains(r)) r.label,
                ].join(' · '),
              ),
              trailing: const Icon(Icons.chevron_right),
              enabled: !busy,
              onTap: () => _editPerson(context, team, person),
            ),
          const SizedBox(height: 24),
          TeamInvitesSection(
            partnerId: controller.partnerId,
            team: team.number,
          ),
        ],
      ),
    );
  });

  Future<void> _editPerson(
    BuildContext context,
    Team team,
    TeamPerson person,
  ) async {
    final roles = {...person.roles};
    await Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) => Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                person.email,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 8),
              for (final role in TeamRole.values)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: roles.contains(role),
                  title: Text(role.label),
                  subtitle: Text(
                    role == TeamRole.share
                        ? 'Compartilha a localização com a equipe'
                        : 'Vê no mapa quem está em campo',
                  ),
                  onChanged: (on) => setState(
                    () => on == true ? roles.add(role) : roles.remove(role),
                  ),
                ),
              if (roles.isEmpty)
                const Text(
                  'Escolha pelo menos um papel, ou remova a pessoa.',
                  style: TextStyle(color: _error, fontWeight: FontWeight.w800),
                ),
              const SizedBox(height: 12),
              _primaryButton(
                label: 'Salvar',
                busy: false,
                busyLabel: '',
                onPressed: roles.isEmpty
                    ? null
                    : () {
                        Get.back();
                        controller.setRoles(team.number, person.email, roles);
                      },
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: _error),
                onPressed: () {
                  Get.back();
                  controller.remove(team.number, person.email);
                },
                child: const Text('Remover da equipe'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _rename(BuildContext context, Team team) async {
    final field = TextEditingController(text: team.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renomear equipe'),
        content: TextField(controller: field, autofocus: true, maxLength: 40),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, field.text),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (name == null) return;
    final problem = controller.nameProblem(name, renaming: team.number);
    if (problem != null) {
      controller.errorMessage.value = problem;
      return;
    }
    await controller.rename(team.number, name);
  }

  Future<void> _delete(BuildContext context, Team team) async {
    final impact = await controller.deletionImpact(team.number);
    if (impact == null || !context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir ${team.name}?'),
        content: Text(
          [
            if (impact.loses.isNotEmpty)
              'Perdem o acesso à organização (não estão em outra equipe): '
                  '${impact.loses.join(', ')}.',
            if (impact.stays.isNotEmpty)
              'Continuam em outras equipes: ${impact.stays.join(', ')}.',
            if (impact.loses.isEmpty && impact.stays.isEmpty)
              'A equipe não tem ninguém.',
            'Os trajetos antigos continuam no histórico.',
          ].join('\n\n'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: _error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed == true && await controller.delete(team.number)) Get.back();
  }
}

/// Opens *Convidar pessoas* for the owner's teams (preselecting [team]).
void openInvite(TeamsController controller, {String? team}) {
  Get.to(
    () => InviteView(
      controller: InviteController(
        partnerId: controller.partnerId,
        partnerName: Partner.current?.name ?? controller.partnerId,
        teams: controller.teams.toList(),
        team: team,
        backend: const FirebaseInvitesBackend(),
      ),
    ),
  )?.then((_) => controller.load());
}

/// *Convidados* of a team: pending invites, expired ones with *Reenviar*,
/// and *Cancelar*.
class TeamInvitesSection extends StatefulWidget {
  const TeamInvitesSection({
    super.key,
    required this.partnerId,
    required this.team,
    this.backend = const FirebaseInvitesBackend(),
  });

  final String partnerId;
  final String team;
  final InvitesBackend backend;

  @override
  State<TeamInvitesSection> createState() => _TeamInvitesSectionState();
}

class _TeamInvitesSectionState extends State<TeamInvitesSection> {
  List<Invite>? _invites;
  String? _working;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final invites = await widget.backend.listForTeam(
        widget.partnerId,
        widget.team,
      );
      if (mounted) setState(() => _invites = invites);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _run(String id, Future<void> Function() action) async {
    if (_working != null) return;
    setState(() {
      _working = id;
      _error = '';
    });
    try {
      await action();
      await _load();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _working = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final invites = _invites;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Convidados${invites == null ? '' : ' · ${invites.length}'}',
          style: const TextStyle(fontWeight: FontWeight.w800, color: _ink),
        ),
        if (_error.isNotEmpty) _errorText(_error),
        if (invites == null)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (invites.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Nenhum convite pendente.',
              style: TextStyle(color: _muted),
            ),
          ),
        for (final invite in invites ?? const <Invite>[])
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(invite.email),
            subtitle: Text(
              invite.expired
                  ? 'Expirado · ${invite.rolesLabel}'
                  : '${invite.rolesLabel}'
                        '${invite.expiresAt == null ? '' : ' · vale até ${dayMonth(invite.expiresAt!)}'}',
            ),
            trailing: _working == invite.id
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : PopupMenuButton<String>(
                    enabled: _working == null,
                    onSelected: (value) => _run(
                      invite.id,
                      () => value == 'resend'
                          ? widget.backend.resend(widget.partnerId, invite.id)
                          : widget.backend.cancel(widget.partnerId, invite.id),
                    ),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'resend', child: Text('Reenviar')),
                      PopupMenuItem(
                        value: 'cancel',
                        child: Text('Cancelar convite'),
                      ),
                    ],
                  ),
          ),
      ],
    );
  }
}
