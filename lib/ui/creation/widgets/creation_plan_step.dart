import 'package:flutter/material.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            children: [
              const Text(
                'Escolha um plano',
                style: TextStyle(
                  fontSize: 34,
                  height: 1.08,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.035 * 34,
                  color: _navy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Os dois têm o mapa, os grupos e a aparência da $name. Muda '
                'onde os dados ficam e quem paga.',
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
                'Community',
                'Grátis',
                'Para começar agora, sem cadastrar pagamento.',
                const [
                  (true, 'Pronta em instantes'),
                  (
                    true,
                    'Dados guardados pela MonAmie, separados das outras organizações',
                  ),
                  (
                    false,
                    'Localização enviada a cada 15 min (perfil Economia)',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _planCard(
                'standard',
                'Standard',
                'Uso no Google',
                'Para quem quer o próprio espaço de dados e mais precisão.',
                [
                  (true, 'Projeto Firebase só da $name'),
                  (true, 'Todos os perfis de acompanhamento, até a cada 1 min'),
                  (
                    false,
                    'Pede uma conta de faturamento do Google Cloud; vocês pagam o uso direto ao Google',
                  ),
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
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(Icons.swap_horiz, size: 18, color: _navy),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Dá para passar do Community para o Standard depois, sem perder grupos nem histórico.',
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
        Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: _line)),
          ),
          child: creationButton(
            community ? 'Continuar com Community' : 'Continuar com Standard',
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
