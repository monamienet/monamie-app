import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:monamie_app/data/repositories/language/language_repository.dart';
import 'package:monamie_app/domain/models/app_language.dart';
import 'package:monamie_app/ui/language/view_models/language_state.dart';
import 'package:monamie_app/utils/command.dart';
import 'package:monamie_app/utils/result.dart';

export 'language_state.dart';

/// State of the language picker (the sheet opened from the menu and from the
/// entry screens): the language in use, and the choice of another.
///
/// It belongs to the app scope: the entry screens use it before any
/// organization is bound.
class LanguageViewModel extends ChangeNotifier {
  /// [deviceLocales] reads the device's languages, most preferred first, for
  /// the language in use while the person has not chosen one.
  LanguageViewModel({required this._repository, required this._deviceLocales}) {
    _state = LanguageState(inUse: _inUse());
    _repository.language.addListener(_refresh);
  }

  final LanguageRepository _repository;
  final List<Locale> Function() _deviceLocales;

  late LanguageState _state;
  bool _disposed = false;

  /// What the picker shows; replaced whole, never changed in place.
  LanguageState get state => _state;

  AppLanguage _inUse() =>
      _repository.language.value ?? AppLanguage.resolve(_deviceLocales());

  /// Replaces the state, notifying only when it differs.
  void _refresh() {
    final next = LanguageState(inUse: _inUse());
    final changed = next != _state;
    _state = next;
    if (changed && !_disposed) notifyListeners();
  }

  /// Reads the device's languages again. Run by the picker when it opens: the
  /// person may have changed the device's language since the app started.
  late final Command0<void> load = Command0(() async {
    _refresh();
    return const Ok(null);
  });

  /// Uses the language given and stores it; every screen follows at once.
  /// [Err] says why it could not be stored, and the language in use stays.
  late final Command1<void, AppLanguage> choose = Command1(_repository.choose);

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _repository.language.removeListener(_refresh);
    load.dispose();
    choose.dispose();
    super.dispose();
  }
}
