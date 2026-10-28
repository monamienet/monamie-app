import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/modules/monamie/controller/google_groups_controller.dart';
import 'package:monamie_app/app/modules/monamie/models/google_group_model.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/home_colors.dart';
import 'package:monamie_app/app/utils/color_pallete.dart';

/// The design's easing for things that open: cubic-bezier(.2,.8,.2,1).
const _openCurve = Cubic(0.2, 0.8, 0.2, 1);

/// The team chip of the app bar as a drop-down, as on the design canvas
/// (`Mapa.dc.html`): the chip opens a 272 px card right under it, headed
/// "Ver no mapa" with the number of teams, listing every team whose map the
/// person can watch with its people in the field, the observed one tinted
/// and checked. Tapping outside, or the chip again, closes it.
class TeamMenuButton extends StatefulWidget {
  const TeamMenuButton({super.key, required this.label});

  /// The text of the chip: the observed team, or a prompt to pick one.
  final String label;

  @override
  State<TeamMenuButton> createState() => _TeamMenuButtonState();
}

class _TeamMenuButtonState extends State<TeamMenuButton>
    with SingleTickerProviderStateMixin {
  final _portal = OverlayPortalController();
  final _link = LayerLink();
  late final _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
    reverseDuration: const Duration(milliseconds: 140),
  );

  GoogleGroupsController get _groups => Get.find<GoogleGroupsController>();

  bool get _open => _portal.isShowing && _animation.status.isForwardOrCompleted;

  void _toggle() => _open ? _close() : _show();

  void _show() {
    _portal.show();
    _animation.forward(from: 0);
    setState(() {});
    _groups.loadTeamSizes();
  }

  Future<void> _close() async {
    if (!_portal.isShowing) return;
    setState(() {});
    await _animation.reverse();
    if (mounted) _portal.hide();
  }

  void _pick(GoogleGroupModel team) {
    _close();
    _groups.pickTeam(team);
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: _overlay,
        child: _chip(),
      ),
    );
  }

  Widget _chip() {
    final open = _open;
    final color = AppColors.onPrimaryDark;
    return Semantics(
      button: true,
      expanded: open,
      label: 'Equipe no mapa: ${widget.label}',
      excludeSemantics: true,
      child: InkWell(
        onTap: _toggle,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 36,
            padding: const EdgeInsets.only(left: 14, right: 12),
            decoration: BoxDecoration(
              color: open ? color.withAlpha(41) : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: open ? color : color.withAlpha(110),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns: open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  curve: _openCurve,
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _overlay(BuildContext context) {
    return Stack(
      children: [
        // Tapping anywhere outside the card closes it.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _close,
          ),
        ),
        CompositedTransformFollower(
          link: _link,
          targetAnchor: Alignment.bottomLeft,
          showWhenUnlinked: false,
          child: Align(
            alignment: Alignment.topLeft,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                final closing = _animation.status == AnimationStatus.reverse;
                final t = closing
                    ? Curves.easeIn.transform(_animation.value)
                    : _openCurve.transform(
                        (_animation.value * 240 / 200).clamp(0.0, 1.0),
                      );
                final dy = closing ? -6 * (1 - t) : -8 * (1 - t);
                final scale = closing ? 0.97 + 0.03 * t : 0.96 + 0.04 * t;
                return Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, dy),
                    child: Transform.scale(
                      scale: scale,
                      alignment: const Alignment(-0.79, -1),
                      child: child,
                    ),
                  ),
                );
              },
              child: Obx(_card),
            ),
          ),
        ),
      ],
    );
  }

  Widget _card() {
    final teams = _groups.googleGroups.toList();
    final selected = _groups.selectedGroup.value?.email;
    // Copied here, not read in the item builder: ListView.builder builds rows
    // after Obx stops listening, so a count arriving later would not redraw.
    final sizes = Map.of(_groups.teamSizes);
    return Container(
      width: 272,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3D091416),
            blurRadius: 28,
            offset: Offset(0, 10),
          ),
          BoxShadow(
            color: Color(0x24091416),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: HomeColors.divider)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Expanded(
                    child: Text(
                      'VER NO MAPA',
                      style: TextStyle(
                        color: HomeColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 12 * 0.06,
                      ),
                    ),
                  ),
                  Text(
                    teams.length == 1 ? '1 equipe' : '${teams.length} equipes',
                    style: const TextStyle(
                      color: HomeColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 392),
              child: teams.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child: Text(
                        'Nenhuma equipe disponível',
                        style: TextStyle(color: HomeColors.muted, fontSize: 14),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(top: 4, bottom: 6),
                      itemCount: teams.length,
                      itemBuilder: (context, i) => _item(
                        index: i,
                        team: teams[i],
                        selected: teams[i].email == selected,
                        size: sizes[teams[i].email],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item({
    required int index,
    required GoogleGroupModel team,
    required bool selected,
    required int? size,
  }) {
    // Each row slides in 18 ms after the one above, as on the canvas.
    final delay = (index.clamp(0, 8) * 18) / 240;
    final appear = CurvedAnimation(
      parent: _animation,
      curve: Interval(delay, 1, curve: _openCurve),
    );
    return AnimatedBuilder(
      animation: appear,
      builder: (context, child) {
        final t = _animation.status == AnimationStatus.reverse
            ? 1.0
            : appear.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, -4 * (1 - t)),
            child: child,
          ),
        );
      },
      child: Semantics(
        selected: selected,
        child: InkWell(
          onTap: () => _pick(team),
          highlightColor: const Color(0xFFE6E3EC),
          splashColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            color: selected
                ? Color.lerp(Colors.white, AppColors.primaryLight, 0.5)
                : null,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected
                              ? AppColors.primaryDark
                              : HomeColors.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (size != null) ...[
                        const SizedBox(height: 1),
                        Text(
                          size == 1 ? '1 pessoa' : '$size pessoas',
                          style: const TextStyle(
                            color: HomeColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.check, size: 20, color: AppColors.primary),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
