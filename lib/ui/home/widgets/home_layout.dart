import 'package:monamie_app/l10n/app_localizations.dart';

/// What the home screen shows to a person, decided by their capabilities in
/// the bound organization.
class HomeLayout {
  const HomeLayout({required this.showShareCard, required this.showGroup});

  /// Whether the card that turns location sharing on and off is shown.
  final bool showShareCard;

  /// Whether the observed group's people are listed under the map.
  final bool showGroup;

  /// [canShare] and [canWatch] are the person's capabilities; background
  /// sharing needs a phone, so [isWeb] hides the card.
  factory HomeLayout.of({
    required bool canShare,
    required bool canWatch,
    required bool isWeb,
  }) => HomeLayout(showShareCard: canShare && !isWeb, showGroup: canWatch);
}

/// The text of the group chip under the app bar.
///
/// A person who watches picks the group whose map they see
/// ([observedGroup], `null` until they pick one); a person who only shares
/// sees the group or groups they share with ([publishGroups]), so where
/// their location goes is never a mystery. In [l10n]'s language.
String groupChipLabel(
  AppLocalizations l10n, {
  required bool canWatch,
  required String? observedGroup,
  required List<String> publishGroups,
}) {
  if (canWatch) return observedGroup ?? l10n.homeChooseGroup;
  if (publishGroups.isEmpty) return l10n.homeNoGroup;
  if (publishGroups.length == 1) return publishGroups.first;
  return l10n.homeMoreGroups(publishGroups.first, publishGroups.length - 1);
}

/// The line under the organization's name in the menu, in [l10n]'s
/// language.
String menuSubtitle(
  AppLocalizations l10n, {
  required bool isAdmin,
  required bool canWatch,
  required bool canShare,
  required List<String> publishGroups,
}) {
  if (isAdmin) return l10n.menuAdministers;
  if (canWatch && canShare) return l10n.menuWatchesAndShares;
  if (canWatch) return l10n.menuWatches;
  final group = groupChipLabel(
    l10n,
    canWatch: false,
    observedGroup: null,
    publishGroups: publishGroups,
  );
  return l10n.menuInTheField(group);
}
