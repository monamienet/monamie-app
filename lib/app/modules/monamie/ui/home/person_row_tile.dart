import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/home_colors.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/initials.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/presence.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/team_rows.dart';
import 'package:monamie_app/app/utils/color_pallete.dart';

/// One person of the team list: avatar, name, how fresh their position is,
/// and the buttons to draw their trail and to call them on Google Meet.
///
/// It reads no controller: the list passes what it shows and what each
/// button does, so the tile can be tested alone.
class PersonRowTile extends StatelessWidget {
  const PersonRowTile({
    super.key,
    required this.row,
    required this.highlighted,
    required this.onToggleTrail,
    this.selected = false,
    this.onCall,
  });

  final TeamRow row;

  /// Whether the person's trail is drawn on the map.
  final bool highlighted;
  final VoidCallback onToggleTrail;

  /// Whether the person's marker was pressed on the map: the row is tinted
  /// softly so it can be found in the list.
  final bool selected;

  /// Opens the call; `null` hides the button (a person does not call
  /// themselves).
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) {
    final kind = row.presence.kind;
    final name = row.member.name;
    final live = kind == PresenceKind.live;
    final trailLabel = highlighted
        ? 'Esconder trajeto de $name'
        : 'Mostrar trajeto de $name';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      constraints: const BoxConstraints(minHeight: 52),
      decoration: BoxDecoration(
        color: selected ? HomeColors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            _Avatar(initials: initialsOf(name), kind: kind),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: HomeColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    highlighted && live
                        ? '${row.presence.label} · trajeto visível'
                        : row.presence.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: live ? AppColors.darkBlue() : HomeColors.muted,
                      fontSize: 12,
                      fontWeight: live ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _SquareButton(
              label: trailLabel,
              toggled: highlighted,
              onTap: onToggleTrail,
              child: Icon(
                Icons.timeline,
                size: 20,
                color: highlighted ? AppColors.darkBlue() : HomeColors.muted,
              ),
            ),
            if (onCall != null) ...[
              const SizedBox(width: 8),
              _SquareButton(
                label: 'Chamar $name no Meet',
                onTap: onCall!,
                child: SvgPicture.asset(
                  'assets/monamie/Google_Meet_icon.svg',
                  width: 22,
                  height: 22,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A 44 px rounded button of the list row; tinted when [toggled].
class _SquareButton extends StatelessWidget {
  const _SquareButton({
    required this.label,
    required this.onTap,
    required this.child,
    this.toggled,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;

  /// `null` for a plain button, a bool for a toggle.
  final bool? toggled;

  @override
  Widget build(BuildContext context) {
    final on = toggled ?? false;
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        toggled: toggled,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? AppColors.lightBlue() : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: on
                  ? null
                  : Border.all(color: HomeColors.outline, width: 1.5),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials, required this.kind});

  final String initials;
  final PresenceKind kind;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;
    BoxBorder? border;
    switch (kind) {
      case PresenceKind.live:
        background = AppColors.mediumBlue();
        foreground = AppColors.onPrimary;
      case PresenceKind.stale:
        background = HomeColors.offline;
        foreground = Colors.white;
      case PresenceKind.off:
      case PresenceKind.never:
        background = HomeColors.surface;
        foreground = HomeColors.muted;
        border = Border.all(color: HomeColors.handle, width: 1.5);
    }
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: border,
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: foreground,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
