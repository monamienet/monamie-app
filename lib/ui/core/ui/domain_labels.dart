import 'package:monamie_app/domain/models/group.dart';
import 'package:monamie_app/domain/models/invite.dart';
import 'package:monamie_app/domain/models/tracking_settings.dart';
import 'package:monamie_app/l10n/app_localizations.dart';

/// How the screens name the domain's values, in the language of the
/// [AppLocalizations] they read: the domain keeps the values, the ARB files
/// the words.
extension DomainLabels on AppLocalizations {
  /// *Em campo*, *Vê o mapa*, *Gestor do grupo*.
  String roleName(GroupRole role) => switch (role) {
    GroupRole.publisher => rolePublisher,
    GroupRole.subscriber => roleSubscriber,
    GroupRole.maintainer => roleMaintainer,
  };

  /// One line under [roleName] in the role pickers.
  String roleDescription(GroupRole role) => switch (role) {
    GroupRole.publisher => rolePublisherDescription,
    GroupRole.subscriber => roleSubscriberDescription,
    GroupRole.maintainer => roleMaintainerDescription,
  };

  /// "Em campo · Vê o mapa", in [GroupRole] order.
  String rolesLabel(Set<GroupRole> roles) => [
    for (final role in GroupRole.values)
      if (roles.contains(role)) roleName(role),
  ].join(' · ');

  /// [pendingInvites], or empty for none.
  String pendingInvitesLabel(int count) =>
      count <= 0 ? '' : pendingInvites(count);

  /// "Vale até 9 de novembro", "Expirado · venceu em 9 de novembro", or
  /// just "Expirado" / empty when the date is unknown. Dates on the device's
  /// calendar (the server sends UTC).
  String inviteStatus(Invite invite) {
    final until = invite.expiresAt?.toLocal();
    if (invite.expired) {
      return until == null ? inviteExpired : inviteExpiredOn(until);
    }
    return until == null ? '' : inviteValidUntil(until);
  }

  /// The name of a tracking profile on *Ajustes de acompanhamento*.
  String presetName(TrackingPreset preset) => switch (preset) {
    TrackingPreset.economia => presetEconomia,
    TrackingPreset.equilibrio => presetEquilibrio,
    TrackingPreset.precisao => presetPrecisao,
    TrackingPreset.personalizado => presetPersonalizado,
  };

  /// What deleting a group does, one sentence per line: who loses access to
  /// [organization] ([loses] people in no other group), who stays, the
  /// [invites] cancelled, and that it cannot be undone.
  List<String> groupDeletionLines({
    required int loses,
    required int stays,
    required int invites,
    required String organization,
  }) => [
    if (loses > 0) groupDeletionLoses(loses, organization),
    if (stays > 0) groupDeletionStays(stays),
    if (invites > 0) groupDeletionInvites(invites),
    groupDeletionTrails,
  ];

  /// The text under "`<group>` excluído": how many people ([loses]) lost
  /// access to [organization].
  String deletedGroupText({required int loses, required String organization}) =>
      [
        if (loses > 0) groupDeletedLost(loses, organization),
        groupDeletedOthersStay,
      ].join(' ');
}
