import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:monamie_app/domain/models/app_language.dart';

part 'language_state.freezed.dart';

/// What the language picker shows, replaced whole by `LanguageViewModel`.
@freezed
abstract class LanguageState with _$LanguageState {
  const factory LanguageState({
    /// The language the app shows now: the person's choice, else the one
    /// the device's languages resolve to. The picker marks it.
    required AppLanguage inUse,
  }) = _LanguageState;
}
