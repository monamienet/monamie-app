import 'package:flutter/material.dart';
import 'package:monamie_app/domain/models/organization/organization.dart';
import 'package:monamie_app/ui/core/themes/organization_palette.dart';
import 'package:monamie_app/utils/result.dart';

/// The administration screens' colors (*Grupos*, *Grupo*, *Administradores*).
abstract final class AdminColors {
  static const ink = Color(0xFF1B1838);
  static const muted = Color(0xFF4A4858);
  static const soft = Color(0xFFF1F0F4);
  static const line = Color(0xFFECEAF0);
  static const cardLine = Color(0xFFDDD9E4);
  static const fieldLine = Color(0xFFB9B4C9);
  static const dangerLine = Color(0xFFE8B4AF);
  static const handle = Color(0xFFC9C3D6);
  static const error = Color(0xFFB3261E);
}

const _ink = AdminColors.ink;
const _muted = AdminColors.muted;
const _line = AdminColors.line;
const _handle = AdminColors.handle;
const _error = AdminColors.error;

/// The bound organization's palette.
OrganizationPalette get adminPalette =>
    OrganizationPalette.fromConfig(Organization.current);

OrganizationPalette get _palette => adminPalette;

/// The bound organization's name, "organização" before one is bound.
String get adminOrganizationName => Organization.current?.name ?? 'organização';

/// The administration screens' app bar.
AppBar adminAppBar(String title) => AppBar(
  backgroundColor: _palette.dark,
  foregroundColor: _palette.onDark,
  toolbarHeight: 64,
  title: Text(title),
  titleTextStyle: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: _palette.onDark,
  ),
  centerTitle: false,
);

/// The administration screens' full-width primary button; while [busy] it
/// is disabled and shows a spinner and [busyLabel].
Widget adminPrimaryButton({
  required String label,
  required bool busy,
  required String busyLabel,
  required VoidCallback? onPressed,
  IconData? icon,
}) => SizedBox(
  width: double.infinity,
  height: 56,
  child: FilledButton(
    style: FilledButton.styleFrom(
      backgroundColor: _palette.primary,
      foregroundColor: _palette.onPrimary,
      disabledBackgroundColor: _line,
      disabledForegroundColor: _muted,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
    ),
    onPressed: busy ? null : onPressed,
    child: busy
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: _palette.onPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Text(busyLabel),
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          ),
  ),
);

/// [message] in bold red over a 12 px gap; nothing when it is empty.
Widget adminErrorText(String message) => message.isEmpty
    ? const SizedBox.shrink()
    : Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          message,
          style: const TextStyle(color: _error, fontWeight: FontWeight.w800),
        ),
      );

/// What [adminActionSheet] shows after an operation: nothing when it
/// worked, else its message (a generic one when the call was ignored, see
/// `Command`).
String? sheetFailureOf(Result<Object?>? result) => switch (result) {
  Ok() => null,
  Err(:final message) when message.isNotEmpty => message,
  _ => 'Não foi possível concluir agora. Tente de novo.',
};

/// A bottom sheet with [title], optional [content] and [lines], and a
/// confirm button that runs [onConfirm] (an error message, or `null` on
/// success; see [sheetFailureOf]). While it runs the sheet cannot close and
/// the button shows [busyLabel]; a failure stays in the sheet. [canConfirm]
/// enables the button; [content] is rebuilt with the sheet's `setState` and
/// whether it runs. Completes with whether it succeeded.
Future<bool> adminActionSheet(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  required String busyLabel,
  required Future<String?> Function() onConfirm,
  bool danger = false,
  List<String> lines = const [],
  Widget Function(StateSetter setSheet, bool busy)? content,
  bool Function()? canConfirm,
}) async {
  var busy = false;
  var error = '';
  final done = await showModalBottomSheet<bool>(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setSheet) {
        final tone = danger ? _error : _palette.primary;
        final onTone = danger ? Colors.white : _palette.onPrimary;
        final allowed = canConfirm?.call() ?? true;
        Future<void> confirm() async {
          if (busy || !allowed) return;
          setSheet(() {
            busy = true;
            error = '';
          });
          String? problem;
          try {
            problem = await onConfirm();
          } finally {
            if (context.mounted) setSheet(() => busy = false);
          }
          if (!context.mounted) return;
          if (problem == null) {
            Navigator.of(context).pop(true);
          } else {
            setSheet(() => error = problem!);
          }
        }

        return PopScope(
          canPop: !busy,
          child: Container(
            padding: EdgeInsets.fromLTRB(
              24,
              8,
              24,
              32 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _handle,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.44,
                      color: _ink,
                    ),
                  ),
                  if (content != null) ...[
                    const SizedBox(height: 16),
                    content(setSheet, busy),
                  ],
                  if (lines.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    for (final (i, line) in lines.indexed)
                      Padding(
                        padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(
                              width: 20,
                              child: Text('•', style: _sheetLine),
                            ),
                            Expanded(child: Text(line, style: _sheetLine)),
                          ],
                        ),
                      ),
                  ],
                  if (error.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      error,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 19 / 13,
                        fontWeight: FontWeight.w800,
                        color: _error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: tone,
                        foregroundColor: onTone,
                        disabledBackgroundColor: busy
                            ? tone.withValues(alpha: 0.8)
                            : _line,
                        disabledForegroundColor: busy ? onTone : _muted,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onPressed: busy || !allowed ? null : confirm,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (busy) ...[
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: onTone,
                                backgroundColor: onTone.withValues(alpha: 0.35),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          Text(busy ? busyLabel : confirmLabel),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 48,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: _ink,
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onPressed: busy ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
    isScrollControlled: true,
    // Dragging would close the sheet past PopScope while an operation runs.
    enableDrag: false,
    barrierColor: const Color(0x8C091416),
    // The sheet draws its own white, rounded background, across the whole
    // width as before (Material 3 caps a sheet at 640 px otherwise).
    backgroundColor: Colors.transparent,
    constraints: const BoxConstraints(),
  );
  return done == true;
}

const _sheetLine = TextStyle(
  fontSize: 15,
  height: 22 / 15,
  fontWeight: FontWeight.w500,
  color: _muted,
);

/// The administration screens' short confirmation at the bottom.
void adminToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        backgroundColor: _ink,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 3),
      ),
    );
}
