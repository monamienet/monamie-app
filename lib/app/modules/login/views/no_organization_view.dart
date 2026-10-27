import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/config/partner/monamie_brand.dart';
import 'package:monamie_app/app/modules/admin/teams/team.dart';
import 'package:monamie_app/app/modules/invites/invite.dart';
import 'package:monamie_app/app/modules/login/controllers/auth_google_controller.dart';

import 'widgets/monamie_account_header.dart';

/// *Sem organização*: the signed-in account belongs to no organization yet
/// (or just lost access to one). The person can create their own or check
/// again after someone adds or invites them.
class NoOrganizationView extends GetView<AuthGoogleController> {
  const NoOrganizationView({super.key});

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    // Dark status bar icons on the cream background.
    value: SystemUiOverlayStyle.dark,
    child: Scaffold(
      backgroundColor: MonAmieBrand.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Obx(() {
            final busy = controller.isLoading.value;
            final reason = controller.noAccessReason.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MonAmieAccountHeader(
                  email: controller.signedInEmail.value,
                  onSwitch: busy || controller.isLoggingOut.value
                      ? null
                      : controller.logout,
                ),
                const SizedBox(height: 32),
                if (reason != null) ...[
                  _Notice(text: reason),
                  const SizedBox(height: 24),
                ],
                // Membership starts on acceptance, so an invited person has
                // no group yet and lands here, with the invite.
                for (final invite in controller.pendingInvites)
                  _InviteCard(invite: invite, controller: controller),
                const Text(
                  'Você ainda não faz parte de uma organização',
                  style: TextStyle(
                    fontSize: 34,
                    height: 1.08,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.1,
                    color: MonAmieBrand.navy,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Crie a da sua equipe agora ou peça para alguém dela '
                  'adicionar você.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: MonAmieBrand.mutedInk,
                  ),
                ),
                const SizedBox(height: 24),
                for (final line in const [
                  'Nome e tema em menos de 2 minutos',
                  'Você fica responsável e convida a equipe',
                  'O logo e a aparência você ajusta depois, no app',
                ])
                  _Bullet(text: line),
                const Spacer(),
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: MonAmieBrand.navy,
                      foregroundColor: MonAmieBrand.cream,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    onPressed: busy
                        ? null
                        : controller.startCreatingOrganization,
                    child: const Text('Criar minha organização'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 52,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: MonAmieBrand.navy,
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    onPressed: busy ? null : controller.recheckPartners,
                    child: busy
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: MonAmieBrand.navy,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text('Verificando…'),
                            ],
                          )
                        : const Text('Já me convidaram · verificar de novo'),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    ),
  );
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: MonAmieBrand.coral,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 15, color: MonAmieBrand.navy),
          ),
        ),
      ],
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFFECE6D9),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: MonAmieBrand.navy,
      ),
    ),
  );
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({required this.invite, required this.controller});

  final Invite invite;
  final AuthGoogleController controller;

  @override
  Widget build(BuildContext context) => Obx(() {
    final accepting = controller.acceptingInvite.value == invite.id;
    final busy = controller.acceptingInvite.value != null;
    final shares = invite.roles.contains(TeamRole.share);
    final watches = invite.roles.contains(TeamRole.watch);
    final role = shares && watches
        ? 'em campo e vendo o mapa'
        : shares
        ? 'em campo'
        : 'vendo o mapa';
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Você tem um convite',
            style: TextStyle(fontSize: 13, color: MonAmieBrand.mutedInk),
          ),
          Text(
            invite.partnerName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: MonAmieBrand.navy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${invite.invitedByName.isEmpty ? 'Alguém' : invite.invitedByName} '
            'chamou você para a ${invite.teamName}, $role.'
            '${invite.expiresAt == null ? '' : ' Vale até ${dayMonth(invite.expiresAt!)}.'}',
            style: const TextStyle(fontSize: 15, color: MonAmieBrand.navy),
          ),
          if (controller.inviteError.value.isNotEmpty && !busy) ...[
            const SizedBox(height: 10),
            Text(
              controller.inviteError.value,
              style: const TextStyle(
                color: Color(0xFFB3261E),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            height: 56,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: MonAmieBrand.navy,
                foregroundColor: MonAmieBrand.cream,
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
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            'Entrando na ${invite.partnerName}…',
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
