import 'package:flutter/material.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/domain/models/organization/organization_theme.dart';
import 'package:monamie_app/ui/core/themes/monamie_brand.dart';

import 'package:monamie_app/ui/creation/view_models/create_organization_view_model.dart';
import 'creation_ui.dart';

const _navy = CreationColors.navy;
const _muted = CreationColors.muted;
const _line = CreationColors.line;

/// *Escolha um tema*, the wizard's second step. Its parent rebuilds it when
/// [controller] changes.
class CreationThemeStep extends StatelessWidget {
  const CreationThemeStep({super.key, required this.controller});

  final CreateOrganizationViewModel controller;

  CreateOrganizationViewModel get c => controller;

  /// *Escolha um tema* (`CriarTema.dc.html`): title, a preview of the app
  /// in the picked theme, the eight themes in a grid of chips with their
  /// names, and the button at the bottom.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            children: [
              creationTitle(
                l10n.creationThemeTitle,
                l10n.creationThemeSubtitle,
              ),
              _themePreview(l10n),
              const SizedBox(height: 20),
              _themeGrid(),
            ],
          ),
        ),
        const SizedBox(height: 20),
        creationButton(l10n.commonContinue, c.next),
      ],
    );
  }

  /// The app in the picked theme: its bar with the organization's tile and
  /// name, a map with a trail, a person, the "Compartilhando" pill and the
  /// locate button.
  Widget _themePreview(AppLocalizations l10n) {
    final theme = c.pickedTheme;
    final name = c.preview.name;
    return Semantics(
      label: l10n.creationThemePreview,
      child: Container(
        height: 220,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _line),
        ),
        child: Column(
          children: [
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              color: theme.dark,
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.primary,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      name.characters.first.toUpperCase(),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: theme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: theme.onDark,
                      ),
                    ),
                  ),
                  Text(
                    l10n.creationPreviewGroup,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.onDark,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: const Color(0xFFEEF0EB),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _PreviewMapPainter(theme.primary),
                      ),
                    ),
                    Positioned(
                      left: 182,
                      top: 80,
                      child: Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: theme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Text(
                          // A sample person's initials.
                          'AL', // check_layers: not_ui_text
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: theme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: theme.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          l10n.creationPreviewSharing,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: theme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: theme.light,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.my_location,
                          size: 20,
                          color: theme.dark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Four chips per row, each a swatch of the theme's color with its dark
  /// shade as a band, and the theme's name under it.
  Widget _themeGrid() {
    final themes = c.state.themes;
    return LayoutBuilder(
      builder: (context, box) {
        const columns = 4;
        const gap = 10.0;
        final chip = (box.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: 12,
          children: [
            for (final theme in themes)
              SizedBox(
                width: chip,
                child: _themeChip(theme, theme.id == c.state.themeId),
              ),
          ],
        );
      },
    );
  }

  Widget _themeChip(OrganizationTheme theme, bool selected) => Semantics(
    label: theme.name,
    selected: selected,
    button: true,
    excludeSemantics: true,
    child: InkWell(
      onTap: () => c.pickTheme(theme.id),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              // A cream ring, then an ink one, outside the chip.
              boxShadow: selected
                  ? const [
                      BoxShadow(color: MonAmieBrand.cream, spreadRadius: 2),
                      BoxShadow(color: _navy, spreadRadius: 4),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  Positioned.fill(child: ColoredBox(color: theme.primary)),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 16,
                    child: ColoredBox(color: theme.dark),
                  ),
                  if (selected)
                    const Icon(Icons.check, size: 22, color: Colors.white),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            theme.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              height: 16 / 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              color: selected ? _navy : _muted,
            ),
          ),
        ],
      ),
    ),
  );
}

/// The roads and the trail of the theme preview, drawn on the canvas' 340 by
/// 168 grid and stretched to the preview's map area.
class _PreviewMapPainter extends CustomPainter {
  const _PreviewMapPainter(this.trail);

  final Color trail;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 340, size.height / 168);
    final road = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    final roads = Path()
      ..moveTo(0, 118)
      ..lineTo(340, 96)
      ..moveTo(70, 0)
      ..lineTo(110, 168)
      ..moveTo(220, 0)
      ..lineTo(190, 168)
      ..moveTo(0, 40)
      ..lineTo(340, 58);
    canvas.drawPath(roads, road);
    canvas.drawPath(
      Path()
        ..moveTo(86, 70)
        ..lineTo(150, 63)
        ..lineTo(204, 60)
        ..lineTo(196, 100),
      Paint()
        ..color = trail
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_PreviewMapPainter old) => old.trail != trail;
}
