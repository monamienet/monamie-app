import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:monamie_app/ui/language/view_models/language_view_model.dart';
import 'package:monamie_app/domain/models/organization/organization.dart';
import 'package:monamie_app/data/repositories/organization/organization_session.dart';
import 'package:monamie_app/data/repositories/tracking/tracking_settings_repository.dart';
import 'package:monamie_app/data/repositories/session/session_repository.dart';
import 'package:monamie_app/domain/use_cases/sign_out.dart';
import 'package:monamie_app/ui/account/view_models/deletion_pending_view_model.dart';
import 'package:monamie_app/ui/account/widgets/deletion_pending_screen.dart';
import 'package:monamie_app/ui/account/view_models/my_account_view_model.dart';
import 'package:monamie_app/ui/account/widgets/my_account_screen.dart';
import 'package:monamie_app/ui/administrators/view_models/administrators_view_model.dart';
import 'package:monamie_app/ui/administrators/widgets/administrators_screen.dart';
import 'package:monamie_app/ui/appearance/view_models/appearance_view_model.dart';
import 'package:monamie_app/ui/appearance/widgets/appearance_screen.dart';
import 'package:monamie_app/ui/groups/view_models/groups_view_model.dart';
import 'package:monamie_app/ui/groups/view_models/group_invites_view_model.dart';
import 'package:monamie_app/ui/groups/widgets/create_group_screen.dart';
import 'package:monamie_app/ui/groups/widgets/group_screen.dart';
import 'package:monamie_app/ui/groups/widgets/groups_screen.dart';
import 'package:monamie_app/ui/groups/widgets/open_invite.dart';
import 'package:monamie_app/ui/tracking_settings/view_models/tracking_settings_edit_view_model.dart';
import 'package:monamie_app/ui/tracking_settings/widgets/tracking_settings_screen.dart';
import 'package:monamie_app/ui/creation/view_models/create_organization_view_model.dart';
import 'package:monamie_app/ui/creation/widgets/create_organization_screen.dart';
import 'package:monamie_app/ui/invites/view_models/invite_view_model.dart';
import 'package:monamie_app/ui/invites/widgets/invite_screen.dart';
import 'package:monamie_app/ui/invites/view_models/welcome_view_model.dart';
import 'package:monamie_app/ui/invites/widgets/welcome_screen.dart';
import 'package:monamie_app/ui/auth/view_models/login_view_model.dart';
import 'package:monamie_app/ui/auth/view_models/organization_choice_view_model.dart';
import 'package:monamie_app/ui/auth/widgets/login_screen.dart';
import 'package:monamie_app/ui/auth/widgets/no_organization_screen.dart';
import 'package:monamie_app/ui/auth/widgets/organization_picker_screen.dart';
import 'package:monamie_app/data/repositories/membership/membership_repository.dart';
import 'package:monamie_app/ui/home/view_models/home_session_view_model.dart';
import 'package:monamie_app/ui/home/view_models/home_view_model.dart';
import 'package:monamie_app/ui/home/view_models/resume_on_restart_view_model.dart';
import 'package:monamie_app/ui/home/view_models/user_view_model.dart';
import 'package:monamie_app/routing/organization_scope.dart';
import 'package:monamie_app/ui/home/widgets/home_screen.dart';
import 'package:monamie_app/routing/routes.dart';
import 'package:monamie_app/routing/session_redirect.dart';
import 'package:monamie_app/ui/core/ui/app_messenger.dart';
import 'package:provider/provider.dart';

