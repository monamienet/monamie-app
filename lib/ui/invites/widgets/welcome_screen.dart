import 'package:flutter/material.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/ui/core/ui/domain_labels.dart';
import 'package:monamie_app/domain/models/organization/organization.dart';
import 'package:monamie_app/ui/core/ui/organization_icon.dart';
import 'package:monamie_app/ui/core/themes/organization_palette.dart';
import 'package:monamie_app/domain/models/group.dart';
import 'package:monamie_app/ui/invites/view_models/welcome_view_model.dart';

/// *Boas-vindas*: shown once, after accepting an invite: the organization,
/// the group and what the person does in the app. People in the field go on
/// to the existing location disclosure on the map.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.controller});

  final WelcomeViewModel controller;

  @override
  Widget build(BuildContext context) {
    // The invite the screen opened with.
    final invite = controller.invite;
    final organization = Organization.current;
    final palette = OrganizationPalette.fromConfig(organization);
    final shares = invite?.roles.contains(GroupRole.publisher) ?? false;
    final l10n = AppLocalizations.of(context);
    // The router follows the session to the map.
    void open() => controller.finishWelcome();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 72, 24, 32),
            decoration: BoxDecoration(
              color: palette.dark,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(28),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OrganizationIcon(organization: organization, size: 72),
                const SizedBox(height: 20),
                Text(
                  l10n.welcomeJoined(
                    organization?.name ?? invite?.organizationName ?? '',
                  ),
                  style: TextStyle(
                    fontSize: 32,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    color: palette.onDark,
                  ),
                ),
                if (invite != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    invite.inviterName.isEmpty
                        ? invite.groupName
                        : l10n.welcomeInvitedBy(
                            invite.groupName,
                            invite.inviterName,
                          ),
                    style: TextStyle(fontSize: 16, color: palette.light),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
              children: [
                Text(
                  l10n.welcomeWhatYouDo,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                for (final role in GroupRole.everyday)
                  if (invite?.roles.contains(role) ?? false)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: palette.light,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            role == GroupRole.publisher
                                ? Icons.place_outlined
                                : Icons.visibility_outlined,
                            color: palette.dark,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.roleName(role),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: palette.dark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  role == GroupRole.publisher
                                      ? l10n.welcomePublisher
                                      : l10n.welcomeSubscriber(
                                          invite!.groupName,
                                        ),
                                  style: TextStyle(color: palette.dark),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.primary,
                      foregroundColor: palette.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    onPressed: open,
                    child: Text(
                      shares ? l10n.welcomeTurnOnLocation : l10n.welcomeOpenMap,
                    ),
                  ),
                ),
                if (shares)
                  TextButton(onPressed: open, child: Text(l10n.welcomeLater)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
