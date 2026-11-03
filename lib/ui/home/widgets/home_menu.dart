import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/ui/core/ui/domain_labels.dart';
import 'package:go_router/go_router.dart';
import 'package:monamie_app/ui/core/themes/monamie_brand.dart';
import 'package:monamie_app/domain/models/organization/organization.dart';
import 'package:monamie_app/ui/core/ui/organization_icon.dart';
import 'package:monamie_app/ui/home/view_models/home_view_model.dart';
import 'package:monamie_app/ui/home/view_models/home_session_view_model.dart';
import 'package:monamie_app/ui/home/view_models/tracking_view_model.dart';
import 'package:monamie_app/ui/home/view_models/user_view_model.dart';
import 'package:monamie_app/ui/home/widgets/home_colors.dart';
import 'package:monamie_app/ui/home/widgets/home_layout.dart';
import 'package:monamie_app/ui/home/widgets/initials.dart';
import 'package:monamie_app/routing/routes.dart';
import 'package:monamie_app/ui/core/ui/app_messenger.dart';
import 'package:monamie_app/ui/language/view_models/language_view_model.dart';
import 'package:monamie_app/ui/language/widgets/language_scheme.dart';
import 'package:monamie_app/ui/language/widgets/language_sheet.dart';
import 'package:monamie_app/ui/core/themes/color_palette.dart';
import 'package:monamie_app/utils/result.dart';

/// The side menu: who the person is and where, the organization's
/// administration (for its administrators only) and sign-out.
class HomeMenu extends StatelessWidget {
  const HomeMenu({
    super.key,
    required this.home,
    required this.user,
    required this.session,
    required this.tracking,
    required this.language,
  });

  final HomeViewModel home;
  final UserViewModel user;

  /// The session: sign-out, switching organization, ownership.
  final HomeSessionViewModel session;
  final TrackingViewModel tracking;

  /// The language picker.
  final LanguageViewModel language;

  HomeViewModel get _home => home;
  UserViewModel get _user => user;
  HomeSessionViewModel get _auth => session;
  TrackingViewModel get _tracking => tracking;

  /// Closes the menu, then opens [route] over the map. A push, not a go:
  /// the screen stays inside the organization's scope, and going back
  /// returns to the map.
  void _open(BuildContext context, String route) {
    final router = GoRouter.of(context);
    Navigator.pop(context);
    router.push<void>(route);
  }

  /// Closes the menu, then opens the language picker over the map, on the
  /// root navigator (the menu's own context is gone once it closes).
  void _openLanguage(BuildContext context) {
    final root = rootNavigatorKey.currentContext;
    Navigator.pop(context);
    if (root == null) return;
    showLanguageSheet(root, controller: language, scheme: LanguageScheme.menu);
  }