/// The app's router.
///
/// The sign-in flow navigates only through [session]'s
/// [SessionRepository.session], the app-wide session: the router
/// listens to it ([GoRouter.refreshListenable]) and [sessionRedirect] decides
/// the screen, on every navigation and on every change of session. Leaving
/// the organization (sign-out, switch, lost access) is always such a
/// redirect, a `go` that replaces the whole stack, so the organization's
/// shell, and with it [OrganizationScope], is disposed.
///
/// Inside the shell, screens open over the map with `push` (going back
/// returns to the map); screens opened from outside never push over it.
///
/// Route builders read view models from the organization's scope, and the
/// repositories and use cases from `appDependencies`, and hand them to the
/// screens; screens never read providers themselves. A route-only view
/// model is created by its route ([_owned]) and disposed when the route
/// closes.
GoRouter buildAppRouter({required SessionRepository session}) => GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: Routes.login,
  refreshListenable: session.session,
  redirect: (context, state) =>
      sessionRedirect(session.session.value, state.uri.path),
  // An unknown path (typed on the web) goes to the session's screen.
  onException: (context, state, router) =>
      router.go(sessionLocation(session.session.value)),
  routes: [
    // *Login* restores a remembered session when it opens: the session
    // becomes bound and the redirect opens the map.
    GoRoute(
      path: Routes.login,
      builder: (context, state) => _owned(
        create: () => LoginViewModel(
          session: context.read(),
          enterOrganization: context.read(),
          bondCheck: context.read(),
          // The web sign-in's failures arrive with no tap waiting for them.
          notices: const ScaffoldNoticePresenter(),
        ),
        builder: (login) => _withLanguage(
          context,
          (language) => LoginScreen(controller: login, language: language),
        ),
      ),
    ),
    GoRoute(
      path: Routes.noOrganization,
      builder: (context, state) => _owned(
        create: () => _organizationChoice(context),
        builder: (controller) => _withLanguage(
          context,
          (language) => NoOrganizationScreen(
            controller: controller,
            language: language,
            onCreateOrganization: () => context.go(
              Routes.createOrganizationOver(Routes.noOrganization),
            ),
          ),
        ),
      ),
      routes: [_createOrganizationRoute()],
    ),
    GoRoute(
      path: Routes.organizationPicker,
      builder: (context, state) => _owned(
        create: () => _organizationChoice(context),
        builder: (controller) => _withLanguage(
          context,
          (language) => OrganizationPickerScreen(
            controller: controller,
            language: language,
            onCreateOrganization: () => context.go(
              Routes.createOrganizationOver(Routes.organizationPicker),
            ),
          ),
        ),
      ),
      routes: [_createOrganizationRoute()],
    ),
    GoRoute(
      path: Routes.welcome,
      builder: (context, state) => _owned(
        create: () => WelcomeViewModel(session: context.read()),
        builder: (controller) => WelcomeScreen(controller: controller),
      ),
    ),
    GoRoute(
      path: Routes.deletionPending,
      builder: (context, state) => _owned(
        create: () => DeletionPendingViewModel(
          session: context.read(),
          enterOrganization: context.read(),
          signOut: context.read(),
          repository: context.read(),
        ),
        builder: (controller) => DeletionPendingScreen(controller: controller),
      ),
    ),
    ShellRoute(
      builder: (context, state, child) => OrganizationScope(
        onAccessLost: context.read<SignOut>().afterAccessLost,
        child: child,
      ),
      routes: [
        GoRoute(
          path: Routes.monamie,
          builder: (context, state) => _owned(
            create: () => HomeSessionViewModel(
              session: context.read(),
              signOut: context.read(),
              directory: context.read(),
            ),
            builder: (session) => _owned(
              create: () => HomeViewModel(
                membership: context.read(),
                permissions: context.read(),
                calls: context.read(),
              ),
              builder: (home) => _owned(
                create: () => ResumeOnRestartViewModel(
                  repository: context.read(),
                  permissions: context.read(),
                  // The device resumes sharing by itself only on Android.
                  available:
                      !kIsWeb &&
                      defaultTargetPlatform == TargetPlatform.android,
                )..load.execute(),
                builder: (resumeOnRestart) => _withLanguage(
                  context,
                  (language) => HomeScreen(
                    userCtrl: context.read(),
                    home: home,
                    trackingCtrl: context.read(),
                    calendar: context.read(),
                    session: session,
                    language: language,
                    resumeOnRestart: resumeOnRestart,
                  ),
                ),
              ),
            ),
          ),
        ),
        GoRoute(
          path: Routes.myAccount,
          builder: (context, state) {
            final organization = Organization.current!;
            return _owned(
              create: () => MyAccountViewModel(
                repository: context.read(),
                organizationId: organization.id,
                directory: context.read(),
                signOut: context.read(),
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
            final isAdmin = context.read<MembershipRepository>().isAdmin;
            return _owned(
              create: () => GroupsViewModel(
                organizationId: Organization.current!.id,
                repository: context.read(),
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
                    repository: context.read(),
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
              builder: (context, state) {
                final groups = state.extra! as GroupsViewModel;
                final groupId = state.pathParameters['groupId']!;
                return _owned(
                  create: () => GroupInvitesViewModel(
                    organizationId: groups.organizationId,
                    groupId: groupId,
                    repository: context.read(),
                  ),
                  builder: (invites) => GroupScreen(
                    controller: groups,
                    groupId: groupId,
                    invites: invites,
                  ),
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: Routes.administrators,
          builder: (context, state) => _owned(
            create: () => AdministratorsViewModel(
              organizationId: Organization.current!.id,
              repository: context.read(),
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
              repository: context.read(),
              onSaved: context.read<OrganizationSession>().storeBranding,
            ),
            builder: (controller) => AppearanceScreen(controller: controller),
          ),
        ),
        GoRoute(
          path: Routes.trackingSettings,
          builder: (context, state) {
            final saved = context
                .read<TrackingSettingsRepository>()
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
/// is still an allowed location, so the screen goes back to the picker
/// itself (`CreateOrganizationViewModel.enter`).
GoRoute _createOrganizationRoute() => GoRoute(
  path: Routes.createOrganizationSegment,
  builder: (context, state) => _owned(
    // A fresh one each time the flow opens; its screen loads the themes.
    create: () => CreateOrganizationViewModel(
      repository: context.read(),
      themes: context.read(),
      enterOrganization: context.read(),
      session: context.read(),
    ),
    builder: (controller) => CreateOrganizationScreen(controller: controller),
  ),
);

/// *Sem organização*'s and the picker's view model.
OrganizationChoiceViewModel _organizationChoice(BuildContext context) =>
    OrganizationChoiceViewModel(
      session: context.read(),
      enterOrganization: context.read(),
      signOut: context.read(),
      invites: context.read(),
    );

/// The language picker's view model of a screen that opens it, over the app's
/// `LanguageRepository`; it reads the device's languages from the platform.
Widget _withLanguage(
  BuildContext context,
  Widget Function(LanguageViewModel language) builder,
) => _owned(
  create: () => LanguageViewModel(
    repository: context.read(),
    deviceLocales: () => WidgetsBinding.instance.platformDispatcher.locales,
  ),
  builder: builder,
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
