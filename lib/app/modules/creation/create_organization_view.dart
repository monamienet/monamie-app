import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/config/partner/monamie_brand.dart';
import 'package:monamie_app/app/config/partner/partner_config.dart';
import 'package:monamie_app/app/config/partner/partner_icon.dart';
import 'package:monamie_app/app/config/partner/partner_theme.dart';

import 'create_organization_controller.dart';
import 'id_input_formatter.dart';

const _navy = MonAmieBrand.navy;
const _muted = MonAmieBrand.mutedInk;
const _line = Color(0xFFDDD5C4);
const _ring = Color(0xFFB8AE9A);
const _danger = Color(0xFFC23F1E);
const _ok = Color(0xFF2F7347);
const _note = Color(0xFFECE6D9);

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

  /// The identifier field changed what the person typed (case, accents,
  /// anything but a to z): the screen says so.
  bool _adjusted = false;

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
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(),
                // The canvas spaces the name screen by 24, the others by 20.
                SizedBox(height: _step == 0 ? 24 : 20),
                Expanded(
                  child: switch (_step) {
                    0 => _nameStep(),
                    1 => _themeStep(),
                    2 => _planStep(),
                    _ => _reviewStep(),
                  },
                ),
              ],
            ),
          );
        }),
      ),
    ),
  );

  /// Back arrow, the screen's name and "n de 2", over a two-segment progress
  /// bar (`CriarNome.dc.html`): the arrow's box starts 12 px left of the
  /// 24 px margin, so the arrow lines up with the text below.
  Widget _header() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Transform.translate(
        offset: const Offset(-12, 0),
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              IconButton(
                tooltip: 'Voltar',
                constraints: const BoxConstraints.tightFor(
                  width: 48,
                  height: 48,
                ),
                padding: EdgeInsets.zero,
                onPressed: c.isCreating.value ? null : _back,
                icon: const Icon(Icons.arrow_back, color: _navy),
              ),
              const SizedBox(width: 8),
              const Text(
                'Nova organização',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _navy,
                ),
              ),
              const Spacer(),
              if (_step < 2)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    '${_step + 1} de 2',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _muted,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          for (var i = 0; i < 2; i++) ...[
            if (i == 1) const SizedBox(width: 6),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: i <= _step ? _navy : _line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ],
      ),
    ],
  );

  Widget _title(String text, [String? subtitle, double gap = 20]) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        text,
        style: const TextStyle(
          fontSize: 34,
          height: 1.08,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.035 * 34,
          color: _navy,
        ),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 16,
            height: 24 / 16,
            fontWeight: FontWeight.w500,
            color: _muted,
          ),
        ),
      ],
      SizedBox(height: gap),
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
        disabledBackgroundColor: _line,
        disabledForegroundColor: _muted,
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
    final id = c.id.value;
    final name = c.name.value.trim();
    if (_id.text != id) _id.text = id;
    // "Mínimo 3 letras" is the field's own status; any other problem goes
    // under it, in red.
    final isShort = id.isNotEmpty && id.length < 3;
    final problem = check == IdCheck.unavailable && !isShort
        ? c.idProblem.value
        : '';
    final ring = isShort || problem.isNotEmpty ? _danger : _ring;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            children: [
              _title(
                'Como sua organização se chama?',
                'Use o nome que a equipe reconhece: da empresa, do grupo ou do projeto.',
                24,
              ),
              _label('Nome da organização'),
              const SizedBox(height: 8),
              TextField(
                controller: _name,
                maxLength: 40,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: _navy,
                ),
                cursorColor: _navy,
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 17,
                  ),
                  enabledBorder: _fieldBorder(_ring, 1.5),
                  focusedBorder: _fieldBorder(_navy, 2),
                  border: _fieldBorder(_ring, 1.5),
                ),
                onChanged: (value) {
                  _adjusted = false;
                  c.setName(value);
                },
              ),
              if (name.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _muted,
                    ),
                    children: [
                      const TextSpan(text: 'Sua equipe vai ver '),
                      TextSpan(
                        text: name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: _navy,
                        ),
                      ),
                      const TextSpan(text: ' no topo do app'),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _label('Identificador'),
              const SizedBox(height: 8),
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ring, width: 1.5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _id,
                        autocorrect: false,
                        enableSuggestions: false,
                        keyboardType: TextInputType.visiblePassword,
                        inputFormatters: [IdInputFormatter(_markAdjusted)],
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.17,
                          color: _navy,
                        ),
                        cursorColor: _navy,
                        decoration: const InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                        ),
                        onChanged: c.setId,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _idStatus(check, isShort),
                  ],
                ),
              ),
              if (problem.isNotEmpty) ...[
                const SizedBox(height: 8),
                _note13(problem, color: _danger, bold: true),
              ] else if (_adjusted) ...[
                const SizedBox(height: 8),
                _note13(
                  'Ajustamos para letras minúsculas, sem acentos, espaços ou números.',
                  color: _navy,
                  bold: true,
                ),
              ],
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  style: const TextStyle(
                    fontSize: 13,
                    height: 19 / 13,
                    fontWeight: FontWeight.w500,
                    color: _muted,
                  ),
                  children: [
                    const TextSpan(
                      text:
                          'Só letras minúsculas, sem acentos, espaços ou números. '
                          'Ele aparece nos endereços dos grupos, como ',
                    ),
                    TextSpan(
                      text:
                          '${id.isEmpty ? 'identificador' : id}01@monamienet.org',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _navy,
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _note,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(Icons.lock_outline, size: 18, color: _navy),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'O identificador não muda depois. O nome pode mudar.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 19 / 13,
                          fontWeight: FontWeight.w500,
                          color: _navy,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _button(
          'Continuar',
          c.canContinueFromName ? () => setState(() => _step = 1) : null,
        ),
      ],
    );
  }

  void _markAdjusted(bool adjusted) {
    if (adjusted == _adjusted || !mounted) return;
    setState(() => _adjusted = adjusted);
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w800,
      color: _navy,
    ),
  );

  Widget _note13(String text, {required Color color, bool bold = false}) =>
      Text(
        text,
        style: TextStyle(
          fontSize: 13,
          height: 19 / 13,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          color: color,
        ),
      );

  OutlineInputBorder _fieldBorder(Color color, double width) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );

  /// What the field says about the identifier, on its right.
  Widget _idStatus(IdCheck check, bool isShort) {
    if (isShort) {
      return const Text(
        'Mínimo 3 letras',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: _danger,
        ),
      );
    }
    return switch (check) {
      IdCheck.checking => const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: _muted),
          ),
          SizedBox(width: 6),
          Text(
            'Verificando…',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _muted,
            ),
          ),
        ],
      ),
      IdCheck.available => const Row(
        children: [
          Icon(Icons.check, size: 16, color: _ok),
          SizedBox(width: 4),
          Text(
            'Disponível',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _ok,
            ),
          ),
        ],
      ),
      _ => const SizedBox.shrink(),
    };
  }

  PartnerConfig get _preview => PartnerConfig(
    id: c.id.value.length >= 3 ? c.id.value : 'nova',
    name: c.name.value.trim().isEmpty ? 'Organização' : c.name.value.trim(),
    theme: c.pickedTheme,
  );

  /// *Escolha um tema* (`CriarTema.dc.html`): title, a preview of the app
  /// in the picked theme, the eight themes in a grid of chips with their
  /// names, and the button at the bottom.
  Widget _themeStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: ListView(
          children: [
            _title(
              'Escolha um tema',
              'Cada tema já traz os tons do app, com contraste garantido para textos e botões.',
            ),
            _themePreview(),
            const SizedBox(height: 20),
            _themeGrid(),
          ],
        ),
      ),
      const SizedBox(height: 20),
      _button('Revisar e criar', () => setState(() => _step = 2)),
    ],
  );

  /// The app in the picked theme: its bar with the organization's tile and
  /// name, a map with a trail, a person, the "Compartilhando" pill and the
  /// locate button.
  Widget _themePreview() {
    final theme = c.pickedTheme;
    final name = _preview.name;
    return Semantics(
      label: 'Prévia do app com o tema',
      child: Container(
        height: 220,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _line),
        ),
        child: Column(
          children: [
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              color: theme.dark,
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.primary,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      name.characters.first.toUpperCase(),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: theme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: theme.onDark,
                      ),
                    ),
                  ),
                  Text(
                    'Equipe Norte',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.onDark,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: const Color(0xFFEEF0EB),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _PreviewMapPainter(theme.primary),
                      ),
                    ),
                    Positioned(
                      left: 182,
                      top: 80,
                      child: Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: theme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Text(
                          'AL',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: theme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: theme.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Compartilhando',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: theme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: theme.light,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.my_location,
                          size: 20,
                          color: theme.dark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Four chips per row, each a swatch of the theme's color with its dark
  /// shade as a band, and the theme's name under it.
  Widget _themeGrid() {
    final themes = c.themes.toList();
    return LayoutBuilder(
      builder: (context, box) {
        const columns = 4;
        const gap = 10.0;
        final chip = (box.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: 12,
          children: [
            for (final theme in themes)
              SizedBox(
                width: chip,
                child: _themeChip(theme, theme.id == c.themeId.value),
              ),
          ],
        );
      },
    );
  }

  Widget _themeChip(PartnerTheme theme, bool selected) => Semantics(
    label: theme.name,
    selected: selected,
    button: true,
    excludeSemantics: true,
    child: InkWell(
      onTap: () => c.themeId.value = theme.id,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              // A cream ring, then an ink one, outside the chip.
              boxShadow: selected
                  ? const [
                      BoxShadow(color: MonAmieBrand.cream, spreadRadius: 2),
                      BoxShadow(color: _navy, spreadRadius: 4),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  Positioned.fill(child: ColoredBox(color: theme.primary)),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 16,
                    child: ColoredBox(color: theme.dark),
                  ),
                  if (selected)
                    const Icon(Icons.check, size: 22, color: Colors.white),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            theme.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              height: 16 / 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              color: selected ? _navy : _muted,
            ),
          ),
        ],
      ),
    ),
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

/// The roads and the trail of the theme preview, drawn on the canvas' 340 by
/// 168 grid and stretched to the preview's map area.
class _PreviewMapPainter extends CustomPainter {
  const _PreviewMapPainter(this.trail);

  final Color trail;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 340, size.height / 168);
    final road = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    final roads = Path()
      ..moveTo(0, 118)
      ..lineTo(340, 96)
      ..moveTo(70, 0)
      ..lineTo(110, 168)
      ..moveTo(220, 0)
      ..lineTo(190, 168)
      ..moveTo(0, 40)
      ..lineTo(340, 58);
    canvas.drawPath(roads, road);
    canvas.drawPath(
      Path()
        ..moveTo(86, 70)
        ..lineTo(150, 63)
        ..lineTo(204, 60)
        ..lineTo(196, 100),
      Paint()
        ..color = trail
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_PreviewMapPainter old) => old.trail != trail;
}
