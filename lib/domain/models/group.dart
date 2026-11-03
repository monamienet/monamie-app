import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:monamie_app/domain/models/role_names.dart';
import 'package:monamie_app/utils/failure.dart';

part 'group.freezed.dart';

/// A person's role in a group. The screens name it in the person's
/// language (`DomainLabels.roleName` in `lib/ui/`).
enum GroupRole {
  /// *Em campo*: shares their own location in the group (`publisher`).
  publisher,

  /// *Vê o mapa*: sees the group on the map (`subscriber`).
  subscriber,

  /// *Gestor do grupo*: manages the group's people, invites and name
  /// (`maintainer`). Only administrators give or take it; it shows no map
  /// by itself.
  maintainer;

  /// The roles a group's maintainer gives, and the only ones an invite
  /// carries.
  static const everyday = [publisher, subscriber];

  /// The role's name in Firestore and in the central functions.
  String get id => switch (this) {
    publisher => GroupRoles.publisher,
    subscriber => GroupRoles.subscriber,
    maintainer => GroupRoles.maintainer,
  };

  /// The role named [name]; `null` for anything else.
  static GroupRole? fromName(Object? name) => switch (name) {
    GroupRoles.publisher => publisher,
    GroupRoles.subscriber => subscriber,
    GroupRoles.maintainer => maintainer,
    _ => null,
  };
}

/// The roles someone may give in a group: every role for an
/// administrator ([byAdmin]), the [GroupRole.everyday] ones for a
/// maintainer.
List<GroupRole> assignableRolesFor({required bool byAdmin}) =>
    byAdmin ? GroupRole.values : GroupRole.everyday;

/// Why [roles] cannot be saved for a person ([NoRoleChosen]), or `null`
/// when they can: an administrator ([byAdmin]) needs at least one role; a
/// maintainer at least one everyday role (the person's *Gestor do grupo*
/// stays as it is).
Failure? rolesChoiceProblem(Set<GroupRole> roles, {required bool byAdmin}) {
  final counted = byAdmin
      ? roles
      : roles.where(GroupRole.everyday.contains).toSet();
  return counted.isEmpty ? const Failure.noRoleChosen() : null;
}

/// Whether someone may remove [person] from a group: an administrator
/// ([byAdmin]) anyone, a maintainer anyone but another *Gestor do grupo*
/// (that would take away a role only administrators take).
bool canRemoveFromGroup(GroupPerson person, {required bool byAdmin}) =>
    byAdmin || !person.roles.contains(GroupRole.maintainer);

/// A person in a group, with one or both roles.
@freezed
abstract class GroupPerson with _$GroupPerson {
  const factory GroupPerson({
    required String email,
    required Set<GroupRole> roles,
  }) = _GroupPerson;
}

/// A group of the bound organization, as `listGroups` returns it.
@freezed
abstract class Group with _$Group {
  const factory Group({
    /// The group's Firestore id (an auto id): never changes, never reused.
    required String id,
    required String name,
    required List<GroupPerson> people,

    /// When the group was created, when known.
    DateTime? createdAt,
  }) = _Group;

  const Group._();

  /// Reads one entry of `listGroups`; `null` when malformed.
  static Group? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final name = json['name'];
    if (id is! String || id.isEmpty || name is! String) return null;
    final people = <GroupPerson>[
      for (final person in (json['people'] as List?) ?? const [])
        if (person case {
          'email': final String email,
          'roles': final List<Object?> roles,
        })
          GroupPerson(
            email: email,
            roles: {for (final r in roles) ?GroupRole.fromName(r)},
          ),
    ];
    final createdAt = json['createdAt'];
    return Group(
      id: id,
      name: name,
      people: people,
      createdAt: createdAt is String ? DateTime.tryParse(createdAt) : null,
    );
  }
}

/// The comparison form of a group name, as the server compares them: no
/// accents, lower case, single spaces, trimmed.
String normalizeGroupName(String name) {
  const accents = {
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
    'ñ': 'n',
  };
  final lower = name.toLowerCase();
  final plain = StringBuffer();
  for (final char in lower.split('')) {
    plain.write(accents[char] ?? char);
  }
  return plain.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Why [name] cannot be a new group name among [existing], or `null` when it
/// can: at least 2 letters ([GroupNameTooShort]), at most 40 characters
/// ([GroupNameTooLong]), unique ignoring case, accents and spaces
/// ([GroupNameTaken]). The server checks the same.
Failure? groupNameProblem(String name, Iterable<String> existing) {
  final clean = name.replaceAll(RegExp(r'\s+'), ' ').trim();
  // Letters in any script, like the server's `\p{L}`.
  final letters = RegExp(r'\p{L}', unicode: true).allMatches(clean).length;
  if (letters < 2) return const Failure.groupNameTooShort();
  if (clean.length > 40) return const Failure.groupNameTooLong();
  final wanted = normalizeGroupName(clean);
  for (final other in existing) {
    if (normalizeGroupName(other) == wanted) {
      return Failure.groupNameTaken(other);
    }
  }
  return null;
}

/// Up to two capitals from the words of [text] split at spaces, dots and
/// `@`: "ana.lima@gmail.com" → "AL"; "?" when there are none.
String initialsOf(String text) {
  final words = text.split(RegExp(r'[\s.@]+')).where((w) => w.isNotEmpty);
  final initials = words.take(2).map((w) => w[0].toUpperCase()).join();
  return initials.isEmpty ? '?' : initials;
}
