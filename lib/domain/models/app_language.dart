import 'dart:ui' show Locale;

/// A language the app speaks, with the [Locale] its texts and Material's use.
///
/// The person's choice is stored by its [name] (`LanguageRepository`).
enum AppLanguage {
  pt(Locale('pt', 'BR')),
  en(Locale('en')),
  es(Locale('es')),
  fr(Locale('fr'));

  const AppLanguage(this.locale);

  /// The locale the app runs in when this language is in use. Portuguese is
  /// Brazilian, which Material's date picker and formats follow; Spanish is
  /// the neutral one, which uses "tú"; French uses "vous".
  final Locale locale;

  /// What a device language the app does not have resolves to.
  static const AppLanguage fallback = AppLanguage.en;

  /// The language stored as [name], or `null` for none or one this build does
  /// not have (a choice saved by a newer version).
  static AppLanguage? tryParse(String? name) {
    for (final language in values) {
      if (language.name == name) return language;
    }
    return null;
  }

  /// The language the app shows for [deviceLocales], most preferred first:
  /// the first one whose language the app has (Portuguese from Portugal gets
  /// Brazilian Portuguese), else [fallback].
  ///
  /// `MaterialApp` resolves its locale through this rule and the language
  /// picker marks the result, so the language marked is always the one on
  /// screen.
  static AppLanguage resolve(Iterable<Locale> deviceLocales) {
    for (final locale in deviceLocales) {
      for (final language in values) {
        if (language.locale.languageCode == locale.languageCode) {
          return language;
        }
      }
    }
    return fallback;
  }
}
