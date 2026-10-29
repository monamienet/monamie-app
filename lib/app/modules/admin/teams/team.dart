/// A role a person has in a team.
enum TeamRole {
  /// *Em campo*: shares their own location (the `w` leaf).
  share('Em campo'),

  /// *Vê o mapa*: sees the team on the map (the `r` leaf).
  watch('Vê o mapa');

  const TeamRole(this.label);

  final String label;

  static TeamRole? fromName(Object? name) => switch (name) {
    'share' => share,
    'watch' => watch,
    _ => null,
  };
}

/// A person in a team, with one or both roles.
class TeamPerson {
  const TeamPerson({required this.email, required this.roles});

  final String email;
  final Set<TeamRole> roles;
}

/// A team of the bound partner, as `listTeams` returns it.
class Team {
  const Team({
    required this.number,
    required this.key,
    required this.name,
    required this.people,
  });

  /// Reads one entry of `listTeams`; `null` when malformed.
  static Team? fromJson(Object? json) {
    if (json is! Map) return null;
    final number = json['team'];
    final key = json['key'];
    final name = json['name'];
    if (number is! String || key is! String || name is! String) return null;
    final people = <TeamPerson>[
      for (final person in (json['people'] as List?) ?? const [])
        if (person case {
          'email': final String email,
          'roles': final List roles,
        })
          TeamPerson(
            email: email,
            roles: {for (final r in roles) ?TeamRole.fromName(r)},
          ),
    ];
    return Team(number: number, key: key, name: name, people: people);
  }

  /// `01`–`99`.
  final String number;

  /// `<partner id><number>`.
  final String key;
  final String name;
  final List<TeamPerson> people;

  /// "4 pessoas", "1 pessoa", "Ninguém ainda".
  String get peopleLabel => switch (people.length) {
    0 => 'Ninguém ainda',
    1 => '1 pessoa',
    final n => '$n pessoas',
  };
}

/// The comparison form of a team name, as the server compares them: no
/// accents, lower case, single spaces, trimmed.
String normalizeTeamName(String name) {
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

/// Why [name] cannot be a new team name among [existing], or `null` when it
/// can: at least 2 letters, at most 40 characters, unique ignoring case,
/// accents and spaces. The server checks the same.
String? teamNameProblem(String name, Iterable<String> existing) {
  final clean = name.replaceAll(RegExp(r'\s+'), ' ').trim();
  // Letters in any script, like the server's `\p{L}`.
  final letters = RegExp(r'\p{L}', unicode: true).allMatches(clean).length;
  if (letters < 2) return 'Use pelo menos 2 letras.';
  if (clean.length > 40) return 'Use no máximo 40 caracteres.';
  final wanted = normalizeTeamName(clean);
  for (final other in existing) {
    if (normalizeTeamName(other) == wanted) return 'Já existe a equipe $other.';
  }
  return null;
}

/// "Em campo · Vê o mapa", in [TeamRole] order.
String teamRolesLabel(Set<TeamRole> roles) => [
  for (final role in TeamRole.values)
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

/// What deleting a team does, one sentence per line: who loses access to
/// [organization] ([loses] people in no other team), who stays, the
/// [invites] cancelled, and that it cannot be undone.
List<String> teamDeletionLines({
  required int loses,
  required int stays,
  required int invites,
  required String organization,
}) => [
  if (loses == 1)
    '1 pessoa só estava nesta equipe e perde o acesso à $organization.'
  else if (loses > 1)
    '$loses pessoas só estavam nesta equipe e perdem o acesso à '
        '$organization.',
  if (stays == 1)
    '1 pessoa continua nas outras equipes.'
  else if (stays > 1)
    '$stays pessoas continuam nas outras equipes.',
  if (invites == 1)
    'O convite pendente é cancelado.'
  else if (invites > 1)
    'Os $invites convites pendentes são cancelados.',
  'Os trajetos antigos continuam no histórico. Não dá para desfazer.',
];

/// The text under "`<team>` excluída": how many people ([loses]) lost
/// access to [organization].
String deletedTeamText({required int loses, required String organization}) {
  final lost = switch (loses) {
    <= 0 => '',
    1 => '1 pessoa perdeu o acesso à $organization. ',
    final n => '$n pessoas perderam o acesso à $organization. ',
  };
  return '${lost}Quem estava em outras equipes continua nelas.';
}
