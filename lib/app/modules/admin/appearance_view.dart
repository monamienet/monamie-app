import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/config/partner/partner_config.dart';
import 'package:monamie_app/app/config/partner/partner_icon.dart';
import 'package:monamie_app/app/config/partner/partner_theme.dart';

import 'appearance_controller.dart';

const _ink = Color(0xFF1B1838);
const _muted = Color(0xFF4A4858);
const _line = Color(0xFFDDD9E4);
const _soft = Color(0xFFF1F0F4);

/// *Aparência da organização*: an administrator changes the name, the theme and
/// the logo. Changes reach the team on their next launch.
class AppearanceView extends StatelessWidget {
  const AppearanceView({super.key, required this.controller});

  final AppearanceController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final theme = controller.pickedTheme;
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: theme.dark,
          foregroundColor: theme.onDark,
          title: const Text('Aparência'),
          centerTitle: false,
        ),
        body: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              children: [
                _header(theme),
                const SizedBox(height: 22),
                _identityCard(context, theme),
                const SizedBox(height: 22),
                _themes(theme),
                const SizedBox(height: 22),
                _note(),
                const SizedBox(height: 22),
                if (controller.errorMessage.value.isNotEmpty) _error(),
                _saveButton(theme),
              ],
            ),
            if (controller.sheet.value != LogoSheet.closed)
              _LogoSheet(controller: controller, theme: theme),
          ],
        ),
      );
    });
  }

  PartnerConfig get _preview => PartnerConfig(
    id: controller.partner.id,
    name: controller.name.value,
    theme: controller.pickedTheme,
    logoVersion: controller.logoPng.value == null ? null : 1,
    logoPng: controller.logoPng.value,
  );

  Widget _header(PartnerTheme theme) => Row(
    children: [
      PartnerIcon(partner: _preview, size: 56),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              controller.name.value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Você administra esta organização',
              style: TextStyle(fontSize: 13, color: _muted),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _identityCard(BuildContext context, PartnerTheme theme) {
    final hasLogo = controller.logoPng.value != null;
    final link = TextButton.styleFrom(
      foregroundColor: theme.primary,
      textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
      minimumSize: const Size(44, 44),
    );
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          _row(
            label: 'Nome',
            value: controller.name.value,
            actions: [
              TextButton(
                style: link,
                onPressed: controller.isSaving.value
                    ? null
                    : () => _editName(context),
                child: const Text('Alterar'),
              ),
            ],
          ),
          const Divider(height: 1, color: Color(0xFFECEAF0)),
          _row(
            label: 'Logo',
            value: !hasLogo
                ? 'Sem logo · usamos a inicial'
                : controller.logoPng.value == controller.partner.logoPng
                ? 'PNG quadrado de 512 px'
                : 'Novo logo · salve para aplicar',
            hint: hasLogo ? null : 'SVG, PNG, JPEG ou WebP',
            actions: [
              if (hasLogo)
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: _muted,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                    minimumSize: const Size(44, 44),
                  ),
                  onPressed: controller.isSaving.value
                      ? null
                      : controller.removeLogo,
                  child: const Text('Remover'),
                ),
              TextButton(
                style: link,
                onPressed: controller.isSaving.value ? null : _pickLogo,
                child: Text(hasLogo ? 'Alterar' : 'Adicionar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row({
    required String label,
    required String value,
    String? hint,
    required List<Widget> actions,
  }) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: _muted)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              if (hint != null)
                Text(hint, style: const TextStyle(fontSize: 12, color: _muted)),
            ],
          ),
        ),
        ...actions,
      ],
    ),
  );

  Widget _themes(PartnerTheme picked) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Tema',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
          Text(
            picked.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _muted,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (controller.isLoadingThemes.value)
        const Center(child: CircularProgressIndicator())
      else
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            for (final theme in controller.themes)
              _ThemeSwatch(
                theme: theme,
                selected: theme.id == picked.id,
                onTap: controller.isSaving.value
                    ? null
                    : () => controller.themeId.value = theme.id,
              ),
          ],
        ),
    ],
  );

  Widget _note() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: _soft,
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 18, color: _muted),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'A equipe vê a nova aparência na próxima vez que abrir o app.',
            style: TextStyle(fontSize: 13, height: 1.45, color: _muted),
          ),
        ),
      ],
    ),
  );

  Widget _error() => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      controller.errorMessage.value,
      style: const TextStyle(
        color: Color(0xFFB3261E),
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Widget _saveButton(PartnerTheme theme) {
    final saving = controller.isSaving.value;
    return SizedBox(
      height: 56,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: theme.primary,
          foregroundColor: theme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        onPressed: saving || !controller.hasChanges ? null : _save,
        child: saving
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: theme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Salvando…'),
                ],
              )
            : const Text('Salvar alterações'),
      ),
    );
  }

  Future<void> _save() async {
    if (await controller.save()) {
      Get.back();
      Get.snackbar(
        'Aparência salva',
        'A equipe vê a nova aparência na próxima vez que abrir o app.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _pickLogo() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['svg', 'png', 'jpg', 'jpeg', 'webp', 'heic'],
    );
    if (files.isEmpty) return;
    await controller.pickLogo(await files.first.readAsBytes());
  }

  Future<void> _editName(BuildContext context) async {
    final field = TextEditingController(text: controller.name.value);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nome da organização'),
        content: TextField(
          controller: field,
          autofocus: true,
          maxLength: 40,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, field.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (name != null && name.trim().length >= 2) {
      controller.name.value = name.trim();
    }
  }
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  final PartnerTheme theme;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    label: theme.name,
    selected: selected,
    inMutuallyExclusiveGroup: true,
    button: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: theme.primary,
          borderRadius: BorderRadius.circular(14),
          border: selected ? Border.all(color: _ink, width: 2) : null,
        ),
        child: selected
            ? Icon(Icons.check, color: theme.onPrimary, size: 20)
            : null,
      ),
    ),
  );
}

