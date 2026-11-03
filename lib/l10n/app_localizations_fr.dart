// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get loginTagline => 'Votre équipe, au même endroit.';

  @override
  String get commonSignOut => 'Se déconnecter';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonOk => 'OK';

  @override
  String get commonSaving => 'Enregistrement…';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonSaveChanges => 'Enregistrer les modifications';

  @override
  String get commonChange => 'Modifier';

  @override
  String get commonContinue => 'Continuer';

  @override
  String get commonBack => 'Retour';

  @override
  String get commonTryAgain => 'Réessayer';

  @override
  String get commonChecking => 'Vérification…';

  @override
  String get commonCreating => 'Création…';

  @override
  String get commonAdd => 'Ajouter';

  @override
  String get commonRemove => 'Retirer';

  @override
  String get commonClose => 'Fermer';

  @override
  String get commonGotIt => 'Compris';

  @override
  String get commonGenericFailure =>
      'Impossible de terminer pour le moment. Veuillez réessayer.';

  @override
  String get deletionRestoredAccountTitle => 'Votre compte est de retour';

  @override
  String deletionRestoredOrganizationTitle(String name) {
    return 'L’organisation $name est de retour';
  }

  @override
  String deletionPendingAccountTitle(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'dans $days jours',
      one: 'dans 1 jour',
      zero: 'aujourd’hui',
    );
    return 'Votre compte sera supprimé $_temp0';
  }

  @override
  String deletionPendingOrganizationTitle(String name, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'dans $days jours',
      one: 'dans 1 jour',
      zero: 'aujourd’hui',
    );
    return 'L’organisation $name sera supprimée $_temp0';
  }

  @override
  String get deletionRestoredBody =>
      'Rien n’a été effacé. Connectez-vous pour reprendre là où vous en étiez.';

  @override
  String deletionPendingAccountBody(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Le $dateString, nous effaçons définitivement votre compte et vos données sur MonAmie.';
  }

  @override
  String deletionPendingOrganizationBody(DateTime date, String name) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Le $dateString, nous effaçons définitivement l’organisation $name, ses groupes, l’historique de tous et votre compte. D’ici là, personne ne peut utiliser l’organisation.';
  }

  @override
  String get deletionEnter => 'Se connecter';

  @override
  String get deletionCancelAccount => 'Annuler la suppression du compte';

  @override
  String get deletionCancel => 'Annuler la suppression';

  @override
  String get myAccountTitle => 'Mon compte';

  @override
  String get myAccountDeleteHeading => 'Supprimer le compte';

  @override
  String myAccountOwnerLeaves(String name) {
    return 'Vous êtes titulaire de l’organisation $name : toute l’organisation est donc supprimée en même temps que votre compte.';
  }

  @override
  String myAccountMemberLeaves(String name) {
    return 'Vous quittez l’organisation $name dès maintenant et n’apparaissez plus sur la carte.';
  }

  @override
  String myAccountEraseOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Le $dateString, nous effaçons définitivement votre compte et vos données sur MonAmie.';
  }

  @override
  String get myAccountUndo =>
      'D’ici là, il suffit de vous reconnecter et d’annuler la suppression.';

  @override
  String get myAccountDeleteWithOrganization =>
      'Supprimer le compte et l’organisation';

  @override
  String get myAccountDelete => 'Supprimer le compte';

  @override
  String myAccountConfirmPrompt(String id) {
    return 'Pour confirmer, saisissez $id';
  }

  @override
  String get adminOrganizationFallback => 'l’organisation';

  @override
  String get loggingOut => 'Déconnexion…';

  @override
  String get switchingOrganization => 'Changement d’organisation…';

  @override
  String get administratorsTitle => 'Administrateurs';

  @override
  String get administratorsIntro =>
      'Les administrateurs s’occupent de tous les groupes, des invitations, de l’apparence et des réglages de l’organisation, et voient tous les groupes sur la carte. Seule la personne titulaire choisit qui administre.';

  @override
  String get administratorsOwner => 'Titulaire';

  @override
  String get administratorsAdministers => 'Administre l’organisation';

  @override
  String get administratorsMakeMember => 'Passer en membre';

  @override
  String get administratorsNone => 'Personne n’administre l’organisation.';

  @override
  String get administratorsMembers => 'Membres';

  @override
  String get administratorsMember => 'Membre';

  @override
  String get administratorsMakeAdmin => 'Nommer administrateur';

  @override
  String get administratorsNoMembers =>
      'Personne d’autre dans l’organisation pour le moment. Les personnes qui acceptent une invitation à un groupe apparaissent ici.';

  @override
  String administratorsSection(String title, int count) {
    return '$title · $count';
  }

  @override
  String administratorsPromoteTitle(String email) {
    return 'Nommer $email administrateur ?';
  }

  @override
  String get administratorsPromoteSees =>
      'La personne verra tous les groupes sur la carte et s’occupera des groupes, des invitations, de l’apparence et des réglages de l’organisation.';

  @override
  String get administratorsUndoLater => 'Vous pourrez annuler plus tard.';

  @override
  String administratorsPromoted(String email) {
    return '$email administre désormais l’organisation';
  }

  @override
  String administratorsDemoteTitle(String email) {
    return 'Passer $email en membre ?';
  }

  @override
  String get administratorsDemoteStops =>
      'La personne n’administre plus l’organisation et ne voit plus les groupes dont elle ne fait pas partie.';

  @override
  String get administratorsDemoteStays =>
      'Elle reste dans les groupes où elle se trouve déjà. Si elle n’est dans aucun, elle reste dans l’organisation sans voir la carte, jusqu’à ce qu’une invitation à un groupe lui parvienne.';

  @override
  String administratorsDemoted(String email) {
    return '$email est désormais membre';
  }

  @override
  String get appearanceTitle => 'Apparence';

  @override
  String get appearanceYouAdminister => 'Vous administrez cette organisation';

  @override
  String get appearanceName => 'Nom';

  @override
  String get appearanceLogo => 'Logo';

  @override
  String get appearanceNoLogo => 'Sans logo · nous utilisons l’initiale';

  @override
  String get appearanceLogoSaved => 'PNG carré de 512 px';

  @override
  String get appearanceLogoNew => 'Nouveau logo · enregistrez pour appliquer';

  @override
  String get appearanceLogoFormats => 'SVG, PNG, JPEG ou WebP';

  @override
  String get appearanceTheme => 'Thème';

  @override
  String get appearanceNextLaunch =>
      'L’équipe verra la nouvelle apparence à sa prochaine ouverture de l’appli.';

  @override
  String get appearanceSaved => 'Apparence enregistrée';

  @override
  String get appearanceNameDialog => 'Nom de l’organisation';

  @override
  String get appearanceLogoError => 'Impossible d’utiliser ce fichier';

  @override
  String get appearanceLogoPreview => 'Voici le rendu du logo';

  @override
  String get appearanceLogoSheet => 'Logo de l’organisation';

  @override
  String get appearanceConverting => 'Conversion en PNG sur votre téléphone';

  @override
  String get appearanceUseLogo => 'Utiliser ce logo';

  @override
  String get appearanceLogoExplained =>
      'Nous avons converti le fichier en PNG carré de 512 px. C’est ainsi qu’il apparaît en haut de l’appli, dans le menu et dans la liste des organisations.';

  @override
  String get loginWithGoogle => 'Se connecter avec Google';

  @override
  String get loginLookingForOrganization => 'Recherche de votre organisation…';

  @override
  String loginEntering(String name) {
    return 'Accès à $name…';
  }

  @override
  String get accountHeaderSwitch => 'Changer';

  @override
  String get inviteCardTitle => 'Vous avez une invitation';

  @override
  String get inviteSomeone => 'Quelqu’un';

  @override
  String inviteCardBody(String inviter, String group, String role) {
    String _temp0 = intl.Intl.selectLogic(role, {
      'both': 'pour être sur le terrain et voir la carte',
      'publisher': 'pour être sur le terrain',
      'other': 'pour voir la carte',
    });
    return '$inviter vous invite à rejoindre le groupe $group, $_temp0.';
  }

  @override
  String inviteCardValidUntil(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Valable jusqu’au $dateString.';
  }

  @override
  String inviteCardEntering(String name) {
    return 'Accès à $name…';
  }

  @override
  String get inviteCardAccept => 'Accepter et entrer';

  @override
  String get noOrganizationTitle =>
      'Vous ne faites pas encore partie d’une organisation';

  @override
  String get noOrganizationBody =>
      'Créez celle de votre équipe maintenant ou demandez à une personne de l’équipe de vous ajouter.';

  @override
  String get noOrganizationFast => 'Nom et thème en moins de 2 minutes';

  @override
  String get noOrganizationYouAdminister =>
      'Vous administrez et invitez l’équipe';

  @override
  String get noOrganizationLater =>
      'Le logo et l’apparence se règlent plus tard, dans l’appli';

  @override
  String get noOrganizationCreate => 'Créer mon organisation';

  @override
  String get noOrganizationRecheck =>
      'J’ai déjà une invitation · vérifier à nouveau';

  @override
  String get pickerTitle => 'Dans quelle organisation voulez-vous entrer ?';

  @override
  String pickerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Vous appartenez à $count organisations. Vous pourrez en changer plus tard depuis le menu.',
      one: 'Vous appartenez à 1 organisation.',
      zero:
          'Vous appartenez à 0 organisation. Vous pourrez en changer plus tard depuis le menu.',
    );
    return '$_temp0';
  }

  @override
  String get pickerCreate => 'Créer une organisation';

  @override
  String get creationTitle => 'Nouvelle organisation';

  @override
  String creationStep(int step, int count) {
    return '$step sur $count';
  }

  @override
  String creationReadyTitle(String name) {
    return 'L’organisation $name est prête';
  }

  @override
  String get creationReadyBody =>
      'L’appli s’affiche déjà avec votre nom et votre thème. Vous ajouterez le logo quand vous voudrez, dans Apparence. Prochaine étape : invitez votre équipe dans Groupes.';

  @override
  String creationReadyEnter(String name) {
    return 'Accéder à $name';
  }

  @override
  String get creationBillingTitle => 'La facturation doit encore être activée';

  @override
  String creationBillingBody(String name, String id) {
    return 'L’organisation $name fonctionne sur un projet Google Cloud payé par votre organisation. Connectez-vous à Google Cloud avec ce même compte Google, choisissez ou créez un compte de facturation et associez-le au projet monamienet-$id. L’identifiant reste réservé pendant 7 jours.';
  }

  @override
  String creationFailedTitle(String name) {
    return 'Un problème est survenu lors de la création de l’organisation $name';
  }

  @override
  String creationFailedBody(String id) {
    return 'Vous n’avez rien à faire. L’équipe MonAmie a été prévenue et terminera la création. En attendant, l’identifiant $id reste réservé pour vous.';
  }

  @override
  String get creationNameTitle => 'Comment s’appelle votre organisation ?';

  @override
  String get creationNameSubtitle =>
      'Utilisez le nom que votre équipe reconnaît : celui de l’entreprise, du groupe ou du projet.';

  @override
  String get creationNameLabel => 'Nom de l’organisation';

  @override
  String creationNamePreview(String name) {
    return 'Votre équipe verra $name en haut de l’appli';
  }

  @override
  String get creationIdLabel => 'Identifiant';

  @override
  String get creationIdAdjusted =>
      'Nous l’avons converti en lettres minuscules, sans accents, espaces ni chiffres.';

  @override
  String get creationIdRules =>
      'Lettres minuscules uniquement, sans accents, espaces ni chiffres. C’est le code de l’organisation dans MonAmie.';

  @override
  String get creationIdPermanent =>
      'L’identifiant ne change plus ensuite. Le nom, lui, peut changer.';

  @override
  String get creationIdTooShort => '3 lettres minimum';

  @override
  String get creationIdAvailable => 'Disponible';

  @override
  String get planCommunity => 'Community';

  @override
  String get planStandard => 'Standard';

  @override
  String get creationPlanTitle => 'Choisissez une formule';

  @override
  String creationPlanSubtitle(String name) {
    return 'Les deux incluent la carte, les groupes et l’apparence de l’organisation $name. Ce qui change : où les données sont stockées et qui paie.';
  }

  @override
  String get creationPlanFree => 'Gratuit';

  @override
  String get creationPlanCommunityTagline =>
      'Pour démarrer tout de suite, sans enregistrer de moyen de paiement.';

  @override
  String get creationPlanCommunityReady => 'Prête en quelques instants';

  @override
  String get creationPlanCommunityData =>
      'Données conservées par MonAmie, séparées de celles des autres organisations';

  @override
  String get creationPlanCommunityInterval =>
      'Position envoyée toutes les 15 min (profil Économie)';

  @override
  String get creationPlanGoogleUsage => 'Utilisation sur Google';

  @override
  String get creationPlanStandardTagline =>
      'Pour qui veut son propre espace de données et plus de précision.';

  @override
  String creationPlanStandardProject(String name) {
    return 'Projet Firebase réservé à l’organisation $name';
  }

  @override
  String get creationPlanStandardProfiles =>
      'Tous les profils de suivi, jusqu’à 1 min d’intervalle';

  @override
  String get creationPlanStandardBilling =>
      'Nécessite un compte de facturation Google Cloud ; vous payez l’utilisation directement à Google';

  @override
  String get creationPlanSwitchLater =>
      'Vous pourrez passer de Community à Standard plus tard, sans perdre ni groupes ni historique.';

  @override
  String creationPlanContinue(String plan) {
    return 'Continuer avec $plan';
  }

  @override
  String get creationReviewTitle => 'Tout est bon ?';

  @override
  String get creationReviewTeamSees => 'Votre équipe verra';

  @override
  String get creationReviewName => 'Nom';

  @override
  String get creationReviewTheme => 'Thème';

  @override
  String get creationReviewPlan => 'Formule';

  @override
  String get creationReviewOwnerTitle => 'Vous serez titulaire';

  @override
  String creationReviewOwnerBody(String email) {
    return '$email administrera l’organisation : inviter des personnes, créer des groupes, changer l’apparence et ajouter le logo. Ensuite, d’autres personnes pourront aussi administrer.';
  }

  @override
  String creationTermsAccept(String terms) {
    return 'J’ai lu et j’accepte les $terms.';
  }

  @override
  String get creationTerms => 'Conditions pour les organisations';

  @override
  String get creationCreate => 'Créer l’organisation';

  @override
  String get creationThemeTitle => 'Choisissez un thème';

  @override
  String get creationThemeSubtitle =>
      'Chaque thème apporte déjà les tons de l’appli, avec un contraste garanti pour les textes et les boutons.';

  @override
  String get creationThemePreview => 'Aperçu de l’appli avec le thème';

  @override
  String get creationPreviewGroup => 'Chauffeurs';

  @override
  String get creationPreviewSharing => 'Partage en cours';

  @override
  String get createGroupTitle => 'Nouveau groupe';

  @override
  String get createGroupHeading => 'Créer un groupe';

  @override
  String get groupNameLabel => 'Nom du groupe';

  @override
  String get groupNameHint => 'Ex. : Chauffeurs';

  @override
  String get groupNameHelper =>
      'C’est ainsi que le groupe apparaît sur la carte et dans les invitations.';

  @override
  String get createGroupNote =>
      'Vous administrez l’organisation : vous voyez donc déjà tous les groupes sur la carte. Le groupe est créé vide : ensuite, invitez les personnes qui en feront partie.';

  @override
  String get createGroupButton => 'Créer le groupe';

  @override
  String get createGroupDone => 'Groupe créé';

  @override
  String createGroupDoneBody(String group) {
    return 'Le groupe $group est encore vide. Invitez les personnes qui y travailleront et choisissez ce que chacune fait dans l’appli.';
  }

  @override
  String get createGroupOpen => 'Voir le groupe';

  @override
  String get rolePublisher => 'Sur le terrain';

  @override
  String get rolePublisherDescription => 'Partage sa propre position';

  @override
  String get roleSubscriber => 'Voit la carte';

  @override
  String get roleSubscriberDescription => 'Voit qui est sur le terrain';

  @override
  String get roleMaintainer => 'Gestionnaire du groupe';

  @override
  String get roleMaintainerDescription =>
      'S’occupe des personnes et des invitations du groupe';

  @override
  String peopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personnes',
      one: '1 personne',
      zero: 'Personne pour l’instant',
    );
    return '$_temp0';
  }

  @override
  String pendingInvites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count invitations en attente',
      one: '1 invitation en attente',
      zero: '0 invitation en attente',
    );
    return '$_temp0';
  }

  @override
  String inviteValidUntil(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Valable jusqu’au $dateString';
  }

  @override
  String get inviteExpired => 'Expirée';

  @override
  String inviteExpiredOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Expirée · échue le $dateString';
  }

  @override
  String get invitesResend => 'Renvoyer';

  @override
  String get invitesNone => 'Aucune invitation en attente.';

  @override
  String get invitesResendTitle => 'Renvoyer l’invitation ?';

  @override
  String get invitesResendConfirm => 'Renvoyer l’invitation';

  @override
  String get invitesResending => 'Renvoi…';

  @override
  String invitesResendEmail(String email) {
    return '$email reçoit un nouvel e-mail.';
  }

  @override
  String get invitesResendValid =>
      'La nouvelle invitation est valable 14 jours.';

  @override
  String get invitesResent => 'Invitation renvoyée';

  @override
  String get invitesCancelTitle => 'Annuler l’invitation ?';

  @override
  String get invitesCancelConfirm => 'Annuler l’invitation';

  @override
  String get invitesCancelling => 'Annulation…';

  @override
  String invitesCancelLink(String email) {
    return 'Le lien envoyé à $email cesse de fonctionner.';
  }

  @override
  String get invitesInviteAgain => 'Vous pourrez inviter à nouveau plus tard.';

  @override
  String get invitesCancelled => 'Invitation annulée';

  @override
  String groupPersonEditRoles(String name) {
    return 'Modifier ce que fait $name';
  }

  @override
  String groupDeletionLoses(int count, String organization) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count personnes n’appartenaient qu’à ce groupe et perdent l’accès à $organization.',
      one:
          '1 personne n’appartenait qu’à ce groupe et perd l’accès à $organization.',
      zero:
          '0 personne n’appartenait qu’à ce groupe et perd l’accès à $organization.',
    );
    return '$_temp0';
  }

  @override
  String groupDeletionStays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personnes restent dans les autres groupes.',
      one: '1 personne reste dans les autres groupes.',
      zero: '0 personne reste dans les autres groupes.',
    );
    return '$_temp0';
  }

  @override
  String groupDeletionInvites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Les $count invitations en attente sont annulées.',
      one: 'L’invitation en attente est annulée.',
      zero: 'Aucune invitation en attente n’est annulée.',
    );
    return '$_temp0';
  }

  @override
  String get groupDeletionTrails =>
      'Les trajets publiés dans ce groupe sont effacés avec lui. Cette action est irréversible.';

  @override
  String groupDeletedLost(int count, String organization) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personnes ont perdu l’accès à $organization.',
      one: '1 personne a perdu l’accès à $organization.',
      zero: '0 personne a perdu l’accès à $organization.',
    );
    return '$_temp0';
  }

  @override
  String get groupDeletedOthersStay =>
      'Les personnes qui étaient dans d’autres groupes y restent.';

  @override
  String get presetEconomia => 'Économie';

  @override
  String get presetEquilibrio => 'Équilibre';

  @override
  String get presetPrecisao => 'Précision';

  @override
  String get presetPersonalizado => 'Personnalisé';

  @override
  String get groupPeopleEmpty =>
      'Personne dans ce groupe pour l’instant. Invitez les personnes qui y travailleront.';

  @override
  String groupRolesTitle(String email) {
    return 'Ce que fait $email';
  }

  @override
  String get groupRolesImmediate => 'La modification s’applique immédiatement.';

  @override
  String get groupRolesUpdated => 'Rôle mis à jour';

  @override
  String groupRemoveTitle(String email, String group) {
    return 'Retirer $email du groupe $group ?';
  }

  @override
  String get groupRemoving => 'Retrait…';

  @override
  String groupRemoveAccess(String organization) {
    return 'Si c’est le seul groupe de la personne, son accès à $organization prend fin (sauf si elle administre l’organisation).';
  }

  @override
  String get groupRemoveMap =>
      'La personne n’apparaît plus sur la carte de ce groupe et ne voit plus qui en fait partie.';

  @override
  String get groupRemoveHistory =>
      'Les anciens trajets restent dans l’historique.';

  @override
  String groupRemoved(String email) {
    return '$email ne fait plus partie du groupe';
  }

  @override
  String get groupTitle => 'Groupe';

  @override
  String get groupNotFound => 'Groupe introuvable.';

  @override
  String get groupRename => 'Renommer';

  @override
  String groupTabPeople(int count) {
    return 'Dans le groupe · $count';
  }

  @override
  String groupTabInvited(String count) {
    return 'Invitations · $count';
  }

  @override
  String get groupInvite => 'Inviter dans ce groupe';

  @override
  String get groupDelete => 'Supprimer le groupe';

  @override
  String get groupDeleted => 'Groupe supprimé';

  @override
  String get groupSeeGroups => 'Voir les groupes';

  @override
  String get groupRenameTitle => 'Renommer le groupe';

  @override
  String get groupRenameConfirm => 'Enregistrer le nom';

  @override
  String get groupRenameNote =>
      'Les personnes du groupe voient le nouveau nom immédiatement.';

  @override
  String get groupRenamed => 'Groupe renommé';

  @override
  String groupDeleteTitle(String group) {
    return 'Supprimer le groupe $group ?';
  }

  @override
  String get groupDeleting => 'Suppression…';

  @override
  String get groupsTitle => 'Groupes';

  @override
  String get groupsEmptyAdmin =>
      'Votre organisation n’a pas encore de groupe. Créez le premier et invitez les personnes qui y travailleront.';

  @override
  String get groupsEmptyMaintainer =>
      'Vous n’êtes gestionnaire d’aucun groupe pour le moment.';

  @override
  String get calendarPreviousMonth => 'Mois précédent';

  @override
  String get calendarNextMonth => 'Mois suivant';

  @override
  String get calendarDaysWithTrails => 'Jours avec trajets';

  @override
  String calendarDayLabel(DateTime date, String today, String status) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    String _temp0 = intl.Intl.selectLogic(today, {
      'yes': ', aujourd’hui',
      'other': '',
    });
    String _temp1 = intl.Intl.selectLogic(status, {
      'future': ', à venir',
      'trails': ', avec trajets',
      'other': ', sans trajet',
    });
    return '$dateString$_temp0$_temp1';
  }

  @override
  String get permissionBackgroundUsage =>
      'Votre appareil restreint l’appli en arrière-plan. Le suivi est donc désactivé quand vous quittez l’appli ou éteignez l’écran.\n\nComment régler cela :\n1. Appuyez sur « Continuer ».\n2. Activez « Autoriser l’utilisation en arrière-plan » (ou choisissez « Sans restriction »).\n3. Revenez à l’appli.\n\nSi l’écran d’informations de l’appli s’ouvre, appuyez d’abord sur « Utilisation de la batterie par l’appli » (ou « Batterie »). Si l’interrupteur est déjà activé, désactivez-le puis réactivez-le.';

  @override
  String get permissionBackgroundLocation =>
      'L’appli souhaite collecter des données de localisation même lorsqu’elle est fermée ou n’est pas utilisée.\n\nCes données permettent à un groupe de personnes, défini et géré par votre entreprise, de voir votre position en temps réel.\n\nComment l’activer :\n1. Appuyez sur « Continuer ».\n2. Allez dans Autorisations > Localisation.\n3. Sélectionnez « Autoriser tout le temps ».';

  @override
  String get permissionGpsOffTitle => 'Le GPS est désactivé';

  @override
  String get permissionGpsOffBody => 'Veuillez activer le GPS pour continuer.';

  @override
  String get permissionGotIt => 'COMPRIS';

  @override
  String get permissionAttention => 'Attention';

  @override
  String get permissionNotNow => 'PAS MAINTENANT';

  @override
  String get permissionContinue => 'CONTINUER';

  @override
  String mapGroupChip(String group) {
    return 'Groupe sur la carte : $group';
  }

  @override
  String get mapSeeOnMap => 'VOIR SUR LA CARTE';

  @override
  String groupCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count groupes',
      one: '1 groupe',
      zero: '0 groupe',
    );
    return '$_temp0';
  }

  @override
  String get mapNoGroups => 'Aucun groupe disponible';

  @override
  String memberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personnes',
      one: '1 personne',
      zero: '0 personne',
    );
    return '$_temp0';
  }

  @override
  String get homeMenuTooltip => 'Menu';

  @override
  String homeGroupChip(String group) {
    return 'Groupe : $group';
  }

  @override
  String homeDayChip(String day) {
    return 'Historique par date, $day';
  }

  @override
  String get homeBackToToday => 'Revenir à aujourd’hui';

  @override
  String get dayToday => 'Aujourd’hui';

  @override
  String get dayYesterday => 'Hier';

  @override
  String get homeChooseGroup => 'Choisir un groupe';

  @override
  String get homeNoGroup => 'Aucun groupe';

  @override
  String homeMoreGroups(String group, int more) {
    return '$group +$more';
  }

  @override
  String get menuAdministers => 'Administre l’organisation';

  @override
  String get menuWatchesAndShares => 'Voit la carte et partage';

  @override
  String get menuWatches => 'Voit la carte';

  @override
  String menuInTheField(String group) {
    return '$group · sur le terrain';
  }

  @override
  String get languageName => 'Français';

  @override
  String get languageTitle => 'Langue';

  @override
  String languageButtonLabel(String language) {
    return 'Langue : $language';
  }

  @override
  String get menuSwitchOrganization => 'Changer d’organisation';

  @override
  String get menuMyAccount => 'Mon compte';

  @override
  String get menuGroupManagement => 'GESTION DES GROUPES';

  @override
  String get menuMyGroups => 'Mes groupes';

  @override
  String get menuAdministration => 'ADMINISTRATION';

  @override
  String get menuAppearance => 'Apparence de l’organisation';

  @override
  String get menuTrackingSettings => 'Réglages de suivi';

  @override
  String homeLoadingGroup(String group) {
    return 'Chargement du groupe $group…';
  }

  @override
  String get homeAllowNotification => 'Autoriser les notifications';

  @override
  String get homeAllowLocationWhileInUse =>
      'Autoriser la position (pendant l’utilisation)';

  @override
  String get homeAllowLocationAlways => 'Autoriser la position (tout le temps)';

  @override
  String get homeAllowBackground => 'Autoriser l’utilisation en arrière-plan';

  @override
  String get mapAttribution => 'OpenStreetMap contributors';

  @override
  String get sheetShowList => 'Afficher la liste du groupe';

  @override
  String get sheetHideList => 'Réduire la liste du groupe';

  @override
  String get sheetNoGroup => 'Aucun groupe choisi';

  @override
  String get sheetEmptyGroup =>
      'Personne dans ce groupe pour l’instant. Invitez les personnes qui y travailleront pour voir tout le monde sur la carte.';

  @override
  String get invitePeople => 'Inviter des personnes';

  @override
  String personHideTrail(String name) {
    return 'Masquer le trajet : $name';
  }

  @override
  String personShowTrail(String name) {
    return 'Afficher le trajet : $name';
  }

  @override
  String personTrailVisible(String presence) {
    return '$presence · trajet visible';
  }

  @override
  String personCallOnMeet(String name) {
    return 'Appeler $name sur Meet';
  }

  @override
  String get presenceNever => 'Position pas encore activée';

  @override
  String get presenceOff => 'Position désactivée';

  @override
  String presenceOffSeen(String ago) {
    return 'Position désactivée · dernière activité $ago';
  }

  @override
  String get presenceLive => 'Maintenant';

  @override
  String get agoNow => 'à l’instant';

  @override
  String agoMinutes(int minutes) {
    return 'il y a $minutes min';
  }

  @override
  String agoHours(int hours) {
    return 'il y a $hours h';
  }

  @override
  String get agoYesterday => 'hier';

  @override
  String agoDays(int days) {
    return 'il y a $days jours';
  }

  @override
  String get presenceDayPoints => 'Positions enregistrées ce jour-là';

  @override
  String get presenceDayNoPoints => 'Aucune position ce jour-là';

  @override
  String get shareStopping => 'Désactivation du partage…';

  @override
  String get shareStarting => 'Activation du partage…';

  @override
  String get shareWait => 'Un instant';

  @override
  String get shareOn => 'Partage de votre position';

  @override
  String get shareOnSubtitle => 'Vos groupes vous voient sur la carte';

  @override
  String get shareOff => 'Position désactivée';

  @override
  String get shareOffSubtitle => 'Vos groupes ne vous voient pas sur la carte';

  @override
  String get inviteFirstGroupTitle => 'Créez votre premier groupe';

  @override
  String get inviteFirstGroupBody =>
      'Toute personne rejoint un groupe. Donnez un nom au premier ; vous en créerez d’autres plus tard, dans Groupes.';

  @override
  String get inviteWhichGroup => 'Dans quel groupe ?';

  @override
  String inviteGroupOption(String group, String people) {
    return '$group · $people';
  }

  @override
  String get inviteWho => 'Qui voulez-vous inviter ?';

  @override
  String get inviteEmailHint => 'email@exemple.com';

  @override
  String get inviteRolesQuestion =>
      'Que fait chaque personne ? Un rôle ou les deux.';

  @override
  String get inviteRolesExplained =>
      '« Sur le terrain » partage sa propre position. « Voit la carte » voit qui est sur le terrain.';

  @override
  String get inviteHowItWorks =>
      'Chaque personne reçoit un e-mail et se connecte à l’appli avec ce compte Google. Sa position n’est partagée qu’une fois qu’elle l’a activée sur son propre téléphone.';

  @override
  String get inviteSending => 'Envoi…';

  @override
  String inviteSend(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Envoyer $count invitations',
      one: 'Envoyer l’invitation',
      zero: 'Envoyer l’invitation',
    );
    return '$_temp0';
  }

  @override
  String inviteRemovePerson(String email) {
    return 'Retirer $email';
  }

  @override
  String get inviteNoRole => 'Cochez au moins une option.';

  @override
  String inviteSent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count invitations envoyées',
      one: 'Invitation envoyée',
      zero: '0 invitation envoyée',
    );
    return '$_temp0';
  }

  @override
  String inviteSentBody(String group) {
    return 'Pour le groupe $group. Validité de 14 jours, à suivre dans Groupes.';
  }

  @override
  String get inviteNotEmailed =>
      'L’e-mail n’est pas parti pour le moment ; la personne verra l’invitation en se connectant à l’appli avec ce compte.';

  @override
  String get inviteMore => 'Inviter d’autres personnes';

  @override
  String welcomeJoined(String name) {
    return 'Vous avez rejoint l’organisation $name';
  }

  @override
  String welcomeInvitedBy(String group, String inviter) {
    return '$group · invitation envoyée par $inviter';
  }

  @override
  String get welcomeWhatYouDo => 'Ce que vous faites dans l’appli';

  @override
  String get welcomePublisher =>
      'Vos groupes voient où vous êtes tant que le partage est activé. Vous l’activez et le désactivez quand vous voulez.';

  @override
  String welcomeSubscriber(String group) {
    return 'Vous suivez sur la carte qui est sur le terrain dans le groupe $group.';
  }

  @override
  String get welcomeTurnOnLocation => 'Activer ma position';

  @override
  String get welcomeOpenMap => 'Ouvrir la carte';

  @override
  String get welcomeLater => 'Activer plus tard';

  @override
  String trackingMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min',
      one: '1 min',
      zero: '0 min',
    );
    return '$_temp0';
  }

  @override
  String get trackingQuestion =>
      'À quelle fréquence l’équipe envoie-t-elle sa position ?';

  @override
  String trackingAppliesTo(String name) {
    return 'Concerne toutes les personnes de l’organisation $name qui sont sur le terrain.';
  }

  @override
  String trackingCommunityLimit(int minutes) {
    return 'Avec la formule Community, la position est envoyée au maximum toutes les $minutes min.';
  }

  @override
  String get trackingInterval => 'Intervalle';

  @override
  String trackingEvery(String interval) {
    return '$interval';
  }

  @override
  String get trackingDistance => 'Distance minimale';

  @override
  String trackingMeters(int meters) {
    return '$meters m';
  }

  @override
  String trackingPositionsPerHour(int count, int meters) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Jusqu’à $count positions',
      one: 'Jusqu’à 1 position',
      zero: 'Jusqu’à 0 position',
    );
    return '$_temp0 par heure, seulement quand la personne se déplace de $meters m ou plus.';
  }

  @override
  String trackingLeavesMap(String duration) {
    return 'Toute personne qui reste $duration sans donner de nouvelles disparaît de la carte.';
  }

  @override
  String trackingBattery(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      'low': 'Faible',
      'medium': 'Moyenne',
      'other': 'Élevée',
    });
    return 'Consommation de batterie : $_temp0';
  }

  @override
  String get trackingSaved =>
      'Enregistré. L’équipe le reçoit dans un instant, sans désactiver le partage.';

  @override
  String get trackingNoChanges => 'Aucune modification';

  @override
  String get trackingCustomDescription =>
      'Vous choisissez l’intervalle et la distance';

  @override
  String trackingPresetDescription(int minutes, int meters) {
    return 'Intervalle de $minutes min, dès $meters m de déplacement';
  }

  @override
  String get trackingInUse => 'En cours d’utilisation';

  @override
  String get failureConnectionConclude =>
      'Impossible de terminer pour le moment. Vérifiez la connexion et réessayez.';

  @override
  String get failureConnectionDelete =>
      'Impossible de supprimer pour le moment. Vérifiez la connexion et réessayez.';

  @override
  String get failureConnectionCancel =>
      'Impossible d’annuler pour le moment. Vérifiez la connexion et réessayez.';

  @override
  String get failureConnectionCreate =>
      'Impossible de créer pour le moment. Vérifiez la connexion et réessayez.';

  @override
  String get failureConnectionSend =>
      'Impossible d’envoyer pour le moment. Vérifiez la connexion et réessayez.';

  @override
  String get failureConnectionAccept =>
      'Impossible d’accepter pour le moment. Vérifiez la connexion et réessayez.';

  @override
  String get failureConnectionSave =>
      'Impossible d’enregistrer pour le moment. Vérifiez la connexion et réessayez.';

  @override
  String get failureConnectionSwitch =>
      'Impossible de changer pour le moment. Vérifiez la connexion et réessayez.';

  @override
  String get failureConnectionLoadAccount =>
      'Impossible de charger votre compte. Vérifiez la connexion et réessayez.';

  @override
  String get failureLoadAdministrators =>
      'Impossible de charger les administrateurs.';

  @override
  String get failureLoadInvites => 'Impossible de charger les invitations.';

  @override
  String get failureLoadGroups => 'Impossible de charger les groupes.';

  @override
  String get failureLoadThemes => 'Impossible de charger les thèmes.';

  @override
  String get failureLoadCreations =>
      'Impossible de charger les organisations en cours de création.';

  @override
  String get failureLoadAccountDeletion =>
      'Impossible de lire la suppression du compte.';

  @override
  String get failureLoadOrganizationIdCheck =>
      'Impossible de vérifier pour le moment.';

  @override
  String get failureRefusedConclude => 'Impossible de terminer.';

  @override
  String get failureRefusedAny => 'Impossible pour le moment.';

  @override
  String get failureRefusedCreate => 'Impossible de créer.';

  @override
  String get failureRefusedSave => 'Impossible d’enregistrer.';

  @override
  String get failureUnexpectedResponse => 'Réponse inattendue du serveur.';

  @override
  String get failureUnexpectedGroupResponse =>
      'Réponse inattendue lors de la création du groupe.';

  @override
  String get failureOrganizationIdNotPlain =>
      'Utilisez uniquement des lettres minuscules, sans accents ni espaces.';

  @override
  String failureOrganizationIdTooLong(int max) {
    return 'Utilisez $max lettres au maximum.';
  }

  @override
  String get failureOrganizationIdReserved => 'Cet identifiant est réservé.';

  @override
  String get failureOrganizationIdUnusable =>
      'Cet identifiant ne peut pas être utilisé.';

  @override
  String get failureGroupNameTooShort => 'Utilisez au moins 2 lettres.';

  @override
  String get failureGroupNameTooLong => 'Utilisez 40 caractères au maximum.';

  @override
  String failureGroupNameTaken(String name) {
    return 'Le groupe $name existe déjà.';
  }

  @override
  String get failureNoRoleChosen => 'Cochez au moins une option.';

  @override
  String get failureInvalidEmail => 'Saisissez une adresse e-mail valide.';

  @override
  String failureEmailAlreadyListed(String email) {
    return '$email figure déjà dans la liste.';
  }

  @override
  String failureLogoTooLarge(int megabytes) {
    return 'Le fichier fait $megabytes Mo. Envoyez-en un de 10 Mo au maximum.';
  }

  @override
  String get failureLogoUnreadable =>
      'Impossible d’ouvrir ce fichier. Envoyez un PNG, JPEG, WebP ou SVG.';

  @override
  String get failureLogoNotConverted => 'Impossible de générer le PNG du logo.';

  @override
  String get failureLogoNotOpened => 'Impossible d’ouvrir ce fichier.';

  @override
  String failureEntryEnter(String detail) {
    return 'Impossible d’entrer pour le moment : $detail';
  }

  @override
  String failureEntryCheck(String detail) {
    return 'Impossible de vérifier pour le moment : $detail';
  }

  @override
  String failureEntryUnexpected(String detail) {
    return 'Une erreur inattendue s’est produite : $detail';
  }

  @override
  String failureEntryLoadData(String detail) {
    return 'Une erreur s’est produite lors du chargement de vos données : $detail';
  }

  @override
  String failureEntryOrganization(String organization, String detail) {
    return 'Impossible d’accéder à $organization : $detail';
  }

  @override
  String get failureGoogleAuth =>
      'Échec de l’authentification. Vérifiez votre compte Google et réessayez.';

  @override
  String get failureGoogleRenewal =>
      'Impossible de renouveler l’accès avec Google. Réessayez.';

  @override
  String failureSignOut(String detail) {
    return 'Impossible de vous déconnecter. Réessayez.\nErreur : $detail';
  }

  @override
  String failureAccessLost(String organization) {
    return 'Votre compte n’a plus accès à $organization.';
  }

  @override
  String failureRemovedFromOrganization(String organization) {
    return 'Vous n’appartenez plus à $organization.';
  }

  @override
  String get failureRemovedFromUnnamedOrganization =>
      'Vous n’appartenez plus à cette organisation.';

  @override
  String get failureSharingNotAllowed =>
      'Vous n’êtes sur le terrain dans aucun groupe. Demandez à un administrateur de vous autoriser à partager votre position.';

  @override
  String get failureSharingNotChanged =>
      'Impossible de modifier le partage pour le moment. Réessayez.';

  @override
  String get failureLanguageNotSaved =>
      'Impossible d’enregistrer la langue. Réessayez.';

  @override
  String get failureTitleSignIn => 'Erreur de connexion';

  @override
  String get failureTitleSwitchOrganization => 'Changer d’organisation';

  @override
  String get failureTitleSignOut => 'Erreur de déconnexion';

  @override
  String get failureTitleSharingNotAllowed => 'Partage non autorisé';

  @override
  String get failureTitleSharing => 'Partage';

  @override
  String get noticeWaitingForGpsTitle => 'En attente du signal GPS';

  @override
  String get noticeWaitingForGps =>
      'Le suivi a démarré, mais votre position initiale est encore en cours d’obtention par les satellites.';

  @override
  String get noticeTrackingAtRiskTitle => 'Suivi menacé';

  @override
  String get noticeTrackingAtRisk =>
      'L’appareil restreint MonAmie en arrière-plan. Le suivi s’arrêtera quand vous quitterez l’appli.';

  @override
  String get noticeTrackingStopUnconfirmedTitle => 'Suivi';

  @override
  String get noticeTrackingStopUnconfirmed =>
      'Impossible de confirmer l’arrêt du suivi. Il s’arrêtera automatiquement dans un instant.';

  @override
  String get noticeBackgroundStillRestrictedTitle =>
      'Utilisation en arrière-plan toujours restreinte';

  @override
  String get noticeBackgroundStillRestricted =>
      'La modification n’a pas été appliquée. Appuyez sur « Autoriser l’utilisation en arrière-plan » et, si l’interrupteur est déjà activé, désactivez-le puis réactivez-le.';

  @override
  String get sharingNotificationTitle => 'Votre position est partagée';

  @override
  String get sharingNotificationContent =>
      'Le partage est activé. Pour protéger votre vie privée, pensez à le désactiver dès que vous avez terminé vos activités.';

  @override
  String get groupUnnamed => 'Groupe sans nom';

  @override
  String get inviteGroupFallback => 'Groupe';

  @override
  String get creationPreviewName => 'Organisation';
}
