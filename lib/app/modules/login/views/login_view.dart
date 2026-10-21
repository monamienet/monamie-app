import 'package:flutter/material.dart';
import 'package:monamie_app/app/config/partner/monamie_brand.dart';
import 'package:monamie_app/app/config/partner/partner.dart';
import 'package:monamie_app/app/config/partner/partner_logo.dart';
import 'package:monamie_app/app/modules/login/controllers/auth_google_controller.dart';
import 'package:monamie_app/app/modules/login/controllers/login_controller.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/utils/color_pallete.dart';

import 'widgets/google_button.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  AppBar _appBar() {
    return AppBar(
      title: Text(
        Partner.current?.displayName ?? MonAmieBrand.name,
        style: TextStyle(
          color: AppColors.onPrimaryDark,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      backgroundColor: AppColors.darkBlue(),
      elevation: 0,
    );
  }

  Widget _body() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const PartnerLogo(width: 220, height: 220),
            const SizedBox(height: 48),
            _loginButton(),
          ],
        ),
      ),
    );
  }

  Widget _loginButton() {
    final authController = Get.find<AuthGoogleController>();

    return Obx(() {
      if (controller.isRestoringSession.value ||
          !authController.googleReady.value) {
        return CircularProgressIndicator(color: AppColors.primary);
      }
      if (authController.isLoading.value) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              authController.enteringPartnerName.value == null
                  ? "Procurando sua organização..."
                  : "Entrando em ${authController.enteringPartnerName.value}...",
              style: TextStyle(color: AppColors.darkBlue(), fontSize: 14),
            ),
          ],
        );
      }
      return buildGoogleButton(() => controller.loginGoogle());
    });
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthGoogleController>();
    // Rebuilds in the partner's brand once it is bound ("Entrando em ...").
    return Obx(() {
      authController.enteringPartnerName.value;
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _appBar(),
        body: _body(),
      );
    });
  }
}
