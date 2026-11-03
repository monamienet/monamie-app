import 'package:flutter/material.dart';
import 'package:monamie_app/domain/models/organization/organization.dart';
import 'package:monamie_app/ui/core/themes/organization_palette.dart';
import 'package:monamie_app/domain/models/group.dart';
import 'package:monamie_app/ui/core/ui/admin_ui.dart';

import 'package:monamie_app/ui/administrators/view_models/administrators_view_model.dart';

const _ink = Color(0xFF1B1838);
const _muted = Color(0xFF4A4858);
const _soft = Color(0xFFF1F0F4);
const _cardLine = Color(0xFFDDD9E4);
const _line = Color(0xFFECEAF0);
const _error = Color(0xFFB3261E);

OrganizationPalette get _palette =>
    OrganizationPalette.fromConfig(Organization.current);

/// *Administradores*: the owner (*Titular*) sees who administers the
/// organization, appoints a member and turns an administrator back into a
/// member. Shown only to the owner; the server checks the same.
class AdministratorsScreen extends StatefulWidget {
  const AdministratorsScreen({super.key, required this.controller});

  final AdministratorsViewModel controller;

  @override
  State<AdministratorsScreen> createState() => _AdministratorsScreenState();
}

class _AdministratorsScreenState extends State<AdministratorsScreen> {
  AdministratorsViewModel get c => widget.controller;

  @override
  void initState() {
    super.initState();
    c.load.execute();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: adminAppBar('Administradores'),
    body: ListenableBuilder(
      listenable: Listenable.merge([c, c.load]),
      builder: (context, _) {
        final people = c.state.people;
        if (c.load.running &&
            people.administrators.isEmpty &&
            people.members.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: c.load.execute,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            children: [
              const Text(
                'Quem administra cuida de todos os grupos, dos convites, da '
                'aparência e dos ajustes da organização, e vê todos os grupos '
                'no mapa. Só você, titular, escolhe quem administra.',
                style: TextStyle(fontSize: 14, height: 1.45, color: _muted),
              ),
              const SizedBox(height: 16),
              if (c.state.errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    c.state.errorMessage,
                    style: const TextStyle(
                      color: _error,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              _section('Administradores', people.administrators.length),
              _card([
                for (final admin in people.administrators)
                  _row(
                    context,
                    email: admin.email,
                    detail: admin.owner
                        ? 'Titular'
                        : 'Administra a organização',
                    highlighted: true,
                    actionText: admin.owner ? null : 'Tornar membro',
                    onAction: () => _demote(context, admin.email),
                  ),
              ], 'Ninguém administra a organização.'),
              const SizedBox(height: 24),
              _section('Membros', people.members.length),
              _card(
                [
                  for (final email in people.members)
                    _row(
                      context,
                      email: email,
                      detail: 'Membro',
                      highlighted: false,
                      actionText: 'Tornar administrador',
                      onAction: () => _promote(context, email),
                    ),
                ],
                'Ninguém mais na organização ainda. Quem aceitar um convite '
                'para um grupo aparece aqui.',
              ),
            ],
          ),
        );
      },
    ),
  );

  Widget _section(String title, int count) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      '${title.toUpperCase()} · $count',
      style: const TextStyle(
        color: _muted,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.7,
      ),
    ),
  );

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
        : Column(
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

  Widget _row(
    BuildContext context, {
    required String email,
    required String detail,
    required bool highlighted,
    required String? actionText,
    required VoidCallback onAction,
  }) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: highlighted ? _palette.primary : _soft,
          ),
          child: Text(
            initialsOf(email),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: highlighted ? _palette.onPrimary : _muted,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: _palette.dark,
                ),
              ),
            ],
          ),
        ),
        if (actionText != null) ...[
          const SizedBox(width: 8),
          ListenableBuilder(
            listenable: c.setAdministrator,
            builder: (context, _) {
              final working = c.setAdministrator.argument?.email;
              return SizedBox(
                height: 44,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: _palette.dark,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  // One change at a time: every row waits for the one in
                  // flight.
                  onPressed: working == null ? onAction : null,
                  child: working == email
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : Text(actionText),
                ),
              );
            },
          ),
        ],
      ],
    ),
  );

  /// What the sheet shows after a change: nothing when it worked, else its
  /// message (a generic one when the call was ignored).
  Future<String?> _change(String email, {required bool admin}) async =>
      sheetFailureOf(
        await c.setAdministrator.execute((email: email, admin: admin)),
      );

  Future<void> _promote(BuildContext context, String email) async {
    final ok = await adminActionSheet(
      context,
      title: 'Tornar $email administrador?',
      confirmLabel: 'Tornar administrador',
      busyLabel: 'Salvando…',
      lines: const [
        'Passa a ver todos os grupos no mapa e a cuidar dos grupos, dos '
            'convites, da aparência e dos ajustes da organização.',
        'Você pode desfazer depois.',
      ],
      onConfirm: () => _change(email, admin: true),
    );
    if (ok && context.mounted) {
      adminToast(context, '$email agora administra a organização');
    }
  }

  Future<void> _demote(BuildContext context, String email) async {
    final ok = await adminActionSheet(
      context,
      title: 'Tornar $email membro?',
      confirmLabel: 'Tornar membro',
      busyLabel: 'Salvando…',
      danger: true,
      lines: const [
        'Deixa de administrar a organização e de ver os grupos em que não '
            'está.',
        'Continua nos grupos em que já está. Se não estiver em nenhum, '
            'continua na organização sem ver o mapa até ser convidado para '
            'um grupo.',
      ],
      onConfirm: () => _change(email, admin: false),
    );
    if (ok && context.mounted) adminToast(context, '$email agora é membro');
  }
}
