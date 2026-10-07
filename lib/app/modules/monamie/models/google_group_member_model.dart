enum GoogleGroupRole {
  owner,
  manager,
  member
}

class GoogleGroupMember {
  String name;
  String email;
  GoogleGroupRole role;

  GoogleGroupMember({
    required this.name,
    required this.email,
    required this.role
  });
}