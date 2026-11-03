import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:monamie_app/domain/models/group.dart';

part 'invite.freezed.dart';

/// A pending invite to a group, as the central invite functions return it.
@freezed
abstract class Invite with _$Invite {
  const factory Invite({
    required String id,
    required String organizationId,
    required String organizationName,
    required String groupId,
    required String groupName,
    required String email,
    required Set<GroupRole> roles,
    required String inviterName,
    required DateTime? expiresAt,

    /// Past its 14 days: shown as *Expirado* with *Reenviar*.
    @Default(false) bool expired,
  }) = _Invite;

  const Invite._();

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
        if (GroupRole.fromName(r) case final role?
            when GroupRole.everyday.contains(role))
          role,
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
}

DateTime? _date(Object? value) => switch (value) {
  final String text => DateTime.tryParse(text),
  {'_seconds': final int seconds} => DateTime.fromMillisecondsSinceEpoch(
    seconds * 1000,
  ),
  _ => null,
};

/// A person on *Convidar pessoas* before sending: e-mail and roles.
@freezed
abstract class InviteDraft with _$InviteDraft {
  /// [email] with the default role (*Em campo*) unless [roles] says
  /// otherwise.
  const factory InviteDraft(
    String email, {
    @Default({GroupRole.publisher}) Set<GroupRole> roles,
  }) = _InviteDraft;
}

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

/// Why [email] cannot be added to the list of [drafts], or `null`.
String? inviteEmailProblem(String email, Iterable<InviteDraft> drafts) {
  final clean = email.trim().toLowerCase();
  if (!_emailPattern.hasMatch(clean)) return 'Digite um e-mail válido.';
  if (drafts.any((d) => d.email == clean)) return '$clean já está na lista.';
  return null;
}
