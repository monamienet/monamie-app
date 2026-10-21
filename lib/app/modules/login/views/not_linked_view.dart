import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/config/partner/partner_logo.dart';
import 'package:monamie_app/app/routes/app_pages.dart';
import 'package:monamie_app/app/utils/color_pallete.dart';

/// Shown, in the MonAmie brand, when the signed-in Google account belongs to
/// no active partner: it is in no `<id>NN@monamienet.org` group.
class NotLinkedView extends StatelessWidget {
  const NotLinkedView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PartnerLogo(width: 160, height: 160),
                const SizedBox(height: 32),
                Text(
                  'Sua conta não está vinculada a nenhuma organização.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Fale com o responsável pela sua equipe para ser '
                  'adicionado e tente novamente.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Get.offAllNamed(Routes.LOGIN),
                  child: const Text('Voltar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
