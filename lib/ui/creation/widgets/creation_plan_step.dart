import 'package:flutter/material.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/ui/core/themes/monamie_brand.dart';

import 'package:monamie_app/ui/creation/view_models/create_organization_view_model.dart';
import 'creation_ui.dart';

const _navy = CreationColors.navy;
const _muted = CreationColors.muted;
const _line = CreationColors.line;
const _ring = CreationColors.ring;
const _note = CreationColors.note;

/// *Escolha um plano*, the wizard's third step. Its parent rebuilds it when
/// [controller] or its `create` command changes.
class CreationPlanStep extends StatelessWidget {
  const CreationPlanStep({super.key, required this.controller});

  final CreateOrganizationViewModel controller;

  CreateOrganizationViewModel get c => controller;

  /// *Escolha um plano* (`Plano.dc.html`): the two plans as radio cards, a
  /// note, and a footer bar whose button goes on to the review.
  @override
  Widget build(BuildContext context) {
    final community = c.state.plan == 'community';
    final name = c.preview.name;
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            children: [
              Text(
                l10n.creationPlanTitle,
                style: const TextStyle(
                  fontSize: 34,
                  height: 1.08,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.035 * 34,
                  color: _navy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.creationPlanSubtitle(name),
                style: const TextStyle(
                  fontSize: 15,
                  height: 22 / 15,
                  fontWeight: FontWeight.w500,
                  color: _muted,
                ),
              ),
              const SizedBox(height: 18),
              _planCard(
                'community',
                l10n.planCommunity,
                l10n.creationPlanFree,
                l10n.creationPlanCommunityTagline,
                [
                  (true, l10n.creationPlanCommunityReady),
                  (true, l10n.creationPlanCommunityData),
                  (false, l10n.creationPlanCommunityInterval),
                ],
              ),
              const SizedBox(height: 12),
              _planCard(
                'standard',
                l10n.planStandard,
                l10n.creationPlanGoogleUsage,
                l10n.creationPlanStandardTagline,
                [
                  (true, l10n.creationPlanStandardProject(name)),
                  (true, l10n.creationPlanStandardProfiles),
                  (false, l10n.creationPlanStandardBilling),
                ],
              ),
              const SizedBox(height: 18),
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
                      child: Icon(Icons.swap_horiz, size: 18, color: _navy),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.creationPlanSwitchLater,
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
        Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: _line)),
          ),
          child: creationButton(
            l10n.creationPlanContinue(
              community ? l10n.planCommunity : l10n.planStandard,
            ),
            c.next,
          ),
        ),
      ],
    );
  }

  Widget _planCard(
    String id,
    String title,
    String price,
    String tagline,
    List<(bool, String)> points,
  ) {
    final selected = c.state.plan == id;
    final offered = CreateOrganizationViewModel.offeredPlans.contains(id);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      enabled: offered,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: c.create.running || !offered ? null : () => c.pickPlan(id),
        child: Opacity(
          opacity: offered ? 1 : 0.45,
          child: Container(
            // The canvas draws the border inside the card (an inset shadow), so
            // picking a plan must not move its content: the thinner border
            // gets the difference as padding.
            padding: EdgeInsets.all(selected ? 15.5 : 17),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? _navy : _line,
                width: selected ? 2.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: selected ? _navy : _ring,
                          width: selected ? 7 : 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.02 * 20,
                          color: _navy,
                        ),
                      ),
                    ),
                    Container(
                      height: 26,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: id == 'community' ? _navy : _note,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Text(
                        price,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: id == 'community' ? MonAmieBrand.cream : _navy,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  tagline,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w500,
                    color: _muted,
                  ),
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < points.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Icon(
                          points[i].$1 ? Icons.check : Icons.schedule,
                          size: 18,
                          color: points[i].$1 ? _navy : _muted,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          points[i].$2,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 20 / 14,
                            fontWeight: FontWeight.w500,
                            color: _navy,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
