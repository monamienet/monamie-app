import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/ui/core/ui/failure_text.dart';
import 'package:monamie_app/domain/models/organization/organization_config.dart';
import 'package:monamie_app/ui/core/ui/organization_icon.dart';
import 'package:monamie_app/domain/models/organization/organization_theme.dart';
import 'package:monamie_app/ui/core/ui/app_messenger.dart';
import 'package:monamie_app/utils/result.dart';

import 'package:monamie_app/ui/appearance/view_models/appearance_view_model.dart';

const _ink = Color(0xFF1B1838);
const _muted = Color(0xFF4A4858);
const _line = Color(0xFFDDD9E4);
const _soft = Color(0xFFF1F0F4);

/// *Aparência da organização*: an administrator changes the name, the theme and
/// the logo. Changes reach the team on their next launch.
class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key, required this.controller});

  final AppearanceViewModel controller;

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  AppearanceViewModel get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.load.execute();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        controller,
        controller.load,
        controller.pickLogo,
        controller.save,
      ]),
      builder: (context, _) {
        final theme = controller.pickedTheme;
        final l10n = AppLocalizations.of(context);
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: theme.dark,
            foregroundColor: theme.onDark,
            title: Text(l10n.appearanceTitle),
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
                  if (controller.state.failure case final failure?)
                    _error(failure.message(l10n)),
                  _saveButton(context, theme),
                ],
              ),
              if (controller.state.sheet != LogoSheet.closed)
                _LogoSheet(controller: controller, theme: theme),
            ],
          ),
        );
      },
    );
  }

  OrganizationConfig get _preview => OrganizationConfig(
    id: controller.organization.id,
    name: controller.state.name,
    theme: controller.pickedTheme,
    logoVersion: controller.state.logoPng == null ? null : 1,
    logoPng: controller.state.logoPng,
  );

  Widget _header(OrganizationTheme theme) => Row(
    children: [
      OrganizationIcon(organization: _preview, size: 56),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              controller.state.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context).appearanceYouAdminister,
              style: const TextStyle(fontSize: 13, color: _muted),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _identityCard(BuildContext context, OrganizationTheme theme) {
    final l10n = AppLocalizations.of(context);
    final hasLogo = controller.state.logoPng != null;
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
            label: l10n.appearanceName,
            value: controller.state.name,
            actions: [
              TextButton(
                style: link,
                onPressed: controller.save.running
                    ? null
                    : () => _editName(context),
                child: Text(l10n.commonChange),
              ),
            ],
          ),
          const Divider(height: 1, color: Color(0xFFECEAF0)),
          _row(
            label: l10n.appearanceLogo,
            value: !hasLogo
                ? l10n.appearanceNoLogo
                : controller.state.logoPng == controller.organization.logoPng
                ? l10n.appearanceLogoSaved
                : l10n.appearanceLogoNew,
            hint: hasLogo ? null : l10n.appearanceLogoFormats,
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
                  onPressed: controller.save.running
                      ? null
                      : controller.removeLogo,
                  child: Text(l10n.commonRemove),
                ),
              TextButton(
                style: link,
                onPressed: controller.save.running ? null : _pickLogo,
                child: Text(hasLogo ? l10n.commonChange : l10n.commonAdd),
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

  Widget _themes(OrganizationTheme picked) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppLocalizations.of(context).appearanceTheme,
            style: const TextStyle(
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
      if (controller.load.running)
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
            for (final theme in controller.state.themes)
              _ThemeSwatch(
                theme: theme,
                selected: theme.id == picked.id,
                onTap: controller.save.running
                    ? null
                    : () => controller.pickTheme(theme.id),
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
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, size: 18, color: _muted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            AppLocalizations.of(context).appearanceNextLaunch,
            style: const TextStyle(fontSize: 13, height: 1.45, color: _muted),
          ),
        ),
      ],
    ),
  );

  Widget _error(String message) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      message,
      style: const TextStyle(
        color: Color(0xFFB3261E),
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Widget _saveButton(BuildContext context, OrganizationTheme theme) {
    final saving = controller.save.running;
    final l10n = AppLocalizations.of(context);
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
        onPressed: saving || !controller.hasChanges
            ? null
            : () => _save(context),
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
                  Text(l10n.commonSaving),
                ],
              )
            : Text(l10n.commonSaveChanges),
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    // Looked up first: the screen closes before the message shows.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final l10n = AppLocalizations.of(context);
    if (await controller.save.execute() case Ok()) {
      navigator.pop();
      messenger.showSnackBar(
        noticeSnackBar(l10n.appearanceNextLaunch, title: l10n.appearanceSaved),
      );
    }
  }

  Future<void> _pickLogo() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['svg', 'png', 'jpg', 'jpeg', 'webp', 'heic'],
    );
    if (files.isEmpty) return;
    await controller.pickLogo.execute(await files.first.readAsBytes());
  }

  Future<void> _editName(BuildContext context) async {
    final field = TextEditingController(text: controller.state.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).appearanceNameDialog),
        content: TextField(
          controller: field,
          autofocus: true,
          maxLength: 40,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, field.text),
            child: Text(AppLocalizations.of(context).commonOk),
          ),
        ],
      ),
    );
    if (name != null) controller.setName(name);
  }
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  final OrganizationTheme theme;
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

  final AppearanceViewModel controller;
  final OrganizationTheme theme;

  @override
  Widget build(BuildContext context) {
    final state = controller.state.sheet;
    final processing = state == LogoSheet.processing;
    final l10n = AppLocalizations.of(context);
    final title = switch (state) {
      LogoSheet.error => l10n.appearanceLogoError,
      LogoSheet.preview => l10n.appearanceLogoPreview,
      _ => l10n.appearanceLogoSheet,
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
                          Text(
                            l10n.appearanceConverting,
                            style: const TextStyle(fontSize: 13, color: _muted),
                          ),
                        ],
                      ),
                    ),
                  if (state == LogoSheet.preview) ..._preview(l10n),
                  if (state == LogoSheet.error)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBE9E7),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        controller.state.sheetFailure?.message(l10n) ?? '',
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
                      child: Text(l10n.appearanceUseLogo),
                    ),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: _ink),
                    onPressed: processing ? null : controller.closeSheet,
                    child: Text(l10n.commonClose),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _preview(AppLocalizations l10n) {
    final organization = OrganizationConfig(
      id: controller.organization.id,
      name: controller.state.name,
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
            OrganizationIcon(organization: organization, size: 96),
            const SizedBox(width: 20),
            OrganizationIcon(organization: organization, size: 56),
            const SizedBox(width: 20),
            OrganizationIcon(organization: organization, size: 30),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Text(
        l10n.appearanceLogoExplained,
        style: const TextStyle(fontSize: 13, height: 1.45, color: _muted),
      ),
    ];
  }
}
