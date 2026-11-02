import 'package:monamie_app/app/modules/login/controllers/session_state.dart';
import 'package:monamie_app/app/routes/app_routes.dart';

/// The screen a person whose sign-in stands at [session] belongs on.
String sessionLocation(SessionState session) => switch (session) {
  SessionSignedOut() => Routes.login,
  SessionNoOrganization() => Routes.noOrganization,
  SessionPicking() => Routes.organizationPicker,
  SessionDeletionPending() => Routes.deletionPending,
  SessionWelcome() => Routes.welcome,
  SessionBound() => Routes.monamie,
};

/// Where the router sends a person whose session is [session] when they ask
/// for [location] (a path, without query): `null` keeps [location];
/// otherwise the [sessionLocation] of [session].
///
/// - bound: the organization's screens (the map, *Minha conta* and the
///   administration, see [isOrganizationLocation]);
/// - no organization and picking: their screen, or *Criar organização*
///   opened over it ([Routes.createOrganizationOver]);
/// - signed out, deletion pending and welcome: their screen only.
///
/// Pure, so the whole sign-in flow's navigation is testable without
/// widgets; the router calls it on every navigation and whenever the
/// session changes.
String? sessionRedirect(SessionState session, String location) {
  final path = _normalized(location);
  final home = sessionLocation(session);
  final allowed = switch (session) {
    SessionBound() => isOrganizationLocation(path),
    SessionNoOrganization() || SessionPicking() =>
      path == home || path == Routes.createOrganizationOver(home),
    SessionSignedOut() ||
    SessionDeletionPending() ||
    SessionWelcome() => path == home,
  };
  return allowed ? null : home;
}

/// Whether [location] is one of the bound organization's screens, all of
/// them inside the organization's scope.
bool isOrganizationLocation(String location) {
  final path = _normalized(location);
  return path == Routes.monamie ||
      path == Routes.myAccount ||
      (path.startsWith(Routes.adminPrefix) &&
          path.length > Routes.adminPrefix.length);
}

/// [location] without a trailing slash (except the root).
String _normalized(String location) =>
    location.length > 1 && location.endsWith('/')
    ? location.substring(0, location.length - 1)
    : location;
