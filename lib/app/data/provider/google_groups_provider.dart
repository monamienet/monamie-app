import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class GoogleGroupsProvider {
  final String _hiveBox = 'google_groups_data';

  Future<void> saveGroupEntities(
    String groupEmail,
    List<Map<String, dynamic>> entities,
  ) async {
    try {
      var box = await Hive.openBox(_hiveBox);

      final dataToSave = {
        'timestamp': DateTime.now().toIso8601String(),
        'entities': jsonEncode(entities),
      };

      await box.put(groupEmail, jsonEncode(dataToSave));
      if (kDebugMode) {
        print('Saved Group Entities in Hive for: $groupEmail');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving Group Entities in Hive: $e');
      }
    }
  }

  Future<List<Map<String, dynamic>>?> getGroupEntities(
    String groupEmail,
  ) async {
    try {
      var box = await Hive.openBox(_hiveBox);
      final rawData = box.get(groupEmail);

      if (rawData == null) return null;

      final Map<String, dynamic> data = jsonDecode(rawData as String);
      final String? timestampStr = data['timestamp'] as String?;
      final String? entitiesStr = data['entities'] as String?;

      if (timestampStr == null || entitiesStr == null) return null;

      final DateTime timestamp = DateTime.parse(timestampStr);
      final DateTime now = DateTime.now();

      // Expiration: 7 days
      if (now.difference(timestamp).inDays >= 7) {
        if (kDebugMode) {
          print('Cache expired for: $groupEmail');
        }
        return null;
      }

      final List<dynamic> decodedList = jsonDecode(entitiesStr);
      final List<Map<String, dynamic>> entities = decodedList
          .map((e) => e as Map<String, dynamic>)
          .toList();

      if (kDebugMode) {
        print('Read Group Entities from Hive for: $groupEmail');
      }
      return entities;
    } catch (e) {
      if (kDebugMode) {
        print('Error reading Group Entities from Hive: $e');
      }
      return null;
    }
  }

  /// Drops the cached entities of [groupEmail], so the next read asks the
  /// gateway.
  Future<void> deleteGroupEntities(String groupEmail) async {
    try {
      final box = await Hive.openBox(_hiveBox);
      await box.delete(groupEmail);
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting Group Entities from Hive: $e');
      }
    }
  }
}
