import 'package:flutter/material.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/ui/core/ui/app_messenger.dart';
import 'package:monamie_app/ui/home/view_models/resume_on_restart_view_model.dart';
import 'package:monamie_app/ui/home/widgets/home_colors.dart';

/// The menu's switch that makes sharing resume by itself after the device
/// restarts or the app is updated, with what would keep it from resuming.
/// Shows nothing where the device cannot resume sharing (web, iOS).
class ResumeOnRestartRow extends StatelessWidget {
  const ResumeOnRestartRow({super.key, required this.controller});

  final ResumeOnRestartViewModel controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      controller,
      controller.setEnabled,
      controller.resolveBlocker,
    ]),
    builder: (context, _) {
      final state = controller.state;
      if (!state.available) return const SizedBox.shrink();
      final l10n = AppLocalizations.of(context);
      final busy = controller.setEnabled.running;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.restart_alt,
                  size: 22,
                  color: HomeColors.muted,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.resumeOnRestartTitle,
                        style: const TextStyle(
                          color: HomeColors.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.resumeOnRestartSubtitle,
                        style: const TextStyle(
                          color: HomeColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: state.enabled,
                  onChanged: busy
                      ? null
                      : (enabled) => runReportingErrors(
                          context,
                          () => controller.setEnabled.execute(enabled),
                        ),
                ),
              ],
            ),
            if (state.blocker case final blocker?)
              _Blocker(
                text: switch (blocker) {
                  ResumeBlocker.alwaysLocation =>
                    l10n.resumeOnRestartNeedsAlwaysLocation,
                  ResumeBlocker.batteryRestricted =>
                    l10n.resumeOnRestartBatteryRestricted,
                },
                busy: controller.resolveBlocker.running,
                onTap: controller.resolveBlocker.execute,
              ),
          ],
        ),
      );
    },
  );
}

/// What keeps sharing from resuming; tapping it opens what fixes it.
class _Blocker extends StatelessWidget {
  const _Blocker({required this.text, required this.busy, required this.onTap});

  final String text;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: busy ? null : onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(38, 6, 4, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (busy)
            const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            const Icon(
              Icons.warning_amber_rounded,
              size: 16,
              color: HomeColors.warning,
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: HomeColors.warningText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
