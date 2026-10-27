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
                  _Wordmark(),
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

/// "monamie" with a dotless ı and a coral dot drawn over it, with the
/// measures of the design canvas (`Main.dc.html`): 48 px, weight 800,
/// letter-spacing -0.045 em, a dot of 0.15 em placed 0.13 em from the top of
/// the line and 0.073 em from the left of the ı.
///
/// CSS puts the letter-spacing after a glyph, while Flutter centers it around
/// a glyph drawn on its own, which moved the ı 0.0225 em left of its cell (a
/// tighter gap before it, a wider one after, and a dot off its stem). The ı is
/// moved back, so its stem and the dot sit where the canvas has them (both
/// centered at 0.148 em).
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  static const _size = 48.0;
  static const _letterSpacing = -0.045 * _size;
  static const _style = TextStyle(
    fontSize: _size,
    height: 1,
    fontWeight: FontWeight.w800,
    letterSpacing: _letterSpacing,
    color: MonAmieBrand.cream,
  );

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'monamie',
    excludeSemantics: true,
    child: Text.rich(
      TextSpan(
        style: _style,
        children: [
          const TextSpan(text: 'monam'),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Transform.translate(
                  offset: const Offset(-_letterSpacing / 2, 0),
                  child: const Text('ı', style: _style),
                ),
                Positioned(
                  left: 0.073 * _size,
                  top: 0.13 * _size,
                  child: Container(
                    width: 0.15 * _size,
                    height: 0.15 * _size,
                    decoration: const BoxDecoration(
                      color: MonAmieBrand.coral,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const TextSpan(text: 'e'),
        ],
      ),
    ),
  );
}
