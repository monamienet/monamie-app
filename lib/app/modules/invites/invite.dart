import 'package:monamie_app/app/modules/admin/teams/team.dart';

/// A pending invite to a team, as the central invite functions return it.
class Invite {
  const Invite({
    required this.id,
    required this.partnerId,
    required this.partnerName,
    required this.team,
    required this.teamName,
    required this.email,
    required this.roles,
    required this.invitedByName,
    required this.expiresAt,
    this.expired = false,
  });

  /// Reads one invite; `null` when malformed.
  static Invite? fromJson(Object? json) {
    if (json is! Map) return null;
    String? text(String key) =>
        json[key] is String ? json[key] as String : null;
    final id = text('id');
    final partnerId = text('partnerId');
    final team = text('team');
    final email = text('email');
    final roles = {
      for (final r in (json['roles'] as List?) ?? const [])
        ?TeamRole.fromName(r),
    };
    if (id == null || partnerId == null || team == null || email == null) {
      return null;
    }
    if (roles.isEmpty) return null;
    return Invite(
      id: id,
      partnerId: partnerId,
      partnerName: text('partnerName') ?? partnerId,
      team: team,
      teamName: text('teamName') ?? 'Equipe $team',
      email: email,
      roles: roles,
      invitedByName: text('invitedByName') ?? '',
      expiresAt: _date(json['expiresAt']),
      expired: json['expired'] == true,
    );
  }

  final String id;
  final String partnerId;
  final String partnerName;
  final String team;
  final String teamName;
  final String email;
  final Set<TeamRole> roles;
  final String invitedByName;
  final DateTime? expiresAt;

  /// Past its 14 days: shown as *Expirado* with *Reenviar*.
  final bool expired;

  /// "Em campo · Vê o mapa".
  String get rolesLabel => teamRolesLabel(roles);

  /// "Vale até 9 de novembro", "Expirado · venceu em 9 de novembro", or
  /// just "Expirado" / empty when the date is unknown.
  String get statusLabel {
    final until = expiresAt;
    if (expired) {
      return until == null
          ? 'Expirado'
          : 'Expirado · venceu em ${dayMonth(until)}';
    }
    return until == null ? '' : 'Vale até ${dayMonth(until)}';
  }
}

DateTime? _date(Object? value) => switch (value) {
  final String text => DateTime.tryParse(text),
  {'_seconds': final int seconds} => DateTime.fromMillisecondsSinceEpoch(
    seconds * 1000,
  ),
  _ => null,
};

const _months = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

/// "9 de novembro", on the device's calendar (the server sends UTC).
String dayMonth(DateTime date) {
  final local = date.toLocal();
  return '${local.day} de ${_months[local.month - 1]}';
}

/// A person on *Convidar pessoas* before sending: e-mail and roles.
class InviteDraft {
  InviteDraft(this.email) : roles = {TeamRole.share};

  final String email;
  final Set<TeamRole> roles;
}

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

/// Why [email] cannot be added to the list of [drafts], or `null`.
String? inviteEmailProblem(String email, Iterable<InviteDraft> drafts) {
  final clean = email.trim().toLowerCase();
  if (!_emailPattern.hasMatch(clean)) return 'Digite um e-mail válido.';
  if (drafts.any((d) => d.email == clean)) return '$clean já está na lista.';
  return null;
}
