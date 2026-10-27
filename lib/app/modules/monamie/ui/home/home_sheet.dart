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
/// observed team for people who watch, and a note for people who only share.
class HomeSheet extends StatelessWidget {
  const HomeSheet({super.key});

  GoogleGroupsController get _groups => Get.find<GoogleGroupsController>();

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
      if (!layout.showShareCard &&
          !layout.showTeam &&
          !layout.showFieldOnlyNote) {
        return const SizedBox.shrink();
      }
      return Material(
        color: Colors.white,
        elevation: 12,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: HomeColors.handle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (layout.showShareCard) ...[
                  const SizedBox(height: 12),
                  const ShareCard(),
                ],
                if (layout.showTeam) ..._team(),
                if (layout.showFieldOnlyNote) ...[
                  const SizedBox(height: 12),
                  _fieldOnlyNote(),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }

  List<Widget> _team() {
    final team = _groups.selectedGroup.value;
    final count = _groups.observedMembers.length;
    return [
      const SizedBox(height: 12),
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

  Widget _fieldOnlyNote() {
    final teams = _groups.shareTeams.map((team) => team.name).join(', ');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HomeColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.info_outline, size: 18, color: HomeColors.muted),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Você compartilha sua localização com $teams. Quem acompanha a '
              'equipe vê você no mapa; daqui você vê só a sua posição.',
              style: const TextStyle(
                color: HomeColors.muted,
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
