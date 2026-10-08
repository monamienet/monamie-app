import 'package:hive/hive.dart';

@HiveType(typeId: 31)
class GdiGroups {
  @HiveField(0)
  String? gid; //Id do grupo
  @HiveField(1)
  String? description;
  @HiveField(2)
  String? name;
  @HiveField(3)
  String? email;
  @HiveField(4)
  String? directMembersCount;

  GdiGroups(this.gid, this.description, this.name, this.email, this.directMembersCount);

  GdiGroups.fromJson(Map<String, dynamic> json) {
    gid = json['gid'] ?? json['id'];
    description = json['description'] ?? json['descricao'];
    name = json['name'];
    email = json['email'];
    directMembersCount = json['directMembersCount'];
  }

  @override
  String toString() {
    return "Group(gid: $gid, descicao: $description)";
  }

  Map<String, dynamic> toJson() {
    return {'gid': gid, 'descricao': description, 'name': name, 'email': email, 'directMembersCount': directMembersCount};
  }
}