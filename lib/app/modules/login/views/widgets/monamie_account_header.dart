import 'package:flutter/material.dart';
import 'package:monamie_app/app/config/organization/monamie_brand.dart';
import 'package:monamie_app/app/config/organization/monamie_mark.dart';

/// The top of MonAmie's own screens after sign-in: the mark, the signed-in
/// account and "Trocar" (sign in with another account).
class MonAmieAccountHeader extends StatelessWidget {
  const MonAmieAccountHeader({
    super.key,
    required this.email,
    required this.onSwitch,
  });

  final String? email;
  final VoidCallback? onSwitch;

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
          child: const Text('Trocar'),
        ),
      ],
    ),
  );
}
