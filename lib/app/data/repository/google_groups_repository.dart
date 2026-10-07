import 'package:monamie_app/app/data/connections/google_service.dart';
import 'package:monamie_app/app/data/provider/google_groups_provider.dart';

class GoogleGroupsRepository {
  final GoogleService _googleService = GoogleService();
  final GoogleGroupsProvider _provider = GoogleGroupsProvider();

  Future<List<Map<String, dynamic>>> getGroupEntities(String token, String groupEmail, {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cachedEntities = await _provider.getGroupEntities(groupEmail);
      if (cachedEntities != null) {
        return cachedEntities;
      }
    }

    // Fetch from API
    final entities = await _googleService.getGroupEntities(token, groupEmail);
    
    // Save to cache
    await _provider.saveGroupEntities(groupEmail, entities);
    
    return entities;
  }
}
