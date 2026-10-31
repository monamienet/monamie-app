import 'package:monamie_app/app/config/organization/group_address.dart';

/// What the signed-in person may do in the bound organization, from the custom
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

  /// Organizations the person administers (member of their root group): they
  /// watch every team of these and manage them.
  final Set<String> admin;

  /// No capability at all: the person was removed from every group.
  bool get isEmpty => share.isEmpty && watch.isEmpty && admin.isEmpty;

  /// Whether the person shares their location in some team.
  bool get canShare => share.isNotEmpty;

  /// Whether the person administers [organizationId] (the *administrador*).
  bool isAdminOf(String organizationId) => admin.contains(organizationId);

  /// Whether the person sees any map of [organizationId]: they watch one of its
  /// teams, or administer it.
  bool canWatchIn(String organizationId) =>
      isAdminOf(organizationId) ||
      watch.any(
        (key) =>
            parseGroupAddress(teamEmailForKey(key))?.organizationId ==
            organizationId,
      );

  /// Whether the person sees the map of team [teamKey].
  bool canWatchTeam(String teamKey) {
    final organizationId = parseGroupAddress(
      teamEmailForKey(teamKey),
    )?.organizationId;
    return watch.contains(teamKey) ||
        (organizationId != null && isAdminOf(organizationId));
  }

  /// The team keys of [organizationId] where the person shares, sorted.
  List<String> shareTeamsIn(String organizationId) => [
    for (final key in share)
      if (parseGroupAddress(teamEmailForKey(key))?.organizationId ==
          organizationId)
        key,
  ]..sort();

  /// The keys of the teams of [organizationId] the person sees on the map,
  /// sorted. An administrator sees every team in [allTeamKeys] (the organization's team
  /// groups); anyone else sees the teams they watch.
  List<String> watchTeamsIn(
    String organizationId,
    Iterable<String> allTeamKeys,
  ) {
    final keys = isAdminOf(organizationId)
        ? {
            ...allTeamKeys.where(
              (key) =>
                  parseGroupAddress(teamEmailForKey(key))?.organizationId ==
                  organizationId,
            ),
          }
        : {
            for (final key in watch)
              if (parseGroupAddress(teamEmailForKey(key))?.organizationId ==
                  organizationId)
                key,
          };
    return keys.toList()..sort();
  }
}
