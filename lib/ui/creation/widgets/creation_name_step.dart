import 'package:flutter/material.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/ui/core/ui/rich_message.dart';

import 'package:monamie_app/ui/creation/view_models/create_organization_view_model.dart';
import 'creation_ui.dart';
import 'id_input_formatter.dart';

const _navy = CreationColors.navy;
const _muted = CreationColors.muted;
const _ring = CreationColors.ring;
const _danger = CreationColors.danger;
const _ok = CreationColors.ok;
const _note = CreationColors.note;

/// *Como sua organização se chama?* (`CriarNome.dc.html`): the name, the
/// identifier suggested from it (checked as it is typed) and the button that
/// goes on to the theme. Its parent rebuilds it when [controller] changes.
class CreationNameStep extends StatelessWidget {
  const CreationNameStep({
    super.key,
    required this.controller,
    required this.nameField,
    required this.idField,
  });

  final CreateOrganizationViewModel controller;

  /// The name and identifier fields, kept by the screen so they survive the
  /// other steps.
  final TextEditingController nameField;
  final TextEditingController idField;

  CreateOrganizationViewModel get c => controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final check = c.state.idCheck;
    final id = c.state.id;
    final name = c.state.name.trim();
    if (idField.text != id) idField.text = id;
    // "Mínimo 3 letras" is the field's own status; any other problem goes
    // under it, in red.
    final isShort = c.idTooShort;
    final problem = c.idShownProblem;
    final ring = isShort || problem.isNotEmpty ? _danger : _ring;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            children: [
              creationTitle(
                l10n.creationNameTitle,
                l10n.creationNameSubtitle,
                24,
              ),
              creationLabel(l10n.creationNameLabel),
              const SizedBox(height: 8),
              TextField(
                controller: nameField,
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
                  enabledBorder: creationFieldBorder(_ring, 1.5),
                  focusedBorder: creationFieldBorder(_navy, 2),
                  border: creationFieldBorder(_ring, 1.5),
                ),
                onChanged: c.setName,
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
                    children: spansAround(
                      l10n.creationNamePreview,
                      name,
                      valueStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _navy,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              creationLabel(l10n.creationIdLabel),
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
                        controller: idField,
                        autocorrect: false,
                        enableSuggestions: false,
                        keyboardType: TextInputType.visiblePassword,
                        inputFormatters: [IdInputFormatter(c.markIdAdjusted)],
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
                    _idStatus(l10n, check, isShort),
                  ],
                ),
              ),
              if (problem.isNotEmpty) ...[
                const SizedBox(height: 8),
                creationNote(problem, color: _danger, bold: true),
              ] else if (c.state.idAdjusted) ...[
                const SizedBox(height: 8),
                creationNote(l10n.creationIdAdjusted, color: _navy, bold: true),
              ],
              const SizedBox(height: 8),
              Text(
                l10n.creationIdRules,
                style: const TextStyle(
                  fontSize: 13,
                  height: 19 / 13,
                  fontWeight: FontWeight.w500,
                  color: _muted,
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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(Icons.lock_outline, size: 18, color: _navy),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.creationIdPermanent,
                        style: const TextStyle(
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
        creationButton(
          l10n.commonContinue,
          c.canContinueFromName ? c.next : null,
        ),
      ],
    );
  }

  /// What the field says about the identifier, on its right.
  Widget _idStatus(AppLocalizations l10n, IdCheck check, bool isShort) {
    if (isShort) {
      return Text(
        l10n.creationIdTooShort,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: _danger,
        ),
      );
    }
    return switch (check) {
      IdCheck.checking => Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: _muted),
          ),
          const SizedBox(width: 6),
          Text(
            l10n.commonChecking,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _muted,
            ),
          ),
        ],
      ),
      IdCheck.available => Row(
        children: [
          const Icon(Icons.check, size: 16, color: _ok),
          const SizedBox(width: 4),
          Text(
            l10n.creationIdAvailable,
            style: const TextStyle(
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
}
