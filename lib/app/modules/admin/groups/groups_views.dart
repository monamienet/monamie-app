import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/config/organization/organization.dart';
import 'package:monamie_app/app/config/organization/organization_palette.dart';

import 'package:monamie_app/app/modules/invites/firebase_invites_backend.dart';
import 'package:monamie_app/app/modules/invites/invite.dart';
import 'package:monamie_app/app/modules/invites/invite_controller.dart';
import 'package:monamie_app/app/modules/invites/invite_view.dart';
import 'package:monamie_app/app/modules/invites/invites_backend.dart';

import 'group.dart';
import 'groups_controller.dart';

const _ink = Color(0xFF1B1838);
const _muted = Color(0xFF4A4858);
const _soft = Color(0xFFF1F0F4);
const _line = Color(0xFFECEAF0);
const _cardLine = Color(0xFFDDD9E4);
const _fieldLine = Color(0xFFB9B4C9);
const _dangerLine = Color(0xFFE8B4AF);
const _handle = Color(0xFFC9C3D6);
const _error = Color(0xFFB3261E);

OrganizationPalette get _palette =>
    OrganizationPalette.fromConfig(Organization.current);

AppBar _bar(String title) => AppBar(
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
);

Widget _primaryButton({
  required String label,
  required bool busy,
  required String busyLabel,
  required VoidCallback? onPressed,
  IconData? icon,
}) => SizedBox(
  width: double.infinity,
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
  final initial = name.replaceFirst(RegExp(r'^Grupo\s+'), '');
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

/// *Grupos*: every group of the organization for an administrator, or the
/// groups a maintainer (*Gestor do grupo*) maintains.
class GroupsView extends StatelessWidget {
  const GroupsView({super.key, required this.controller});

  final GroupsController controller;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: _bar('Grupos'),
    body: Column(
      children: [
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value && controller.groups.isEmpty) {
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
                  if (controller.groups.isEmpty &&
                      controller.errorMessage.value.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                      child: Text(
                        controller.isAdmin
                            ? 'Sua organização ainda não tem grupos. Crie o '
                                  'primeiro e convide quem vai trabalhar nele.'
                            : 'Você não é gestor de nenhum grupo agora.',
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.45,
                          color: _muted,
                        ),
                      ),
                    ),
                  for (final group in controller.groups) _groupRow(group),
                ],
              ),
            );
          }),
        ),
        // Only administrators create groups.
        if (controller.isAdmin)
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _line)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 32),
              child: _primaryButton(
                label: 'Criar grupo',
                busy: false,
                busyLabel: '',
                icon: Icons.add,
                onPressed: () =>
                    Get.to(() => CreateGroupView(controller: controller)),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _groupRow(Group group) => InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: () =>
        Get.to(() => GroupView(controller: controller, groupId: group.id)),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            _initialTile(group.name, size: 40, fontSize: 15),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
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
                    group.peopleLabel,
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

/// *Criar grupo*: a name, checked as it is typed; the server gives the
/// group its id.
class CreateGroupView extends StatefulWidget {
  const CreateGroupView({super.key, required this.controller});

  final GroupsController controller;

  @override
  State<CreateGroupView> createState() => _CreateGroupViewState();
}

class _CreateGroupViewState extends State<CreateGroupView> {
  final _name = TextEditingController();
  Group? _created;

  GroupsController get c => widget.controller;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: _bar('Novo grupo'),
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
            'Você administra a organização, então já vê todos os grupos no '
            'mapa. O grupo nasce vazio: depois de criar, convide quem vai '
            'fazer parte dele.',
            style: TextStyle(fontSize: 13, height: 1.45, color: _muted),
          ),
        ),
        const Spacer(),
        _errorText(c.errorMessage.value),
        _primaryButton(
          label: 'Criar grupo',
          busy: busy,
          busyLabel: 'Criando…',
          onPressed: typed.isEmpty || problem != null
              ? null
              : () async {
                  final group = await c.create(typed);
                  if (group != null && mounted) {
                    setState(() => _created = group);
                  }
                },
        ),
      ],
    );
  });

  Widget _done(Group group) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Spacer(),
      Icon(Icons.check_circle, size: 56, color: _palette.primary),
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
      _primaryButton(
        label: 'Ver o grupo',
        busy: false,
        busyLabel: '',
        onPressed: () =>
            Get.off(() => GroupView(controller: c, groupId: group.id)),
      ),
      TextButton(onPressed: Get.back, child: const Text('Voltar')),
    ],
  );
}

