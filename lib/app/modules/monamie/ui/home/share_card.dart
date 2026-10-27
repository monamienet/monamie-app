import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/modules/monamie/controller/tracking_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/tracking_toggle_controller.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/home_colors.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/share_card_state.dart';
import 'package:monamie_app/app/utils/color_pallete.dart';

/// The card that turns location sharing on and off.
///
/// It reads as one switch: tinted and "on" while sharing, grey while off, and
/// locked with a spinner while the service starts or stops, so a second tap
/// can neither queue nor race.
class ShareCard extends StatelessWidget {
  /// [controller] lets a widget test inject a fake.
  const ShareCard({super.key, this.controller});

  final TrackingToggleController? controller;

  TrackingToggleController get _tracking =>
      controller ?? Get.find<TrackingController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = shareCardState(
        enabled: _tracking.isTrackingEnabled.value,
        loading: _tracking.isTrackingLoading.value,
      );
      final tinted = state.isOn && !state.busy;
      final background = tinted ? AppColors.lightBlue() : HomeColors.surface;
      final titleColor = tinted ? AppColors.darkBlue() : HomeColors.ink;
      final subtitleColor = tinted ? AppColors.darkBlue() : HomeColors.muted;

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
            onTap: state.busy ? null : _tracking.toggleService,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
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
    });
  }

  Widget _icon(ShareCardState state) {
    if (state.busy) {
      return SizedBox(
        key: const ValueKey('share_card_busy'),
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.6,
          color: AppColors.mediumBlue(),
          backgroundColor: HomeColors.handle,
        ),
      );
    }
    return Icon(
      state.isOn ? Icons.location_on_outlined : Icons.location_off_outlined,
      key: ValueKey(state.isOn ? 'share_card_on' : 'share_card_off'),
      size: 24,
      color: state.isOn ? AppColors.darkBlue() : HomeColors.muted,
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
        ? HomeColors.handle
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
