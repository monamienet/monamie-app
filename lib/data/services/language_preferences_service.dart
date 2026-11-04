import 'package:shared_preferences/shared_preferences.dart';

/// The language the person chose, kept in SharedPreferences.
///
/// Only the UI isolate reads it; the tracking service gets the texts it needs
/// from the UI. Both methods may throw when the storage fails.
class LanguagePreferencesService {
  LanguagePreferencesService({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  /// The key of the stored language.
  static const key = 'language';

  final SharedPreferencesAsync _preferences;

  /// The stored `AppLanguage.name`, or `null` when none was stored.
  Future<String?> read() => _preferences.getString(key);

  Future<void> write(String language) => _preferences.setString(key, language);
}
