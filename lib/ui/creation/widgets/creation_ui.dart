import 'package:flutter/material.dart';
import 'package:monamie_app/ui/core/themes/monamie_brand.dart';

/// The colors of *Criar organização*.
abstract final class CreationColors {
  static const navy = MonAmieBrand.navy;
  static const muted = MonAmieBrand.mutedInk;
  static const line = Color(0xFFDDD5C4);
  static const ring = Color(0xFFB8AE9A);
  static const danger = Color(0xFFC23F1E);
  static const ok = Color(0xFF2F7347);
  static const note = Color(0xFFECE6D9);
}

const _navy = CreationColors.navy;
const _muted = CreationColors.muted;
const _line = CreationColors.line;

/// A step's big title, an optional [subtitle] under it and [gap] below.
Widget creationTitle(String text, [String? subtitle, double gap = 20]) =>
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 34,
            height: 1.08,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.035 * 34,
            color: _navy,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 16,
              height: 24 / 16,
              fontWeight: FontWeight.w500,
              color: _muted,
            ),
          ),
        ],
        SizedBox(height: gap),
      ],
    );

/// The wizard's full-width navy button; while [busy] it is disabled and
/// shows a spinner and [busyLabel].
Widget creationButton(
  String label,
  VoidCallback? onPressed, {
  bool busy = false,
  String? busyLabel,
}) => SizedBox(
  height: 56,
  child: FilledButton(
    style: FilledButton.styleFrom(
      backgroundColor: _navy,
      foregroundColor: MonAmieBrand.cream,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      disabledBackgroundColor: _line,
      disabledForegroundColor: _muted,
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
    ),
    onPressed: busy ? null : onPressed,
    child: busy
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: MonAmieBrand.cream,
                ),
              ),
              const SizedBox(width: 12),
              Text(busyLabel ?? label),
            ],
          )
        : Text(label),
  ),
);

/// A field's bold label.
Widget creationLabel(String text) => Text(
  text,
  style: const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    color: _navy,
  ),
);

/// A 13 px line of [text] in [color].
Widget creationNote(String text, {required Color color, bool bold = false}) =>
    Text(
      text,
      style: TextStyle(
        fontSize: 13,
        height: 19 / 13,
        fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
        color: color,
      ),
    );

/// A text field's rounded border.
OutlineInputBorder creationFieldBorder(Color color, double width) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