/// Darker than primary, for the role lines (the prototype's #0B6A66 on the
/// default theme).
Color get _roleTone => Color.lerp(_palette.primary, _palette.dark, 0.3)!;

String get _organization => Organization.current?.name ?? 'organização';

/// A bottom sheet with [title], optional [content] and [lines], and a
/// confirm button that runs [onConfirm] (an error message, or `null` on
/// success). While it runs the sheet cannot close and the button shows
/// [busyLabel]; a failure stays in the sheet. Returns whether it succeeded.
Future<bool> _actionSheet({
  required String title,
  required String confirmLabel,
  required String busyLabel,
  required Future<String?> Function() onConfirm,
  bool danger = false,
  List<String> lines = const [],
  Widget Function(StateSetter setSheet, bool busy)? content,
  bool Function()? canConfirm,
}) async {
  var busy = false;
  var error = '';
  final done = await Get.bottomSheet<bool>(
    StatefulBuilder(
      builder: (context, setSheet) {
        final tone = danger ? _error : _palette.primary;
        final onTone = danger ? Colors.white : _palette.onPrimary;
        final allowed = canConfirm?.call() ?? true;
        Future<void> confirm() async {
          if (busy || !allowed) return;
          setSheet(() {
            busy = true;
            error = '';
          });
          String? problem;
          try {
            problem = await onConfirm();
          } finally {
            if (context.mounted) setSheet(() => busy = false);
          }
          if (!context.mounted) return;
          if (problem == null) {
            Navigator.of(context).pop(true);
          } else {
            setSheet(() => error = problem!);
          }
        }

        return PopScope(
          canPop: !busy,
          child: Container(
            padding: EdgeInsets.fromLTRB(
              24,
              8,
              24,
              32 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _handle,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.44,
                      color: _ink,
                    ),
                  ),
                  if (content != null) ...[
                    const SizedBox(height: 16),
                    content(setSheet, busy),
                  ],
                  if (lines.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    for (final (i, line) in lines.indexed)
                      Padding(
                        padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(
                              width: 20,
                              child: Text('•', style: _sheetLine),
                            ),
                            Expanded(child: Text(line, style: _sheetLine)),
                          ],
                        ),
                      ),
                  ],
                  if (error.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      error,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 19 / 13,
                        fontWeight: FontWeight.w800,
                        color: _error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: tone,
                        foregroundColor: onTone,
                        disabledBackgroundColor: busy
                            ? tone.withValues(alpha: 0.8)
                            : _line,
                        disabledForegroundColor: busy ? onTone : _muted,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onPressed: busy || !allowed ? null : confirm,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (busy) ...[
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: onTone,
                                backgroundColor: onTone.withValues(alpha: 0.35),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          Text(busy ? busyLabel : confirmLabel),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 48,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: _ink,
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onPressed: busy ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
    isScrollControlled: true,
    // Dragging would close the sheet past PopScope while an operation runs.
    enableDrag: false,
    barrierColor: const Color(0x8C091416),
  );
  return done == true;
}

const _sheetLine = TextStyle(
  fontSize: 15,
  height: 22 / 15,
  fontWeight: FontWeight.w500,
  color: _muted,
);

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        backgroundColor: _ink,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 3),
      ),
    );
}

/// *Grupo*: the group's people and pending invites in two tabs; rename,
/// change roles, remove, resend or cancel invites, and (administrators
/// only) delete the group.
class GroupView extends StatefulWidget {
  const GroupView({
    super.key,
    required this.controller,
    required this.groupId,
    this.invitesBackend = const FirebaseInvitesBackend(),
  });

  final GroupsController controller;
  final String groupId;
  final InvitesBackend invitesBackend;

  @override
  State<GroupView> createState() => _GroupViewState();
}

class _GroupViewState extends State<GroupView> {
  bool _onInvites = false;
  List<Invite>? _invites;
  String _invitesError = '';
  bool _loadingImpact = false;

  /// Set once the group is deleted: its name and how many lost access.
  ({String name, int loses})? _deleted;

