import 'package:flutter/material.dart';
import 'package:monamie_app/app/config/partner/monamie_brand.dart';
import 'package:monamie_app/app/config/partner/monamie_mark.dart';
import 'package:monamie_app/app/modules/login/controllers/auth_google_controller.dart';
import 'package:monamie_app/app/modules/login/controllers/login_controller.dart';
import 'package:get/get.dart';

import 'widgets/google_button.dart';

/// *Login*: MonAmie's own screen, never in a partner's brand (the partner
/// is only known after sign-in).
class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: MonAmieBrand.navy,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MonAmieMark(width: 150, color: MonAmieBrand.cream),
                  SizedBox(height: 28),
                  Text(
                    'monamie',
                    style: TextStyle(
                      fontSize: 48,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -2.2,
                      color: MonAmieBrand.cream,
                    ),
                  ),
                  SizedBox(height: 28),
                  SizedBox(
                    width: 280,
                    child: Text(
                      MonAmieBrand.tagline,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.5,
                        color: MonAmieBrand.mutedCream,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _action(),
          ],
        ),
      ),
    ),
  );

  Widget _action() {
    final auth = Get.find<AuthGoogleController>();
    return Obx(() {
      if (controller.isRestoringSession.value || !auth.googleReady.value) {
        return const Center(
          child: CircularProgressIndicator(color: MonAmieBrand.cream),
        );
      }
      if (auth.isLoading.value) {
        final name = auth.enteringPartnerName.value;
        return SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  color: MonAmieBrand.cream,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                name == null
                    ? 'Procurando sua organização…'
                    : 'Entrando em $name…',
                style: const TextStyle(
                  color: MonAmieBrand.cream,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      }
      return buildGoogleButton(controller.loginGoogle);
    });
  }
}
