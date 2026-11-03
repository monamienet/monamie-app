import 'dart:ui' show Locale;

import 'package:monamie_app/domain/models/app_language.dart';
import 'package:monamie_app/l10n/app_localizations.dart';

/// The languages the app speaks, for `MaterialApp.supportedLocales`: the
/// [AppLanguage]s' locales, English first.
///
/// English first: it is what a device language the app does not have gets,
/// and the Material, Widgets and Cupertino delegates
/// ([AppLocalizations.localizationsDelegates]) then use English too. The
/// Portuguese entry is Brazilian, which the date picker labels, month and
/// weekday names and dd/MM dates follow (the app's own texts for pt_BR come
/// from `app_pt.arb`).
const List<Locale> appSupportedLocales = [
  Locale('en'),
  Locale('pt', 'BR'),
  Locale('es'),
];

/// `MaterialApp.localeListResolutionCallback`: the locale of the language the
/// app shows for the device's languages, or for the one the person chose,
/// which `MaterialApp` puts first ([AppLanguage.resolve]).
Locale resolveAppLocale(
  List<Locale>? preferredLocales,
  Iterable<Locale> supportedLocales,
) => AppLanguage.resolve(preferredLocales ?? const []).locale;