  GroupsController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    _loadInvites();
  }

  Future<void> _loadInvites() async {
    try {
      final invites = await widget.invitesBackend.listForGroup(
        c.organizationId,
        widget.groupId,
      );
      if (mounted) {
        setState(() {
          _invites = invites;
          _invitesError = '';
        });
      }
    } catch (e) {
      debugPrint('[Groups] Could not load invites: $e');
      if (mounted) {
        setState(
          () => _invitesError = 'Não foi possível carregar os convites.',
        );
      }
    }
  }

  /// The controller's message for a failed operation.
  String get _failure => c.errorMessage.value.isEmpty
      ? 'Não foi possível concluir agora. Tente de novo.'
      : c.errorMessage.value;

  @override
  Widget build(BuildContext context) => Obx(() {
    final deleted = _deleted;
    if (deleted != null) return _deletedScreen(deleted);
    final group = c.byId(widget.groupId);
    if (group == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: _bar('Grupo'),
        body: const Center(child: Text('Grupo não encontrado.')),
      );
    }
    final invites = _invites;
    final pending = pendingInvitesLabel(invites?.length ?? 0);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _bar('Grupo'),
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
                  group.peopleLabel,
                  if (pending.isNotEmpty) pending,
                ].join(' · '),
              ),
              const SizedBox(height: 20),
              _tabs(group.people.length, invites?.length),
              const SizedBox(height: 20),
              // Loose height: a short list keeps its size, a long one
              // scrolls inside the card.
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: _onInvites
                      ? _invitesCard(invites)
                      : _membersCard(group),
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
  });

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
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_outlined, size: 16),
              SizedBox(width: 6),
              Text('Renomear'),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _tabs(int members, int? invites) {
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
          tab('No grupo · $members', !_onInvites, false),
          tab('Convidados · ${invites ?? '…'}', _onInvites, true),
        ],
      ),
    );
  }

  /// The bordered list both tabs share; [empty] shows when [rows] is empty.
  Widget _card(List<Widget> rows, String empty) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _cardLine),
    ),
    child: rows.isEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Text(
              empty,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 21 / 14,
                fontWeight: FontWeight.w500,
                color: _muted,
              ),
            ),
          )
        : ListView(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            children: [
              for (final (i, row) in rows.indexed)
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: i == 0
                        ? null
                        : const Border(top: BorderSide(color: _line)),
                  ),
                  child: row,
                ),
            ],
          ),
  );

  Widget _membersCard(Group group) => _card([
    for (final person in group.people)
      _personRow(
        initials: initialsOf(person.email),
        title: person.email,
        roles: groupRolesLabel(person.roles),
        member: true,
        onEditRoles: () => _editRoles(group, person),
        // A maintainer cannot remove another *Gestor do grupo*.
        actionText: c.canRemove(person) ? 'Remover' : null,
        onAction: c.canRemove(person) ? () => _remove(group, person) : null,
      ),
  ], 'Ninguém neste grupo ainda. Convide quem vai trabalhar nele.');

  Widget _invitesCard(List<Invite>? invites) {
    if (invites == null) {
      return _invitesError.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          : _card(const [], _invitesError);
    }
    return _card([
      for (final invite in invites)
        _personRow(
          initials: initialsOf(invite.email),
          title: invite.email,
          detail: invite.statusLabel,
          expired: invite.expired,
          roles: invite.rolesLabel,
          member: false,
          actionText: invite.expired ? 'Reenviar' : 'Cancelar',
          onAction: () =>
              invite.expired ? _resend(invite) : _cancelInvite(invite),
        ),
    ], 'Nenhum convite pendente.');
  }

  Widget _personRow({
    required String initials,
    required String title,
    required String roles,
    required bool member,
    String? actionText,
    VoidCallback? onAction,
    String detail = '',
    bool expired = false,
    VoidCallback? onEditRoles,
  }) {
    final roleLine = Row(
      children: [
        Flexible(
          child: Text(
            roles,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: _roleTone,
            ),
          ),
        ),
        if (onEditRoles != null) ...[
          const SizedBox(width: 4),
          Icon(Icons.edit_outlined, size: 12, color: _roleTone),
        ],
      ],
    );
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        if (detail.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: expired ? FontWeight.w800 : FontWeight.w500,
              color: expired ? _error : _muted,
            ),
          ),
        ],
        const SizedBox(height: 2),
        roleLine,
      ],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: member ? _palette.primary : _soft,
              border: member ? null : Border.all(color: _fieldLine, width: 1.5),
            ),
            child: Text(
              initials,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: member ? _palette.onPrimary : _muted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: onEditRoles == null
                ? text
                : Semantics(
                    button: true,
                    label: 'Mudar o que $title faz',
                    child: InkWell(onTap: onEditRoles, child: text),
                  ),
          ),
          const SizedBox(width: 12),
          if (actionText != null && onAction != null)
            SizedBox(
              height: 44,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: expired
                      ? _palette.light
                      : Colors.transparent,
                  foregroundColor: expired ? _palette.dark : _error,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onPressed: onAction,
                child: Text(actionText),
              ),
            ),
        ],
      ),
    );
  }

  Widget _inviteButton() => SizedBox(
    height: 52,
    child: TextButton(
      style: TextButton.styleFrom(
        backgroundColor: _palette.light,
        foregroundColor: _palette.dark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      ),
      onPressed: () async {
        await openInvite(c, groupId: widget.groupId);
        await _loadInvites();
      },
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_add_alt, size: 20),
          SizedBox(width: 8),
          Text('Convidar para este grupo'),
        ],
      ),
    ),
  );

  Widget _deleteButton(Group group) => SizedBox(
    height: 52,
    child: OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: _error,
        side: const BorderSide(color: _dangerLine, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      ),
      onPressed: _loadingImpact ? null : () => _delete(group),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_loadingImpact)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: _error),
            )
          else
            const Icon(Icons.delete_outline, size: 18),
          const SizedBox(width: 8),
          const Text('Excluir grupo'),
        ],
      ),
    ),
  );

  Widget _deletedScreen(({String name, int loses}) deleted) => Scaffold(
    backgroundColor: Colors.white,
    appBar: _bar('Grupo'),
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
                child: const Icon(Icons.delete_outline, size: 30, color: _ink),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Grupo excluído',
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
              deletedGroupText(
                loses: deleted.loses,
                organization: _organization,
              ),
              style: const TextStyle(
                fontSize: 16,
                height: 24 / 16,
                fontWeight: FontWeight.w500,
                color: _muted,
              ),
            ),
            const Spacer(),
            _primaryButton(
              label: 'Ver grupos',
              busy: false,
              busyLabel: '',
              onPressed: Get.back,
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _rename(Group group) async {
    final field = TextEditingController(text: group.name);
    String typed() => field.text.replaceAll(RegExp(r'\s+'), ' ').trim();
    String? problem() =>
        typed().isEmpty ? null : c.nameProblem(typed(), renaming: group.id);
    final ok = await _actionSheet(
      title: 'Renomear grupo',
      confirmLabel: 'Salvar nome',
      busyLabel: 'Salvando…',
      canConfirm: () =>
          typed().isNotEmpty && typed() != group.name && problem() == null,
      onConfirm: () async =>
          await c.rename(group.id, typed()) ? null : _failure,
      content: (setSheet, busy) {
        final invalid = problem() != null;
        OutlineInputBorder border(Color color, double width) =>
            OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: color, width: width),
            );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Nome do grupo',
              style: TextStyle(
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
              problem() ?? 'As pessoas do grupo veem o novo nome na hora.',
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
    if (ok && mounted) _toast(context, 'Grupo renomeado');
  }

  Future<void> _editRoles(Group group, GroupPerson person) async {
    final roles = {...person.roles};
    final choices = c.assignableRoles;
    String? problem() => rolesChoiceProblem(roles, byAdmin: c.isAdmin);
    final ok = await _actionSheet(
      title: 'O que ${person.email} faz',
      confirmLabel: 'Salvar',
      busyLabel: 'Salvando…',
      canConfirm: () =>
          problem() == null &&
          !(roles.length == person.roles.length &&
              roles.containsAll(person.roles)),
      onConfirm: () async =>
          await c.setRoles(group.id, person.email, roles) ? null : _failure,
      content: (setSheet, busy) {
        Widget tappable(GroupRole role) => _roleOption(
          role,
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
              problem() ?? 'A mudança vale na hora.',
              style: TextStyle(
                fontSize: 13,
                height: 19 / 13,
                fontWeight: problem() != null
                    ? FontWeight.w800
                    : FontWeight.w500,
                color: problem() != null ? _error : _muted,
              ),
            ),
          ],
        );
      },
    );
    if (ok && mounted) _toast(context, 'Papel atualizado');
  }

  Widget _roleOption(GroupRole role, {required bool on, VoidCallback? onTap}) =>
      Semantics(
        checked: on,
        child: Material(
          color: on ? _palette.light : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: on
                ? BorderSide(color: _palette.primary, width: 2)
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
                      color: on ? _palette.primary : null,
                      borderRadius: BorderRadius.circular(5),
                      border: on
                          ? null
                          : Border.all(color: _fieldLine, width: 2),
                    ),
                    child: on
                        ? Icon(Icons.check, size: 12, color: _palette.onPrimary)
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
                            color: _palette.dark,
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

  Future<void> _remove(Group group, GroupPerson person) async {
    final ok = await _actionSheet(
      title: 'Remover ${person.email} de ${group.name}?',
      confirmLabel: 'Remover',
      busyLabel: 'Removendo…',
      danger: true,
      lines: [
        'Se este for o único grupo da pessoa, o acesso à $_organization '
            'acaba (a não ser que ela administre a organização).',
        'Deixa de aparecer no mapa deste grupo e de ver quem está nele.',
        'Os trajetos antigos continuam no histórico.',
      ],
      onConfirm: () async =>
          await c.remove(group.id, person.email) ? null : _failure,
    );
    if (ok && mounted) {
      _toast(context, '${person.email} não faz mais parte do grupo');
    }
  }

  /// Runs an invite operation for [_actionSheet]: an error message or
  /// `null`, then reloads the invites.
  Future<String?> _inviteOperation(Future<void> Function() operation) async {
    try {
      await operation();
    } on InvitesException catch (e) {
      return e.message;
    } catch (e) {
      debugPrint('[Groups] Invite operation failed: $e');
      return 'Não foi possível concluir agora. Verifique a conexão e tente '
          'de novo.';
    }
    await _loadInvites();
    return null;
  }

  Future<void> _resend(Invite invite) async {
    final ok = await _actionSheet(
      title: 'Reenviar o convite?',
      confirmLabel: 'Reenviar convite',
      busyLabel: 'Reenviando…',
      lines: [
        '${invite.email} recebe um novo e-mail.',
        'O novo convite vale por 14 dias.',
      ],
      onConfirm: () => _inviteOperation(
        () => widget.invitesBackend.resend(c.organizationId, invite.id),
      ),
    );
    if (ok && mounted) _toast(context, 'Convite reenviado');
  }

  Future<void> _cancelInvite(Invite invite) async {
    final ok = await _actionSheet(
      title: 'Cancelar o convite?',
      confirmLabel: 'Cancelar convite',
      busyLabel: 'Cancelando…',
      danger: true,
      lines: [
        'O link enviado para ${invite.email} deixa de funcionar.',
        'Você pode convidar de novo depois.',
      ],
      onConfirm: () => _inviteOperation(
        () => widget.invitesBackend.cancel(c.organizationId, invite.id),
      ),
    );
    if (ok && mounted) _toast(context, 'Convite cancelado');
  }

  Future<void> _delete(Group group) async {
    if (_loadingImpact) return;
    setState(() => _loadingImpact = true);
    ({List<String> loses, List<String> stays})? impact;
    try {
      impact = await c.deletionImpact(group.id);
    } finally {
      if (mounted) setState(() => _loadingImpact = false);
    }
    if (!mounted) return;
    if (impact == null) {
      _toast(context, _failure);
      return;
    }
    final loses = impact.loses.length;
    await _actionSheet(
      title: 'Excluir ${group.name}?',
      confirmLabel: 'Excluir grupo',
      busyLabel: 'Excluindo…',
      danger: true,
      lines: groupDeletionLines(
        loses: loses,
        stays: impact.stays.length,
        invites: _invites?.length ?? 0,
        organization: _organization,
      ),
      onConfirm: () async {
        if (!await c.delete(group.id)) return _failure;
        // Set before the next frame: the group is already gone from the list.
        if (mounted) {
          setState(() => _deleted = (name: group.name, loses: loses));
        }
        return null;
      },
    );
  }
}

