import 'package:monamie_app/app/config/partner/group_address.dart';

/// What the signed-in person may do in the bound partner, from the custom
/// claims `syncClaims` sets (see `firestore.rules`).
class Capabilities {
  const Capabilities({
    this.share = const {},
    this.watch = const {},
    this.admin = const {},
  });

  /// Reads the claims `share`, `watch` and `admin` (lists of strings). A
  /// missing or malformed claim is an empty set, never an error.
  factory Capabilities.fromClaims(Map<String, Object?> claims) {
    Set<String> list(String name) => switch (claims[name]) {
      final List<Object?> values => {
        for (final value in values)
          if (value is String && value.isNotEmpty) value.toLowerCase(),
      },
      _ => const {},
    };
    return Capabilities(
      share: list('share'),
      watch: list('watch'),
      admin: list('admin'),
    );
  }

  /// Team keys (`rotasul01`) where the person shares their location.
  final Set<String> share;

  /// Team keys whose map the person sees.
  final Set<String> watch;

  /// Partners the person administers (member of their root group): they
  /// watch every team of these and manage them.
  final Set<String> admin;

  /// No capability at all: the person was removed from every group.
  bool get isEmpty => share.isEmpty && watch.isEmpty && admin.isEmpty;

  /// Whether the person shares their location in some team.
  bool get canShare => share.isNotEmpty;

  /// Whether the person administers [partnerId] (the *administrador*).
  bool isAdminOf(String partnerId) => admin.contains(partnerId);

  /// Whether the person sees any map of [partnerId]: they watch one of its
  /// teams, or administer it.
  bool canWatchIn(String partnerId) =>
      isAdminOf(partnerId) ||
      watch.any(
        (key) =>
            parseGroupAddress(teamEmailForKey(key))?.partnerId == partnerId,
      );

  /// Whether the person sees the map of team [teamKey].
  bool canWatchTeam(String teamKey) {
    final partnerId = parseGroupAddress(teamEmailForKey(teamKey))?.partnerId;
    return watch.contains(teamKey) ||
        (partnerId != null && isAdminOf(partnerId));
  }

  /// The team keys of [partnerId] where the person shares, sorted.
  List<String> shareTeamsIn(String partnerId) => [
    for (final key in share)
      if (parseGroupAddress(teamEmailForKey(key))?.partnerId == partnerId) key,
  ]..sort();

  /// The keys of the teams of [partnerId] the person sees on the map,
  /// sorted. An administrator sees every team in [allTeamKeys] (the partner's team
  /// groups); anyone else sees the teams they watch.
  List<String> watchTeamsIn(String partnerId, Iterable<String> allTeamKeys) {
    final keys = isAdminOf(partnerId)
        ? {
            ...allTeamKeys.where(
              (key) =>
                  parseGroupAddress(teamEmailForKey(key))?.partnerId ==
                  partnerId,
            ),
          }
        : {
            for (final key in watch)
              if (parseGroupAddress(teamEmailForKey(key))?.partnerId ==
                  partnerId)
                key,
          };
    return keys.toList()..sort();
  }
}
