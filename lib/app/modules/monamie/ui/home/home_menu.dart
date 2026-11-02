import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/config/organization/monamie_brand.dart';
import 'package:monamie_app/app/config/organization/organization.dart';
import 'package:monamie_app/app/config/organization/organization_icon.dart';
import 'package:monamie_app/app/modules/login/controllers/auth_google_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/group_map_state.dart';
import 'package:monamie_app/app/modules/monamie/controller/tracking_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/user_controller.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/home_colors.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/home_layout.dart';
import 'package:monamie_app/app/modules/monamie/ui/home/initials.dart';
import 'package:monamie_app/app/routes/app_pages.dart';
import 'package:monamie_app/app/utils/app_messenger.dart';
import 'package:monamie_app/app/utils/color_pallete.dart';
import 'package:monamie_app/app/utils/result.dart';

/// The side menu: who the person is and where, the organization's
/// administration (for its administrators only) and sign-out.
class HomeMenu extends StatelessWidget {
  const HomeMenu({super.key});

  GroupMapState get _groups => Get.find<GroupMapState>();
  UserController get _user => Get.find<UserController>();
  AuthGoogleController get _auth => Get.find<AuthGoogleController>();
  TrackingController get _tracking => Get.find<TrackingController>();

  /// Closes the menu, then goes to [route].
  void _open(BuildContext context, String route) {
    Navigator.pop(context);
    Get.toNamed<void>(route);
  }

  /// Closes the menu, then runs [action] and shows its message when it fails.
  /// The messenger outlives the menu (and the home screen, on sign-out).
  Future<void> _closeAndRun(
    BuildContext context,
    Future<Result<Object?>> Function() action,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    showErrorOf(messenger, await action());
  }

  @override
  Widget build(BuildContext context) {
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
                label: 'Trocar de organização',
                onTap: () => _closeAndRun(context, _auth.switchOrganization),
              ),
              ListenableBuilder(
                listenable: _groups.capabilities,
                builder: (context, _) {
                  if (_groups.isAdmin) return _admin(context);
                  // A group's maintainer manages only their groups.
                  if (_groups.capabilities.value.canManageGroups) {
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
                listenable: _auth,
                builder: (context, _) => Obx(() {
                  // Both read every time: Obx needs to see the Rx.
                  final trackingBusy = _tracking.isTrackingLoading.value;
                  final loggingOut = _auth.state.isLoggingOut;
                  return _MenuItem(
                    icon: Icons.logout,
                    label: 'Sair',
                    onTap: loggingOut || trackingBusy
                        ? null
                        : () => _closeAndRun(context, _auth.logout),
                  );
                }),
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
                    _groups.capabilities,
                    _groups.publishGroups,
                  ]),
                  builder: (context, _) => Text(
                    menuSubtitle(
                      isAdmin: _groups.isAdmin,
                      canWatch: _groups.canWatch,
                      canShare: _groups.canPublish,
                      publishGroups: [
                        for (final group in _groups.publishGroups.value)
                          group.name,
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
          label: 'Minha conta',
          excludeSemantics: true,
          child: Material(
            color: HomeColors.surface,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _open(context, Routes.MY_ACCOUNT),
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
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(color: HomeColors.divider, height: 1),
          _sectionTitle('GESTÃO DE GRUPOS'),
          _MenuItem(
            icon: Icons.groups_outlined,
            label: 'Meus grupos',
            onTap: () => _open(context, Routes.GROUPS),
          ),
        ],
      ),
    );
  }

  Widget _admin(BuildContext context) {
    final organizationId = Organization.current?.id;
    // The owner-only entry needs to know who owns the organization: read
    // once per organization, while the menu is open.
    if (organizationId != null) _auth.loadOwnership(organizationId);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(color: HomeColors.divider, height: 1),
          _sectionTitle('ADMINISTRAÇÃO'),
          _MenuItem(
            icon: Icons.groups_outlined,
            label: 'Grupos',
            onTap: () => _open(context, Routes.GROUPS),
          ),
          ListenableBuilder(
            listenable: _auth,
            builder: (context, _) =>
                _auth.state.ownership[organizationId] == true
                ? _MenuItem(
                    icon: Icons.admin_panel_settings_outlined,
                    label: 'Administradores',
                    onTap: () => _open(context, Routes.ADMINISTRATORS),
                  )
                : const SizedBox.shrink(),
          ),
          _MenuItem(
            icon: Icons.palette_outlined,
            label: 'Aparência da organização',
            onTap: () => _open(context, Routes.APPEARANCE),
          ),
          _MenuItem(
            icon: Icons.tune,
            label: 'Ajustes de acompanhamento',
            onTap: () => _open(context, Routes.TRACKING_SETTINGS),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;

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
            ],
          ),
        ),
      ),
    );
  }
}
