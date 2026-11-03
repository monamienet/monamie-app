import 'package:flutter/foundation.dart';
import 'package:monamie_app/data/repositories/language/language_repository.dart';
import 'package:monamie_app/domain/models/app_language.dart';
import 'package:monamie_app/utils/result.dart';

import 'fake_outcomes.dart';

/// [LanguageRepository] in memory: [stored] stands for what the device
/// keeps, [restore] reads it and [choose] writes it. A failure asked for
/// with `fail('choose', …)` changes nothing, as the real one.
class FakeLanguageRepository with FakeOutcomes implements LanguageRepository {
  /// Starts with [stored] kept on the device (none when omitted).
  FakeLanguageRepository({this.stored});

  /// What the device keeps between launches.
  AppLanguage? stored;

  final _language = ValueNotifier<AppLanguage?>(null);

  @override
  ValueListenable<AppLanguage?> get language => _language;

  @override
  Future<void> restore() => run('restore', const [], () {
    _language.value = stored;
  });

  @override
  Future<Result<void>> choose(AppLanguage language) =>
      answer('choose', [language], () {
        stored = language;
        _language.value = language;
      });
}
