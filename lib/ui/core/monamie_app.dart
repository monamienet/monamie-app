import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:monamie_app/data/repositories/session/session_repository.dart';
import 'package:monamie_app/ui/core/themes/monamie_brand.dart';
import 'package:monamie_app/domain/models/organization/organization.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/routing/router.dart';
import 'package:monamie_app/ui/core/app_locales.dart';
import 'package:monamie_app/ui/core/ui/app_messenger.dart';
import 'package:monamie_app/ui/core/themes/app_theme.dart';
import 'package:provider/provider.dart';

/// The app scope: what lives as long as the app, above the router.
///
/// It reads the [SessionRepository] from the providers of `appDependencies`
/// (in `main`, above it), builds the router that follows its session, and
/// holds the theme, which follows the session too: the bound organization's
/// when the session changes while one is bound, MonAmie's when none.
class MonAmieApp extends StatefulWidget {
  const MonAmieApp({super.key});

  @override
  State<MonAmieApp> createState() => _MonAmieAppState();
}

class _MonAmieAppState extends State<MonAmieApp> {
  /// The light theme of the bound organization (MonAmie's when none).
  final _theme = ValueNotifier<ThemeData>(AppTheme.lightTheme);

  late final SessionRepository _session = context.read<SessionRepository>()
    ..session.addListener(_refreshTheme);

  late final GoRouter _router = buildAppRouter(session: _session);

  /// Rebuilds the theme from the bound organization (or MonAmie's when
  /// none). The session changes only after the organization is bound and
  /// the person is known to belong to it, or after it is forgotten, so a
  /// removed person never sees its brand (#78).
  void _refreshTheme() => _theme.value = AppTheme.lightTheme;

  @override
  void dispose() {
    _session.session.removeListener(_refreshTheme);
    _router.dispose();
    _theme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeData>(
    valueListenable: _theme,
    builder: (context, theme, _) => MaterialApp.router(
      debugShowCheckedModeBanner: false,
      // Messages shown by view models, which have no BuildContext of their
      // own, go through this key (the router holds the root navigator's
      // key, for their dialogs).
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      title: Organization.current?.name ?? MonAmieBrand.name,
      theme: theme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      // The app's texts (lib/l10n/) and Material's, in the device's language
      // (Portuguese when the app does not have it).
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: appSupportedLocales,
      routerConfig: _router,
    ),
  );
}
