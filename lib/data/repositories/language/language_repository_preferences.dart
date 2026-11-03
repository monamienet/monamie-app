import 'package:flutter/foundation.dart';
import 'package:monamie_app/data/repositories/language/language_repository.dart';
import 'package:monamie_app/data/services/language_preferences_service.dart';
import 'package:monamie_app/domain/models/app_language.dart';
import 'package:monamie_app/utils/result.dart';

/// [LanguageRepository] over [LanguagePreferencesService].
class LanguageRepositoryPreferences implements LanguageRepository {
  LanguageRepositoryPreferences({required this._service});

  final LanguagePreferencesService _service;

  final _language = ValueNotifier<AppLanguage?>(null);

  @override
  ValueListenable<AppLanguage?> get language => _language;

  @override
  Future<void> restore() async {
    try {
      _language.value = AppLanguage.tryParse(await _service.read());
    } catch (error) {
      // An unreadable storage leaves the device's language in use.
      debugPrint('Ignoring an unreadable language choice: $error');
    }
  }

  @override
  Future<Result<void>> choose(AppLanguage language) async {
    try {
      await _service.write(language.name);
    } catch (error, stackTrace) {
      return Err(
        const Failure.languageNotSaved(),
        error: error,
        stackTrace: stackTrace,
      );
    }
    _language.value = language;
    return const Ok(null);
  }
}
