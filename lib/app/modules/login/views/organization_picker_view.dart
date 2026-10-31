import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/config/organization/monamie_brand.dart';
import 'package:monamie_app/app/config/organization/organization_icon.dart';
import 'package:monamie_app/app/data/organization/organization_binding.dart';
import 'package:monamie_app/app/modules/login/controllers/auth_google_controller.dart';

import 'widgets/invite_card.dart';
import 'widgets/monamie_account_header.dart';

/// *Escolher organização*: the account belongs to several organizations.
class OrganizationPickerView extends GetView<AuthGoogleController> {
  const OrganizationPickerView({super.key});

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    // Dark status bar icons on the cream background.
    value: SystemUiOverlayStyle.dark,
    child: Scaffold(
      backgroundColor: MonAmieBrand.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Obx(() {
            final busy = controller.isLoading.value;
            final entering = controller.enteringOrganizationName.value;
            final choices = controller.organizationChoices;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MonAmieAccountHeader(
                  email: controller.signedInEmail.value,
                  onSwitch: busy ? null : controller.logout,
                ),
                const SizedBox(height: 28),
                const Text(
                  'Em qual organização você quer entrar?',
                  style: TextStyle(
                    fontSize: 30,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.9,
                    color: MonAmieBrand.navy,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  choices.length == 1
                      ? 'Você participa de 1 organização.'
                      : 'Você participa de ${choices.length}. Dá para trocar '
                            'depois pelo menu.',
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
                      for (final invite in controller.pendingInvites) ...[
                        InviteCard(invite: invite, controller: controller),
                        const SizedBox(height: 12),
                      ],
                      for (final (index, binding) in choices.indexed) ...[
                        if (index > 0) const SizedBox(height: 10),
                        _choice(binding, busy: busy, entering: entering),
                      ],
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: busy || controller.acceptingInvite.value != null
                      ? null
                      : controller.startCreatingOrganization,
                  style: TextButton.styleFrom(
                    foregroundColor: MonAmieBrand.navy,
                    minimumSize: const Size.fromHeight(52),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Criar nova organização'),
                ),
              ],
            );
          }),
        ),
      ),
    ),
  );

  Widget _choice(
    OrganizationBinding binding, {
    required bool busy,
    required String? entering,
  }) {
    final isEntering = busy && entering == binding.organization.name;
    // Accepting an invite enters its organization: no other choice meanwhile.
    final locked = busy || controller.acceptingInvite.value != null;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: locked ? null : () => controller.chooseOrganization(binding),
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
