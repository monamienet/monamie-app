import 'package:monamie_app/app/data/models/gdi_groups_model.dart';
import 'package:hive/hive.dart';

@HiveType(typeId: 33)
class GdiGroupsGoogle {
  @HiveField(0)
  DateTime? lastUpdate;
  @HiveField(1)
  List<GdiGroups>? gdiGroups;

  GdiGroupsGoogle(this.lastUpdate, this.gdiGroups);

  GdiGroupsGoogle.fromJson(Map<String, dynamic> json) {
    lastUpdate = json['lastUpdate'] != null
        ? DateTime.parse(json['lastUpdate'])
        : null;
    gdiGroups = json['gdiGroups'] != null
        ? (json['gdiGroups'] as List)
              .map((group) => GdiGroups.fromJson(group))
              .toList()
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};

    data['lastUpdate'] = lastUpdate?.toIso8601String();

    data['gdiGroups'] = gdiGroups?.map((group) => group.toJson()).toList();

    return data;
  }
}