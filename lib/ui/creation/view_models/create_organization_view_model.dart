import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:monamie_app/domain/models/organization/organization_id.dart';
import 'package:monamie_app/domain/models/organization/organization_theme.dart';
import 'package:monamie_app/data/repositories/theme/theme_catalog.dart';

import 'create_organization_state.dart';
import 'package:monamie_app/data/repositories/creation/creation_backend.dart';

export 'create_organization_state.dart';

const _maxIdLength = 20;

/// The identifier suggested for an organization name: its letters only,
/// without accents, lower case, at most 20 ("Rota Sul" → "rotasul"). Twin
/// of `suggestOrganizationId` in central/functions/organization_creation.js.
String suggestOrganizationId(String name) {
  const accents = {
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
    'ñ': 'n',
  };
  final letters = StringBuffer();
  for (final char in name.toLowerCase().split('')) {
    final plain = accents[char] ?? char;
    if (RegExp(r'^[a-z]$').hasMatch(plain)) letters.write(plain);
  }
  final id = letters.toString();
  return id.length > _maxIdLength ? id.substring(0, _maxIdLength) : id;
}

/// The id's format problem as the person sees it, or `null`.
String? idFormatProblem(String id) {
  if (id.isEmpty) return 'Mínimo 3 letras';
  if (!RegExp(r'^[a-z]+$').hasMatch(id)) {
    return 'Use só letras minúsculas, sem acentos nem espaços.';
  }
  if (id.length < 3) return 'Mínimo 3 letras';
  if (id.length > _maxIdLength) return 'Use no máximo $_maxIdLength letras.';
  if (organizationIdProblem(id) != null) {
    return 'Esse identificador é reservado.';
  }
  return null;
}

/// State of *Criar organização*: name and identifier, theme, plan, review,
/// then the creation itself. The screen calls [load] when it opens; its
/// route disposes the controller when it closes, which stops the pending id
/// check.
class CreateOrganizationViewModel extends ChangeNotifier {
  CreateOrganizationViewModel({
    required this._backend,
    required this._themes,
    this.debounce = const Duration(milliseconds: 500),
  });

  final CreationBackend _backend;
  final ThemeCatalog _themes;
  final Duration debounce;

  CreateOrganizationState _state = CreateOrganizationState(
    themeId: defaultOrganizationTheme.id,
  );
  bool _disposed = false;

  /// What the screen shows; replaced whole, never changed in place.
  CreateOrganizationState get state => _state;

  /// Replaces the state, notifying only when it differs.
  void _emit(CreateOrganizationState next) {
    final changed = next != _state;
    _state = next;
    if (changed && !_disposed) notifyListeners();
  }

  /// Once the person edits the id, the name stops suggesting it.
  bool _idEdited = false;

  /// The pending id check, run once the person stops typing.
  Timer? _timer;

  /// The plans that can be picked for now. Standard stays on screen, greyed
  /// out, until it is opened to organizations.
  static const offeredPlans = {'community'};

  /// Picks [id] when it is offered and nothing is being created.
  void pickPlan(String id) {
    if (_state.isCreating || !offeredPlans.contains(id)) return;
    _emit(_state.copyWith(plan: id));
  }

  /// Picks theme [id].
  void pickTheme(String id) => _emit(_state.copyWith(themeId: id));

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }

  /// Loads the themes that can be picked; the default theme alone when the
  /// catalog cannot be read.
  Future<void> load() async {
    try {
      final themes = pickableThemes((await _themes.themes()).values);
      _emit(_state.copyWith(themes: themes));
    } catch (e) {
      debugPrint('[Creation] Could not load themes: $e');
      _emit(_state.copyWith(themes: [defaultOrganizationTheme]));
    }
  }

  OrganizationTheme get pickedTheme =>
      _state.themes.where((t) => t.id == _state.themeId).firstOrNull ??
      defaultOrganizationTheme;

  void setName(String value) {
    _emit(_state.copyWith(name: value));
    if (!_idEdited) _setId(suggestOrganizationId(value));
  }

  void setId(String value) {
    _idEdited = true;
    _setId(value.trim());
  }

  void _setId(String value) {
    _timer?.cancel();
    final problem = idFormatProblem(value);
    if (problem != null) {
      _emit(
        _state.copyWith(
          id: value,
          idCheck: IdCheck.unavailable,
          idProblem: problem,
        ),
      );
      return;
    }
    _emit(_state.copyWith(id: value, idCheck: IdCheck.checking, idProblem: ''));
    _timer = Timer(debounce, () => _check(value));
  }

  Future<void> _check(String value) async {
    try {
      final problem = await _backend.idProblem(value);
      if (_state.id != value) return; // typed on meanwhile
      _emit(
        _state.copyWith(
          idCheck: problem == null ? IdCheck.available : IdCheck.unavailable,
          idProblem: problem ?? '',
        ),
      );
    } catch (e) {
      if (_state.id != value) return;
      _emit(
        _state.copyWith(
          idCheck: IdCheck.unavailable,
          idProblem: 'Não foi possível verificar agora.',
        ),
      );
    }
  }

  bool get nameValid {
    final clean = _state.name.trim();
    return clean.length >= 2 &&
        clean.length <= 40 &&
        !clean.toLowerCase().startsWith('monamie ');
  }

  bool get canContinueFromName =>
      nameValid && _state.idCheck == IdCheck.available;

  /// Creates the organization. Returns whether the call went through (the
  /// status is in [CreateOrganizationState.result]).
  Future<bool> create() async {
    if (_state.isCreating || !canContinueFromName) return false;
    _emit(_state.copyWith(isCreating: true, errorMessage: ''));
    try {
      final result = await _backend.create(
        id: _state.id,
        name: _state.name.trim(),
        themeId: _state.themeId,
        plan: _state.plan,
      );
      _emit(_state.copyWith(result: result));
      return true;
    } on CreationException catch (e) {
      _emit(_state.copyWith(errorMessage: e.message));
      return false;
    } catch (e) {
      debugPrint('[Creation] Create failed: $e');
      _emit(
        _state.copyWith(
          errorMessage:
              'Não foi possível criar agora. Verifique a conexão e tente de '
              'novo.',
        ),
      );
      return false;
    } finally {
      _emit(_state.copyWith(isCreating: false));
    }
  }
}
