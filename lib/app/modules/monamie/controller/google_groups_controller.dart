import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/config/partner/group_address.dart';
import 'package:monamie_app/app/config/partner/partner.dart';
import 'package:monamie_app/app/data/partner/partner_membership.dart';
import 'package:monamie_app/app/modules/login/controllers/auth_google_controller.dart';
import 'package:monamie_app/app/data/repository/google_groups_repository.dart';
import 'package:monamie_app/app/data/services/capabilities.dart';
import 'package:monamie_app/app/data/services/monamie_claims_service.dart';
import 'package:monamie_app/app/modules/monamie/models/google_group_model.dart';
import 'package:monamie_app/app/modules/monamie/models/google_group_member_model.dart';
import 'package:monamie_app/app/data/firebase/current_partner_firebase.dart';

class GoogleGroupsController extends GetxController {
  GoogleGroupsController({Future<void> Function()? onAccessLost})
    : _onAccessLost =
          onAccessLost ??
          (() => Get.find<AuthGoogleController>().forgetRemovedPartner());

  /// Called when the user no longer belongs to the bound partner.
  final Future<void> Function() _onAccessLost;

  final GoogleGroupsRepository _repository = GoogleGroupsRepository();
  fb.FirebaseAuth get _auth => CurrentPartnerFirebase.instance.auth;

  final RxString _loadError = RxString('');
  RxString get loadError => _loadError;

  RxString observedGroup = RxString('Nenhum');
  final Rxn<GoogleGroupModel> selectedGroup = Rxn<GoogleGroupModel>();

  RxList<GoogleGroupMember> observedMembers = RxList();

  final _highlightedObservedUsers = <GoogleGroupMember>[].obs;
  RxList<GoogleGroupMember> get highlightedObservedUsers =>
      _highlightedObservedUsers;

  /// What the person may do in the bound partner (from the claims).
  final Rx<Capabilities> capabilities = const Capabilities().obs;

  /// The teams where the person shares their location: the choices when
  /// they start sharing.
  final RxList<GoogleGroupModel> shareTeams = RxList<GoogleGroupModel>();

  /// Whether the person sees any team's map in the bound partner. A
  /// field-only person sees just their own position.
  bool get canWatch {
    final partner = Partner.current;
    return partner != null && capabilities.value.canWatchIn(partner.id);
  }

  /// Whether the person owns (is the *responsável* of) the bound partner.
  bool get isOwner {
    final partner = Partner.current;
    return partner != null && capabilities.value.isOwnerOf(partner.id);
  }

  /// The teams where the signed-in person shares their location.
  Future<List<GoogleGroupModel>> getObservableGroupsForUser() async =>
      shareTeams.toList();

  /// Root group of the bound partner: `<id>00@monamienet.org`.
  static String get rootGroupEmail {
    final partner = Partner.current;
    if (partner == null) {
      throw StateError('No partner is bound, so there is no root group.');
    }
    return partner.rootGroupEmail;
  }

  /// The teams whose map the signed-in person sees: the ones they watch,
  /// or every team of the partner for its owner.
  final RxList<GoogleGroupModel> _observableGoogleGroups =
      RxList<GoogleGroupModel>();
  List<GoogleGroupModel> get googleGroups => _observableGoogleGroups;

  /// Indica se o carregamento dos grupos já foi concluído.
  final RxBool isLoading = RxBool(true);

  @override
  void onInit() {
    super.onInit();
    _loadGroups();
  }

  /// The teams of [partnerId] as groups, for the keys in [teamKeys].
  ///
  /// [rootEntities] are the root group's members (`/members`): its subgroups
  /// are the teams, with their display names. [userGroups] are the person's
  /// own groups (`/groups`). A team's name comes from its entry in either
  /// list, or is "Equipe NN" when neither names it.
  @visibleForTesting
  static List<GoogleGroupModel> teamsFor(
    Iterable<String> teamKeys,
    List<Map<String, dynamic>> rootEntities,
    List<Map<String, dynamic>> userGroups,
  ) {
    final names = <String, String>{};
    for (final entry in [...userGroups, ...rootEntities]) {
      final email = entry['email'];
      final name = entry['name'];
      if (email is! String || name is! String || name.trim().isEmpty) continue;
      final address = parseGroupAddress(email);
      if (address?.level == GroupLevel.team) {
        names[address!.teamKey] = name.trim();
      }
    }
    return [
      for (final key in teamKeys)
        GoogleGroupModel(
          name: names[key] ?? 'Equipe ${key.substring(key.length - 2)}',
          email: teamEmailForKey(key),
          description: '',
          members: [],
          subgroups: [],
        ),
    ];
  }

