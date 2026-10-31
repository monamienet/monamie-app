import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/config/organization/monamie_brand.dart';
import 'package:monamie_app/app/modules/login/controllers/auth_google_controller.dart';

import 'account_deletion.dart';

/// *Em exclusão*: the account (and the organization its owner deletes with
/// it) is waiting to be erased. Cancelling within the 30 days brings
/// everything back.
class DeletionPendingView extends GetView<AuthGoogleController> {
  const DeletionPendingView({super.key});

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark,
    child: Scaffold(
      backgroundColor: MonAmieBrand.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
          child: Obx(() {
            final deletion = controller.accountDeletion.value;
            final restored = controller.deletionRestored.value;
            final busy =
                controller.cancellingDeletion.value ||
                controller.isLoading.value;
            final name = deletion?.organizationName;
            final when = deletion == null
                ? ''
                : inDays(daysLeft(deletion.deleteAt, DateTime.now()));
            final title = restored
                ? (name == null
                      ? 'Sua conta está de volta'
                      : 'A $name está de volta')
                : (name == null
                      ? 'Sua conta será excluída $when'
                      : 'A $name será excluída $when');
            final body = restored
                ? 'Nada foi apagado. Entre para continuar de onde parou.'
                : deletion == null
                ? ''
                : name == null
                ? 'Em ${longDate(deletion.deleteAt)} apagamos de vez sua '
                      'conta e seus dados no MonAmie.'
                : 'Em ${longDate(deletion.deleteAt)} apagamos de vez a $name, '
                      'os grupos, o histórico de todos e a sua conta. Até lá '
                      'ninguém usa a organização.';
            final error = controller.deletionError.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  restored ? Icons.restore : Icons.hourglass_bottom,
                  size: 48,
                  color: restored ? MonAmieBrand.navy : MonAmieBrand.coral,
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 32,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    color: MonAmieBrand.navy,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: MonAmieBrand.mutedInk,
                  ),
                ),
                if (error.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(error, style: TextStyle(color: Colors.red.shade800)),
                ],
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
                        : restored
                        ? controller.recheckOrganizations
                        : controller.cancelAccountDeletion,
                    child: busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: MonAmieBrand.cream,
                            ),
                          )
                        : Text(
                            restored
                                ? 'Entrar'
                                : name == null
                                ? 'Cancelar exclusão da conta'
                                : 'Cancelar exclusão',
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 52,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: MonAmieBrand.navy,
                    ),
                    onPressed: busy || controller.isLoggingOut.value
                        ? null
                        : controller.logout,
                    child: const Text('Sair'),
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
