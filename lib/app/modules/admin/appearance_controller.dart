import 'package:flutter/foundation.dart';
import 'package:monamie_app/app/config/organization/organization_config.dart';
import 'package:monamie_app/app/config/organization/organization_theme.dart';

import 'appearance_backend.dart';
import 'appearance_state.dart';
import 'logo_converter.dart';

export 'appearance_state.dart';

/// State and actions of an administrator's *Aparência* screen: name, theme and
/// logo, saved together. The screen calls [load] when it opens.
class AppearanceController extends ChangeNotifier {
  AppearanceController({
    required this.organization,
    required this._backend,
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
  final AppearanceBackend _backend;
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
    super.dispose();
  }

  /// The converted logo waiting for "Usar este logo".
  Uint8List? get candidate => _state.candidate;

  /// Loads the themes that can be picked; the organization's own theme
  /// alone when the catalog cannot be read.
  Future<void> load() async {
    _emit(_state.copyWith(isLoadingThemes: true));
    try {
      final themes = await _backend.pickableThemes();
      _emit(_state.copyWith(themes: themes));
    } catch (e) {
      debugPrint('[Appearance] Could not load the themes: $e');
      _emit(_state.copyWith(themes: [organization.effectiveTheme]));
    } finally {
      _emit(_state.copyWith(isLoadingThemes: false));
    }
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

  /// The name being edited (saved with the other changes).
  void setName(String name) => _emit(_state.copyWith(name: name));

  /// Picks theme [themeId] (saved with the other changes).
  void pickTheme(String themeId) => _emit(_state.copyWith(themeId: themeId));

  /// Converts a picked file into the square PNG and shows the preview.
  Future<void> pickLogo(Uint8List bytes) async {
    if (_state.sheet == LogoSheet.processing) return;
    _emit(_state.copyWith(sheet: LogoSheet.processing));
    try {
      final png = await _convertLogo(bytes);
      _emit(_state.copyWith(candidate: png, sheet: LogoSheet.preview));
    } on LogoException catch (e) {
      _emit(_state.copyWith(sheetError: e.message, sheet: LogoSheet.error));
    } catch (e) {
      _emit(
        _state.copyWith(
          sheetError: 'Não deu para abrir este arquivo.',
          sheet: LogoSheet.error,
        ),
      );
    }
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

  /// Saves what changed. Returns whether it worked.
  Future<bool> save() async {
    if (_state.isSaving || !hasChanges) return false;
    _emit(_state.copyWith(isSaving: true, errorMessage: ''));
    try {
      String? logo;
      if (_logoChanged) {
        final png = _state.logoPng;
        if (png == null) {
          await _backend.deleteLogo(organization.id);
          logo = 'removed';
        } else {
          await _backend.uploadLogo(organization.id, png);
          logo = 'set';
        }
      }
      final newName = _state.name.trim();
      final themeId = _state.themeId;
      await _backend.saveBranding(
        organization.id,
        name: newName != organization.name ? newName : null,
        themeId: themeId != organization.effectiveTheme.id ? themeId : null,
        logo: logo,
      );
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
      return true;
    } on AppearanceException catch (e) {
      _emit(_state.copyWith(errorMessage: e.message));
      return false;
    } catch (e) {
      debugPrint('[Appearance] Save failed: $e');
      _emit(
        _state.copyWith(
          errorMessage:
              'Não foi possível salvar agora. Verifique a conexão e tente de '
              'novo.',
        ),
      );
      return false;
    } finally {
      _emit(_state.copyWith(isSaving: false));
    }
  }
}
