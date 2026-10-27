import 'package:flutter/material.dart';
import 'package:monamie_app/app/utils/color_pallete.dart';

/// A rounded outline chip on the dark app bar: the team and the day.
///
/// The visible chip is 36 px tall inside a 44 px touch target.
class HomeChip extends StatelessWidget {
  const HomeChip({
    super.key,
    required this.label,
    this.icon,
    this.showChevron = false,
    this.onTap,
    this.semanticsLabel,
  });

  final String label;
  final IconData? icon;
  final bool showChevron;

  /// `null` makes the chip a plain label.
  final VoidCallback? onTap;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.onPrimaryDark;
    final chip = Container(
      height: 36,
      padding: EdgeInsets.only(left: icon == null ? 14 : 12, right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withAlpha(110), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (showChevron) ...[
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 18, color: color),
          ],
        ],
      ),
    );

    return Semantics(
      button: onTap != null,
      label: semanticsLabel ?? label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: chip,
        ),
      ),
    );
  }
}
