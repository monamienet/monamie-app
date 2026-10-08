import 'package:flutter/material.dart';
import 'package:monamie_app/app/modules/login/controllers/auth_google_controller.dart';
import 'package:monamie_app/app/modules/login/controllers/login_controller.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/utils/color_pallete.dart';

import 'widgets/google_button.dart';


class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  AppBar _appBar() {
    return AppBar(
        title: const Text('MonAmie AquariusTur', style: TextStyle(color: Colors.white),),
        centerTitle: true,
        backgroundColor: AppColors.darkBlue(),
      );
  }

  //Widget _body() {
  //  //return Center(
  //  //    child: _loginButton()
  //  //  );
  //  return _loginButton();
  //}

  Widget _body() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 50),
          _loginButton()
        ],
      )
    );
  }

  Widget _loginButton() {
    final authController = Get.find<AuthGoogleController>();

    // Obx reconstrói esse widget quando googleReady ou isLoading mudar de valor
    return Obx(() {
      if (!authController.googleReady.value) {
        return const CircularProgressIndicator();
      }
      if (authController.isLoading.value) {
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              "Fazendo login...",
              style: TextStyle(color: Colors.white70, fontSize: 14),
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
      backgroundColor: AppColors.darkBlue(),
      appBar: _appBar(),
      body: _body()
    );
  }
}
