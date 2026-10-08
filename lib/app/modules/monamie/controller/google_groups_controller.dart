import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/data/repository/google_groups_repository.dart';
import 'package:monamie_app/app/data/services/monamie_claims_service.dart';
import 'package:monamie_app/app/modules/monamie/models/google_group_model.dart';
import 'package:monamie_app/app/modules/monamie/models/google_group_member_model.dart';

class GoogleGroupsController extends GetxController {
  final GoogleGroupsRepository _repository = GoogleGroupsRepository();
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;

  final RxString _loadError = RxString('');
  RxString get loadError => _loadError;

  RxString observedGroup = RxString('Nenhum');
  final Rxn<GoogleGroupModel> selectedGroup = Rxn<GoogleGroupModel>();

  RxList<GoogleGroupMember> observedMembers = RxList();
  
  final _highlightedObservedUsers = <GoogleGroupMember>[].obs;
  RxList<GoogleGroupMember> get highlightedObservedUsers => _highlightedObservedUsers;

  /// Retorna a lista de grupos onde o usuário logado é observável
  /// (ou seja, possui papel de MEMBER ou MANAGER nos claims).
  Future<List<GoogleGroupModel>> getObservableGroupsForUser() async {
    final claims = await MonAmieClaimsService.readClaims();
    if (claims == null || claims.isEmpty) return [];

    final allowedEmails = claims.entries
        .where((e) => e.value == 'MEMBER' || e.value == 'MANAGER')
        .map((e) => e.key.toLowerCase().trim())
        .toSet();

    return _observableGoogleGroups
        .where((g) => allowedEmails.contains(g.email.toLowerCase().trim()))
        .toList();
  }

  /// Email do grupo raiz que contém os subgrupos do MonAmie.
  /// Em debug, usa um grupo de teste; em release, o grupo de produção.
  static String get rootGroupEmail => 'monamie-aquariustur@monamienet.org';
  /// Lista de grupos que o usuário logado pode observar.
  /// Representa os subgrupos (type == GROUP) de [rootGroupEmail].
  final RxList<GoogleGroupModel> _observableGoogleGroups = RxList<GoogleGroupModel>();
  List<GoogleGroupModel> get googleGroups => _observableGoogleGroups;

  /// Indica se o carregamento dos grupos já foi concluído.
  final RxBool isLoading = RxBool(true);

  @override
  void onInit() {
    super.onInit();
    _loadGroups();
  }

  /// Dadas as entidades do grupo raiz e os grupos do usuário (`/groups`),
  /// retorna os grupos do usuário que são subgrupos diretos do grupo raiz.
  ///
  /// Subgrupos são entidades com `type == GROUP` cujo email não começa com
  /// `space/`. Nome e descrição vêm de [userGroups].
  @visibleForTesting
  static List<GoogleGroupModel> userSubgroups(
    List<Map<String, dynamic>> rootEntities,
    List<Map<String, dynamic>> userGroups,
  ) {
    final subgroupEmails = rootEntities
        .where((e) => e['type'] == 'GROUP' && (e['email'] as String?)?.startsWith('space/') != true)
        .map((e) => (e['email'] as String?)?.trim().toLowerCase())
        .whereType<String>()
        .toSet();

    return userGroups
        .where((g) => subgroupEmails.contains((g['email'] as String?)?.trim().toLowerCase()))
        .map((g) => GoogleGroupModel(
              name: g['name'] ?? 'Nome indisponível',
              email: g['email'],
              description: g['description'] ?? '',
              members: [], // TODO
              subgroups: [], // TODO
            ))
        .toList();
  }

  Future<void> _loadGroups({bool forceRefresh = false}) async {
    loadError.value = '';
    _observableGoogleGroups.clear();
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint("Usuário não autenticado.");
        loadError.value = 'not_autenticated';
        isLoading.value = false;
        return;
      }

      final token = await user.getIdToken(true);
      if (token == null) {
        debugPrint("Token não disponível.");
        _loadError.value = 'no_token';
        isLoading.value = false;
        return;
      }

      final userEmail = user.email;
      if (userEmail == null) {
        debugPrint("Email do usuário não disponível.");
        _loadError.value = 'no_email';
        isLoading.value = false;
        return;
      }

