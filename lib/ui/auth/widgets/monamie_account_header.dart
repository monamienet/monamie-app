import 'package:flutter/material.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/ui/core/themes/monamie_brand.dart';
import 'package:monamie_app/ui/core/ui/monamie_mark.dart';
import 'package:monamie_app/ui/language/view_models/language_view_model.dart';
import 'package:monamie_app/ui/language/widgets/language_button.dart';
import 'package:monamie_app/ui/language/widgets/language_scheme.dart';

/// The top of MonAmie's own screens after sign-in: the mark, the signed-in
/// account, "Trocar" (sign in with another account) and the language
/// button.
class MonAmieAccountHeader extends StatelessWidget {
  const MonAmieAccountHeader({
    super.key,
    required this.email,
    required this.onSwitch,
    required this.language,
  });

  final String? email;
  final VoidCallback? onSwitch;

  /// The language picker, opened by the globe at the end of the row.
  final LanguageViewModel language;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: Row(
      children: [
        const MonAmieMark(width: 40, color: MonAmieBrand.navy),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            email ?? '',
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, color: MonAmieBrand.mutedInk),
          ),
        ),
        TextButton(
          onPressed: onSwitch,
          style: TextButton.styleFrom(
            foregroundColor: MonAmieBrand.navy,
            minimumSize: const Size(44, 44),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              decoration: TextDecoration.underline,
            ),
          ),
          child: Text(AppLocalizations.of(context).accountHeaderSwitch),
        ),
        LanguageButton(
          controller: language,
          scheme: LanguageScheme.organization,
        ),
      ],
    ),
  );
}
