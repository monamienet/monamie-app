import 'package:freezed_annotation/freezed_annotation.dart';

part 'administrators.freezed.dart';

/// An administrator of the organization, as `listAdministrators` returns
/// them.
@freezed
abstract class Administrator with _$Administrator {
  const factory Administrator({
    required String email,

    /// Whether they are the owner (*Titular*): always an administrator,
    /// never demoted.
    @Default(false) bool owner,
  }) = _Administrator;
}

/// Who administers the organization and who may be appointed: the response
/// of `listAdministrators`.
@freezed
abstract class OrganizationAdministrators with _$OrganizationAdministrators {
  const factory OrganizationAdministrators({
    /// The owner first, then by e-mail (the server's order).
    @Default([]) List<Administrator> administrators,

    /// E-mails of the members who are not administrators, by e-mail.
    @Default([]) List<String> members,
  }) = _OrganizationAdministrators;

  /// Reads `{administrators: [{email, owner}], members: [{email}]}`;
  /// malformed entries are left out, a malformed response is empty.
  static OrganizationAdministrators fromJson(Object? json) {
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
}
