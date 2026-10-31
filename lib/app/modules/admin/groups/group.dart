import 'package:monamie_app/app/data/firebase/firestore_paths.dart';

/// A role an administrator gives a person in a group.
enum GroupRole {
  /// *Em campo*: shares their own location in the group (`publisher`).
  publisher('Em campo'),

  /// *Vê o mapa*: sees the group on the map (`subscriber`).
  subscriber('Vê o mapa');

  const GroupRole(this.label);

  final String label;

  /// The role's name in Firestore and in the central functions.
  String get id => switch (this) {
    publisher => GroupRoles.publisher,
    subscriber => GroupRoles.subscriber,
  };

  /// The role named [name]; `null` for anything else (a `maintainer` role,
  /// which the app does not manage yet, included).
  static GroupRole? fromName(Object? name) => switch (name) {
    GroupRoles.publisher => publisher,
    GroupRoles.subscriber => subscriber,
    _ => null,
  };
}

/// A person in a group, with one or both roles.
class GroupPerson {
  const GroupPerson({required this.email, required this.roles});

  final String email;
  final Set<GroupRole> roles;
}

/// A group of the bound organization, as `listGroups` returns it.
class Group {
  const Group({
    required this.id,
    required this.name,
    required this.people,
    this.createdAt,
  });

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
          'roles': final List roles,
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

  /// The group's Firestore id (an auto id): never changes, never reused.
  final String id;
  final String name;
  final List<GroupPerson> people;

  /// When the group was created, when known.
  final DateTime? createdAt;

  /// "4 pessoas", "1 pessoa", "Ninguém ainda".
  String get peopleLabel => switch (people.length) {
    0 => 'Ninguém ainda',
    1 => '1 pessoa',
    final n => '$n pessoas',
  };
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
/// can: at least 2 letters, at most 40 characters, unique ignoring case,
/// accents and spaces. The server checks the same.
String? groupNameProblem(String name, Iterable<String> existing) {
  final clean = name.replaceAll(RegExp(r'\s+'), ' ').trim();
  // Letters in any script, like the server's `\p{L}`.
  final letters = RegExp(r'\p{L}', unicode: true).allMatches(clean).length;
  if (letters < 2) return 'Use pelo menos 2 letras.';
  if (clean.length > 40) return 'Use no máximo 40 caracteres.';
  final wanted = normalizeGroupName(clean);
  for (final other in existing) {
    if (normalizeGroupName(other) == wanted) return 'Já existe o grupo $other.';
  }
  return null;
}

/// "Em campo · Vê o mapa", in [GroupRole] order.
String groupRolesLabel(Set<GroupRole> roles) => [
  for (final role in GroupRole.values)
    if (roles.contains(role)) role.label,
].join(' · ');

/// Up to two capitals from the words of [text] split at spaces, dots and
/// `@`: "ana.lima@gmail.com" → "AL"; "?" when there are none.
String initialsOf(String text) {
  final words = text.split(RegExp(r'[\s.@]+')).where((w) => w.isNotEmpty);
  final initials = words.take(2).map((w) => w[0].toUpperCase()).join();
  return initials.isEmpty ? '?' : initials;
}

/// "1 convite pendente", "3 convites pendentes", or empty for none.
String pendingInvitesLabel(int count) => switch (count) {
  <= 0 => '',
  1 => '1 convite pendente',
  final n => '$n convites pendentes',
};

/// What deleting a group does, one sentence per line: who loses access to
/// [organization] ([loses] people in no other group), who stays, the
/// [invites] cancelled, and that it cannot be undone.
List<String> groupDeletionLines({
  required int loses,
  required int stays,
  required int invites,
  required String organization,
}) => [
  if (loses == 1)
    '1 pessoa só estava neste grupo e perde o acesso à $organization.'
  else if (loses > 1)
    '$loses pessoas só estavam neste grupo e perdem o acesso à '
        '$organization.',
  if (stays == 1)
    '1 pessoa continua nos outros grupos.'
  else if (stays > 1)
    '$stays pessoas continuam nos outros grupos.',
  if (invites == 1)
    'O convite pendente é cancelado.'
  else if (invites > 1)
    'Os $invites convites pendentes são cancelados.',
  'Os trajetos publicados neste grupo são apagados junto. Não dá para '
      'desfazer.',
];

/// The text under "`<group>` excluído": how many people ([loses]) lost
/// access to [organization].
String deletedGroupText({required int loses, required String organization}) {
  final lost = switch (loses) {
    <= 0 => '',
    1 => '1 pessoa perdeu o acesso à $organization. ',
    final n => '$n pessoas perderam o acesso à $organization. ',
  };
  return '${lost}Quem estava em outros grupos continua neles.';
}
