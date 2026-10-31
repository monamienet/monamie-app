import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/config/organization/organization.dart';
import 'package:monamie_app/app/config/organization/organization_icon.dart';
import 'package:monamie_app/app/config/organization/organization_palette.dart';
import 'package:monamie_app/app/modules/admin/groups/group.dart';
import 'package:monamie_app/app/modules/login/controllers/auth_google_controller.dart';
import 'package:monamie_app/app/routes/app_pages.dart';

/// *Boas-vindas*: shown once, after accepting an invite: the organization,
/// the group and what the person does in the app. People in the field go on
/// to the existing location disclosure on the map.
class WelcomeView extends GetView<AuthGoogleController> {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final invite = controller.welcome.value;
    final organization = Organization.current;
    final palette = OrganizationPalette.fromConfig(organization);
    final shares = invite?.roles.contains(GroupRole.publisher) ?? false;
    void open() {
      controller.welcome.value = null;
      Get.offAllNamed(Routes.MONAMIE);
    }

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
                  'Você entrou na ${organization?.name ?? invite?.organizationName ?? ''}',
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
                        : '${invite.groupName} · convite de ${invite.inviterName}',
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
                const Text(
                  'O que você faz no app',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
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
                                  role.label,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: palette.dark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  role == GroupRole.publisher
                                      ? 'Seus grupos veem onde você está enquanto o '
                                            'compartilhamento estiver ligado. Você '
                                            'liga e desliga quando quiser.'
                                      : 'Você acompanha no mapa quem está em campo '
                                            'em ${invite!.groupName}.',
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
                      shares ? 'Ativar minha localização' : 'Abrir o mapa',
                    ),
                  ),
                ),
                if (shares)
                  TextButton(
                    onPressed: open,
                    child: const Text('Ativar depois'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
