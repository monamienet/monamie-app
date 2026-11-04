import 'package:flutter/foundation.dart';
import 'package:monamie_app/domain/models/app_language.dart';
import 'package:monamie_app/utils/result.dart';

/// The language the person chose for the app, kept on the device.
///
/// It belongs to the app scope: the sign-in screens need it before any
/// organization is bound, and it follows the person across organizations.
abstract class LanguageRepository {
  /// The language chosen, or `null` until the person chooses: the device's
  /// language is then in use (`AppLanguage.resolve`).
  ValueListenable<AppLanguage?> get language;

  /// Reads the stored choice. Called once, before the app runs, so its first
  /// frame is already in the right language.
  Future<void> restore();

  /// Uses and stores [language]. Fails when the choice could not be stored;
  /// the language in use is then unchanged.
  Future<Result<void>> choose(AppLanguage language);
}
