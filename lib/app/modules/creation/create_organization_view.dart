import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/config/partner/monamie_brand.dart';
import 'package:monamie_app/app/config/partner/partner_config.dart';
import 'package:monamie_app/app/config/partner/partner_icon.dart';

import 'create_organization_controller.dart';

const _navy = MonAmieBrand.navy;
const _muted = MonAmieBrand.mutedInk;
const _line = Color(0xFFDDD5C4);

/// *Criar organização*: Nome → Tema → Plano → Revisão, then the outcome.
class CreateOrganizationView extends StatefulWidget {
  const CreateOrganizationView({
    super.key,
    required this.controller,
    required this.ownerEmail,
    required this.onReady,
  });

  final CreateOrganizationController controller;
  final String ownerEmail;

  /// Enters the new organization (Community, once it is `active`).
  final Future<void> Function() onReady;

  @override
  State<CreateOrganizationView> createState() => _CreateOrganizationViewState();
}

class _CreateOrganizationViewState extends State<CreateOrganizationView> {
  int _step = 0;
  late final _name = TextEditingController();
  late final _id = TextEditingController();

  CreateOrganizationController get c => widget.controller;

  @override
  void dispose() {
    _name.dispose();
    _id.dispose();
    super.dispose();
  }

  void _back() => _step == 0 ? Get.back() : setState(() => _step--);

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark,
    child: Scaffold(
      backgroundColor: MonAmieBrand.cream,
      body: SafeArea(
        child: Obx(() {
          final result = c.result.value;
          if (result != null) return _outcome(result);
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Voltar',
                      onPressed: c.isCreating.value ? null : _back,
                      icon: const Icon(Icons.arrow_back, color: _navy),
                    ),
                    const Expanded(
                      child: Text(
                        'Nova organização',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: _navy,
                        ),
                      ),
                    ),
                    if (_step < 2)
                      Text(
                        '${_step + 1} de 2',
                        style: const TextStyle(color: _muted),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: switch (_step) {
                      0 => _nameStep(),
                      1 => _themeStep(),
                      2 => _planStep(),
                      _ => _reviewStep(),
                    },
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    ),
  );

  Widget _title(String text, [String? subtitle]) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        text,
        style: const TextStyle(
          fontSize: 30,
          height: 1.1,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          color: _navy,
        ),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 15, height: 1.45, color: _muted),
        ),
      ],
      const SizedBox(height: 20),
    ],
  );

  Widget _button(
    String label,
    VoidCallback? onPressed, {
    bool busy = false,
    String? busyLabel,
  }) => SizedBox(
    height: 56,
    child: FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: _navy,
        foregroundColor: MonAmieBrand.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
      onPressed: busy ? null : onPressed,
      child: busy
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: MonAmieBrand.cream,
                  ),
                ),
                const SizedBox(width: 12),
                Text(busyLabel ?? label),
              ],
            )
          : Text(label),
    ),
  );

  Widget _nameStep() {
    final check = c.idCheck.value;
    final idHint = switch (check) {
      IdCheck.checking => 'Verificando…',
      IdCheck.available => 'Disponível',
      IdCheck.unavailable => c.idProblem.value,
      IdCheck.idle => 'Mínimo 3 letras',
    };
    if (_id.text != c.id.value) _id.text = c.id.value;
    return ListView(
      children: [
        _title(
          'Como sua organização se chama?',
          'Use o nome que a equipe reconhece: da empresa, do grupo ou do projeto.',
        ),
        TextField(
          controller: _name,
          maxLength: 40,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Nome da organização',
            helperText: c.name.value.trim().isEmpty
                ? null
                : 'Sua equipe vai ver ${c.name.value.trim()} no topo do app',
            filled: true,
            fillColor: Colors.white,
            border: const OutlineInputBorder(),
          ),
          onChanged: c.setName,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _id,
          maxLength: 20,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: 'Identificador',
            helperText: check == IdCheck.unavailable ? null : idHint,
            errorText: check == IdCheck.unavailable ? idHint : null,
            suffixIcon: switch (check) {
              IdCheck.checking => const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              IdCheck.available => const Icon(
                Icons.check_circle,
                color: Color(0xFF2F7347),
              ),
              _ => null,
            },
            filled: true,
            fillColor: Colors.white,
            border: const OutlineInputBorder(),
          ),
          onChanged: c.setId,
        ),
        Text(
          'Só letras minúsculas, sem acentos, espaços ou números. Ele aparece '
          'nos endereços dos grupos, como ${c.id.value.isEmpty ? 'rotasul' : c.id.value}01@monamienet.org. '
          'O identificador não muda depois. O nome pode mudar.',
          style: const TextStyle(fontSize: 13, height: 1.45, color: _muted),
        ),
        const SizedBox(height: 24),
        _button(
          'Continuar',
          c.canContinueFromName ? () => setState(() => _step = 1) : null,
        ),
      ],
    );
  }

  PartnerConfig get _preview => PartnerConfig(
    id: c.id.value.length >= 3 ? c.id.value : 'nova',
    name: c.name.value.trim().isEmpty ? 'Organização' : c.name.value.trim(),
    theme: c.pickedTheme,
  );

  Widget _themeStep() => ListView(
    children: [
      _title(
        'Escolha um tema',
        'Cada tema já traz os tons do app, com contraste garantido para textos e botões.',
      ),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.pickedTheme.dark,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            PartnerIcon(partner: _preview, size: 44),
            const SizedBox(width: 12),
            Text(
              _preview.name,
              style: TextStyle(
                color: c.pickedTheme.onDark,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [
          for (final theme in c.themes)
            Semantics(
              label: theme.name,
              selected: theme.id == c.themeId.value,
              button: true,
              child: InkWell(
                onTap: () => c.themeId.value = theme.id,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.primary,
                    borderRadius: BorderRadius.circular(14),
                    border: theme.id == c.themeId.value
                        ? Border.all(color: _navy, width: 2.5)
                        : null,
                  ),
                  child: theme.id == c.themeId.value
                      ? Icon(Icons.check, color: theme.onPrimary)
                      : null,
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 8),
      Text(c.pickedTheme.name, style: const TextStyle(color: _muted)),
      const SizedBox(height: 24),
      _button('Continuar', () => setState(() => _step = 2)),
    ],
  );

  Widget _planCard(
    String id,
    String title,
    String price,
    String tagline,
    List<(bool, String)> points,
  ) {
    final selected = c.plan.value == id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: selected ? _navy : _line,
            width: selected ? 2.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => c.plan.value = id,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _navy,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      price,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(tagline, style: const TextStyle(color: _muted)),
                const SizedBox(height: 8),
                for (final (good, text) in points)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          good ? Icons.check : Icons.info_outline,
                          size: 18,
                          color: good ? const Color(0xFF2F7347) : _muted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            text,
                            style: const TextStyle(color: _navy),
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

  Widget _planStep() => ListView(
    children: [
      _title(
        'Escolha um plano',
        'Os dois têm o mapa, as equipes e a aparência da ${_preview.name}. Muda onde os dados ficam e quem paga.',
      ),
      _planCard(
        'community',
        'Community',
        'Grátis',
        'Para começar agora, sem cadastrar pagamento.',
        const [
          (true, 'Pronta em instantes'),
          (
            true,
            'Dados guardados pela MonAmie, separados das outras organizações',
          ),
          (false, 'Localização enviada a cada 15 min (perfil Economia)'),
        ],
      ),
      _planCard(
        'standard',
        'Standard',
        'Uso no Google',
        'Para quem quer o próprio espaço de dados e mais precisão.',
        [
          (true, 'Projeto Firebase só da ${_preview.name}'),
          (true, 'Todos os perfis de acompanhamento, até a cada 1 min'),
          (
            false,
            'Pede uma conta de faturamento do Google Cloud; vocês pagam o uso direto ao Google',
          ),
        ],
      ),
      const Text(
        'Dá para passar do Community para o Standard depois, sem perder equipes nem histórico.',
        style: TextStyle(fontSize: 13, color: _muted),
      ),
      const SizedBox(height: 20),
      _button(
        c.plan.value == 'community'
            ? 'Começar no Community'
            : 'Continuar com Standard',
        () => setState(() => _step = 3),
      ),
    ],
  );

  Widget _reviewRow(String label, String value, int step) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label, style: const TextStyle(fontSize: 12, color: _muted)),
    subtitle: Text(
      value,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: _navy,
      ),
    ),
    trailing: TextButton(
      onPressed: c.isCreating.value ? null : () => setState(() => _step = step),
      child: const Text('Alterar'),
    ),
  );

  Widget _reviewStep() => ListView(
    children: [
      _title('Tudo certo?'),
      Row(
        children: [
          PartnerIcon(partner: _preview, size: 56),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sua equipe vai ver',
                  style: TextStyle(color: _muted),
                ),
                Text(
                  _preview.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _navy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _reviewRow('Nome', c.name.value.trim(), 0),
      _reviewRow('Identificador', c.id.value, 0),
      _reviewRow('Tema', c.pickedTheme.name, 1),
      _reviewRow(
        'Plano',
        c.plan.value == 'community' ? 'Community' : 'Standard',
        2,
      ),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'Você será o responsável. ${widget.ownerEmail} poderá convidar pessoas, '
          'criar equipes, mudar a aparência e adicionar o logo.',
          style: const TextStyle(height: 1.45, color: _navy),
        ),
      ),
      const SizedBox(height: 16),
      if (c.errorMessage.value.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            c.errorMessage.value,
            style: const TextStyle(
              color: Color(0xFFB3261E),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      _button(
        'Criar organização',
        c.create,
        busy: c.isCreating.value,
        busyLabel: 'Criando…',
      ),
    ],
  );

  Widget _outcome(String status) {
    final name = c.name.value.trim();
    final (title, text, action) = switch (status) {
      'active' => (
        'A $name está pronta',
        'O app já aparece com o nome e o tema de vocês. O logo você adiciona '
            'quando quiser, em Aparência. Próximo passo: chame sua equipe em Equipes.',
        'Entrar na $name',
      ),
      'awaiting_billing' => (
        'Falta ativar o faturamento',
        'A $name roda num projeto do Google Cloud pago pela sua organização. '
            'Entre no Google Cloud com esta mesma Conta Google, escolha ou crie '
            'uma conta de faturamento e vincule ao projeto monamienet-${c.id.value}. '
            'O identificador fica reservado por 7 dias.',
        'Entendi',
      ),
      _ => (
        'Algo deu errado ao criar a $name',
        'Não é nada que você precise fazer. A equipe do MonAmie já foi avisada e '
            'vai terminar a criação. O identificador ${c.id.value} continua '
            'reservado para vocês enquanto isso.',
        'Sair',
      ),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: PartnerIcon(partner: _preview, size: 72),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 30,
              height: 1.1,
              fontWeight: FontWeight.w800,
              color: _navy,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: const TextStyle(fontSize: 16, height: 1.5, color: _muted),
          ),
          const Spacer(),
          _button(action, status == 'active' ? widget.onReady : Get.back),
        ],
      ),
    );
  }
}
