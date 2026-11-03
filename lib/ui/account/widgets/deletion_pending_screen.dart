import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/ui/core/ui/app_messenger.dart';
import 'package:monamie_app/ui/core/themes/monamie_brand.dart';
import 'package:monamie_app/ui/account/view_models/deletion_pending_view_model.dart';

import 'package:monamie_app/domain/models/account_deletion.dart';

/// *Em exclusão*: the account (and the organization its owner deletes with
/// it) is waiting to be erased. Cancelling within the 30 days brings
/// everything back.
class DeletionPendingScreen extends StatelessWidget {
  const DeletionPendingScreen({super.key, required this.controller});

  final DeletionPendingViewModel controller;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark,
    child: Scaffold(
      backgroundColor: MonAmieBrand.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
          child: ListenableBuilder(
            listenable: Listenable.merge([
              controller,
              controller.cancelAccountDeletion,
              controller.enter,
            ]),
            builder: (context, _) {
              final state = controller.state;
              final deletion = state.accountDeletion;
              final restored = state.deletionRestored;
              final busy =
                  controller.cancelAccountDeletion.running ||
                  controller.enter.running;
              final l10n = AppLocalizations.of(context);
              final name = deletion?.organizationName;
              final days = deletion == null
                  ? 0
                  : daysLeft(deletion.deleteAt, DateTime.now());
              final title = restored
                  ? (name == null
                        ? l10n.deletionRestoredAccountTitle
                        : l10n.deletionRestoredOrganizationTitle(name))
                  : (name == null
                        ? l10n.deletionPendingAccountTitle(days)
                        : l10n.deletionPendingOrganizationTitle(name, days));
              final body = restored
                  ? l10n.deletionRestoredBody
                  : deletion == null
                  ? ''
                  : name == null
                  ? l10n.deletionPendingAccountBody(deletion.deleteAt.toLocal())
                  : l10n.deletionPendingOrganizationBody(
                      deletion.deleteAt.toLocal(),
                      name,
                    );
              final error = state.deletionError;
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
                          ? () => runReportingErrors(
                              context,
                              controller.enter.execute,
                            )
                          : controller.cancelAccountDeletion.execute,
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
                                  ? l10n.deletionEnter
                                  : name == null
                                  ? l10n.deletionCancelAccount
                                  : l10n.deletionCancel,
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
                      onPressed: busy || state.isLoggingOut
                          ? null
                          : () => runReportingErrors(
                              context,
                              controller.logout.execute,
                            ),
                      child: Text(l10n.commonSignOut),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}