  /// The team keys of [partnerId] among [rootEntities]: the root group's
  /// subgroups named `<id>NN@`.
  @visibleForTesting
  static List<String> teamKeysOf(
    String partnerId,
    List<Map<String, dynamic>> rootEntities,
  ) => [
    for (final entity in rootEntities)
      if (entity['type'] == 'GROUP' && entity['email'] is String)
        if (parseGroupAddress(entity['email'] as String) case final address?
            when address.partnerId == partnerId &&
                address.level == GroupLevel.team)
          address.teamKey,
  ];

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
      final rootEntities = await _repository.getGroupEntities(
        token,
        rootGroupEmail,
        forceRefresh: forceRefresh,
      );
      final userGroups = await _repository.getUserGroups(
        token,
        userEmail,
        forceRefresh: forceRefresh,
      );

      // Removed from every group of the partner: forget it.
      final partner = Partner.current;
      if (partner == null) return;
      if (!belongsToPartner(partner.id, userGroups)) {
        await _onAccessLost();
        return;
      }

      // 2. Capabilities decide which teams the person sees and shares in.
      final caps =
          await MonAmieClaimsService.readClaims() ?? const Capabilities();
      capabilities.value = caps;
      final partnerId = partner.id;
      _observableGoogleGroups.assignAll(
        teamsFor(
          caps.watchTeamsIn(partnerId, teamKeysOf(partnerId, rootEntities)),
          rootEntities,
          userGroups,
        ),
      );
      shareTeams.assignAll(
        teamsFor(caps.shareTeamsIn(partnerId), rootEntities, userGroups),
      );
    } catch (e, stack) {
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

  /// Atualiza os membros observados com base no grupo selecionado.
  /// Busca os participantes do grupo via API e filtra apenas usuários (type == USER).
  Future<void> updateObservedUsers(
    GoogleGroupModel selectedGroup, {
    bool forceRefresh = false,
  }) async {
    observedGroup.value = selectedGroup.name;
    this.selectedGroup.value = selectedGroup;

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final token = await user.getIdToken(true);
      if (token == null) return;

      // The people in the field are the members of the team's share leaf.
      final entities = await _repository.getGroupEntities(
        token,
        shareLeafEmail(selectedGroup.email),
        forceRefresh: forceRefresh,
      );

      final users = entities.where((e) => e['type'] == 'USER').toList();

      // Filtrar apenas usuários e mapear para GoogleGroupMember
      observedMembers.value = users.where((m) => m['type'] == 'USER').map((m) {
        final email = (m['email'] as String?)?.trim() ?? '';
        final rawName = (m['name'] as String?)?.trim();
        final name = (rawName != null && rawName.isNotEmpty)
            ? rawName
            : (email.isNotEmpty ? email.split('@').first : 'Sem nome');
        return GoogleGroupMember(name: name, email: email);
      }).toList();
    } catch (e) {
      debugPrint("Erro ao buscar membros do grupo ${selectedGroup.email}: $e");
      observedMembers.clear();
    }
  }

  /// The share leaf of a team: `rotasul01@…` → `rotasul01w@…`.
  @visibleForTesting
  static String shareLeafEmail(String teamEmail) {
    final address = parseGroupAddress(teamEmail);
    return address == null ? teamEmail : '${address.teamKey}w@$groupDomain';
  }

  Future<void> refreshGroups() async {
    isLoading.value = true;
    _observableGoogleGroups.clear();

    // Re-sincronizar claims (o usuário pode ter sido
    // adicionado/removido de um grupo desde o último login).
    if (claimsShowNoAccess(await _syncClaims())) {
      isLoading.value = false;
      await _onAccessLost();
      return;
    }

    await _loadGroups(forceRefresh: true);

    final currentGroupName = observedGroup.value;
    if (currentGroupName != 'Nenhum') {
      try {
        final selectedGroup = _observableGoogleGroups.firstWhere(
          (g) => g.name == currentGroupName,
        );
        await updateObservedUsers(selectedGroup, forceRefresh: true);
      } catch (e) {
        // Group not found anymore
        observedGroup.value = 'Nenhum';
        selectedGroup.value = null;
        observedMembers.clear();
      }
    }
  }

  /// Recomputes the person's capabilities (they may have been added to or
  /// removed from a team since the last sign-in).
  Future<Capabilities?> _syncClaims() => MonAmieClaimsService.syncClaims();
}
