/// What the home screen shows to a person, decided by their capabilities in
/// the bound partner.
class HomeLayout {
  const HomeLayout({required this.showShareCard, required this.showTeam});

  /// Whether the card that turns location sharing on and off is shown.
  final bool showShareCard;

  /// Whether the team's people are listed under the map.
  final bool showTeam;

  /// [canShare] and [canWatch] are the person's capabilities; background
  /// sharing needs a phone, so [isWeb] hides the card.
  factory HomeLayout.of({
    required bool canShare,
    required bool canWatch,
    required bool isWeb,
  }) => HomeLayout(showShareCard: canShare && !isWeb, showTeam: canWatch);
}

/// The text of the team chip under the app bar.
///
/// A person who watches picks the team whose map they see ([observedTeam],
/// `null` until they pick one); a person who only shares sees the team or
/// teams they share with, so the team is never a mystery.
String teamChipLabel({
  required bool canWatch,
  required String? observedTeam,
  required List<String> shareTeams,
}) {
  if (canWatch) return observedTeam ?? 'Escolher equipe';
  if (shareTeams.isEmpty) return 'Sem equipe';
  if (shareTeams.length == 1) return shareTeams.first;
  return '${shareTeams.first} +${shareTeams.length - 1}';
}

/// The line under the organization's name in the menu.
String menuSubtitle({
  required bool isOwner,
  required bool canWatch,
  required bool canShare,
  required List<String> shareTeams,
}) {
  if (isOwner) return 'Você é responsável';
  if (canWatch && canShare) return 'Acompanha e compartilha';
  if (canWatch) return 'Acompanha o mapa';
  final team = teamChipLabel(
    canWatch: false,
    observedTeam: null,
    shareTeams: shareTeams,
  );
  return '$team · em campo';
}
