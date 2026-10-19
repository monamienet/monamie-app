import 'package:hive/hive.dart';

@HiveType(typeId: 32)
enum ProfileTypes {
  @HiveField(0)
  anonymous,
  @HiveField(1)
  grad,
  @HiveField(2)
  pos,
  @HiveField(3)
  teacher,
  @HiveField(4)
  employee,
  @HiveField(5)
  outsourced,
}

List<ProfileTypes> everyoneLogged = [
  ProfileTypes.grad,
  ProfileTypes.pos,
  ProfileTypes.teacher,
  ProfileTypes.employee,
  ProfileTypes.outsourced,
];
List<ProfileTypes> everyone = [
  ProfileTypes.grad,
  ProfileTypes.pos,
  ProfileTypes.teacher,
  ProfileTypes.employee,
  ProfileTypes.outsourced,
  ProfileTypes.anonymous,
];