/// Opens *Convidar pessoas* for the organization's groups (preselecting
/// [groupId]); completes after the groups are reloaded.
Future<void> openInvite(GroupsController controller, {String? groupId}) async {
  await Get.to(
    () => InviteView(
      controller: InviteController(
        organizationId: controller.organizationId,
        organizationName:
            Organization.current?.name ?? controller.organizationId,
        groups: controller.groups.toList(),
        groupId: groupId,
        backend: const FirebaseInvitesBackend(),
        canCreateFirstGroup: controller.isAdmin,
      ),
    ),
  );
  await controller.load();
}

/// The administration screens' app bar, for the other admin screens.
AppBar adminAppBar(String title) => _bar(title);

/// The administration screens' confirmation sheet (see the group screens):
/// completes with whether [onConfirm] succeeded; [onConfirm] returns an
/// error message to show in the sheet, or `null`.
Future<bool> adminActionSheet({
  required String title,
  required String confirmLabel,
  required String busyLabel,
  required Future<String?> Function() onConfirm,
  bool danger = false,
  List<String> lines = const [],
}) => _actionSheet(
  title: title,
  confirmLabel: confirmLabel,
  busyLabel: busyLabel,
  onConfirm: onConfirm,
  danger: danger,
  lines: lines,
);

/// The administration screens' short confirmation at the bottom.
void adminToast(BuildContext context, String message) =>
    _toast(context, message);
