import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:monamie_app/app/modules/login/controllers/auth_google_controller.dart';
import 'package:monamie_app/app/modules/login/controllers/login_controller.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/utils/color_pallete.dart';

import 'widgets/google_button.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  AppBar _appBar() {
    return AppBar(
      title: const Text(
        'MonAmie AquariusTur',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
            SvgPicture.asset(
              'assets/aquariustur/AquariusTurLogo.svg',
              width: 220,
              height: 220,
              fit: BoxFit.contain,
            ),
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
      if (!authController.googleReady.value) {
        return CircularProgressIndicator(color: AppColors.primary);
      }
      if (authController.isLoading.value) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              "Fazendo login...",
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _appBar(),
      body: _body(),
    );
  }
}
