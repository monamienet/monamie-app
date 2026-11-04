import 'package:flutter/material.dart';
import 'package:monamie_app/domain/models/app_language.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/ui/core/ui/failure_text.dart';
import 'package:monamie_app/ui/language/view_models/language_view_model.dart';
import 'package:monamie_app/ui/language/widgets/language_scheme.dart';
import 'package:monamie_app/utils/result.dart';

/// Opens the language picker over [context]'s screen, on the root navigator
/// (outside the organization's scope), wearing [scheme]'s colors. The sheet
/// closes once the language is chosen.
Future<void> showLanguageSheet(
  BuildContext context, {
  required LanguageViewModel controller,
  required LanguageScheme scheme,
}) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  barrierColor: const Color(0x8C091416),
  // The sheet draws its own rounded background across the whole width.
  backgroundColor: Colors.transparent,
  constraints: const BoxConstraints(),
  builder: (_) => LanguageSheet(controller: controller, scheme: scheme),
);

/// The name of [language], written in [language] itself.
String languageName(AppLanguage language) =>
    lookupAppLocalizations(language.locale).languageName;

/// The language picker: each language written in itself, the one in use
/// marked. Choosing one applies at once (the sheet redraws in it) and closes
/// the sheet; no Save button.
class LanguageSheet extends StatefulWidget {
  const LanguageSheet({
    super.key,
    required this.controller,
    required this.scheme,
  });

  final LanguageViewModel controller;
  final LanguageScheme scheme;

  @override
  State<LanguageSheet> createState() => _LanguageSheetState();
}

class _LanguageSheetState extends State<LanguageSheet> {
  LanguageViewModel get controller => widget.controller;

  /// The message of the last choice that could not be stored.
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => controller.load.execute(),
    );
  }

  Future<void> _choose(AppLanguage language) async {
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    setState(() => _error = null);
    switch (await controller.choose.execute(language)) {
      case Ok():
        navigator.pop();
      case Err(:final failure):
        if (mounted) setState(() => _error = failure.message(l10n));
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = LanguageColors.of(widget.scheme);
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([controller, controller.choose]),
      builder: (context, _) {
        final busy = controller.choose.running;
        return PopScope(
          canPop: !busy,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            decoration: BoxDecoration(
              color: colors.sheet,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: colors.sheetBorder == null
                  ? null
                  : Border(top: BorderSide(color: colors.sheetBorder!)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2E1B1838),
                  blurRadius: 16,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.handle,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Semantics(
                    header: true,
                    child: Text(
                      l10n.languageTitle,
                      style: TextStyle(
                        fontSize: 22,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.44,
                        color: colors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final (index, language) in AppLanguage.values.indexed)
                    Padding(
                      padding: EdgeInsets.only(top: index == 0 ? 0 : 8),
                      child: _LanguageRow(
                        language: language,
                        colors: colors,
                        selected: controller.state.inUse == language,
                        pending: controller.choose.argument == language,
                        onTap: busy ? null : () => _choose(language),
                      ),
                    ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: TextStyle(
                        fontSize: 13,
                        height: 19 / 13,
                        fontWeight: FontWeight.w800,
                        color: colors.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.language,
    required this.colors,
    required this.selected,
    required this.pending,
    required this.onTap,
  });

  final AppLanguage language;
  final LanguageColors colors;
  final bool selected;

  /// Whether choosing this language is in flight.
  final bool pending;

  /// `null` locks the row while a choice is stored.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final name = languageName(language);
    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: name,
      excludeSemantics: true,
      child: Material(
        color: colors.row,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? colors.selectedRing : colors.rowRing,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.chip,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      language.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.56,
                        color: colors.onChip,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      name,
                      locale: language.locale,
                      style: TextStyle(
                        fontSize: 17,
                        height: 22 / 17,
                        fontWeight: FontWeight.w800,
                        color: colors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  _Mark(colors: colors, selected: selected, pending: pending),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The 24 px mark at the end of a row: a check on the language in use, a
/// spinner while it is being stored, an empty ring on the others.
class _Mark extends StatelessWidget {
  const _Mark({
    required this.colors,
    required this.selected,
    required this.pending,
  });

  final LanguageColors colors;
  final bool selected;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    if (pending) {
      return SizedBox(
        width: 24,
        height: 24,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: colors.ink,
            backgroundColor: colors.ink.withValues(alpha: 0.2),
          ),
        ),
      );
    }
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? colors.mark : null,
        border: selected
            ? null
            : Border.all(color: colors.unselectedMark, width: 2),
      ),
      child: selected
          ? Icon(Icons.check, size: 14, color: colors.onMark)
          : null,
    );
  }
}
