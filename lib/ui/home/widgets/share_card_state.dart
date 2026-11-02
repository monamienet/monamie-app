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

/// The card's state from the tracking controller's two flags.
ShareCardState shareCardState({required bool enabled, required bool loading}) {
  if (loading) {
    return enabled
        ? const ShareCardState(
            SharePhase.stopping,
            'Desativando compartilhamento…',
            'Aguarde um instante',
          )
        : const ShareCardState(
            SharePhase.starting,
            'Ativando compartilhamento…',
            'Aguarde um instante',
          );
  }
  return enabled
      ? const ShareCardState(
          SharePhase.on,
          'Compartilhando sua localização',
          'Seus grupos veem você no mapa',
        )
      : const ShareCardState(
          SharePhase.off,
          'Localização desligada',
          'Seus grupos não veem você no mapa',
        );
}
