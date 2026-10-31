import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/config/organization/group_address.dart';
import 'package:monamie_app/app/config/organization/organization_theme.dart';
import 'package:monamie_app/app/data/theme/theme_catalog.dart';

import 'creation_backend.dart';

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

/// Where the id check is.
enum IdCheck { idle, checking, available, unavailable }

/// State of *Criar organização*: name and identifier, theme, plan, review,
/// then the creation itself.
class CreateOrganizationController extends GetxController {
  CreateOrganizationController({
    required CreationBackend backend,
    required ThemeCatalog themes,
    this.debounce = const Duration(milliseconds: 500),
  }) : _backend = backend,
       _themes = themes;

  final CreationBackend _backend;
  final ThemeCatalog _themes;
  final Duration debounce;

  final RxString name = ''.obs;
  final RxString id = ''.obs;

  /// Once the person edits the id, the name stops suggesting it.
  bool _idEdited = false;

  final Rx<IdCheck> idCheck = IdCheck.idle.obs;
  final RxString idProblem = ''.obs;
  Timer? _timer;

  final RxList<OrganizationTheme> themes = <OrganizationTheme>[].obs;
  final RxString themeId = defaultOrganizationTheme.id.obs;
  final RxString plan = 'community'.obs;

  /// The plans that can be picked for now. Standard stays on screen, greyed
  /// out, until it is opened to organizations.
  static const offeredPlans = {'community'};

  /// Picks [id] when it is offered and nothing is being created.
  void pickPlan(String id) {
    if (isCreating.value || !offeredPlans.contains(id)) return;
    plan.value = id;
  }

  final RxBool isCreating = false.obs;
  final RxString errorMessage = ''.obs;

  /// The status after creating (`active`, `awaiting_billing`, `failed`).
  final RxnString result = RxnString();

  @override
  void onInit() {
    super.onInit();
    _loadThemes();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  Future<void> _loadThemes() async {
    try {
      themes.assignAll(pickableThemes((await _themes.themes()).values));
    } catch (e) {
      debugPrint('[Creation] Could not load themes: $e');
      themes.assignAll([defaultOrganizationTheme]);
    }
  }

  OrganizationTheme get pickedTheme =>
      themes.firstWhereOrNull((t) => t.id == themeId.value) ??
      defaultOrganizationTheme;

  void setName(String value) {
    name.value = value;
    if (!_idEdited) _setId(suggestOrganizationId(value));
  }

  void setId(String value) {
    _idEdited = true;
    _setId(value.trim());
  }

  void _setId(String value) {
    id.value = value;
    _timer?.cancel();
    final problem = idFormatProblem(value);
    if (problem != null) {
      idCheck.value = IdCheck.unavailable;
      idProblem.value = problem;
      return;
    }
    idCheck.value = IdCheck.checking;
    idProblem.value = '';
    _timer = Timer(debounce, () => _check(value));
  }

  Future<void> _check(String value) async {
    try {
      final problem = await _backend.idProblem(value);
      if (id.value != value) return; // typed on meanwhile
      idCheck.value = problem == null ? IdCheck.available : IdCheck.unavailable;
      idProblem.value = problem ?? '';
    } catch (e) {
      if (id.value != value) return;
      idCheck.value = IdCheck.unavailable;
      idProblem.value = 'Não foi possível verificar agora.';
    }
  }

  bool get nameValid {
    final clean = name.value.trim();
    return clean.length >= 2 &&
        clean.length <= 40 &&
        !clean.toLowerCase().startsWith('monamie ');
  }

  bool get canContinueFromName =>
      nameValid && idCheck.value == IdCheck.available;

  /// Creates the organization. Returns whether the call went through (the
  /// status is in [result]).
  Future<bool> create() async {
    if (isCreating.value || !canContinueFromName) return false;
    isCreating.value = true;
    errorMessage.value = '';
    try {
      result.value = await _backend.create(
        id: id.value,
        name: name.value.trim(),
        themeId: themeId.value,
        plan: plan.value,
      );
      return true;
    } on CreationException catch (e) {
      errorMessage.value = e.message;
      return false;
    } catch (e) {
      debugPrint('[Creation] Create failed: $e');
      errorMessage.value =
          'Não foi possível criar agora. Verifique a conexão e tente de novo.';
      return false;
    } finally {
      isCreating.value = false;
    }
  }
}
