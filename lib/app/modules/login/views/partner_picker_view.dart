import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/config/partner/monamie_brand.dart';
import 'package:monamie_app/app/config/partner/partner_icon.dart';
import 'package:monamie_app/app/modules/login/controllers/auth_google_controller.dart';

import 'widgets/monamie_account_header.dart';

/// *Escolher organização*: the account belongs to several organizations.
class PartnerPickerView extends GetView<AuthGoogleController> {
  const PartnerPickerView({super.key});

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
            final entering = controller.enteringPartnerName.value;
            final choices = controller.partnerChoices;
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
                  'Você participa de ${choices.length}. Dá para trocar depois '
                  'pelo menu.',
                  style: const TextStyle(
                    fontSize: 15,
                    color: MonAmieBrand.mutedInk,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.separated(
                    itemCount: choices.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final binding = choices[index];
                      final isEntering =
                          busy && entering == binding.partner.name;
                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: busy
                              ? null
                              : () => controller.choosePartner(binding),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                PartnerIcon(partner: binding.partner, size: 48),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    binding.partner.name,
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
                                    : const Icon(
                                        Icons.chevron_right,
                                        color: MonAmieBrand.navy,
                                      ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                TextButton.icon(
                  onPressed: busy ? null : controller.startCreatingOrganization,
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
}
