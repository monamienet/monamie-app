import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:monamie_app/app/config/organization/organization.dart';
import 'package:monamie_app/app/data/organization/organization_session.dart';
import 'package:monamie_app/app/data/theme/firestore_theme_catalog.dart';
import 'package:monamie_app/app/data/tracking/firestore_tracking_settings_repository.dart';
import 'package:monamie_app/app/data/tracking/tracking_settings_controller.dart';
import 'package:monamie_app/app/modules/account/deletion_pending_view.dart';
import 'package:monamie_app/app/modules/account/firebase_account_deletion_backend.dart';
import 'package:monamie_app/app/modules/account/my_account_controller.dart';
import 'package:monamie_app/app/modules/account/my_account_view.dart';
import 'package:monamie_app/app/modules/admin/administrators/administrators_controller.dart';
import 'package:monamie_app/app/modules/admin/administrators/administrators_view.dart';
import 'package:monamie_app/app/modules/admin/administrators/firebase_administrators_backend.dart';
import 'package:monamie_app/app/modules/admin/appearance_controller.dart';
import 'package:monamie_app/app/modules/admin/appearance_view.dart';
import 'package:monamie_app/app/modules/admin/firebase_appearance_backend.dart';
import 'package:monamie_app/app/modules/admin/groups/firebase_groups_backend.dart';
import 'package:monamie_app/app/modules/admin/groups/groups_controller.dart';
import 'package:monamie_app/app/modules/admin/groups/groups_views.dart';
import 'package:monamie_app/app/modules/admin/tracking_settings_edit_controller.dart';
import 'package:monamie_app/app/modules/admin/tracking_settings_view.dart';
import 'package:monamie_app/app/modules/creation/create_organization_controller.dart';
import 'package:monamie_app/app/modules/creation/create_organization_view.dart';
import 'package:monamie_app/app/modules/creation/firebase_creation_backend.dart';
import 'package:monamie_app/app/modules/invites/firebase_invites_backend.dart';
import 'package:monamie_app/app/modules/invites/invite_controller.dart';
import 'package:monamie_app/app/modules/invites/invite_view.dart';
import 'package:monamie_app/app/modules/invites/welcome_view.dart';
import 'package:monamie_app/app/modules/login/controllers/auth_google_controller.dart';
import 'package:monamie_app/app/modules/login/controllers/login_controller.dart';
import 'package:monamie_app/app/modules/login/views/login_view.dart';
import 'package:monamie_app/app/modules/login/views/no_organization_view.dart';
import 'package:monamie_app/app/modules/login/views/organization_picker_view.dart';
import 'package:monamie_app/app/modules/monamie/controller/group_map_state.dart';
import 'package:monamie_app/app/modules/monamie/controller/user_controller.dart';
import 'package:monamie_app/app/modules/monamie/organization_scope.dart';
import 'package:monamie_app/app/modules/monamie/ui/monamie_page.dart';
import 'package:monamie_app/app/routes/app_routes.dart';
import 'package:monamie_app/app/routes/session_redirect.dart';
import 'package:monamie_app/app/utils/app_messenger.dart';
import 'package:monamie_app/app/utils/result.dart';
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
/// [AuthGoogleController], the organization's scope) and hand them to the
/// screens; screens never read providers themselves. A route-only
/// controller is created by its route ([_owned]) and disposed when the route
/// closes.
GoRouter buildAppRouter({required AuthGoogleController auth}) => GoRouter(
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
        final auth = context.read<AuthGoogleController>();
        return _owned(
          create: () => LoginController(signIn: auth),
          builder: (login) => LoginView(controller: login, auth: auth),
        );
      },
    ),
    GoRoute(
      path: Routes.noOrganization,
      builder: (context, state) => NoOrganizationView(
        controller: context.read<AuthGoogleController>(),
        onCreateOrganization: () =>
            context.go(Routes.createOrganizationOver(Routes.noOrganization)),
      ),
      routes: [_createOrganizationRoute()],
    ),
    GoRoute(
      path: Routes.organizationPicker,
      builder: (context, state) => OrganizationPickerView(
        controller: context.read<AuthGoogleController>(),
        onCreateOrganization: () => context.go(
          Routes.createOrganizationOver(Routes.organizationPicker),
        ),
      ),
      routes: [_createOrganizationRoute()],
    ),
    GoRoute(
      path: Routes.welcome,
      builder: (context, state) =>
          WelcomeView(controller: context.read<AuthGoogleController>()),
    ),
    GoRoute(
      path: Routes.deletionPending,
      builder: (context, state) =>
          DeletionPendingView(controller: context.read<AuthGoogleController>()),
    ),
    ShellRoute(
      builder: (context, state, child) => OrganizationScope(
        onAccessLost: context
            .read<AuthGoogleController>()
            .forgetRemovedOrganization,
        child: child,
      ),
      routes: [
        GoRoute(
          path: Routes.monamie,
          builder: (context, state) => MonamiePage(
            userCtrl: context.read(),
            permissionsCtrl: context.read(),
            trackingCtrl: context.read(),
            groupMap: context.read(),
            calendar: context.read(),
            calls: context.read(),
            authCtrl: context.read<AuthGoogleController>(),
          ),
        ),
        GoRoute(
          path: Routes.myAccount,
          builder: (context, state) {
            final auth = context.read<AuthGoogleController>();
            final organization = Organization.current!;
            return _owned(
              create: () => MyAccountController(
                backend: const FirebaseAccountDeletionBackend(),
                organizationId: organization.id,
                checkOwner: () => auth.ownsOrganization(organization.id),
                onDeleted: auth.accountDeleted,
              ),
              builder: (controller) => MyAccountView(
                controller: controller,
                email: context.read<UserController>().googleUser?.email ?? '',
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
              create: () => GroupsController(
                organizationId: Organization.current!.id,
                backend: const FirebaseGroupsBackend(),
                isAdmin: isAdmin,
              ),
              builder: (controller) => GroupsView(controller: controller),
            );
          },
          // The screens over *Grupos* share its controller, which lives
          // with the *Grupos* page under them; it comes as the push's extra.
          // Without one (a path typed on the web), they fall back to it.
          routes: [
            GoRoute(
              path: 'new',
              redirect: (context, state) =>
                  state.extra is GroupsController ? null : Routes.groups,
              builder: (context, state) =>
                  CreateGroupView(controller: state.extra! as GroupsController),
            ),
            GoRoute(
              path: 'invite',
              redirect: (context, state) =>
                  state.extra is InviteRequest ? null : Routes.groups,
              builder: (context, state) {
                final request = state.extra! as InviteRequest;
                final groups = request.groups;
                return _owned(
                  create: () => InviteController(
                    organizationId: groups.organizationId,
                    organizationName:
                        Organization.current?.name ?? groups.organizationId,
                    groups: groups.state.groups,
                    groupId: request.groupId,
                    backend: const FirebaseInvitesBackend(),
                    canCreateFirstGroup: groups.isAdmin,
                  ),
                  builder: (controller) => InviteView(controller: controller),
                );
              },
            ),
            GoRoute(
              path: ':groupId',
              redirect: (context, state) =>
                  state.extra is GroupsController ? null : Routes.groups,
              builder: (context, state) => GroupView(
                controller: state.extra! as GroupsController,
                groupId: state.pathParameters['groupId']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: Routes.administrators,
          builder: (context, state) => _owned(
            create: () => AdministratorsController(
              organizationId: Organization.current!.id,
              backend: const FirebaseAdministratorsBackend(),
            ),
            builder: (controller) => AdministratorsView(controller: controller),
          ),
        ),
        GoRoute(
          path: Routes.appearance,
          builder: (context, state) => _owned(
            create: () => AppearanceController(
              organization: Organization.current!,
              backend: FirebaseAppearanceBackend(),
              onSaved: OrganizationSession().storeBranding,
            ),
            builder: (controller) => AppearanceView(controller: controller),
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
              create: () => TrackingSettingsEditController(
                repository: const FirestoreTrackingSettingsRepository(),
                saved: saved,
              ),
              builder: (controller) =>
                  TrackingSettingsView(controller: controller),
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
    final auth = context.read<AuthGoogleController>();
    return _owned(
      // A fresh one each time the flow opens; its screen loads the themes.
      create: () => CreateOrganizationController(
        backend: const FirebaseCreationBackend(),
        themes: const FirestoreThemeCatalog(),
      ),
      builder: (controller) => CreateOrganizationView(
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
