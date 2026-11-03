import 'package:monamie_app/l10n/app_localizations.dart';

/// How fresh a person's last position is, which decides the line under their
/// name and the color of their avatar in the group list.
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
/// "live" until [validity] has passed since [lastSeen]. The label is in
/// [l10n]'s language.
Presence presenceOf(
  AppLocalizations l10n, {
  required bool hasRecord,
  required bool? isPublishing,
  required DateTime? lastSeen,
  required DateTime now,
  required Duration validity,
}) {
  final never = Presence(PresenceKind.never, l10n.presenceNever);
  if (!hasRecord) return never;

  if (isPublishing == false) {
    return Presence(
      PresenceKind.off,
      lastSeen == null
          ? l10n.presenceOff
          : l10n.presenceOffSeen(agoLabel(l10n, lastSeen, now)),
    );
  }

  if (lastSeen == null) return never;

  if (now.difference(lastSeen) >= validity) {
    final ago = agoLabel(l10n, lastSeen, now);
    return Presence(
      PresenceKind.stale,
      '${ago[0].toUpperCase()}${ago.substring(1)}',
    );
  }
  return Presence(PresenceKind.live, l10n.presenceLive);
}

/// "agora", "há 12 min", "há 2 h", "ontem" or "há 3 dias" for [then] seen
/// from [now], in [l10n]'s language.
String agoLabel(AppLocalizations l10n, DateTime then, DateTime now) {
  final diff = now.difference(then);
  if (diff.inMinutes < 1) return l10n.agoNow;
  if (diff.inMinutes < 60) return l10n.agoMinutes(diff.inMinutes);
  if (diff.inHours < 24) return l10n.agoHours(diff.inHours);
  final days = DateTime(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime(then.year, then.month, then.day)).inDays;
  return days <= 1 ? l10n.agoYesterday : l10n.agoDays(days);
}

/// The line under a name while a past day is observed: that day's trail, not
/// whether the person is sharing now. In [l10n]'s language.
Presence dayPresence(AppLocalizations l10n, {required bool hasPoints}) =>
    hasPoints
    ? Presence(PresenceKind.live, l10n.presenceDayPoints)
    : Presence(PresenceKind.off, l10n.presenceDayNoPoints);
