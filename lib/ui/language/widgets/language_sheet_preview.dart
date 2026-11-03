import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:monamie_app/data/repositories/language/language_repository.dart';
import 'package:monamie_app/domain/models/app_language.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/ui/core/app_locales.dart';
import 'package:monamie_app/ui/language/view_models/language_view_model.dart';
import 'package:monamie_app/ui/language/widgets/language_scheme.dart';
import 'package:monamie_app/ui/language/widgets/language_sheet.dart';
import 'package:monamie_app/utils/result.dart';

/// Widget Previewer entries (`flutter widget-preview start`, or the IDE's
/// preview tab) of the language picker in its three schemes. Nothing here is
/// used by the app.

/// The localization setup the previews run in: the app's own, in Brazilian
/// Portuguese. (Public and top-level, as the previewer requires.)
PreviewLocalizationsData languagePreviewLocalizations() =>
    const PreviewLocalizationsData(
      locale: Locale('pt', 'BR'),
      supportedLocales: appSupportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
    );

/// A [LanguageRepository] that keeps the choice in memory, so the previewed
/// sheet can be tapped.
class _MemoryLanguages implements LanguageRepository {
  final _language = ValueNotifier<AppLanguage?>(null);

  @override
  ValueListenable<AppLanguage?> get language => _language;

  @override
  Future<void> restore() async {}

  @override
  Future<Result<void>> choose(AppLanguage language) async {
    _language.value = language;
    return const Ok(null);
  }
}

/// The sheet in [scheme], over the dim barrier it opens above.
class _PreviewSheet extends StatefulWidget {
  const _PreviewSheet(this.scheme);

  final LanguageScheme scheme;

  @override
  State<_PreviewSheet> createState() => _PreviewSheetState();
}

class _PreviewSheetState extends State<_PreviewSheet> {
  late final LanguageViewModel _controller = LanguageViewModel(
    repository: _MemoryLanguages(),
    deviceLocales: () => const [Locale('pt', 'BR')],
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0x8C091416),
    body: Align(
      alignment: Alignment.bottomCenter,
      child: LanguageSheet(controller: _controller, scheme: widget.scheme),
    ),
  );
}

@Preview(
  name: 'Menu', // check_layers: not_ui_text
  group: 'LanguageSheet', // check_layers: not_ui_text
  size: Size(390, 460),
  localizations: languagePreviewLocalizations,
)
Widget languageSheetMenuPreview() => const _PreviewSheet(LanguageScheme.menu);

@Preview(
  name: 'Login', // check_layers: not_ui_text
  group: 'LanguageSheet', // check_layers: not_ui_text
  size: Size(390, 460),
  localizations: languagePreviewLocalizations,
)
Widget languageSheetLoginPreview() => const _PreviewSheet(LanguageScheme.login);

@Preview(
  name: 'Organization', // check_layers: not_ui_text
  group: 'LanguageSheet', // check_layers: not_ui_text
  size: Size(390, 460),
  localizations: languagePreviewLocalizations,
)
Widget languageSheetOrganizationPreview() =>
    const _PreviewSheet(LanguageScheme.organization);
