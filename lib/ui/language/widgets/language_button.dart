import 'package:flutter/material.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/ui/language/view_models/language_view_model.dart';
import 'package:monamie_app/ui/language/widgets/language_scheme.dart';
import 'package:monamie_app/ui/language/widgets/language_sheet.dart';

/// The globe button of MonAmie's entry screens: the code of the language in
/// use, opening the language picker, so a person who does not read the
/// device's language can change it before signing in.
class LanguageButton extends StatelessWidget {
  const LanguageButton({
    super.key,
    required this.controller,
    required this.scheme,
  });

  final LanguageViewModel controller;

  /// The colors of the screen the button sits on, which the picker it opens
  /// wears too.
  final LanguageScheme scheme;

  @override
  Widget build(BuildContext context) {
    final colors = LanguageColors.of(scheme);
    final shape = StadiumBorder(
      side: BorderSide(
        color: colors.buttonRing,
        width: scheme == LanguageScheme.login ? 1.5 : 1,
      ),
    );
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final language = controller.state.inUse;
        return Semantics(
          button: true,
          label: AppLocalizations.of(
            context,
          ).languageButtonLabel(languageName(language)),
          excludeSemantics: true,
          child: Material(
            color: Colors.transparent,
            shape: shape,
            child: InkWell(
              customBorder: shape,
              onTap: () => showLanguageSheet(
                context,
                controller: controller,
                scheme: scheme,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.language, size: 18, color: colors.ink),
                      const SizedBox(width: 6),
                      Text(
                        language.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.52,
                          color: colors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
