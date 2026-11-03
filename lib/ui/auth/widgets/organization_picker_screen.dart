import 'package:flutter/material.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:monamie_app/ui/core/ui/app_messenger.dart';
import 'package:monamie_app/ui/core/themes/monamie_brand.dart';
import 'package:monamie_app/ui/core/ui/organization_icon.dart';
import 'package:monamie_app/data/model/organization_binding.dart';
import 'package:monamie_app/ui/auth/view_models/organization_choice_view_model.dart';
import 'package:monamie_app/ui/language/view_models/language_view_model.dart';

import 'invite_card.dart';
import 'monamie_account_header.dart';

/// *Escolher organização*: the account belongs to several organizations.
class OrganizationPickerScreen extends StatelessWidget {
  const OrganizationPickerScreen({
    super.key,
    required this.controller,
    required this.language,
    required this.onCreateOrganization,
  });

  final OrganizationChoiceViewModel controller;

  /// The language picker, opened by the globe in the header.
  final LanguageViewModel language;

  /// "Criar nova organização": opens the creation flow over this screen.
  final VoidCallback onCreateOrganization;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    // Dark status bar icons on the cream background.
    value: SystemUiOverlayStyle.dark,
    child: Scaffold(
      backgroundColor: MonAmieBrand.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: ListenableBuilder(
            listenable: Listenable.merge([
              controller,
              controller.recheckOrganizations,
              controller.chooseOrganization,
              controller.acceptInvite,
            ]),
            builder: (context, _) {
              final state = controller.state;
              final l10n = AppLocalizations.of(context);
              final busy = controller.isEntering;
              final entering = state.enteringOrganizationName;
              final choices = state.organizationChoices;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MonAmieAccountHeader(
                    language: language,
                    email: state.signedInEmail,
                    onSwitch: busy
                        ? null
                        : () => runReportingErrors(
                            context,
                            controller.logout.execute,
                          ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    l10n.pickerTitle,
                    style: const TextStyle(
                      fontSize: 30,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.9,
                      color: MonAmieBrand.navy,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.pickerCount(choices.length),
                    style: const TextStyle(
                      fontSize: 15,
                      color: MonAmieBrand.mutedInk,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      children: [
                        // Someone already in an organization can be invited to
                        // another one (or another group): the invites come first.
                        for (final invite in state.pendingInvites) ...[
                          InviteCard(invite: invite, controller: controller),
                          const SizedBox(height: 12),
                        ],
                        for (final (index, binding) in choices.indexed) ...[
                          if (index > 0) const SizedBox(height: 10),
                          _choice(
                            context,
                            binding,
                            busy: busy,
                            entering: entering,
                          ),
                        ],
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: busy || controller.acceptingInvite != null
                        ? null
                        : onCreateOrganization,
                    style: TextButton.styleFrom(
                      foregroundColor: MonAmieBrand.navy,
                      minimumSize: const Size.fromHeight(52),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.pickerCreate),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );

  Widget _choice(
    BuildContext context,
    OrganizationBinding binding, {
    required bool busy,
    required String? entering,
  }) {
    final isEntering = busy && entering == binding.organization.name;
    // Accepting an invite enters its organization: no other choice meanwhile.
    final locked = busy || controller.acceptingInvite != null;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: locked
            ? null
            : () => runReportingErrors(
                context,
                () => controller.chooseOrganization.execute(binding),
              ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              OrganizationIcon(organization: binding.organization, size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  binding.organization.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: MonAmieBrand.navy,
                  ),
                ),
              ),
              isEntering
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: MonAmieBrand.navy,
                      ),
                    )
                  : const Icon(Icons.chevron_right, color: MonAmieBrand.navy),
            ],
          ),
        ),
      ),
    );
  }
}
