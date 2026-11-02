import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:monamie_app/app/config/organization/monamie_brand.dart';
import 'package:monamie_app/app/config/organization/organization.dart';
import 'package:monamie_app/app/modules/login/controllers/auth_google_controller.dart';
import 'package:monamie_app/app/routes/app_router.dart';
import 'package:monamie_app/app/utils/app_messenger.dart';
import 'package:monamie_app/app/utils/app_theme.dart';
import 'package:provider/provider.dart';

/// The app scope: what lives as long as the app, above the router.
///
/// It creates and starts the [AuthGoogleController] once (web sign-in
/// listener, Google Sign-In initialization), provides it to the routes,
/// builds the router that follows its session, and holds the theme, which
/// the controller rebuilds when an organization is bound or forgotten.
class MonAmieApp extends StatefulWidget {
  const MonAmieApp({super.key});

  @override
  State<MonAmieApp> createState() => _MonAmieAppState();
}

class _MonAmieAppState extends State<MonAmieApp> {
  /// The light theme of the bound organization (MonAmie's when none).
  final _theme = ValueNotifier<ThemeData>(AppTheme.lightTheme);

  late final AuthGoogleController _auth = AuthGoogleController(
    // Messages no screen waits for go through the root messenger.
    notices: const ScaffoldNoticePresenter(),
    refreshTheme: () => _theme.value = AppTheme.lightTheme,
  )..start();

  late final GoRouter _router = buildAppRouter(auth: _auth);

  @override
  void dispose() {
    _router.dispose();
    _auth.dispose();
    _theme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider<AuthGoogleController>.value(
        value: _auth,
        child: ValueListenableBuilder<ThemeData>(
          valueListenable: _theme,
          builder: (context, theme, _) => MaterialApp.router(
            debugShowCheckedModeBanner: false,
            // Messages shown by controllers, which have no BuildContext of
            // their own, go through this key (the router holds the root
            // navigator's key, for their dialogs).
            scaffoldMessengerKey: rootScaffoldMessengerKey,
            title: Organization.current?.name ?? MonAmieBrand.name,
            theme: theme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            routerConfig: _router,
          ),
        ),
      );
}
