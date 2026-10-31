import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/config/organization/monamie_brand.dart';
import 'package:monamie_app/app/modules/admin/groups/group.dart';
import 'package:monamie_app/app/modules/invites/invite.dart';
import 'package:monamie_app/app/modules/login/controllers/auth_google_controller.dart';

/// A pending invite with *Aceitar e entrar*, on *Sem organização* and
/// *Escolher organização*.
class InviteCard extends StatelessWidget {
  const InviteCard({super.key, required this.invite, required this.controller});

  final Invite invite;
  final AuthGoogleController controller;

  @override
  Widget build(BuildContext context) => Obx(() {
    final accepting = controller.acceptingInvite.value == invite.id;
    // Entering an organization from the picker also locks the card.
    final busy =
        controller.acceptingInvite.value != null || controller.isLoading.value;
    final shares = invite.roles.contains(GroupRole.publisher);
    final watches = invite.roles.contains(GroupRole.subscriber);
    final role = shares && watches
        ? 'em campo e vendo o mapa'
        : shares
        ? 'em campo'
        : 'vendo o mapa';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MonAmieBrand.navy, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Você tem um convite',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: MonAmieBrand.mutedInk,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            invite.organizationName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: MonAmieBrand.navy,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${invite.inviterName.isEmpty ? 'Alguém' : invite.inviterName} '
            'chamou você para o grupo ${invite.groupName}, $role.'
            '${invite.expiresAt == null ? '' : ' Vale até ${dayMonth(invite.expiresAt!)}.'}',
            style: const TextStyle(
              fontSize: 15,
              height: 22 / 15,
              fontWeight: FontWeight.w500,
              color: MonAmieBrand.mutedInk,
            ),
          ),
          if (controller.inviteError.value.isNotEmpty && !busy) ...[
            const SizedBox(height: 16),
            Text(
              controller.inviteError.value,
              style: const TextStyle(
                fontSize: 13,
                height: 19 / 13,
                color: Color(0xFFB3261E),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 56,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: MonAmieBrand.navy,
                foregroundColor: MonAmieBrand.cream,
                disabledBackgroundColor: MonAmieBrand.navy.withValues(
                  alpha: accepting ? 0.8 : 0.38,
                ),
                disabledForegroundColor: MonAmieBrand.cream,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              onPressed: busy ? null : () => controller.acceptInvite(invite),
              child: accepting
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: MonAmieBrand.cream,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'Entrando na ${invite.organizationName}…',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  : const Text('Aceitar e entrar'),
            ),
          ),
        ],
      ),
    );
  });
}
