import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/ui/core/ui/domain_labels.dart';
import 'package:go_router/go_router.dart';
import 'package:monamie_app/ui/history/view_models/calendar_view_model.dart';
import 'package:monamie_app/ui/home/view_models/home_view_model.dart';
import 'package:monamie_app/ui/home/view_models/tracking_view_model.dart';
import 'package:monamie_app/ui/home/view_models/user_view_model.dart';
import 'package:monamie_app/ui/home/widgets/home_layout.dart';
import 'package:monamie_app/ui/home/widgets/people_list.dart';
import 'package:monamie_app/ui/home/widgets/share_card.dart';
import 'package:monamie_app/ui/home/widgets/sheet_colors.dart';
import 'package:monamie_app/routing/routes.dart';
import 'package:monamie_app/ui/core/themes/color_palette.dart';

/// The panel under the map: the sharing switch for people who share, the
/// observed group for people who watch. It is drawn on the theme's dark
/// shade, continuing the header ([SheetColors]).
///
/// Dragging the grabber down hides the group's list so the map gets the
/// room; dragging it up (or tapping it) shows the list again.
class HomeSheet extends StatefulWidget {
  const HomeSheet({
    super.key,
    required this.home,
    required this.tracking,
    required this.calendar,
    required this.user,
  });

  final HomeViewModel home;
  final TrackingViewModel tracking;
  final CalendarViewModel calendar;
  final UserViewModel user;

  @override
  State<HomeSheet> createState() => _HomeSheetState();
}

class _HomeSheetState extends State<HomeSheet> {
  HomeViewModel get _home => widget.home;

  /// Whether the group's list is hidden.
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
    return ListenableBuilder(
      listenable: Listenable.merge([
        _home.capabilities,
        _home.selectedGroup,
        _home.observedMembers,
      ]),
      builder: (context, _) {
        final layout = HomeLayout.of(
          canShare: _home.canPublish,
          canWatch: _home.canWatch,
          isWeb: kIsWeb,
        );
        if (!layout.showShareCard && !layout.showGroup) {
          return const SizedBox.shrink();
        }
        return Material(
          color: SheetColors.background,
          elevation: 12,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (layout.showGroup)
                    _grabber()
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: _grabberBar(),
                    ),
                  if (layout.showShareCard) ...[
                    const SizedBox(height: 4),
                    ShareCard(controller: widget.tracking),
                  ],
                  if (layout.showGroup)
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: _collapsed
                          ? const SizedBox(width: double.infinity)
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: _group(afterCard: layout.showShareCard),
                            ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// The bar drawn at the top of the sheet.
  Widget _grabberBar() => Center(
    child: Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: SheetColors.handle,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );

  /// The bar with a touch area tall enough to drag or tap, which hides and
  /// shows the group's list.
  Widget _grabber() => Semantics(
    button: true,
    label: _collapsed
        ? AppLocalizations.of(context).sheetShowList
        : AppLocalizations.of(context).sheetHideList,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _collapsed = !_collapsed),
      onVerticalDragUpdate: (details) => _drag += details.delta.dy,
      onVerticalDragEnd: _onDragEnd,
      child: SizedBox(height: 20, child: _grabberBar()),
    ),
  );

  /// The observed group's header and people. [afterCard] keeps the design's
  /// 12 px under the share card; right under the grabber it needs only 4.
  List<Widget> _group({required bool afterCard}) {
    final group = _home.selectedGroup.value;
    final count = _home.observedMembers.value.length;
    final l10n = AppLocalizations.of(context);
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
                group == null ? l10n.sheetNoGroup : l10n.mapGroupName(group),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: SheetColors.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (group != null)
              Text(
                l10n.memberCount(count),
                style: TextStyle(
                  color: SheetColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
      if (group != null && count == 0)
        _emptyGroup()
      else if (group != null)
        PeopleList(
          home: _home,
          tracking: widget.tracking,
          calendar: widget.calendar,
          user: widget.user,
        ),
    ];
  }

  Widget _emptyGroup() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context).sheetEmptyGroup,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SheetColors.muted,
              fontSize: 15,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_home.isAdmin) ...[
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 48),
                backgroundColor: SheetColors.accent,
                foregroundColor: AppColors.darkBlue(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => context.push<void>(Routes.groups),
              child: Text(
                AppLocalizations.of(context).invitePeople,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
