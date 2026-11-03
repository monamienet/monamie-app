import 'package:monamie_app/l10n/app_localizations.dart';

/// Where the location-sharing switch is in its life.
enum SharePhase { off, starting, on, stopping }

/// The text and look of the sharing card for one moment.
class ShareCardState {
  const ShareCardState(this.phase, this.title, this.subtitle);

  final SharePhase phase;
  final String title;
  final String subtitle;

  /// A change is in flight: the switch is locked and shows a spinner.
  bool get busy => phase == SharePhase.starting || phase == SharePhase.stopping;

  /// The switch reads as on (it stays on while stopping).
  bool get isOn => phase == SharePhase.on || phase == SharePhase.stopping;
}

/// The card's state from the tracking controller's two flags, its text in
/// [l10n]'s language.
ShareCardState shareCardState(
  AppLocalizations l10n, {
  required bool enabled,
  required bool loading,
}) {
  if (loading) {
    return enabled
        ? ShareCardState(
            SharePhase.stopping,
            l10n.shareStopping,
            l10n.shareWait,
          )
        : ShareCardState(
            SharePhase.starting,
            l10n.shareStarting,
            l10n.shareWait,
          );
  }
  return enabled
      ? ShareCardState(SharePhase.on, l10n.shareOn, l10n.shareOnSubtitle)
      : ShareCardState(SharePhase.off, l10n.shareOff, l10n.shareOffSubtitle);
}
