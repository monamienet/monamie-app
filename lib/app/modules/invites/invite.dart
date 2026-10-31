import 'package:monamie_app/app/modules/admin/groups/group.dart';

/// A pending invite to a group, as the central invite functions return it.
class Invite {
  const Invite({
    required this.id,
    required this.organizationId,
    required this.organizationName,
    required this.groupId,
    required this.groupName,
    required this.email,
    required this.roles,
    required this.inviterName,
    required this.expiresAt,
    this.expired = false,
  });

  /// Reads one invite; `null` when malformed.
  static Invite? fromJson(Object? json) {
    if (json is! Map) return null;
    String? text(String key) =>
        json[key] is String ? json[key] as String : null;
    final id = text('id');
    final organizationId = text('organizationId');
    final groupId = text('groupId');
    final email = text('email');
    final roles = {
      for (final r in (json['roles'] as List?) ?? const [])
        ?GroupRole.fromName(r),
    };
    if (id == null ||
        organizationId == null ||
        groupId == null ||
        email == null) {
      return null;
    }
    if (roles.isEmpty) return null;
    return Invite(
      id: id,
      organizationId: organizationId,
      organizationName: text('organizationName') ?? organizationId,
      groupId: groupId,
      groupName: text('groupName') ?? 'Grupo',
      email: email,
      roles: roles,
      inviterName: text('inviterName') ?? '',
      expiresAt: _date(json['expiresAt']),
      expired: json['expired'] == true,
    );
  }

  final String id;
  final String organizationId;
  final String organizationName;
  final String groupId;
  final String groupName;
  final String email;
  final Set<GroupRole> roles;
  final String inviterName;
  final DateTime? expiresAt;

  /// Past its 14 days: shown as *Expirado* with *Reenviar*.
  final bool expired;

  /// "Em campo · Vê o mapa".
  String get rolesLabel => groupRolesLabel(roles);

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
  InviteDraft(this.email) : roles = {GroupRole.publisher};

  final String email;
  final Set<GroupRole> roles;
}

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

/// Why [email] cannot be added to the list of [drafts], or `null`.
String? inviteEmailProblem(String email, Iterable<InviteDraft> drafts) {
  final clean = email.trim().toLowerCase();
  if (!_emailPattern.hasMatch(clean)) return 'Digite um e-mail válido.';
  if (drafts.any((d) => d.email == clean)) return '$clean já está na lista.';
  return null;
}
