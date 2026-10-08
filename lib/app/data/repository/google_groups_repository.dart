import 'package:monamie_app/app/data/connections/google_service.dart';
import 'package:monamie_app/app/data/provider/google_groups_provider.dart';

class GoogleGroupsRepository {
  final GoogleService _googleService;
  final GoogleGroupsProvider _provider;

  GoogleGroupsRepository({GoogleService? googleService, GoogleGroupsProvider? provider})
      : _googleService = googleService ?? GoogleService(),
        _provider = provider ?? GoogleGroupsProvider();

  /// Chave de cache dos grupos de um usuário (distinta da dos membros de grupo).
  static String userGroupsKey(String userEmail) => 'user-groups:${userEmail.trim().toLowerCase()}';

  /// Membros/subgrupos de [groupEmail]. Falhas da API propagam como exceção
  /// e NUNCA são gravadas em cache. Um cache vazio é tratado como ausente.
  Future<List<Map<String, dynamic>>> getGroupEntities(String token, String groupEmail, {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cachedEntities = await _provider.getGroupEntities(groupEmail);
      if (cachedEntities != null && cachedEntities.isNotEmpty) {
        return cachedEntities;
      }
    }

    final entities = await _googleService.getGroupEntities(token, groupEmail);
    await _provider.saveGroupEntities(groupEmail, entities);
    return entities;
  }

  /// Grupos dos quais [userEmail] participa. Mesmas regras de cache de
  /// [getGroupEntities].
  Future<List<Map<String, dynamic>>> getUserGroups(String token, String userEmail, {bool forceRefresh = false}) async {
    final key = userGroupsKey(userEmail);
    if (!forceRefresh) {
      final cached = await _provider.getGroupEntities(key);
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
    }

    final groups = await _googleService.getUserGroups(token, userEmail);
    await _provider.saveGroupEntities(key, groups);
    return groups;
  }
}
