import 'package:flutter/services.dart';

import 'create_organization_controller.dart';

/// Keeps the identifier to a to z, as the canvas does: capitals are lowered,
/// accents dropped and anything else removed (by [suggestOrganizationId]), and
/// the caret goes to the end of what is left. [onAdjusted] is told after every
/// edit whether it was changed, so the screen can say so.
class IdInputFormatter extends TextInputFormatter {
  IdInputFormatter(this.onAdjusted);

  final void Function(bool adjusted) onAdjusted;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final clean = suggestOrganizationId(newValue.text);
    onAdjusted(clean != newValue.text);
    if (clean == newValue.text) return newValue;
    return TextEditingValue(
      text: clean,
      selection: TextSelection.collapsed(offset: clean.length),
    );
  }
}
