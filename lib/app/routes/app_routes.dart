/// The app's paths, used by the router (`app_router.dart`), by the session
/// redirect (`session_redirect.dart`) and by the screens that navigate.
abstract final class Routes {
  /// *Login*, the first screen and the one after signing out.
  static const login = '/login';

  /// *Escolher organização*.
  static const organizationPicker = '/organization';

  /// *Sem organização*.
  static const noOrganization = '/sem-organizacao';

  /// *Boas-vindas*, once after accepting an invite.
  static const welcome = '/boas-vindas';

  /// *Em exclusão*.
  static const deletionPending = '/em-exclusao';

  /// The last segment of *Criar organização*, opened over
  /// [noOrganization] or [organizationPicker] (see [createOrganizationOver]).
  static const createOrganizationSegment = 'nova-organizacao';

  /// *Criar organização* opened over [entry], one of [noOrganization] and
  /// [organizationPicker]: going back returns to [entry].
  static String createOrganizationOver(String entry) =>
      '$entry/$createOrganizationSegment';

  /// The map of the bound organization (inside the organization's scope,
  /// as every path below).
  static const monamie = '/monamie';

  /// *Minha conta*.
  static const myAccount = '/minha-conta';

  /// The prefix shared by the administration screens.
  static const adminPrefix = '/admin/';

  /// *Grupos* (administrators) or *Meus grupos* (maintainers).
  static const groups = '/admin/groups';

  /// *Novo grupo*, over [groups].
  static const newGroup = '$groups/new';

  /// *Convidar pessoas*, over [groups] or a group.
  static const invite = '$groups/invite';

  /// *Grupo* [groupId], over [groups]. Group ids are Firestore auto ids, so
  /// they never collide with `new` or `invite`.
  static String group(String groupId) => '$groups/$groupId';

  /// *Administradores* (the owner only).
  static const administrators = '/admin/administrators';

  /// *Aparência da organização*.
  static const appearance = '/admin/appearance';

  /// *Ajustes de acompanhamento*.
  static const trackingSettings = '/admin/tracking';
}
