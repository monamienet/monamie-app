import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:monamie_app/domain/models/organization/organization.dart';
import 'package:monamie_app/data/repositories/organization/organization_session.dart';
import 'package:monamie_app/data/repositories/tracking/tracking_settings_controller.dart';
import 'package:monamie_app/ui/account/widgets/deletion_pending_screen.dart';
import 'package:monamie_app/ui/account/view_models/my_account_view_model.dart';
import 'package:monamie_app/ui/account/widgets/my_account_screen.dart';
import 'package:monamie_app/ui/administrators/view_models/administrators_view_model.dart';
import 'package:monamie_app/ui/administrators/widgets/administrators_screen.dart';
import 'package:monamie_app/ui/appearance/view_models/appearance_view_model.dart';
import 'package:monamie_app/ui/appearance/widgets/appearance_screen.dart';
import 'package:monamie_app/ui/groups/view_models/groups_view_model.dart';
import 'package:monamie_app/ui/groups/widgets/groups_screen.dart';
import 'package:monamie_app/ui/tracking_settings/view_models/tracking_settings_edit_view_model.dart';
import 'package:monamie_app/ui/tracking_settings/widgets/tracking_settings_screen.dart';
import 'package:monamie_app/ui/creation/view_models/create_organization_view_model.dart';
import 'package:monamie_app/ui/creation/widgets/create_organization_screen.dart';
import 'package:monamie_app/ui/invites/view_models/invite_view_model.dart';
import 'package:monamie_app/ui/invites/widgets/invite_screen.dart';
import 'package:monamie_app/ui/invites/widgets/welcome_screen.dart';
import 'package:monamie_app/ui/auth/view_models/auth_google_view_model.dart';
import 'package:monamie_app/ui/auth/view_models/login_view_model.dart';
import 'package:monamie_app/ui/auth/widgets/login_screen.dart';
import 'package:monamie_app/ui/auth/widgets/no_organization_screen.dart';
import 'package:monamie_app/ui/auth/widgets/organization_picker_screen.dart';
import 'package:monamie_app/ui/home/view_models/group_map_state.dart';
import 'package:monamie_app/ui/home/view_models/user_view_model.dart';
import 'package:monamie_app/routing/organization_scope.dart';
import 'package:monamie_app/ui/home/widgets/home_screen.dart';
import 'package:monamie_app/routing/routes.dart';
import 'package:monamie_app/routing/session_redirect.dart';
import 'package:monamie_app/ui/core/ui/app_messenger.dart';
import 'package:monamie_app/utils/result.dart';
import 'package:provider/provider.dart';

