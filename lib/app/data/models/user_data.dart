import 'package:monamie_app/app/data/models/gd_groups_google_model.dart';
import 'package:monamie_app/app/data/models/gdi_groups_model.dart';
import 'package:monamie_app/app/data/models/profile_types.dart';
import 'package:hive/hive.dart';

@HiveType(typeId: 18)
class UserData extends HiveObject {
  @HiveField(0)
  String? name;

  @HiveField(1)
  String? nomesocial;

  @HiveField(2)
  String? matricula;

  @HiveField(3)
  String? idMonamie;

  @HiveField(4)
  String? curso;

  @HiveField(5)
  String? fotoUrl;

  @HiveField(6)
  String? dataValidadeMatricula;

  @HiveField(7)
  String? bond;

  @HiveField(8)
  String? textoQrCodeCarteirinha;

  @HiveField(9)
  String? accessToken;

  @HiveField(10)
  String? bondId;

  @HiveField(11)
  List<GdiGroups>? gdiGroups;

  @HiveField(12)
  ProfileTypes? profileType;

  @HiveField(13)
  List<String>? shortcutRoutes;

  @HiveField(14)
  GdiGroupsGoogle? gdiGroupsGoogle;

  @HiveField(15)
  DateTime? lastRegisteredTokenCdcUpdate;

  UserData({
    this.name,
    this.nomesocial,
    this.matricula,
    this.idMonamie,
    this.curso,
    this.fotoUrl,
    this.dataValidadeMatricula,
    this.bond,
    this.textoQrCodeCarteirinha,
    this.accessToken,
    this.bondId,
    this.gdiGroups,
    this.profileType,
    this.shortcutRoutes,
    this.gdiGroupsGoogle,
    this.lastRegisteredTokenCdcUpdate,
  });

  UserData copyWith({
    String? name,
    String? nomesocial,
    String? matricula,
    String? idMonamie,
    String? curso,
    String? fotoUrl,  
  String? dataValidadeMatricula,
    String? bond,
    String? textoQrCodeCarteirinha,
    String? accessToken,
    String? bondId,
    List<GdiGroups>? gdiGroups,
    ProfileTypes? profileType,
    List<String>? shortcutRoutes,
    GdiGroupsGoogle? gdiGroupsGoogle,
    DateTime? lastRegisteredTokenCdcUpdate,
  }) {
    return UserData(
     name: name ?? this.name,
     nomesocial: nomesocial ?? this.nomesocial,
     matricula: matricula ?? this.matricula,
     idMonamie: idMonamie ?? this.idMonamie,
     curso: curso ?? this.curso,
     fotoUrl: fotoUrl ?? this.fotoUrl,
     dataValidadeMatricula: dataValidadeMatricula ?? this.dataValidadeMatricula,
     bond: bond ?? this.bond,
     textoQrCodeCarteirinha: textoQrCodeCarteirinha ?? this.textoQrCodeCarteirinha,
     accessToken: accessToken ?? this.accessToken,
     bondId: bondId ?? this.bondId,
     gdiGroups: gdiGroups ?? this.gdiGroups,
     profileType: profileType ?? this.profileType,
     shortcutRoutes: shortcutRoutes ?? this.shortcutRoutes,
     gdiGroupsGoogle: gdiGroupsGoogle ?? this.gdiGroupsGoogle,
     lastRegisteredTokenCdcUpdate: lastRegisteredTokenCdcUpdate ?? this.lastRegisteredTokenCdcUpdate,
    );
  }

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      name: json['name'] as String?,
      nomesocial: json['nomesocial'] as String?,
      matricula: json['matricula'] as String?,
      idMonamie: json['idMonamie'] as String?,
      curso: json['curso'] as String?,
      fotoUrl: json['fotoUrl'] as String?,
      dataValidadeMatricula: json['dataValidadeMatricula'] as String?,
      bond: json['bond'] as String?,
      textoQrCodeCarteirinha: json['textoQrCodeCarteirinha'] as String?,
      accessToken: json['accessToken'] as String?,
      bondId: json['bondId'] as String?,
      gdiGroups: json['gdiGroups'] != null
          ? (json['gdiGroups'] as List)
                .map((group) => GdiGroups.fromJson(group))
                .toList()
          : null,
      profileType: json['profileType'] != null
          ? ProfileTypes.values.firstWhere(
              (e) => e.toString() == 'ProfileTypes.${json['profileType']}',
            )
          : null,
      shortcutRoutes: json['shortcutRoutes'] != null
          ? List<String>.from(json['shortcutRoutes'] as List)
          : null,
      gdiGroupsGoogle: json['gdiGroupsGoogle'] != null
          ? GdiGroupsGoogle.fromJson(json['gdiGroupsGoogle'])
          : null,
      lastRegisteredTokenCdcUpdate: json['lastRegisteredTokenCdcUpdate'] != null
          ? DateTime.parse(json['lastRegisteredTokenCdcUpdate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'nomesocial': nomesocial,
      'matricula': matricula,
      'idMonamie': idMonamie,
      'curso': curso,
      'fotoUrl': fotoUrl,
      'dataValidadeMatricula': dataValidadeMatricula,
      'bond': bond,
      'textoQrCodeCarteirinha': textoQrCodeCarteirinha,
      'accessToken': accessToken,
      'bondId': bondId,
      'gdiGroups': gdiGroups
          ?.map((group) => {'gid': group.gid, 'descricao': group.description})
          .toList(),
      'profileType': profileType?.toString().split('.').last,
      'shortcutRoutes': shortcutRoutes,
      'gdiGroupsGoogle': gdiGroupsGoogle?.toJson(),
      'lastRegisteredTokenCdcUpdate':
          lastRegisteredTokenCdcUpdate?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'UserData(name: $name, nomesocial: $nomesocial, matricula: $matricula, idMonamie: $idMonamie, curso: $curso, dataValidadeMatricula: $dataValidadeMatricula, bond: $bond, textoQrCodeCarteirinha: $textoQrCodeCarteirinha,  bondId: $bondId, gdiGroups: $gdiGroups, gdiGroupsGoogle: $gdiGroupsGoogle, lastRegisteredTokenCdcUpdate: $lastRegisteredTokenCdcUpdate)';
  }
}