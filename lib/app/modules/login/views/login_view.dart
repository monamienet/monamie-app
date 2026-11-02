import 'package:flutter/material.dart';
import 'package:monamie_app/app/config/organization/monamie_brand.dart';
import 'package:monamie_app/app/config/organization/monamie_mark.dart';
import 'package:monamie_app/app/config/organization/monamie_wordmark.dart';
import 'package:monamie_app/app/modules/login/controllers/session_flow.dart';
import 'package:monamie_app/app/modules/login/controllers/login_controller.dart';
import 'package:monamie_app/app/utils/app_messenger.dart';

import 'widgets/google_button.dart';

/// *Login*: MonAmie's own screen, never in an organization's brand (the organization
/// is only known after sign-in).
///
/// Restores a remembered session after its first frame.
class LoginView extends StatefulWidget {
  const LoginView({super.key, required this.controller, required this.auth});

  final LoginController controller;

  /// The sign-in in progress (Google readiness, the entry's busy state).
  final SessionFlow auth;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  LoginController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => controller.restoreSession(),
    );
  }

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
                  MonAmieWordmark(color: MonAmieBrand.cream),
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
            _action(context),
          ],
        ),
      ),
    ),
  );

  Widget _action(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([controller, widget.auth]),
      builder: (context, _) {
        final auth = widget.auth.state;
        if (controller.state.isRestoringSession || !auth.googleReady) {
          return const Center(
            child: CircularProgressIndicator(color: MonAmieBrand.cream),
          );
        }
        if (auth.isLoading) {
          final name = auth.enteringOrganizationName;
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
        return buildGoogleButton(
          () => runReportingErrors(context, controller.loginGoogle),
        );
      },
    );
  }
}