  /// Closes the menu, then runs [action] and shows its message when it fails.
  /// The messenger outlives the menu (and the home screen, on sign-out).
  Future<void> _closeAndRun(
    BuildContext context,
    Future<Result<Object?>?> Function() action,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    final result = await action();
    if (result != null) showErrorOf(messenger, result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Drawer(
      width: 304,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _identity(),
              const SizedBox(height: 8),
              _account(context),
              const SizedBox(height: 8),
              _MenuItem(
                icon: Icons.swap_horiz,
                label: l10n.menuSwitchOrganization,
                onTap: () =>
                    _closeAndRun(context, _auth.switchOrganization.execute),
              ),
              ListenableBuilder(
                listenable: language,
                builder: (context, _) => _MenuItem(
                  icon: Icons.language,
                  label: l10n.languageTitle,
                  trailing: languageName(language.state.inUse),
                  onTap: () => _openLanguage(context),
                ),
              ),
              ListenableBuilder(
                listenable: _home.capabilities,
                builder: (context, _) {
                  if (_home.isAdmin) return _admin(context);
                  // A group's maintainer manages only their groups.
                  if (_home.capabilities.value.canManageGroups) {
                    return _maintainer(context);
                  }
                  return const SizedBox.shrink();
                },
              ),
              const Spacer(),
              const Divider(color: HomeColors.divider, height: 1),
              const SizedBox(height: 8),
              // Disabled while signing out and while tracking starts or
              // stops: leaving in the middle of the start could turn the
              // service on after the sign-out.
              ListenableBuilder(
                listenable: Listenable.merge([_auth, _tracking.toggleService]),
                builder: (context, _) {
                  final trackingBusy = _tracking.toggleService.running;
                  final loggingOut = _auth.state.isLoggingOut;
                  return _MenuItem(
                    icon: Icons.logout,
                    label: l10n.commonSignOut,
                    onTap: loggingOut || trackingBusy
                        ? null
                        : () => _closeAndRun(context, _auth.logout.execute),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _identity() {
    final organization = Organization.current;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: Row(
        children: [
          OrganizationIcon(organization: organization, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  organization?.name ?? MonAmieBrand.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: HomeColors.ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                ListenableBuilder(
                  listenable: Listenable.merge([
                    _home.capabilities,
                    _home.publishGroups,
                  ]),
                  builder: (context, _) => Text(
                    menuSubtitle(
                      AppLocalizations.of(context),
                      isAdmin: _home.isAdmin,
                      canWatch: _home.canWatch,
                      canShare: _home.canPublish,
                      publishGroups: [
                        for (final group in _home.publishGroups.value)
                          AppLocalizations.of(context).mapGroupName(group),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: HomeColors.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _account(BuildContext context) {
    return ListenableBuilder(
      listenable: _user,
      builder: (context, _) {
        final user = _user.googleUser;
        final name = user?.name ?? '';
        final email = user?.email ?? '';
        final avatar = user?.avatarBase64;
        return Semantics(
          button: true,
          label: AppLocalizations.of(context).menuMyAccount,
          excludeSemantics: true,
          child: Material(
            color: HomeColors.surface,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _open(context, Routes.myAccount),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    if (avatar != null && avatar.isNotEmpty)
                      ClipOval(
                        child: Image.memory(
                          base64Decode(avatar),
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.lightBlue(),
                        child: Text(
                          initialsOf(name.isEmpty ? email : name),
                          style: TextStyle(
                            color: AppColors.darkBlue(),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isEmpty ? email : name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: HomeColors.ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (name.isNotEmpty)
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: HomeColors.muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: HomeColors.muted),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
    child: Text(
      title,
      style: const TextStyle(
        color: HomeColors.muted,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.7,
      ),
    ),
  );

  /// The maintainer's section: their groups only.
  Widget _maintainer(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(color: HomeColors.divider, height: 1),
          _sectionTitle(l10n.menuGroupManagement),
          _MenuItem(
            icon: Icons.groups_outlined,
            label: l10n.menuMyGroups,
            onTap: () => _open(context, Routes.groups),
          ),
        ],
      ),
    );
  }

  Widget _admin(BuildContext context) {
    final organizationId = Organization.current?.id;
    final l10n = AppLocalizations.of(context);
    // The owner-only entry needs to know who owns the organization: read
    // once per organization, while the menu is open.
    // After the frame: the command notifies when it starts, which must not
    // happen while the menu is building.
    if (organizationId != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _auth.loadOwnership.execute(organizationId),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(color: HomeColors.divider, height: 1),
          _sectionTitle(l10n.menuAdministration),
          _MenuItem(
            icon: Icons.groups_outlined,
            label: l10n.groupsTitle,
            onTap: () => _open(context, Routes.groups),
          ),
          ListenableBuilder(
            listenable: _auth,
            builder: (context, _) =>
                _auth.state.ownership[organizationId] == true
                ? _MenuItem(
                    icon: Icons.admin_panel_settings_outlined,
                    label: l10n.administratorsTitle,
                    onTap: () => _open(context, Routes.administrators),
                  )
                : const SizedBox.shrink(),
          ),
          _MenuItem(
            icon: Icons.palette_outlined,
            label: l10n.menuAppearance,
            onTap: () => _open(context, Routes.appearance),
          ),
          _MenuItem(
            icon: Icons.tune,
            label: l10n.menuTrackingSettings,
            onTap: () => _open(context, Routes.trackingSettings),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;

  /// A short value shown at the end of the row (the language in use).
  final String? trailing;

  /// `null` greys the item out.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = onTap == null ? HomeColors.offline : HomeColors.ink;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(icon, size: 22, color: HomeColors.muted),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: const TextStyle(
                    color: HomeColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