/// The app's router.
///
/// The sign-in flow navigates only through [auth]'s session: the router
/// listens to it ([GoRouter.refreshListenable]) and [sessionRedirect] decides
/// the screen, on every navigation and on every change of session. Leaving
/// the organization (sign-out, switch, lost access) is always such a
/// redirect, a `go` that replaces the whole stack, so the organization's
/// shell, and with it [OrganizationScope], is disposed.
///
/// Inside the shell, screens open over the map with `push` (going back
/// returns to the map); screens opened from outside never push over it.
///
/// Route builders read controllers from the providers (the app scope's
/// [AuthGoogleViewModel], the organization's scope) and hand them to the
/// screens; screens never read providers themselves. A route-only
/// controller is created by its route ([_owned]) and disposed when the route
/// closes.
GoRouter buildAppRouter({required AuthGoogleViewModel auth}) => GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: Routes.login,
  refreshListenable: auth.session,
  redirect: (context, state) =>
      sessionRedirect(auth.session.value, state.uri.path),
  // An unknown path (typed on the web) goes to the session's screen.
  onException: (context, state, router) =>
      router.go(sessionLocation(auth.session.value)),
  routes: [
    // *Login* restores a remembered session when it opens: the session
    // becomes bound and the redirect opens the map.
    GoRoute(
      path: Routes.login,
      builder: (context, state) {
        final auth = context.read<AuthGoogleViewModel>();
        return _owned(
          create: () => LoginViewModel(signIn: auth, bondCheck: context.read()),
          builder: (login) => LoginScreen(controller: login, auth: auth),
        );
      },
    ),
    GoRoute(
      path: Routes.noOrganization,
      builder: (context, state) => NoOrganizationScreen(
        controller: context.read<AuthGoogleViewModel>(),
        onCreateOrganization: () =>
            context.go(Routes.createOrganizationOver(Routes.noOrganization)),
      ),
      routes: [_createOrganizationRoute()],
    ),
    GoRoute(
      path: Routes.organizationPicker,
      builder: (context, state) => OrganizationPickerScreen(
        controller: context.read<AuthGoogleViewModel>(),
        onCreateOrganization: () => context.go(
          Routes.createOrganizationOver(Routes.organizationPicker),
        ),
      ),
      routes: [_createOrganizationRoute()],
    ),
    GoRoute(
      path: Routes.welcome,
      builder: (context, state) =>
          WelcomeScreen(controller: context.read<AuthGoogleViewModel>()),
    ),
    GoRoute(
      path: Routes.deletionPending,
      builder: (context, state) => DeletionPendingScreen(
        controller: context.read<AuthGoogleViewModel>(),
      ),
    ),
    ShellRoute(
      builder: (context, state, child) => OrganizationScope(
        onAccessLost: context
            .read<AuthGoogleViewModel>()
            .forgetRemovedOrganization,
        child: child,
      ),
      routes: [
        GoRoute(
          path: Routes.monamie,
          builder: (context, state) => HomeScreen(
            userCtrl: context.read(),
            permissionsCtrl: context.read(),
            trackingCtrl: context.read(),
            groupMap: context.read(),
            calendar: context.read(),
            calls: context.read(),
            authCtrl: context.read<AuthGoogleViewModel>(),
          ),
        ),
        GoRoute(
          path: Routes.myAccount,
          builder: (context, state) {
            final auth = context.read<AuthGoogleViewModel>();
            final organization = Organization.current!;
            return _owned(
              create: () => MyAccountViewModel(
                backend: context.read(),
                organizationId: organization.id,
                checkOwner: () => auth.ownsOrganization(organization.id),
                onDeleted: auth.accountDeleted,
              ),
              builder: (controller) => MyAccountScreen(
                controller: controller,
                email: context.read<UserViewModel>().googleUser?.email ?? '',
                organizationName: organization.name,
              ),
            );
          },
        ),
        GoRoute(
          path: Routes.groups,
          builder: (context, state) {
            final isAdmin = context.read<GroupMapState>().isAdmin;
            return _owned(
              create: () => GroupsViewModel(
                organizationId: Organization.current!.id,
                backend: context.read(),
                isAdmin: isAdmin,
              ),
              builder: (controller) => GroupsScreen(controller: controller),
            );
          },
          // The screens over *Grupos* share its controller, which lives
          // with the *Grupos* page under them; it comes as the push's extra.
          // Without one (a path typed on the web), they fall back to it.
          routes: [
            GoRoute(
              path: 'new',
              redirect: (context, state) =>
                  state.extra is GroupsViewModel ? null : Routes.groups,
              builder: (context, state) => CreateGroupScreen(
                controller: state.extra! as GroupsViewModel,
              ),
            ),
            GoRoute(
              path: 'invite',
              redirect: (context, state) =>
                  state.extra is InviteRequest ? null : Routes.groups,
              builder: (context, state) {
                final request = state.extra! as InviteRequest;
                final groups = request.groups;
                return _owned(
                  create: () => InviteViewModel(
                    organizationId: groups.organizationId,
                    organizationName:
                        Organization.current?.name ?? groups.organizationId,
                    groups: groups.state.groups,
                    groupId: request.groupId,
                    backend: context.read(),
                    canCreateFirstGroup: groups.isAdmin,
                  ),
                  builder: (controller) => InviteScreen(controller: controller),
                );
              },
            ),
            GoRoute(
              path: ':groupId',
              redirect: (context, state) =>
                  state.extra is GroupsViewModel ? null : Routes.groups,
              builder: (context, state) => GroupScreen(
                controller: state.extra! as GroupsViewModel,
                groupId: state.pathParameters['groupId']!,
                invitesBackend: context.read(),
              ),
            ),
          ],
        ),
        GoRoute(
          path: Routes.administrators,
          builder: (context, state) => _owned(
            create: () => AdministratorsViewModel(
              organizationId: Organization.current!.id,
              backend: context.read(),
            ),
            builder: (controller) =>
                AdministratorsScreen(controller: controller),
          ),
        ),
        GoRoute(
          path: Routes.appearance,
          builder: (context, state) => _owned(
            create: () => AppearanceViewModel(
              organization: Organization.current!,
              backend: context.read(),
              onSaved: context.read<OrganizationSession>().storeBranding,
            ),
            builder: (controller) => AppearanceScreen(controller: controller),
          ),
        ),
        GoRoute(
          path: Routes.trackingSettings,
          builder: (context, state) {
            final saved = context
                .read<TrackingSettingsController>()
                .settings
                .value;
            return _owned(
              create: () => TrackingSettingsEditViewModel(
                repository: context.read(),
                saved: saved,
              ),
              builder: (controller) =>
                  TrackingSettingsScreen(controller: controller),
            );
          },
        ),
      ],
    ),
  ],
);

/// *Criar organização*, opened over *Sem organização* or the picker; the
/// session stays as it is until the new organization is entered.
///
/// Entering it normally binds it (the redirect opens the map). When the
/// directory does not list it yet, the session goes to the picker; over
/// *Sem organização* the redirect opens it, but over the picker this screen
/// is still an allowed location, so it goes back to the picker itself.
GoRoute _createOrganizationRoute() => GoRoute(
  path: Routes.createOrganizationSegment,
  builder: (context, state) {
    final auth = context.read<AuthGoogleViewModel>();
    return _owned(
      // A fresh one each time the flow opens; its screen loads the themes.
      create: () => CreateOrganizationViewModel(
        backend: context.read(),
        themes: context.read(),
      ),
      builder: (controller) => CreateOrganizationScreen(
        controller: controller,
        ownerEmail: auth.state.signedInEmail ?? '',
        onReady: () async {
          final result = await auth.enterCreatedOrganization(
            controller.state.id,
          );
          if (result is Ok &&
              auth.session.value is SessionPicking &&
              context.mounted) {
            context.go(Routes.organizationPicker);
          }
          return result;
        },
      ),
    );
  },
);

/// A screen whose controller lives as long as its route: [create] runs
/// once, when the route is first built, and the controller is disposed when
/// the route leaves the stack.
///
/// Not a `ChangeNotifierProvider`: nothing reads it with `watch`, and its
/// listener would mark this scope dirty when a screen's `initState` starts
/// a load that notifies at once ("markNeedsBuild called during build").
Widget _owned<T extends ChangeNotifier>({
  required T Function() create,
  required Widget Function(T controller) builder,
}) => InheritedProvider<T>(
  create: (_) => create(),
  dispose: (_, controller) => controller.dispose(),
  child: Builder(builder: (context) => builder(context.read<T>())),
);
