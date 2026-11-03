import 'dart:ui' show Locale;

import 'package:monamie_app/l10n/app_localizations.dart';

/// The languages the app speaks, for `MaterialApp.supportedLocales`.
///
/// Portuguese (Brazil) first: Flutter falls back to the first entry for a
/// device language the app does not have, and the Material, Widgets and
/// Cupertino delegates ([AppLocalizations.localizationsDelegates]) then use
/// Brazilian Portuguese too (date picker labels, month and weekday names,
/// dd/MM dates). The app's own texts for pt_BR come from `app_pt.arb`.
const List<Locale> appSupportedLocales = [Locale('pt', 'BR'), Locale('en')];
