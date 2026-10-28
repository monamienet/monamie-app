import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/config/partner/partner_config.dart';
import 'package:monamie_app/app/config/partner/partner_theme.dart';

import 'appearance_backend.dart';
import 'logo_converter.dart';

/// Where the logo sheet is: closed, converting the picked file, showing the
/// converted logo, or explaining why the file cannot be used.
enum LogoSheet { closed, processing, preview, error }

/// State and actions of the owner's *Aparência* screen: name, theme and
/// logo, saved together.
class AppearanceController extends GetxController {
  AppearanceController({
    required this.partner,
    required AppearanceBackend backend,
    Future<Uint8List> Function(Uint8List bytes)? convertLogo,
    Future<void> Function(PartnerConfig saved)? onSaved,
  }) : _backend = backend,
       _convertLogo = convertLogo ?? toSquareLogoPng,
       _onSaved = onSaved;

  /// The partner as it is now (bound).
  final PartnerConfig partner;
  final AppearanceBackend _backend;
  final Future<Uint8List> Function(Uint8List bytes) _convertLogo;
  final Future<void> Function(PartnerConfig saved)? _onSaved;

  late final RxString name = partner.name.obs;
  late final RxString themeId = partner.effectiveTheme.id.obs;
  late final Rxn<Uint8List> logoPng = Rxn<Uint8List>(partner.logoPng);
  final RxList<PartnerTheme> themes = <PartnerTheme>[].obs;
  final RxBool isLoadingThemes = true.obs;
  final RxBool isSaving = false.obs;
  final Rx<LogoSheet> sheet = LogoSheet.closed.obs;
  final RxString sheetError = ''.obs;
  final RxString errorMessage = ''.obs;

  /// The converted logo waiting for "Usar este logo".
  Uint8List? _candidate;
  Uint8List? get candidate => _candidate;

  @override
  void onInit() {
    super.onInit();
    _loadThemes();
  }

  Future<void> _loadThemes() async {
    isLoadingThemes.value = true;
    try {
      themes.assignAll(await _backend.pickableThemes());
    } catch (e) {
      debugPrint('[Appearance] Could not load the themes: $e');
      themes.assignAll([partner.effectiveTheme]);
    } finally {
      isLoadingThemes.value = false;
    }
  }

  /// The theme currently picked, for the screen's colors.
  PartnerTheme get pickedTheme =>
      themes.firstWhereOrNull((t) => t.id == themeId.value) ??
      partner.effectiveTheme;

  bool get _logoChanged => !identical(logoPng.value, partner.logoPng);

  /// Whether anything differs from what is saved.
  bool get hasChanges =>
      name.value.trim() != partner.name ||
      themeId.value != partner.effectiveTheme.id ||
      _logoChanged;

  /// Converts a picked file into the square PNG and shows the preview.
  Future<void> pickLogo(Uint8List bytes) async {
    if (sheet.value == LogoSheet.processing) return;
    sheet.value = LogoSheet.processing;
    try {
      _candidate = await _convertLogo(bytes);
      sheet.value = LogoSheet.preview;
    } on LogoException catch (e) {
      sheetError.value = e.message;
      sheet.value = LogoSheet.error;
    } catch (e) {
      sheetError.value = 'Não deu para abrir este arquivo.';
      sheet.value = LogoSheet.error;
    }
  }

  /// Keeps the previewed logo (saved with the other changes).
  void useCandidate() {
    final png = _candidate;
    if (png == null) return;
    logoPng.value = png;
    _candidate = null;
    sheet.value = LogoSheet.closed;
  }

  void closeSheet() {
    if (sheet.value == LogoSheet.processing) return;
    _candidate = null;
    sheet.value = LogoSheet.closed;
  }

  /// Back to the name's initial (saved with the other changes).
  void removeLogo() => logoPng.value = null;

  /// Saves what changed. Returns whether it worked.
  Future<bool> save() async {
    if (isSaving.value || !hasChanges) return false;
    isSaving.value = true;
    errorMessage.value = '';
    try {
      String? logo;
      if (_logoChanged) {
        final png = logoPng.value;
        if (png == null) {
          await _backend.deleteLogo(partner.id);
          logo = 'removed';
        } else {
          await _backend.uploadLogo(partner.id, png);
          logo = 'set';
        }
      }
      final newName = name.value.trim();
      await _backend.saveBranding(
        partner.id,
        name: newName != partner.name ? newName : null,
        themeId: themeId.value != partner.effectiveTheme.id
            ? themeId.value
            : null,
        logo: logo,
      );
      await _onSaved?.call(
        PartnerConfig(
          id: partner.id,
          name: newName,
          themeId: themeId.value,
          theme: pickedTheme,
          logoVersion: logo == 'removed'
              ? null
              : (logo == 'set'
                    ? DateTime.now().millisecondsSinceEpoch
                    : partner.logoVersion),
          logoPng: logoPng.value,
        ),
      );
      return true;
    } on AppearanceException catch (e) {
      errorMessage.value = e.message;
      return false;
    } catch (e) {
      debugPrint('[Appearance] Save failed: $e');
      errorMessage.value =
          'Não foi possível salvar agora. Verifique a conexão e tente de novo.';
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
