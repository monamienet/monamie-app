/// How fresh a person's last position is, which decides the line under their
/// name and the color of their avatar in the team list.
enum PresenceKind {
  /// Updated within the organization's freshness threshold.
  live,

  /// Sharing, but silent for longer than the threshold.
  stale,

  /// Turned the location off.
  off,

  /// Never shared a position.
  never,
}

class Presence {
  const Presence(this.kind, this.label);

  final PresenceKind kind;
  final String label;

  @override
  bool operator ==(Object other) =>
      other is Presence && other.kind == kind && other.label == label;

  @override
  int get hashCode => Object.hash(kind, label);

  @override
  String toString() => 'Presence($kind, $label)';
}

/// The presence of one person from their live document in `positions`.
///
/// [hasRecord] is false when the person has no document yet; [isPublishing] and
/// [lastSeen] are the document's `isPublishing` and `capturedAt`. A person is
/// "live" until [validity] has passed since [lastSeen].
Presence presenceOf({
  required bool hasRecord,
  required bool? isPublishing,
  required DateTime? lastSeen,
  required DateTime now,
  required Duration validity,
}) {
  const never = Presence(PresenceKind.never, 'Ainda não ativou a localização');
  if (!hasRecord) return never;

  if (isPublishing == false) {
    final seen = lastSeen == null ? '' : ' · visto ${agoLabel(lastSeen, now)}';
    return Presence(PresenceKind.off, 'Localização desligada$seen');
  }

  if (lastSeen == null) return never;

  if (now.difference(lastSeen) >= validity) {
    final ago = agoLabel(lastSeen, now);
    return Presence(
      PresenceKind.stale,
      '${ago[0].toUpperCase()}${ago.substring(1)}',
    );
  }
  return const Presence(PresenceKind.live, 'Agora');
}

/// "agora", "há 12 min", "há 2 h", "ontem" or "há 3 dias" for [then] seen
/// from [now].
String agoLabel(DateTime then, DateTime now) {
  final diff = now.difference(then);
  if (diff.inMinutes < 1) return 'agora';
  if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'há ${diff.inHours} h';
  final days = DateTime(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime(then.year, then.month, then.day)).inDays;
  return days <= 1 ? 'ontem' : 'há $days dias';
}

/// The line under a name while a past day is observed: that day's trail, not
/// whether the person is sharing now.
Presence dayPresence({required bool hasPoints}) => hasPoints
    ? const Presence(PresenceKind.live, 'Tem posições neste dia')
    : const Presence(PresenceKind.off, 'Sem posições neste dia');
