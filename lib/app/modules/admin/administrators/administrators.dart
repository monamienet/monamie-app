/// An administrator of the organization, as `listAdministrators` returns
/// them.
class Administrator {
  const Administrator({required this.email, this.owner = false});

  final String email;

  /// Whether they are the owner (*Titular*): always an administrator,
  /// never demoted.
  final bool owner;
}

/// Who administers the organization and who may be appointed: the response
/// of `listAdministrators`.
class OrganizationAdministrators {
  const OrganizationAdministrators({
    this.administrators = const [],
    this.members = const [],
  });

  /// Reads `{administrators: [{email, owner}], members: [{email}]}`;
  /// malformed entries are left out, a malformed response is empty.
  factory OrganizationAdministrators.fromJson(Object? json) {
    if (json is! Map) return const OrganizationAdministrators();
    List<Map> entries(String key) => [
      for (final e in json[key] is List ? json[key] as List : const [])
        if (e is Map && e['email'] is String && (e['email'] as String) != '') e,
    ];
    return OrganizationAdministrators(
      administrators: [
        for (final e in entries('administrators'))
          Administrator(email: e['email'] as String, owner: e['owner'] == true),
      ],
      members: [for (final e in entries('members')) e['email'] as String],
    );
  }

  /// The owner first, then by e-mail (the server's order).
  final List<Administrator> administrators;

  /// E-mails of the members who are not administrators, by e-mail.
  final List<String> members;
}
