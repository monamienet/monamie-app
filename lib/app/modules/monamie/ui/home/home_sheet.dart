import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/modules/monamie/controller/google_groups_controller.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/home_colors.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/home_layout.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/people_list.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/share_card.dart';
import 'package:monamie_app/app/routes/app_pages.dart';
import 'package:monamie_app/app/utils/color_pallete.dart';

/// The panel under the map: the sharing switch for people who share, the
/// observed team for people who watch.
///
/// Dragging the grabber down hides the team's list so the map gets the
/// room; dragging it up (or tapping it) shows the list again.
class HomeSheet extends StatefulWidget {
  const HomeSheet({super.key});

  @override
  State<HomeSheet> createState() => _HomeSheetState();
}

class _HomeSheetState extends State<HomeSheet> {
  GoogleGroupsController get _groups => Get.find<GoogleGroupsController>();

  /// Whether the team's list is hidden.
  bool _collapsed = false;

  /// How far the grabber moved in the current drag, down positive.
  double _drag = 0;

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final collapse = _drag > 24 || velocity > 300;
    final expand = _drag < -24 || velocity < -300;
    _drag = 0;
    if (collapse && !_collapsed) setState(() => _collapsed = true);
    if (expand && _collapsed) setState(() => _collapsed = false);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.45;
    return Obx(() {
      final layout = HomeLayout.of(
        canShare: _groups.capabilities.value.canShare,
        canWatch: _groups.canWatch,
        isWeb: kIsWeb,
      );
      if (!layout.showShareCard && !layout.showTeam) {
        return const SizedBox.shrink();
      }
      return Material(
        color: Colors.white,
        elevation: 12,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (layout.showTeam)
                  _grabber()
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: _grabberBar(),
                  ),
                if (layout.showShareCard) ...[
                  const SizedBox(height: 4),
                  const ShareCard(),
                ],
                if (layout.showTeam)
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: _collapsed
                        ? const SizedBox(width: double.infinity)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: _team(afterCard: layout.showShareCard),
                          ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  /// The bar drawn at the top of the sheet.
  Widget _grabberBar() => Center(
    child: Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: HomeColors.handle,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );

  /// The bar with a touch area tall enough to drag or tap, which hides and
  /// shows the team's list.
  Widget _grabber() => Semantics(
    button: true,
    label: _collapsed
        ? 'Mostrar a lista da equipe'
        : 'Recolher a lista da equipe',
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _collapsed = !_collapsed),
      onVerticalDragUpdate: (details) => _drag += details.delta.dy,
      onVerticalDragEnd: _onDragEnd,
      child: SizedBox(height: 20, child: _grabberBar()),
    ),
  );

  /// The observed team's header and people. [afterCard] keeps the design's
  /// 12 px under the share card; right under the grabber it needs only 4.
  List<Widget> _team({required bool afterCard}) {
    final team = _groups.selectedGroup.value;
    final count = _groups.observedMembers.length;
    return [
      SizedBox(height: afterCard ? 12 : 4),
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                team?.name ?? 'Nenhuma equipe escolhida',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: HomeColors.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (team != null)
              Text(
                count == 1 ? '1 pessoa' : '$count pessoas',
                style: const TextStyle(
                  color: HomeColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
      if (team != null && count == 0)
        _emptyTeam()
      else if (team != null)
        const PeopleList(),
    ];
  }

  Widget _emptyTeam() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
      child: Column(
        children: [
          const Text(
            'Ninguém nesta equipe ainda. Convide quem vai trabalhar nela '
            'para ver todos no mapa.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: HomeColors.muted,
              fontSize: 15,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_groups.isOwner) ...[
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 48),
                backgroundColor: AppColors.mediumBlue(),
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Get.toNamed<void>(Routes.TEAMS),
              child: const Text(
                'Convidar pessoas',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