      // 1. Subgrupos do grupo raiz (/members) e grupos do usuário (/groups).
      final rootEntities = await _repository.getGroupEntities(token, rootGroupEmail, forceRefresh: forceRefresh);
      final userGroups = await _repository.getUserGroups(token, userEmail, forceRefresh: forceRefresh);

      // 2. Interseção: subgrupos do raiz dos quais o usuário participa.
      _observableGoogleGroups.assignAll(userSubgroups(rootEntities, userGroups));

      if (_observableGoogleGroups.isEmpty) {
        _loadError.value = 'Você não participa de nenhum subgrupo de $rootGroupEmail.';
        return;
      }
    } catch(e, stack) {
      debugPrint('$e\n$stack');
      _loadError.value = '$e';
      _observableGoogleGroups.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void toggleHighlight(GoogleGroupMember member) {
    if (_highlightedObservedUsers.any((m) => m.email == member.email)) {
      _highlightedObservedUsers.removeWhere((m) => m.email == member.email);
    } else {
      _highlightedObservedUsers.add(member);
    }
  }

  bool isHighlighted(GoogleGroupMember member) {
    return _highlightedObservedUsers.any((m) => m.email == member.email);
  }

  /// Mapeia o role da API para [GoogleGroupRole].
  GoogleGroupRole _parseRole(String role) {
    switch (role.toUpperCase()) {
      case 'OWNER':
        return GoogleGroupRole.owner;
      case 'MANAGER':
        return GoogleGroupRole.manager;
      default:
        return GoogleGroupRole.member;
    }
  }

  /// Atualiza os membros observados com base no grupo selecionado.
  /// Busca os participantes do grupo via API e filtra apenas usuários (type == USER).
  Future<void> updateObservedUsers(GoogleGroupModel selectedGroup, {bool forceRefresh = false}) async {
    observedGroup.value = selectedGroup.name;
    this.selectedGroup.value = selectedGroup;

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final token = await user.getIdToken(true);
      if (token == null) return;

      // Busca usuários do grupo selecionado
      final entities = await _repository.getGroupEntities(token, selectedGroup.email, forceRefresh: forceRefresh);

      final users = entities
        .where((e) => e['type'] == 'USER')
        .toList();

      // Filtrar apenas usuários e mapear para GoogleGroupMember
      observedMembers.value = users
          .where((m) => m['type'] == 'USER')
          .map((m) {
            final email = (m['email'] as String?)?.trim() ?? '';
            final rawName = (m['name'] as String?)?.trim();
            final name = (rawName != null && rawName.isNotEmpty)
                ? rawName
                : (email.isNotEmpty ? email.split('@').first : 'Sem nome');
            final roleStr = (m['role'] as String?)?.trim() ?? 'MEMBER';

            return GoogleGroupMember(
              name: name,
              email: email,
              role: _parseRole(roleStr),
            );
          })
          .toList();
    } catch (e) {
      debugPrint("Erro ao buscar membros do grupo ${selectedGroup.email}: $e");
      observedMembers.clear();
    }
  }

  Future<void> refreshGroups() async {
    isLoading.value = true;
    _observableGoogleGroups.clear();

    // Re-sincronizar claims (o usuário pode ter sido
    // adicionado/removido de um grupo desde o último login).
    await _syncClaims();

    await _loadGroups(forceRefresh: true);
    
    final currentGroupName = observedGroup.value;
    if (currentGroupName != 'Nenhum') {
      try {
        final selectedGroup = _observableGoogleGroups.firstWhere((g) => g.name == currentGroupName);
        await updateObservedUsers(selectedGroup, forceRefresh: true);
      } catch (e) {
        // Group not found anymore
        observedGroup.value = 'Nenhum';
        selectedGroup.value = null;
        observedMembers.clear();
      }
    }
  }

  /// Chama a Cloud Function `syncClaims` para re-sincronizar
  /// os Custom Claims do usuário com seus papéis atuais nos grupos.
  Future<void> _syncClaims() async {
    await MonAmieClaimsService.syncClaims();
  }
}
