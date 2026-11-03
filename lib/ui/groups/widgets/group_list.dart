import 'package:flutter/material.dart';
import 'package:monamie_app/l10n/app_localizations.dart';

import 'package:monamie_app/ui/core/ui/admin_ui.dart';

const _ink = AdminColors.ink;
const _muted = AdminColors.muted;
const _soft = AdminColors.soft;
const _line = AdminColors.line;
const _cardLine = AdminColors.cardLine;
const _fieldLine = AdminColors.fieldLine;
const _error = AdminColors.error;

/// Darker than primary, for the role lines (the prototype's #0B6A66 on the
/// default theme).
Color get _roleTone =>
    Color.lerp(adminPalette.primary, adminPalette.dark, 0.3)!;

/// The bordered list both tabs of *Grupo* share; [empty] shows when [rows]
/// is empty.
class GroupListCard extends StatelessWidget {
  const GroupListCard({super.key, required this.rows, required this.empty});

  final List<Widget> rows;
  final String empty;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _cardLine),
    ),
    child: rows.isEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Text(
              empty,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 21 / 14,
                fontWeight: FontWeight.w500,
                color: _muted,
              ),
            ),
          )
        : ListView(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            children: [
              for (final (i, row) in rows.indexed)
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: i == 0
                        ? null
                        : const Border(top: BorderSide(color: _line)),
                  ),
                  child: row,
                ),
            ],
          ),
  );
}

/// One row of [GroupListCard]: a person in the group ([member]) or an
/// invite, their roles (tappable when [onEditRoles] is given) and an
/// optional action button.
class GroupPersonRow extends StatelessWidget {
  const GroupPersonRow({
    super.key,
    required this.initials,
    required this.title,
    required this.roles,
    required this.member,
    this.actionText,
    this.onAction,
    this.detail = '',
    this.expired = false,
    this.onEditRoles,
  });

  final String initials;
  final String title;
  final String roles;
  final bool member;
  final String? actionText;
  final VoidCallback? onAction;
  final String detail;
  final bool expired;
  final VoidCallback? onEditRoles;

  @override
  Widget build(BuildContext context) {
    final roleLine = Row(
      children: [
        Flexible(
          child: Text(
            roles,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: _roleTone,
            ),
          ),
        ),
        if (onEditRoles != null) ...[
          const SizedBox(width: 4),
          Icon(Icons.edit_outlined, size: 12, color: _roleTone),
        ],
      ],
    );
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        if (detail.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: expired ? FontWeight.w800 : FontWeight.w500,
              color: expired ? _error : _muted,
            ),
          ),
        ],
        const SizedBox(height: 2),
        roleLine,
      ],
    );
    final palette = adminPalette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: member ? palette.primary : _soft,
              border: member ? null : Border.all(color: _fieldLine, width: 1.5),
            ),
            child: Text(
              initials,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: member ? palette.onPrimary : _muted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: onEditRoles == null
                ? text
                : Semantics(
                    button: true,
                    label: AppLocalizations.of(
                      context,
                    ).groupPersonEditRoles(title),
                    child: InkWell(onTap: onEditRoles, child: text),
                  ),
          ),
          const SizedBox(width: 12),
          if (actionText != null && onAction != null)
            SizedBox(
              height: 44,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: expired ? palette.light : Colors.transparent,
                  foregroundColor: expired ? palette.dark : _error,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onPressed: onAction,
                child: Text(actionText!),
              ),
            ),
        ],
      ),
    );
  }
}
