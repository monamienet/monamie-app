import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/config/partner/partner_icon.dart';
import 'package:monamie_app/app/modules/login/controllers/auth_google_controller.dart';
import 'package:monamie_app/app/utils/color_pallete.dart';

/// Lets a user who belongs to several partners choose which one to enter.
/// Each option shows the partner's own name and icon.
class PartnerPickerView extends GetView<AuthGoogleController> {
  const PartnerPickerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Escolha a organização',
          style: TextStyle(color: AppColors.onPrimaryDark),
        ),
        backgroundColor: AppColors.darkBlue(),
        iconTheme: IconThemeData(color: AppColors.onPrimaryDark),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  controller.enteringPartnerName.value == null
                      ? 'Entrando...'
                      : 'Entrando em ${controller.enteringPartnerName.value}...',
                ),
              ],
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Sua conta participa de mais de uma organização. '
                'Escolha com qual deseja entrar; você pode trocar depois.',
              ),
            ),
            for (final binding in controller.partnerChoices)
              Card(
                child: ListTile(
                  leading: PartnerIcon(partner: binding.partner),
                  title: Text(binding.partner.name),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => controller.choosePartner(binding),
                ),
              ),
          ],
        );
      }),
    );
  }
}
