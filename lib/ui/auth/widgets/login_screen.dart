import 'package:flutter/material.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/ui/core/themes/monamie_brand.dart';
import 'package:monamie_app/ui/core/ui/monamie_mark.dart';
import 'package:monamie_app/ui/core/ui/monamie_wordmark.dart';
import 'package:monamie_app/ui/auth/view_models/login_view_model.dart';
import 'package:monamie_app/ui/core/ui/app_messenger.dart';
import 'package:monamie_app/ui/language/view_models/language_view_model.dart';
import 'package:monamie_app/ui/language/widgets/language_button.dart';
import 'package:monamie_app/ui/language/widgets/language_scheme.dart';

import 'google_button.dart';

/// *Login*: MonAmie's own screen, never in an organization's brand (the organization
/// is only known after sign-in).
///
/// Restores a remembered session after its first frame.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.controller,
    required this.language,
  });

  final LoginViewModel controller;

  /// The language picker, opened by the globe in the corner.
  final LanguageViewModel language;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  LoginViewModel get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => controller.restoreSession.execute(),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: MonAmieBrand.navy,
    body: SafeArea(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const MonAmieMark(width: 150, color: MonAmieBrand.cream),
                      const SizedBox(height: 28),
                      const MonAmieWordmark(color: MonAmieBrand.cream),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: 280,
                        child: Text(
                          AppLocalizations.of(context).loginTagline,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 17,
                            height: 1.5,
                            color: MonAmieBrand.mutedCream,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _action(context),
              ],
            ),
          ),
          Positioned(
            top: 16,
            right: 20,
            child: LanguageButton(
              controller: widget.language,
              scheme: LanguageScheme.login,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _action(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final state = controller.state;
        if (state.isRestoringSession || !state.googleReady) {
          return const Center(
            child: CircularProgressIndicator(color: MonAmieBrand.cream),
          );
        }
        if (state.isLoading) {
          final name = state.enteringOrganizationName;
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
                      ? AppLocalizations.of(context).loginLookingForOrganization
                      : AppLocalizations.of(context).loginEntering(name),
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
        return buildGoogleButton(
          () => runReportingErrors(context, controller.loginGoogle.execute),
          locale: Localizations.localeOf(context),
        );
      },
    );
  }
}
