import 'package:flutter/material.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/ui/home/view_models/tracking_toggle_view_model.dart';
import 'package:monamie_app/ui/home/widgets/home_colors.dart';
import 'package:monamie_app/ui/home/widgets/sheet_colors.dart';
import 'package:monamie_app/ui/home/widgets/share_card_state.dart';
import 'package:monamie_app/ui/core/ui/app_messenger.dart';
import 'package:monamie_app/ui/core/themes/color_palette.dart';
import 'package:monamie_app/utils/result.dart';

/// The card that turns location sharing on and off.
///
/// It reads as one switch: tinted and "on" while sharing, grey while off, and
/// locked with a spinner while the service starts or stops, so a second tap
/// can neither queue nor race.
class ShareCard extends StatelessWidget {
  const ShareCard({super.key, required this.controller});

  /// Starts and stops the sharing (the tracking controller).
  final TrackingToggleViewModel controller;

  TrackingToggleViewModel get _tracking => controller;

  @override
  Widget build(BuildContext context) {
    final tracking = _tracking;
    return ListenableBuilder(
      listenable: Listenable.merge([
        tracking.isTrackingEnabled,
        tracking.toggleService,
      ]),
      builder: (context, _) => _card(context, tracking),
    );
  }

  Widget _card(BuildContext context, TrackingToggleViewModel tracking) {
    final state = shareCardState(
      AppLocalizations.of(context),
      enabled: tracking.isTrackingEnabled.value,
      loading: tracking.toggleService.running,
    );
    final tinted = state.isOn && !state.busy;
    final background = tinted ? SheetColors.accent : SheetColors.surface;
    final titleColor = tinted ? AppColors.darkBlue() : SheetColors.ink;
    final subtitleColor = tinted ? AppColors.darkBlue() : SheetColors.muted;

    return Semantics(
      toggled: state.isOn,
      enabled: !state.busy,
      label: '${state.title}. ${state.subtitle}',
      excludeSemantics: true,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: state.busy ? null : () => _toggle(context),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: Center(child: _icon(state)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.title,
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          state.subtitle,
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _Switch(on: state.isOn, busy: state.busy),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Toggles sharing and shows what the controller says: why it did not
  /// start, or a remark on a start (e.g. no GPS fix yet).
  Future<void> _toggle(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await _tracking.toggleService.execute();
    switch (result) {
      case Ok(value: final notice?):
        showNotice(messenger, notice);
      case Ok():
        break;
      case Err():
        showErrorOf(messenger, result);
      case null:
        break;
    }
  }

  Widget _icon(ShareCardState state) {
    if (state.busy) {
      return SizedBox(
        key: const ValueKey('share_card_busy'),
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.6,
          color: SheetColors.accent,
          backgroundColor: SheetColors.handle,
        ),
      );
    }
    return Icon(
      state.isOn ? Icons.location_on_outlined : Icons.location_off_outlined,
      key: ValueKey(state.isOn ? 'share_card_on' : 'share_card_off'),
      size: 24,
      color: state.isOn ? AppColors.darkBlue() : SheetColors.muted,
    );
  }
}

class _Switch extends StatelessWidget {
  const _Switch({required this.on, required this.busy});

  final bool on;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final track = busy
        ? SheetColors.handle
        : on
        ? AppColors.mediumBlue()
        : HomeColors.offline;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 44,
      height: 26,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: track,
        borderRadius: BorderRadius.circular(13),
      ),
      alignment: on ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}
