import 'package:hive/hive.dart';
part 'user_google_model.g.dart';

@HiveType(typeId: 17)
class UserGoogleModel extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String? name;

  @HiveField(2)
  String email;

  @HiveField(3)
  String? urlImage;

  @HiveField(4)
  DateTime? createdAt;

  @HiveField(5)
  String? avatarBase64;

  UserGoogleModel({
    this.id,
    this.name,
    required this.email,
    this.urlImage,
    this.createdAt,
    this.avatarBase64,
  });

  factory UserGoogleModel.fromJson(Map<String, dynamic> json) {
    return UserGoogleModel(
      id: json['id'] as String,
      name: json['name'] as String?,
      email: json['email'] as String,
      urlImage: json['urlImage'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      avatarBase64: json['avatarBase64'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'urlImage': urlImage,
      'createdAt': createdAt?.toIso8601String(),
      'avatarBase64': avatarBase64,
    };
  }
}
