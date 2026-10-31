import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/config/organization/organization.dart';
import 'package:monamie_app/app/config/organization/organization_palette.dart';
import 'package:monamie_app/app/modules/admin/groups/group.dart';

import 'invite.dart';
import 'invite_controller.dart';
import 'invites_backend.dart';

const _ink = Color(0xFF1B1838);
const _muted = Color(0xFF4A4858);
const _soft = Color(0xFFF1F0F4);
const _error = Color(0xFFB3261E);

/// *Convidar pessoas*: e-mails, one or both roles each, to a group (or to a
/// first group created in the same step).
class InviteView extends StatefulWidget {
  const InviteView({super.key, required this.controller});

  final InviteController controller;

  @override
  State<InviteView> createState() => _InviteViewState();
}

class _InviteViewState extends State<InviteView> {
  final _email = TextEditingController();

  InviteController get c => widget.controller;
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
      title: const Text('Convidar pessoas'),
      centerTitle: false,
    ),
    body: SafeArea(
      child: Obx(() {
        final result = c.result.value;
        return result == null ? _form() : _sent(result);
      }),
    ),
  );

  Widget _form() {
    final sending = c.isSending.value;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            children: [
              if (c.firstGroupMode) ...[
                const Text(
                  'Crie seu primeiro grupo',
                  style: TextStyle(fontWeight: FontWeight.w800, color: _ink),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Toda pessoa entra num grupo. Dê um nome para o primeiro; '
                  'você cria outros depois, em Grupos.',
                  style: TextStyle(fontSize: 13, color: _muted),
                ),
                const SizedBox(height: 8),
                TextField(
                  enabled: !sending,
                  maxLength: 40,
                  decoration: InputDecoration(
                    hintText: 'Ex.: Motoristas',
                    border: const OutlineInputBorder(),
                    errorText: c.firstGroupName.value.isEmpty
                        ? null
                        : c.firstGroupProblem,
                  ),
                  onChanged: (v) => c.firstGroupName.value = v,
                ),
              ] else ...[
                const Text(
                  'Para qual grupo?',
                  style: TextStyle(fontWeight: FontWeight.w800, color: _ink),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: c.groupId.value,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final group in c.groups)
                      DropdownMenuItem(
                        value: group.id,
                        child: Text('${group.name} · ${group.peopleLabel}'),
                      ),
                  ],
                  onChanged: sending ? null : (v) => c.groupId.value = v,
                ),
              ],
              const SizedBox(height: 20),
              const Text(
                'Quem você quer chamar?',
                style: TextStyle(fontWeight: FontWeight.w800, color: _ink),
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
                        hintText: 'email@exemplo.com',
                        border: const OutlineInputBorder(),
                        errorText: c.draftError.value.isEmpty
                            ? null
                            : c.draftError.value,
                      ),
                      onSubmitted: (_) => _add(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      onPressed: sending ? null : _add,
                      child: const Text('Adicionar'),
                    ),
                  ),
                ],
              ),
              if (c.people.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'O que cada pessoa faz? Uma ou as duas.',
                  style: TextStyle(fontWeight: FontWeight.w800, color: _ink),
                ),
                for (final person in c.people) _personCard(person, sending),
                const SizedBox(height: 4),
                const Text(
                  'Em campo compartilha a própria localização. Vê o mapa vê '
                  'quem está em campo.',
                  style: TextStyle(fontSize: 12, color: _muted),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _soft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Cada pessoa recebe um e-mail e entra no app com essa Conta '
                  'Google. A localização só é compartilhada depois que ela '
                  'ativar no próprio celular.',
                  style: TextStyle(fontSize: 13, height: 1.45, color: _muted),
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
              if (c.errorMessage.value.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    c.errorMessage.value,
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
                  onPressed: c.canSend ? c.send : null,
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
                            const Text('Enviando…'),
                          ],
                        )
                      : Text(
                          c.people.length <= 1
                              ? 'Enviar convite'
                              : 'Enviar ${c.people.length} convites',
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _personCard(InviteDraft person, bool sending) => Container(
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
              tooltip: 'Tirar ${person.email}',
              onPressed: sending ? null : () => c.remove(person),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          children: [
            for (final role in GroupRole.values)
              FilterChip(
                label: Text(role.label),
                selected: person.roles.contains(role),
                selectedColor: palette.light,
                onSelected: sending ? null : (_) => c.toggle(person, role),
              ),
          ],
        ),
        if (person.roles.isEmpty)
          const Text(
            'Marque pelo menos uma opção.',
            style: TextStyle(color: _error, fontWeight: FontWeight.w800),
          ),
      ],
    ),
  );

  Widget _sent(InviteSendResult result) {
    final sent = result.sent;
    final notEmailed = result.notEmailed;
    final skipped = result.skipped;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      children: [
        Icon(Icons.mark_email_read_outlined, size: 56, color: palette.primary),
        const SizedBox(height: 16),
        Text(
          sent.length == 1
              ? 'Convite enviado'
              : '${sent.length} convites enviados',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Para ${result.groupName}. Vale por 14 dias; acompanhe em Grupos.',
          style: const TextStyle(fontSize: 15, color: _muted),
        ),
        const SizedBox(height: 16),
        for (final email in sent)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.person_outline),
            title: Text(email),
            subtitle: notEmailed.contains(email)
                ? const Text(
                    'O e-mail não saiu agora; a pessoa vê o convite ao '
                    'entrar no app com essa conta.',
                  )
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
        OutlinedButton(
          onPressed: c.again,
          child: const Text('Convidar mais pessoas'),
        ),
        TextButton(onPressed: Get.back, child: const Text('Voltar')),
      ],
    );
  }
}
