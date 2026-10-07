import 'package:monamie_app/app/modules/monamie/models/google_group_member_model.dart';

class GoogleGroupModel {
  String name;
  String email;
  String description;
  List<GoogleGroupMember> members;
  List<GoogleGroupModel> subgroups; 

  GoogleGroupModel({
    required this.name,
    required this.email,
    required this.description,
    required this.members,
    required this.subgroups
  });

  GoogleGroupModel.fromJson(Map<String, dynamic> json)
    : name = json['name'].toString(),
      email = json['email'].toString(),
      description = json['description'].toString(),
      members = json['members'],
      subgroups = json['subgroups'];



  //GoogleGroupModel.fromMap(Map<String, dynamic> json)
  //  : name = json['name'].toString(),
  //    email = json['email'].toString(),
  //    description = json['description']?.toString() ?? '',
  //    participants = json['participants'];
  //
  //Map<String, dynamic> toMap() {
  //  return {
  //    'name': name,
  //    'email': email,
  //    'description': description,
  //    'participants': participants
  //  };
  //}
}