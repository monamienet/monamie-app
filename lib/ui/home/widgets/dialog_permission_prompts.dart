import 'package:flutter/material.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/utils/permission_prompts.dart';
import 'package:monamie_app/ui/core/ui/app_messenger.dart';
import 'package:monamie_app/ui/core/themes/color_palette.dart';

/// [PermissionPrompts] as dialogs on the root navigator
/// ([rootNavigatorKey]): the questions come from `PermissionsRepository` in
/// the middle of a flow, with no `BuildContext` of its own.
class DialogPermissionPrompts implements PermissionPrompts {
  const DialogPermissionPrompts();

  @override
  Future<bool> confirmBackgroundUsageSettings() => _confirm(
    icon: Icons.battery_alert,
    message: (l10n) => l10n.permissionBackgroundUsage,
  );

  /// Required by Google Play.
  @override
  Future<bool> confirmBackgroundLocation() => _confirm(
    icon: Icons.security,
    message: (l10n) => l10n.permissionBackgroundLocation,
  );

  @override
  Future<void> notifyGpsDisabled() async {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(dialogContext);
        return AlertDialog(
          title: Text(l10n.permissionGpsOffTitle),
          content: Text(l10n.permissionGpsOffBody),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.darkBlue(),
              ),
              child: Text(l10n.permissionGotIt),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        );
      },
    );
  }

  /// An "Atenção" dialog with [icon] and [message] (in the dialog's
  /// language); completes with whether the person tapped "PROSSEGUIR". It
  /// cannot be dismissed by tapping outside.
  Future<bool> _confirm({
    required IconData icon,
    required String Function(AppLocalizations l10n) message,
  }) async {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return false;
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            final l10n = AppLocalizations.of(dialogContext);
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0),
              ),
              title: Row(
                children: [
                  Icon(icon, color: AppColors.darkBlue()),
                  const SizedBox(width: 10),
                  Text(l10n.permissionAttention),
                ],
              ),
              content: Text(message(l10n)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.darkBlue(),
                  ),
                  child: Text(l10n.permissionNotNow),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.darkBlue(),
                  ),
                  child: Text(l10n.permissionContinue),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}
