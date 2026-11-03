import 'package:flutter/foundation.dart';
import 'package:monamie_app/domain/models/organization/organization_config.dart';
import 'package:monamie_app/domain/models/organization/organization_theme.dart';

import 'package:monamie_app/data/repositories/appearance/appearance_repository.dart';
import 'package:monamie_app/utils/command.dart';
import 'package:monamie_app/utils/result.dart';
import 'appearance_state.dart';
import 'package:monamie_app/data/services/logo_converter.dart';

export 'appearance_state.dart';

/// State and actions of an administrator's *Aparência* screen: name, theme and
/// logo, saved together. The screen runs [load] when it opens.
class AppearanceViewModel extends ChangeNotifier {
  AppearanceViewModel({
    required this.organization,
    required this._repository,
    Future<Uint8List> Function(Uint8List bytes)? convertLogo,
    this._onSaved,
  }) : _convertLogo = convertLogo ?? toSquareLogoPng,
       _state = AppearanceState(
         name: organization.name,
         themeId: organization.effectiveTheme.id,
         logoPng: organization.logoPng,
       );

  /// The organization as it is now (bound).
  final OrganizationConfig organization;
  final AppearanceRepository _repository;
  final Future<Uint8List> Function(Uint8List bytes) _convertLogo;
  final Future<void> Function(OrganizationConfig saved)? _onSaved;

  AppearanceState _state;
  bool _disposed = false;

  /// What the screen shows; replaced whole, never changed in place.
  AppearanceState get state => _state;

  /// Replaces the state, notifying only when it differs.
  void _emit(AppearanceState next) {
    final changed = next != _state;
    _state = next;
    if (changed && !_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    load.dispose();
    pickLogo.dispose();
    save.dispose();
    super.dispose();
  }

  /// Loads the themes that can be picked; the organization's own theme
  /// alone when the catalog cannot be read (so it always ends [Ok]).
  late final Command0<void> load = Command0(_load);

  /// Converts a picked file into the square PNG and shows the preview, or
  /// says in [AppearanceState.sheetFailure] why it cannot be used (so it
  /// always ends [Ok]).
  late final Command1<void, Uint8List> pickLogo = Command1(_pickLogo);

  /// Saves what changed. The failure is also kept in
  /// [AppearanceState.failure]. Ignored when nothing changed.
  late final Command0<void> save = Command0(_save, blocked: () => !hasChanges);

  /// The converted logo waiting for "Usar este logo".
  Uint8List? get candidate => _state.candidate;

  Future<Result<void>> _load() async {
    final themes = switch (await _repository.pickableThemes()) {
      Ok(:final value) => value,
      Err() => [organization.effectiveTheme],
    };
    _emit(_state.copyWith(themes: themes));
    return const Ok(null);
  }

  /// The theme currently picked, for the screen's colors.
  OrganizationTheme get pickedTheme =>
      _state.themes.where((t) => t.id == _state.themeId).firstOrNull ??
      organization.effectiveTheme;

  bool get _logoChanged => !identical(_state.logoPng, organization.logoPng);

  /// Whether anything differs from what is saved.
  bool get hasChanges =>
      _state.name.trim() != organization.name ||
      _state.themeId != organization.effectiveTheme.id ||
      _logoChanged;

  /// The name being edited (saved with the other changes): [name] trimmed;
  /// a name shorter than 2 characters is ignored.
  void setName(String name) {
    final clean = name.trim();
    if (clean.length < 2) return;
    _emit(_state.copyWith(name: clean));
  }

  /// Picks theme [themeId] (saved with the other changes).
  void pickTheme(String themeId) => _emit(_state.copyWith(themeId: themeId));

  Future<Result<void>> _pickLogo(Uint8List bytes) async {
    _emit(_state.copyWith(sheet: LogoSheet.processing));
    try {
      final png = await _convertLogo(bytes);
      _emit(_state.copyWith(candidate: png, sheet: LogoSheet.preview));
    } on LogoException catch (e) {
      _emit(_state.copyWith(sheetFailure: e.failure, sheet: LogoSheet.error));
    } catch (e) {
      _emit(
        _state.copyWith(
          sheetFailure: const Failure.logoNotOpened(),
          sheet: LogoSheet.error,
        ),
      );
    }
    return const Ok(null);
  }

  /// Keeps the previewed logo (saved with the other changes).
  void useCandidate() {
    final png = _state.candidate;
    if (png == null) return;
    _emit(
      _state.copyWith(logoPng: png, candidate: null, sheet: LogoSheet.closed),
    );
  }

  void closeSheet() {
    if (_state.sheet == LogoSheet.processing) return;
    _emit(_state.copyWith(candidate: null, sheet: LogoSheet.closed));
  }

  /// Back to the name's initial (saved with the other changes).
  void removeLogo() => _emit(_state.copyWith(logoPng: null));

  Future<Result<void>> _save() async {
    _emit(_state.copyWith(failure: null));
    try {
      String? logo;
      if (_logoChanged) {
        final png = _state.logoPng;
        final Result<void> stored;
        if (png == null) {
          stored = await _repository.deleteLogo(organization.id);
          logo = 'removed';
        } else {
          stored = await _repository.uploadLogo(organization.id, png);
          logo = 'set';
        }
        if (stored case Err(:final failure)) {
          _emit(_state.copyWith(failure: failure));
          return stored;
        }
      }
      final newName = _state.name.trim();
      final themeId = _state.themeId;
      final saved = await _repository.saveBranding(
        organization.id,
        name: newName != organization.name ? newName : null,
        themeId: themeId != organization.effectiveTheme.id ? themeId : null,
        logo: logo,
      );
      if (saved case Err(:final failure)) {
        _emit(_state.copyWith(failure: failure));
        return saved;
      }
      await _onSaved?.call(
        OrganizationConfig(
          id: organization.id,
          name: newName,
          themeId: _state.themeId,
          theme: pickedTheme,
          logoVersion: logo == 'removed'
              ? null
              : (logo == 'set'
                    ? DateTime.now().millisecondsSinceEpoch
                    : organization.logoVersion),
          logoPng: _state.logoPng,
        ),
      );
      return const Ok(null);
    } catch (e, stackTrace) {
      // Storing the saved branding on the device failed.
      debugPrint('[Appearance] Save failed: $e');
      const failure = Failure.connection(FailedAction.save);
      _emit(_state.copyWith(failure: failure));
      return Err(failure, error: e, stackTrace: stackTrace);
    }
  }
}
