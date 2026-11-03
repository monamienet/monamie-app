import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:monamie_app/domain/models/organization/organization_id.dart';
import 'package:monamie_app/domain/models/organization/organization_theme.dart';
import 'package:monamie_app/data/repositories/theme/theme_repository.dart';

import 'create_organization_state.dart';
import 'package:monamie_app/data/repositories/creation/creation_repository.dart';
import 'package:monamie_app/utils/command.dart';
import 'package:monamie_app/utils/result.dart';

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
/// then the creation itself. The screen runs [load] when it opens; its
/// route disposes the controller when it closes, which stops the pending id
/// check.
class CreateOrganizationViewModel extends ChangeNotifier {
  CreateOrganizationViewModel({
    required this._repository,
    required this._themes,
    this.debounce = const Duration(milliseconds: 500),
  });

  final CreationRepository _repository;
  final ThemeRepository _themes;
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
    if (create.running || !offeredPlans.contains(id)) return;
    _emit(_state.copyWith(plan: id));
  }

  /// Picks theme [id].
  void pickTheme(String id) => _emit(_state.copyWith(themeId: id));

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    load.dispose();
    create.dispose();
    super.dispose();
  }

  /// Loads the themes that can be picked; the default theme alone when the
  /// catalog cannot be read (so it always ends [Ok]).
  late final Command0<void> load = Command0(_load);

  /// Creates the organization; [Ok] holds its status, also kept in
  /// [CreateOrganizationState.result]. The failure is also kept in
  /// [CreateOrganizationState.errorMessage]. Ignored until
  /// [canContinueFromName].
  late final Command0<String> create = Command0(
    _create,
    blocked: () => !canContinueFromName,
  );

  Future<Result<void>> _load() async {
    try {
      final themes = pickableThemes((await _themes.themes()).values);
      _emit(_state.copyWith(themes: themes));
    } catch (e) {
      debugPrint('[Creation] Could not load themes: $e');
      _emit(_state.copyWith(themes: [defaultOrganizationTheme]));
    }
    return const Ok(null);
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
    final checked = await _repository.idProblem(value);
    if (_state.id != value) return; // typed on meanwhile
    switch (checked) {
      case Ok(value: final problem):
        _emit(
          _state.copyWith(
            idCheck: problem == null ? IdCheck.available : IdCheck.unavailable,
            idProblem: problem ?? '',
          ),
        );
      case Err():
        // Whatever failed, the field says only that it was not checked.
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

  Future<Result<String>> _create() async {
    _emit(_state.copyWith(errorMessage: ''));
    final created = await _repository.create(
      id: _state.id,
      name: _state.name.trim(),
      themeId: _state.themeId,
      plan: _state.plan,
    );
    switch (created) {
      case Ok(value: final result):
        _emit(_state.copyWith(result: result));
      case Err(:final message):
        _emit(_state.copyWith(errorMessage: message));
    }
    return created;
  }
}