class _LogoSheet extends StatelessWidget {
  const _LogoSheet({required this.controller, required this.theme});

  final AppearanceController controller;
  final PartnerTheme theme;

  @override
  Widget build(BuildContext context) {
    final state = controller.sheet.value;
    final processing = state == LogoSheet.processing;
    final title = switch (state) {
      LogoSheet.error => 'Não deu para usar este arquivo',
      LogoSheet.preview => 'Assim fica o logo',
      _ => 'Logo da organização',
    };
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: controller.closeSheet,
            child: const ColoredBox(color: Color(0x8C091416)),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (processing)
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: _soft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: theme.primary),
                          const SizedBox(height: 14),
                          const Text(
                            'Convertendo para PNG no seu celular',
                            style: TextStyle(fontSize: 13, color: _muted),
                          ),
                        ],
                      ),
                    ),
                  if (state == LogoSheet.preview) ..._preview(),
                  if (state == LogoSheet.error)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBE9E7),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        controller.sheetError.value,
                        style: const TextStyle(
                          color: Color(0xFFB3261E),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (state == LogoSheet.preview)
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.primary,
                        foregroundColor: theme.onPrimary,
                        minimumSize: const Size.fromHeight(56),
                      ),
                      onPressed: controller.useCandidate,
                      child: const Text('Usar este logo'),
                    ),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: _ink),
                    onPressed: processing ? null : controller.closeSheet,
                    child: const Text('Fechar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _preview() {
    final partner = PartnerConfig(
      id: controller.partner.id,
      name: controller.name.value,
      theme: theme,
      logoVersion: 1,
      logoPng: controller.candidate,
    );
    return [
      Container(
        height: 150,
        decoration: BoxDecoration(
          color: _soft,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PartnerIcon(partner: partner, size: 96),
            const SizedBox(width: 20),
            PartnerIcon(partner: partner, size: 56),
            const SizedBox(width: 20),
            PartnerIcon(partner: partner, size: 30),
          ],
        ),
      ),
      const SizedBox(height: 14),
      const Text(
        'Convertemos o arquivo para um PNG quadrado de 512 px. É assim que ele '
        'aparece no topo do app, no menu e na lista de organizações.',
        style: TextStyle(fontSize: 13, height: 1.45, color: _muted),
      ),
    ];
  }
}
