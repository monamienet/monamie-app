import 'package:flutter/material.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:monamie_app/routing/routes.dart';
import 'package:monamie_app/ui/core/themes/monamie_brand.dart';
import 'package:monamie_app/ui/core/ui/organization_icon.dart';
import 'package:monamie_app/ui/core/ui/app_messenger.dart';
import 'package:monamie_app/utils/result.dart';

import 'package:monamie_app/ui/creation/view_models/create_organization_view_model.dart';
import 'creation_name_step.dart';
import 'creation_plan_step.dart';
import 'creation_review_step.dart';
import 'creation_theme_step.dart';
import 'creation_ui.dart';

const _navy = CreationColors.navy;
const _muted = CreationColors.muted;
const _line = CreationColors.line;

/// *Criar organização*: Nome → Tema → Plano → Revisão
/// ([CreateOrganizationState.step]), then the outcome.
class CreateOrganizationScreen extends StatefulWidget {
  const CreateOrganizationScreen({super.key, required this.controller});

  final CreateOrganizationViewModel controller;

  @override
  State<CreateOrganizationScreen> createState() =>
      _CreateOrganizationScreenState();
}

class _CreateOrganizationScreenState extends State<CreateOrganizationScreen> {
  late final _name = TextEditingController();
  late final _id = TextEditingController();

  CreateOrganizationViewModel get c => widget.controller;

  @override
  void initState() {
    super.initState();
    c.load.execute();
  }

  @override
  void dispose() {
    _name.dispose();
    _id.dispose();
    super.dispose();
  }

  void _back() {
    if (!c.back()) Navigator.pop(context);
  }

  /// "Entrar na `<nome>`": enters the organization and shows why it could
  /// not. Over the picker this screen is still an allowed location, so when
  /// the session lands on the picker it goes back to it itself (over *Sem
  /// organização* the redirect does).
  Future<void> _enter() async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await c.enter.execute();
    if (result == null) return;
    showErrorOf(messenger, result);
    if (result is Ok && c.landedOnPicker && mounted) {
      context.go(Routes.organizationPicker);
    }
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark,
    child: Scaffold(
      backgroundColor: MonAmieBrand.cream,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([c, c.create]),
          builder: (context, _) {
            final result = c.state.result;
            if (result != null) return _outcome(result);
            // The plan screen scrolls between a header and a footer bar that
            // reach the screen's edges (`Plano.dc.html`); the others are one
            // column with 24 px margins.
            final step = c.state.step;
            final plan = step == 2;
            return Padding(
              padding: plan
                  ? const EdgeInsets.only(top: 8)
                  : const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (plan)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _header(step),
                    )
                  else
                    _header(step),
                  SizedBox(
                    height: switch (step) {
                      0 => 24,
                      2 => 12,
                      _ => 20,
                    },
                  ),
                  Expanded(
                    child: switch (step) {
                      0 => CreationNameStep(
                        controller: c,
                        nameField: _name,
                        idField: _id,
                      ),
                      1 => CreationThemeStep(controller: c),
                      2 => CreationPlanStep(controller: c),
                      _ => CreationReviewStep(controller: c),
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );

  /// Back arrow, the screen's name and "n de 4", over a four-segment progress
  /// bar (`CriarNome.dc.html`): the arrow's box starts 12 px left of the
  /// 24 px margin, so the arrow lines up with the text below.
  Widget _header(int step) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Transform.translate(
          offset: const Offset(-12, 0),
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                IconButton(
                  tooltip: l10n.commonBack,
                  constraints: const BoxConstraints.tightFor(
                    width: 48,
                    height: 48,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: c.create.running ? null : _back,
                  icon: const Icon(Icons.arrow_back, color: _navy),
                ),
                const SizedBox(width: 8),
                // Expanded: the step counter keeps its room, and a longer
                // title in another language gives way (ellipsis).
                Expanded(
                  child: Text(
                    l10n.creationTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _navy,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    l10n.creationStep(
                      step + 1,
                      CreateOrganizationViewModel.stepCount,
                    ),
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
            for (var i = 0; i < CreateOrganizationViewModel.stepCount; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= step ? _navy : _line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _outcome(String status) {
    final name = c.state.name.trim();
    final l10n = AppLocalizations.of(context);
    final (title, text, action) = switch (status) {
      'active' => (
        l10n.creationReadyTitle(name),
        l10n.creationReadyBody,
        l10n.creationReadyEnter(name),
      ),
      'awaiting_billing' => (
        l10n.creationBillingTitle,
        l10n.creationBillingBody(name, c.state.id),
        l10n.commonGotIt,
      ),
      _ => (
        l10n.creationFailedTitle(name),
        l10n.creationFailedBody(c.state.id),
        l10n.commonSignOut,
      ),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: OrganizationIcon(
              organization: c.preview(
                placeholderName: l10n.creationPreviewName,
              ),
              size: 72,
            ),
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
          creationButton(
            action,
            status == 'active' ? _enter : () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
