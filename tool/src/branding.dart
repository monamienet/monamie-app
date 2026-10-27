import 'partners.dart';

/// Path of partner [id]'s branding document in its project.
String brandingDocumentPath(String id) =>
    '${partnerDataPath(id)}/config/branding';

/// Builds the `config/branding` document of a partner: its [name] and the
/// catalog theme [themeId] (one of [themeIds]).
///
/// The name is mandatory and must not start with "MonAmie " (it would read
/// as MonAmie's own brand; the app never shows the two names together).
/// Partners pick a theme, never free colors. The logo is not set here: the
/// owner uploads it from the app (*Aparência*).
Map<String, Object?> buildBrandingDocument({
  required String name,
  required String themeId,
  required Iterable<String> themeIds,
}) {
  final trimmedName = name.trim();
  if (trimmedName.isEmpty) {
    throw PartnerToolException('The partner name must not be blank.');
  }
  if (trimmedName.toLowerCase().startsWith('monamie ')) {
    throw PartnerToolException(
      "The partner name must not start with 'MonAmie ': it would read as "
      "MonAmie's own brand, and the app never shows the two names together.",
    );
  }
  if (!themeIds.contains(themeId)) {
    throw PartnerToolException(
      "Unknown theme '$themeId'. Pick one of: ${themeIds.join(', ')}.",
    );
  }
  return {'name': trimmedName, 'themeId': themeId};
}
