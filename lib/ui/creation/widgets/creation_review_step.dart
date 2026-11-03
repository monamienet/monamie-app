import 'package:flutter/material.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/ui/core/ui/failure_text.dart';
import 'package:monamie_app/ui/core/ui/rich_message.dart';
import 'package:monamie_app/ui/core/themes/monamie_brand.dart';

import 'package:monamie_app/ui/creation/view_models/create_organization_view_model.dart';
import 'creation_ui.dart';

const _navy = CreationColors.navy;
const _muted = CreationColors.muted;
const _line = CreationColors.line;
const _note = CreationColors.note;

/// *Tudo certo?*, the wizard's last step. Its parent rebuilds it when
/// [controller] or its `create` command changes.
class CreationReviewStep extends StatelessWidget {
  const CreationReviewStep({super.key, required this.controller});

  final CreateOrganizationViewModel controller;

  CreateOrganizationViewModel get c => controller;

  /// *Tudo certo?* (`CriarRevisao.dc.html`): what the team will see, the
  /// choices (plan included) with a link back to each, who becomes the owner
  /// and first administrator, the terms and the button that creates the
  /// organization.
  @override
  Widget build(BuildContext context) {
    final theme = c.pickedTheme;
    final l10n = AppLocalizations.of(context);
    final name = c.preview(placeholderName: l10n.creationPreviewName).name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            children: [
              Text(
                l10n.creationReviewTitle,
                style: const TextStyle(
                  fontSize: 34,
                  height: 1.08,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.035 * 34,
                  color: _navy,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.dark,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        name.characters.first.toUpperCase(),
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: theme.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.creationReviewTeamSees,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: theme.light,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.02 * 22,
                              color: theme.onDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _line),
                ),
                child: Column(
                  children: [
                    _reviewRow(
                      l10n,
                      l10n.creationReviewName,
                      Text(c.state.name.trim(), style: _value),
                      0,
                    ),
                    _reviewRow(
                      l10n,
                      l10n.creationIdLabel,
                      Text(c.state.id, style: _value),
                      0,
                    ),
                    _reviewRow(
                      l10n,
                      l10n.creationReviewTheme,
                      Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: theme.primary,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(theme.name, style: _value),
                        ],
                      ),
                      1,
                    ),
                    _reviewRow(
                      l10n,
                      l10n.creationReviewPlan,
                      Text(
                        c.state.plan == 'community'
                            ? l10n.planCommunity
                            : l10n.planStandard,
                        style: _value,
                      ),
                      2,
                      last: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _note,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: _navy,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        c.ownerEmail.isEmpty
                            ? '?'
                            : c.ownerEmail.characters.first.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: MonAmieBrand.cream,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.creationReviewOwnerTitle,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: _navy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.creationReviewOwnerBody(c.ownerEmail),
                            style: const TextStyle(
                              fontSize: 13,
                              height: 19 / 13,
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
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (c.state.failure case final failure?)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              failure.message(l10n),
              style: const TextStyle(
                fontSize: 13,
                height: 19 / 13,
                color: Color(0xFFB3261E),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: c.state.acceptedTerms,
                activeColor: _navy,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                onChanged: c.create.running
                    ? null
                    : (v) => c.acceptTerms(v ?? false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w500,
                    color: _navy,
                  ),
                  children: spansAround(
                    l10n.creationTermsAccept,
                    l10n.creationTerms,
                    valueStyle: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        creationButton(
          l10n.creationCreate,
          c.canCreate ? c.create.execute : null,
          busy: c.create.running,
          busyLabel: l10n.commonCreating,
        ),
      ],
    );
  }

  static const _value = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: _navy,
  );

  /// One line of the review: a small label over its value, and "Alterar",
  /// which goes back to [step].
  Widget _reviewRow(
    AppLocalizations l10n,
    String label,
    Widget value,
    int step, {
    bool last = false,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      border: last ? null : const Border(bottom: BorderSide(color: _note)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _muted,
                ),
              ),
              const SizedBox(height: 2),
              value,
            ],
          ),
        ),
        const SizedBox(width: 12),
        InkWell(
          onTap: c.create.running ? null : () => c.goToStep(step),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              l10n.commonChange,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _navy,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
