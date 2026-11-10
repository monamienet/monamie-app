// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get loginTagline => 'Tu equipo, en el mismo punto.';

  @override
  String get commonSignOut => 'Cerrar sesión';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonOk => 'OK';

  @override
  String get commonSaving => 'Guardando…';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonSaveChanges => 'Guardar cambios';

  @override
  String get commonChange => 'Cambiar';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonBack => 'Volver';

  @override
  String get commonTryAgain => 'Reintentar';

  @override
  String get commonChecking => 'Comprobando…';

  @override
  String get commonCreating => 'Creando…';

  @override
  String get commonAdd => 'Agregar';

  @override
  String get commonRemove => 'Quitar';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonGotIt => 'Entendido';

  @override
  String get commonGenericFailure =>
      'No se pudo completar ahora. Inténtalo de nuevo.';

  @override
  String get deletionRestoredAccountTitle => 'Tu cuenta está de vuelta';

  @override
  String deletionRestoredOrganizationTitle(String name) {
    return '$name está de vuelta';
  }

  @override
  String deletionPendingAccountTitle(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'en $days días',
      one: 'en 1 día',
      zero: 'hoy',
    );
    return 'Tu cuenta se eliminará $_temp0';
  }

  @override
  String deletionPendingOrganizationTitle(String name, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'en $days días',
      one: 'en 1 día',
      zero: 'hoy',
    );
    return '$name se eliminará $_temp0';
  }

  @override
  String get deletionRestoredBody =>
      'No se borró nada. Inicia sesión para continuar donde lo dejaste.';

  @override
  String deletionPendingAccountBody(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'El $dateString borramos definitivamente tu cuenta y tus datos en MonAmie.';
  }

  @override
  String deletionPendingOrganizationBody(DateTime date, String name) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'El $dateString borramos definitivamente $name, sus grupos, el historial de todos y tu cuenta. Hasta entonces, nadie puede usar la organización.';
  }

  @override
  String get deletionEnter => 'Iniciar sesión';

  @override
  String get deletionCancelAccount => 'Cancelar eliminación de la cuenta';

  @override
  String get deletionCancel => 'Cancelar eliminación';

  @override
  String get myAccountTitle => 'Mi cuenta';

  @override
  String get myAccountDeleteHeading => 'Eliminar cuenta';

  @override
  String myAccountOwnerLeaves(String name) {
    return 'Eres titular de $name, así que la organización entera se elimina junto con tu cuenta.';
  }

  @override
  String myAccountMemberLeaves(String name) {
    return 'Sales de $name ahora y dejas de aparecer en el mapa.';
  }

  @override
  String myAccountEraseOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'El $dateString borramos definitivamente tu cuenta y tus datos en MonAmie.';
  }

  @override
  String get myAccountUndo =>
      'Hasta entonces, solo tienes que iniciar sesión de nuevo y cancelar la eliminación.';

  @override
  String get myAccountDeleteWithOrganization =>
      'Eliminar cuenta y organización';

  @override
  String get myAccountDelete => 'Eliminar cuenta';

  @override
  String myAccountConfirmPrompt(String id) {
    return 'Para confirmar, escribe $id';
  }

  @override
  String get adminOrganizationFallback => 'organización';

  @override
  String get loggingOut => 'Cerrando sesión…';

  @override
  String get switchingOrganization => 'Cambiando de organización…';

  @override
  String get administratorsTitle => 'Administradores';

  @override
  String get administratorsIntro =>
      'Quien administra se ocupa de todos los grupos, las invitaciones, la apariencia y los ajustes de la organización, y ve todos los grupos en el mapa. Solo tú, titular, eliges quién administra.';

  @override
  String get administratorsOwner => 'Titular';

  @override
  String get administratorsAdministers => 'Administra la organización';

  @override
  String get administratorsMakeMember => 'Convertir en miembro';

  @override
  String get administratorsNone => 'Nadie administra la organización.';

  @override
  String get administratorsMembers => 'Miembros';

  @override
  String get administratorsMember => 'Miembro';

  @override
  String get administratorsMakeAdmin => 'Hacer administrador';

  @override
  String get administratorsNoMembers =>
      'Aún no hay nadie más en la organización. Quien acepte una invitación a un grupo aparece aquí.';

  @override
  String administratorsSection(String title, int count) {
    return '$title · $count';
  }

  @override
  String administratorsPromoteTitle(String email) {
    return '¿Hacer administrador a $email?';
  }

  @override
  String get administratorsPromoteSees =>
      'Pasa a ver todos los grupos en el mapa y a ocuparse de los grupos, las invitaciones, la apariencia y los ajustes de la organización.';

  @override
  String get administratorsUndoLater => 'Puedes deshacerlo después.';

  @override
  String administratorsPromoted(String email) {
    return '$email ahora administra la organización';
  }

  @override
  String administratorsDemoteTitle(String email) {
    return '¿Convertir a $email en miembro?';
  }

  @override
  String get administratorsDemoteStops =>
      'Deja de administrar la organización y de ver los grupos en los que no está.';

  @override
  String get administratorsDemoteStays =>
      'Sigue en los grupos en los que ya está. Si no está en ninguno, sigue en la organización sin ver el mapa hasta recibir una invitación a un grupo.';

  @override
  String administratorsDemoted(String email) {
    return '$email ahora es miembro';
  }

  @override
  String get appearanceTitle => 'Apariencia';

  @override
  String get appearanceYouAdminister => 'Administras esta organización';

  @override
  String get appearanceName => 'Nombre';

  @override
  String get appearanceLogo => 'Logo';

  @override
  String get appearanceNoLogo => 'Sin logo · usamos la inicial';

  @override
  String get appearanceLogoSaved => 'PNG cuadrado de 512 px';

  @override
  String get appearanceLogoNew => 'Logo nuevo · guarda para aplicar';

  @override
  String get appearanceLogoFormats => 'SVG, PNG, JPEG o WebP';

  @override
  String get appearanceTheme => 'Tema';

  @override
  String get appearanceNextLaunch =>
      'El equipo verá la nueva apariencia la próxima vez que abra la app.';

  @override
  String get appearanceSaved => 'Apariencia guardada';

  @override
  String get appearanceNameDialog => 'Nombre de la organización';

  @override
  String get appearanceLogoError => 'No se pudo usar este archivo';

  @override
  String get appearanceLogoPreview => 'Así se ve el logo';

  @override
  String get appearanceLogoSheet => 'Logo de la organización';

  @override
  String get appearanceConverting => 'Convirtiendo a PNG en tu teléfono';

  @override
  String get appearanceUseLogo => 'Usar este logo';

  @override
  String get appearanceLogoExplained =>
      'Convertimos el archivo en un PNG cuadrado de 512 px. Así aparece en la parte superior de la app, en el menú y en la lista de organizaciones.';

  @override
  String get loginWithGoogle => 'Iniciar sesión con Google';

  @override
  String get loginLookingForOrganization => 'Buscando tu organización…';

  @override
  String loginEntering(String name) {
    return 'Entrando en $name…';
  }

  @override
  String get accountHeaderSwitch => 'Cambiar';

  @override
  String get inviteCardTitle => 'Tienes una invitación';

  @override
  String get inviteSomeone => 'Alguien';

  @override
  String inviteCardBody(String inviter, String group, String role) {
    String _temp0 = intl.Intl.selectLogic(role, {
      'both': 'en campo y viendo el mapa',
      'publisher': 'en campo',
      'other': 'viendo el mapa',
    });
    return '$inviter te invitó al grupo $group, $_temp0.';
  }

  @override
  String inviteCardValidUntil(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Válida hasta el $dateString.';
  }

  @override
  String inviteCardEntering(String name) {
    return 'Entrando en $name…';
  }

  @override
  String get inviteCardAccept => 'Aceptar y entrar';

  @override
  String get noOrganizationTitle => 'Aún no formas parte de una organización';

  @override
  String get noOrganizationBody =>
      'Crea la de tu equipo ahora o pide a alguien de tu equipo que te agregue.';

  @override
  String get noOrganizationFast => 'Nombre y tema en menos de 2 minutos';

  @override
  String get noOrganizationYouAdminister => 'Administras e invitas al equipo';

  @override
  String get noOrganizationLater =>
      'El logo y la apariencia los ajustas después, en la app';

  @override
  String get noOrganizationCreate => 'Crear mi organización';

  @override
  String get noOrganizationRecheck => 'Ya me invitaron · comprobar de nuevo';

  @override
  String get pickerTitle => '¿A qué organización quieres entrar?';

  @override
  String pickerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Participas en $count. Puedes cambiar después desde el menú.',
      one: 'Participas en 1 organización.',
      zero: 'Participas en 0. Puedes cambiar después desde el menú.',
    );
    return '$_temp0';
  }

  @override
  String get pickerCreate => 'Crear nueva organización';

  @override
  String get creationTitle => 'Nueva organización';

  @override
  String creationStep(int step, int count) {
    return '$step de $count';
  }

  @override
  String creationReadyTitle(String name) {
    return '$name está lista';
  }

  @override
  String get creationReadyBody =>
      'La app ya aparece con tu nombre y tu tema. El logo lo agregas cuando quieras, en Apariencia. Siguiente paso: invita a tu equipo en Grupos.';

  @override
  String creationReadyEnter(String name) {
    return 'Entrar en $name';
  }

  @override
  String get creationBillingTitle => 'Falta activar la facturación';

  @override
  String creationBillingBody(String name, String id) {
    return '$name funciona en un proyecto de Google Cloud pagado por tu organización. Entra en Google Cloud con esta misma cuenta de Google, elige o crea una cuenta de facturación y vincúlala al proyecto monamienet-$id. El identificador queda reservado durante 7 días.';
  }

  @override
  String creationFailedTitle(String name) {
    return 'Algo salió mal al crear $name';
  }

  @override
  String creationFailedBody(String id) {
    return 'No tienes que hacer nada. El equipo de MonAmie ya fue avisado y terminará la creación. Mientras tanto, el identificador $id sigue reservado para ti.';
  }

  @override
  String get creationNameTitle => '¿Cómo se llama tu organización?';

  @override
  String get creationNameSubtitle =>
      'Usa el nombre que tu equipo reconoce: el de la empresa, el del grupo o el del proyecto.';

  @override
  String get creationNameLabel => 'Nombre de la organización';

  @override
  String creationNamePreview(String name) {
    return 'Tu equipo verá $name en la parte superior de la app';
  }

  @override
  String get creationIdLabel => 'Identificador';

  @override
  String get creationIdAdjusted =>
      'Lo ajustamos a letras minúsculas, sin tildes, espacios ni números.';

  @override
  String get creationIdRules =>
      'Solo letras minúsculas, sin tildes, espacios ni números. Es el código de la organización en MonAmie.';

  @override
  String get creationIdPermanent =>
      'El identificador no cambia después. El nombre sí puede cambiar.';

  @override
  String get creationIdTooShort => 'Mínimo 3 letras';

  @override
  String get creationIdAvailable => 'Disponible';

  @override
  String get planCommunity => 'Community';

  @override
  String get planStandard => 'Standard';

  @override
  String get creationPlanTitle => 'Elige un plan';

  @override
  String creationPlanSubtitle(String name) {
    return 'Ambos incluyen el mapa, los grupos y la apariencia de $name. Cambia dónde se guardan los datos y quién paga.';
  }

  @override
  String get creationPlanFree => 'Gratis';

  @override
  String get creationPlanCommunityTagline =>
      'Para empezar ahora, sin registrar ningún pago.';

  @override
  String get creationPlanCommunityReady => 'Lista en instantes';

  @override
  String get creationPlanCommunityData =>
      'Datos guardados por MonAmie, separados de las demás organizaciones';

  @override
  String get creationPlanCommunityInterval =>
      'Ubicación enviada cada 15 min (perfil Economía)';

  @override
  String get creationPlanGoogleUsage => 'Uso en Google';

  @override
  String get creationPlanStandardTagline =>
      'Para quien quiere su propio espacio de datos y más precisión.';

  @override
  String creationPlanStandardProject(String name) {
    return 'Proyecto de Firebase solo para $name';
  }

  @override
  String get creationPlanStandardProfiles =>
      'Todos los perfiles de seguimiento, hasta cada 1 min';

  @override
  String get creationPlanStandardBilling =>
      'Requiere una cuenta de facturación de Google Cloud; pagas el uso directamente a Google';

  @override
  String get creationPlanSwitchLater =>
      'Puedes pasar de Community a Standard después, sin perder grupos ni historial.';

  @override
  String creationPlanContinue(String plan) {
    return 'Continuar con $plan';
  }

  @override
  String get creationReviewTitle => '¿Todo bien?';

  @override
  String get creationReviewTeamSees => 'Tu equipo verá';

  @override
  String get creationReviewName => 'Nombre';

  @override
  String get creationReviewTheme => 'Tema';

  @override
  String get creationReviewPlan => 'Plan';

  @override
  String get creationReviewOwnerTitle => 'Serás titular';

  @override
  String creationReviewOwnerBody(String email) {
    return '$email administrará la organización: invitar a personas, crear grupos, cambiar la apariencia y agregar el logo. Después, otras personas también podrán administrar.';
  }

  @override
  String creationTermsAccept(String terms) {
    return 'He leído y acepto los $terms.';
  }

  @override
  String get creationTerms => 'Términos para organizaciones';

  @override
  String get creationCreate => 'Crear organización';

  @override
  String get creationThemeTitle => 'Elige un tema';

  @override
  String get creationThemeSubtitle =>
      'Cada tema ya trae los tonos de la app, con contraste garantizado para textos y botones.';

  @override
  String get creationThemePreview => 'Vista previa de la app con el tema';

  @override
  String get creationPreviewGroup => 'Conductores';

  @override
  String get creationPreviewSharing => 'Compartiendo';

  @override
  String get createGroupTitle => 'Nuevo grupo';

  @override
  String get createGroupHeading => 'Crear un grupo';

  @override
  String get groupNameLabel => 'Nombre del grupo';

  @override
  String get groupNameHint => 'Ej.: Conductores';

  @override
  String get groupNameHelper =>
      'Así aparece el grupo en el mapa y en las invitaciones.';

  @override
  String get createGroupNote =>
      'Administras la organización, así que ya ves todos los grupos en el mapa. El grupo nace vacío: después de crearlo, invita a quienes formarán parte de él.';

  @override
  String get createGroupButton => 'Crear grupo';

  @override
  String get createGroupDone => 'Grupo creado';

  @override
  String createGroupDoneBody(String group) {
    return '$group aún no tiene a nadie. Invita a las personas que trabajarán en él y elige qué hace cada una en la app.';
  }

  @override
  String get createGroupOpen => 'Ver el grupo';

  @override
  String get rolePublisher => 'En campo';

  @override
  String get rolePublisherDescription => 'Comparte su propia ubicación';

  @override
  String get roleSubscriber => 'Ve el mapa';

  @override
  String get roleSubscriberDescription => 'Ve quién está en campo';

  @override
  String get roleMaintainer => 'Gestor del grupo';

  @override
  String get roleMaintainerDescription =>
      'Se ocupa de las personas y las invitaciones del grupo';

  @override
  String peopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas',
      one: '1 persona',
      zero: 'Nadie aún',
    );
    return '$_temp0';
  }

  @override
  String pendingInvites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count invitaciones pendientes',
      one: '1 invitación pendiente',
      zero: '0 invitaciones pendientes',
    );
    return '$_temp0';
  }

  @override
  String inviteValidUntil(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Válida hasta el $dateString';
  }

  @override
  String get inviteExpired => 'Expirada';

  @override
  String inviteExpiredOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Expirada · venció el $dateString';
  }

  @override
  String get invitesResend => 'Reenviar';

  @override
  String get invitesNone => 'Ninguna invitación pendiente.';

  @override
  String get invitesResendTitle => '¿Reenviar la invitación?';

  @override
  String get invitesResendConfirm => 'Reenviar invitación';

  @override
  String get invitesResending => 'Reenviando…';

  @override
  String invitesResendEmail(String email) {
    return '$email recibe un nuevo correo.';
  }

  @override
  String get invitesResendValid => 'La nueva invitación es válida por 14 días.';

  @override
  String get invitesResent => 'Invitación reenviada';

  @override
  String get invitesCancelTitle => '¿Cancelar la invitación?';

  @override
  String get invitesCancelConfirm => 'Cancelar invitación';

  @override
  String get invitesCancelling => 'Cancelando…';

  @override
  String invitesCancelLink(String email) {
    return 'El enlace enviado a $email deja de funcionar.';
  }

  @override
  String get invitesInviteAgain => 'Puedes volver a invitar después.';

  @override
  String get invitesCancelled => 'Invitación cancelada';

  @override
  String groupPersonEditRoles(String name) {
    return 'Cambiar lo que hace $name';
  }

  @override
  String groupDeletionLoses(int count, String organization) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count personas solo estaban en este grupo y pierden el acceso a $organization.',
      one:
          '1 persona solo estaba en este grupo y pierde el acceso a $organization.',
      zero:
          '0 personas solo estaban en este grupo y pierden el acceso a $organization.',
    );
    return '$_temp0';
  }

  @override
  String groupDeletionStays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas siguen en los otros grupos.',
      one: '1 persona sigue en los otros grupos.',
      zero: '0 personas siguen en los otros grupos.',
    );
    return '$_temp0';
  }

  @override
  String groupDeletionInvites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Las $count invitaciones pendientes se cancelan.',
      one: 'La invitación pendiente se cancela.',
      zero: 'Las 0 invitaciones pendientes se cancelan.',
    );
    return '$_temp0';
  }

  @override
  String get groupDeletionTrails =>
      'Los recorridos publicados en este grupo se borran junto con él. No se puede deshacer.';

  @override
  String groupDeletedLost(int count, String organization) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas perdieron el acceso a $organization.',
      one: '1 persona perdió el acceso a $organization.',
      zero: '0 personas perdieron el acceso a $organization.',
    );
    return '$_temp0';
  }

  @override
  String get groupDeletedOthersStay =>
      'Quienes estaban en otros grupos siguen en ellos.';

  @override
  String get presetEconomia => 'Economía';

  @override
  String get presetEquilibrio => 'Equilibrio';

  @override
  String get presetPrecisao => 'Precisión';

  @override
  String get presetPersonalizado => 'Personalizado';

  @override
  String get groupPeopleEmpty =>
      'Aún no hay nadie en este grupo. Invita a quienes van a trabajar en él.';

  @override
  String groupRolesTitle(String email) {
    return 'Qué hace $email';
  }

  @override
  String get groupRolesImmediate => 'El cambio se aplica al instante.';

  @override
  String get groupRolesUpdated => 'Rol actualizado';

  @override
  String groupRemoveTitle(String email, String group) {
    return '¿Quitar a $email de $group?';
  }

  @override
  String get groupRemoving => 'Quitando…';

  @override
  String groupRemoveAccess(String organization) {
    return 'Si este es el único grupo de la persona, su acceso a $organization termina (a menos que administre la organización).';
  }

  @override
  String get groupRemoveMap =>
      'Deja de aparecer en el mapa de este grupo y de ver quién está en él.';

  @override
  String get groupRemoveHistory =>
      'Los recorridos anteriores siguen en el historial.';

  @override
  String groupRemoved(String email) {
    return '$email ya no forma parte del grupo';
  }

  @override
  String get groupTitle => 'Grupo';

  @override
  String get groupNotFound => 'Grupo no encontrado.';

  @override
  String get groupRename => 'Renombrar';

  @override
  String groupTabPeople(int count) {
    return 'En el grupo · $count';
  }

  @override
  String groupTabInvited(String count) {
    return 'Invitaciones · $count';
  }

  @override
  String get groupInvite => 'Invitar a este grupo';

  @override
  String get groupDelete => 'Eliminar grupo';

  @override
  String get groupDeleted => 'Grupo eliminado';

  @override
  String get groupSeeGroups => 'Ver grupos';

  @override
  String get groupRenameTitle => 'Renombrar grupo';

  @override
  String get groupRenameConfirm => 'Guardar nombre';

  @override
  String get groupRenameNote =>
      'Las personas del grupo ven el nuevo nombre al instante.';

  @override
  String get groupRenamed => 'Grupo renombrado';

  @override
  String groupDeleteTitle(String group) {
    return '¿Eliminar $group?';
  }

  @override
  String get groupDeleting => 'Eliminando…';

  @override
  String get groupsTitle => 'Grupos';

  @override
  String get groupsEmptyAdmin =>
      'Tu organización aún no tiene grupos. Crea el primero e invita a quienes van a trabajar en él.';

  @override
  String get groupsEmptyMaintainer => 'Ahora no eres gestor de ningún grupo.';

  @override
  String get calendarPreviousMonth => 'Mes anterior';

  @override
  String get calendarNextMonth => 'Mes siguiente';

  @override
  String get calendarDaysWithTrails => 'Días con recorridos';

  @override
  String calendarDayLabel(DateTime date, String today, String status) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    String _temp0 = intl.Intl.selectLogic(today, {'yes': ', hoy', 'other': ''});
    String _temp1 = intl.Intl.selectLogic(status, {
      'future': ', aún no llega',
      'trails': ', con recorridos',
      'other': ', sin recorridos',
    });
    return '$dateString$_temp0$_temp1';
  }

  @override
  String get permissionBackgroundUsage =>
      'Tu dispositivo está restringiendo la app en segundo plano. Por eso, el seguimiento se desactiva cuando sales de la app o apagas la pantalla.\n\nCómo ajustarlo:\n1. Toca \'Continuar\'.\n2. Activa \'Permitir uso en segundo plano\' (o elige \'Sin restricciones\').\n3. Vuelve a la app.\n\nSi se abre la pantalla de información de la app, toca antes \'Uso de batería de la app\' (o \'Batería\'). Si el interruptor ya aparece activado, desactívalo y vuelve a activarlo.';

  @override
  String get permissionBackgroundLocation =>
      'La app quiere recopilar datos de ubicación incluso cuando está cerrada o no se está usando.\n\nEstos datos permiten que un grupo de personas, definido y gestionado por tu empresa, vea tu posición en tiempo real.\n\nCómo activarlo:\n1. Toca \'Continuar\'.\n2. Ve a Permisos > Ubicación.\n3. Selecciona \'Permitir todo el tiempo\'.';

  @override
  String get permissionGpsOffTitle => 'El GPS está desactivado';

  @override
  String get permissionGpsOffBody => 'Activa el GPS para continuar.';

  @override
  String get permissionGotIt => 'ENTENDIDO';

  @override
  String get permissionAttention => 'Atención';

  @override
  String get permissionNotNow => 'AHORA NO';

  @override
  String get permissionContinue => 'CONTINUAR';

  @override
  String mapGroupChip(String group) {
    return 'Grupo en el mapa: $group';
  }

  @override
  String get mapSeeOnMap => 'VER EN EL MAPA';

  @override
  String groupCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count grupos',
      one: '1 grupo',
      zero: '0 grupos',
    );
    return '$_temp0';
  }

  @override
  String get mapNoGroups => 'Ningún grupo disponible';

  @override
  String memberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas',
      one: '1 persona',
      zero: '0 personas',
    );
    return '$_temp0';
  }

  @override
  String get homeMenuTooltip => 'Menú';

  @override
  String homeGroupChip(String group) {
    return 'Grupo: $group';
  }

  @override
  String homeDayChip(String day) {
    return 'Historial por fecha, $day';
  }

  @override
  String get homeBackToToday => 'Volver a hoy';

  @override
  String get dayToday => 'Hoy';

  @override
  String get dayYesterday => 'Ayer';

  @override
  String get homeChooseGroup => 'Elegir grupo';

  @override
  String get homeNoGroup => 'Sin grupo';

  @override
  String homeMoreGroups(String group, int more) {
    return '$group +$more';
  }

  @override
  String get menuAdministers => 'Administra la organización';

  @override
  String get menuWatchesAndShares => 'Ve el mapa y comparte';

  @override
  String get menuWatches => 'Ve el mapa';

  @override
  String menuInTheField(String group) {
    return '$group · en campo';
  }

  @override
  String get languageName => 'Español';

  @override
  String get languageTitle => 'Idioma';

  @override
  String languageButtonLabel(String language) {
    return 'Idioma: $language';
  }

  @override
  String get menuSwitchOrganization => 'Cambiar de organización';

  @override
  String get menuMyAccount => 'Mi cuenta';

  @override
  String get menuGroupManagement => 'GESTIÓN DE GRUPOS';

  @override
  String get menuMyGroups => 'Mis grupos';

  @override
  String get menuAdministration => 'ADMINISTRACIÓN';

  @override
  String get menuAppearance => 'Apariencia de la organización';

  @override
  String get menuTrackingSettings => 'Ajustes de seguimiento';

  @override
  String homeLoadingGroup(String group) {
    return 'Cargando $group…';
  }

  @override
  String get homeAllowNotification => 'Permitir notificaciones';

  @override
  String get homeAllowLocationWhileInUse =>
      'Permitir ubicación (durante el uso)';

  @override
  String get homeAllowLocationAlways => 'Permitir ubicación (siempre)';

  @override
  String get homeAllowBackground => 'Permitir uso en segundo plano';

  @override
  String get mapAttribution => 'OpenStreetMap contributors';

  @override
  String get sheetShowList => 'Mostrar la lista del grupo';

  @override
  String get sheetHideList => 'Contraer la lista del grupo';

  @override
  String get sheetNoGroup => 'Ningún grupo elegido';

  @override
  String get sheetEmptyGroup =>
      'Aún no hay nadie en este grupo. Invita a quienes van a trabajar en él para ver a todos en el mapa.';

  @override
  String get invitePeople => 'Invitar a personas';

  @override
  String personHideTrail(String name) {
    return 'Ocultar recorrido de $name';
  }

  @override
  String personShowTrail(String name) {
    return 'Mostrar recorrido de $name';
  }

  @override
  String personTrailVisible(String presence) {
    return '$presence · recorrido visible';
  }

  @override
  String personCallOnMeet(String name) {
    return 'Llamar a $name en Meet';
  }

  @override
  String get presenceNever => 'Aún no ha activado la ubicación';

  @override
  String get presenceOff => 'Ubicación desactivada';

  @override
  String presenceOffSeen(String ago) {
    return 'Ubicación desactivada · última vez $ago';
  }

  @override
  String get presenceLive => 'Ahora';

  @override
  String get agoNow => 'hace un momento';

  @override
  String agoMinutes(int minutes) {
    return 'hace $minutes min';
  }

  @override
  String agoHours(int hours) {
    return 'hace $hours h';
  }

  @override
  String get agoYesterday => 'ayer';

  @override
  String agoDays(int days) {
    return 'hace $days días';
  }

  @override
  String get presenceDayPoints => 'Tiene posiciones este día';

  @override
  String get presenceDayNoPoints => 'Sin posiciones este día';

  @override
  String get shareStopping => 'Desactivando la ubicación compartida…';

  @override
  String get shareStarting => 'Activando la ubicación compartida…';

  @override
  String get shareWait => 'Espera un momento';

  @override
  String get shareOn => 'Compartiendo tu ubicación';

  @override
  String get shareOnSubtitle => 'Tus grupos te ven en el mapa';

  @override
  String get shareOff => 'Ubicación desactivada';

  @override
  String get shareOffSubtitle => 'Tus grupos no te ven en el mapa';

  @override
  String get inviteFirstGroupTitle => 'Crea tu primer grupo';

  @override
  String get inviteFirstGroupBody =>
      'Toda persona entra en un grupo. Ponle nombre al primero; creas otros después, en Grupos.';

  @override
  String get inviteWhichGroup => '¿A qué grupo?';

  @override
  String inviteGroupOption(String group, String people) {
    return '$group · $people';
  }

  @override
  String get inviteWho => '¿A quién quieres invitar?';

  @override
  String get inviteEmailHint => 'correo@ejemplo.com';

  @override
  String get inviteRolesQuestion =>
      '¿Qué hace cada persona? Una o las dos cosas.';

  @override
  String get inviteRolesExplained =>
      'En campo comparte su propia ubicación. Ve el mapa ve quién está en campo.';

  @override
  String get inviteHowItWorks =>
      'Cada persona recibe un correo e inicia sesión en la app con esa cuenta de Google. Su ubicación solo se comparte después de que la active en su propio teléfono.';

  @override
  String get inviteSending => 'Enviando…';

  @override
  String inviteSend(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Enviar $count invitaciones',
      one: 'Enviar invitación',
      zero: 'Enviar invitación',
    );
    return '$_temp0';
  }

  @override
  String inviteRemovePerson(String email) {
    return 'Quitar a $email';
  }

  @override
  String get inviteNoRole => 'Marca al menos una opción.';

  @override
  String inviteSent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count invitaciones enviadas',
      one: 'Invitación enviada',
      zero: '0 invitaciones enviadas',
    );
    return '$_temp0';
  }

  @override
  String inviteSentBody(String group) {
    return 'Para $group. Validez de 14 días; haz el seguimiento en Grupos.';
  }

  @override
  String get inviteNotEmailed =>
      'El correo no salió ahora; la persona verá la invitación al iniciar sesión en la app con esa cuenta.';

  @override
  String get inviteMore => 'Invitar a más personas';

  @override
  String welcomeJoined(String name) {
    return 'Ahora formas parte de $name';
  }

  @override
  String welcomeInvitedBy(String group, String inviter) {
    return '$group · invitación de $inviter';
  }

  @override
  String get welcomeWhatYouDo => 'Qué haces en la app';

  @override
  String get welcomePublisher =>
      'Tus grupos ven dónde estás mientras la ubicación compartida esté activada. La activas y desactivas cuando quieras.';

  @override
  String welcomeSubscriber(String group) {
    return 'Ves en el mapa quién está en campo en $group.';
  }

  @override
  String get welcomeTurnOnLocation => 'Activar mi ubicación';

  @override
  String get welcomeOpenMap => 'Abrir el mapa';

  @override
  String get welcomeLater => 'Activar después';

  @override
  String trackingMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min',
      one: '1 min',
      zero: '0 min',
    );
    return '$_temp0';
  }

  @override
  String get trackingQuestion =>
      '¿Con qué frecuencia envía el equipo su ubicación?';

  @override
  String trackingAppliesTo(String name) {
    return 'Vale para todas las personas de $name que están en campo.';
  }

  @override
  String trackingCommunityLimit(int minutes) {
    return 'En el plan Community, la ubicación se envía como máximo cada $minutes min.';
  }

  @override
  String get trackingInterval => 'Intervalo';

  @override
  String trackingEvery(String interval) {
    return 'cada $interval';
  }

  @override
  String get trackingDistance => 'Distancia mínima';

  @override
  String trackingMeters(int meters) {
    return '$meters m';
  }

  @override
  String trackingPositionsPerHour(int count, int meters) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hasta $count posiciones',
      one: 'Hasta 1 posición',
      zero: 'Hasta 0 posiciones',
    );
    return '$_temp0 por hora, solo cuando la persona se mueve $meters m o más.';
  }

  @override
  String trackingLeavesMap(String duration) {
    return 'Quien pase $duration sin dar señales sale del mapa.';
  }

  @override
  String trackingBattery(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      'low': 'Bajo',
      'medium': 'Medio',
      'other': 'Alto',
    });
    return 'Uso de batería: $_temp0';
  }

  @override
  String get trackingSaved =>
      'Guardado. El equipo lo recibe en instantes, sin desactivar la ubicación compartida.';

  @override
  String get trackingNoChanges => 'Sin cambios';

  @override
  String get trackingCustomDescription =>
      'Tú eliges el intervalo y la distancia';

  @override
  String trackingPresetDescription(int minutes, int meters) {
    return 'Cada $minutes min, si se mueve $meters m';
  }

  @override
  String get trackingInUse => 'En uso';

  @override
  String get failureConnectionConclude =>
      'No se pudo completar ahora. Revisa la conexión e inténtalo de nuevo.';

  @override
  String get failureConnectionDelete =>
      'No se pudo eliminar ahora. Revisa la conexión e inténtalo de nuevo.';

  @override
  String get failureConnectionCancel =>
      'No se pudo cancelar ahora. Revisa la conexión e inténtalo de nuevo.';

  @override
  String get failureConnectionCreate =>
      'No se pudo crear ahora. Revisa la conexión e inténtalo de nuevo.';

  @override
  String get failureConnectionSend =>
      'No se pudo enviar ahora. Revisa la conexión e inténtalo de nuevo.';

  @override
  String get failureConnectionAccept =>
      'No se pudo aceptar ahora. Revisa la conexión e inténtalo de nuevo.';

  @override
  String get failureConnectionSave =>
      'No se pudo guardar ahora. Revisa la conexión e inténtalo de nuevo.';

  @override
  String get failureConnectionSwitch =>
      'No se pudo cambiar ahora. Revisa la conexión e inténtalo de nuevo.';

  @override
  String get failureConnectionLoadAccount =>
      'No se pudo cargar tu cuenta. Revisa la conexión e inténtalo de nuevo.';

  @override
  String get failureLoadAdministrators =>
      'No se pudieron cargar los administradores.';

  @override
  String get failureLoadInvites => 'No se pudieron cargar las invitaciones.';

  @override
  String get failureLoadGroups => 'No se pudieron cargar los grupos.';

  @override
  String get failureLoadThemes => 'No se pudieron cargar los temas.';

  @override
  String get failureLoadCreations =>
      'No se pudieron cargar las organizaciones en creación.';

  @override
  String get failureLoadAccountDeletion =>
      'No se pudo leer la eliminación de la cuenta.';

  @override
  String get failureLoadOrganizationIdCheck => 'No se pudo comprobar ahora.';

  @override
  String get failureRefusedConclude => 'No se pudo completar.';

  @override
  String get failureRefusedAny => 'No es posible ahora.';

  @override
  String get failureRefusedCreate => 'No se pudo crear.';

  @override
  String get failureRefusedSave => 'No se pudo guardar.';

  @override
  String get failureUnexpectedResponse => 'Respuesta inesperada del servidor.';

  @override
  String get failureUnexpectedGroupResponse =>
      'Respuesta inesperada al crear el grupo.';

  @override
  String get failureOrganizationIdNotPlain =>
      'Usa solo letras minúsculas, sin tildes ni espacios.';

  @override
  String failureOrganizationIdTooLong(int max) {
    return 'Usa como máximo $max letras.';
  }

  @override
  String get failureOrganizationIdReserved =>
      'Este identificador está reservado.';

  @override
  String get failureOrganizationIdUnusable =>
      'Este identificador no se puede usar.';

  @override
  String get failureGroupNameTooShort => 'Usa al menos 2 letras.';

  @override
  String get failureGroupNameTooLong => 'Usa como máximo 40 caracteres.';

  @override
  String failureGroupNameTaken(String name) {
    return 'Ya existe el grupo $name.';
  }

  @override
  String get failureNoRoleChosen => 'Marca al menos una opción.';

  @override
  String get failureInvalidEmail => 'Escribe un correo válido.';

  @override
  String failureEmailAlreadyListed(String email) {
    return '$email ya está en la lista.';
  }

  @override
  String failureLogoTooLarge(int megabytes) {
    return 'El archivo pesa $megabytes MB. Envía uno de hasta 10 MB.';
  }

  @override
  String get failureLogoUnreadable =>
      'No se pudo abrir este archivo. Envía un PNG, JPEG, WebP o SVG.';

  @override
  String get failureLogoNotConverted => 'No se pudo generar el PNG del logo.';

  @override
  String get failureLogoNotOpened => 'No se pudo abrir este archivo.';

  @override
  String failureEntryEnter(String detail) {
    return 'No se pudo entrar ahora: $detail';
  }

  @override
  String failureEntryCheck(String detail) {
    return 'No se pudo comprobar ahora: $detail';
  }

  @override
  String failureEntryUnexpected(String detail) {
    return 'Ocurrió un error inesperado: $detail';
  }

  @override
  String failureEntryLoadData(String detail) {
    return 'Ocurrió un error al cargar tus datos: $detail';
  }

  @override
  String failureEntryOrganization(String organization, String detail) {
    return 'No se pudo entrar en $organization: $detail';
  }

  @override
  String get failureGoogleAuth =>
      'No se pudo autenticar al usuario. Revisa tu cuenta de Google e inténtalo de nuevo.';

  @override
  String get failureGoogleRenewal =>
      'No se pudo renovar el acceso con Google. Inténtalo de nuevo.';

  @override
  String failureSignOut(String detail) {
    return 'No se pudo cerrar la sesión. Inténtalo de nuevo.\nError: $detail';
  }

  @override
  String failureAccessLost(String organization) {
    return 'Tu cuenta ya no tiene acceso a $organization.';
  }

  @override
  String failureRemovedFromOrganization(String organization) {
    return 'Ya no formas parte de $organization.';
  }

  @override
  String get failureRemovedFromUnnamedOrganization =>
      'Ya no formas parte de esta organización.';

  @override
  String get failureSharingNotAllowed =>
      'No estás en campo en ningún grupo. Pide a un administrador que te permita compartir tu ubicación.';

  @override
  String get failureSharingNotChanged =>
      'No se pudo cambiar si compartes tu ubicación. Inténtalo de nuevo.';

  @override
  String get failureLanguageNotSaved =>
      'No se pudo guardar el idioma. Inténtalo de nuevo.';

  @override
  String get failureTitleSignIn => 'Error de inicio de sesión';

  @override
  String get failureTitleSwitchOrganization => 'Cambiar de organización';

  @override
  String get failureTitleSignOut => 'Error al cerrar sesión';

  @override
  String get failureTitleSharingNotAllowed =>
      'Ubicación compartida no permitida';

  @override
  String get failureTitleSharing => 'Ubicación compartida';

  @override
  String get noticeWaitingForGpsTitle => 'Esperando señal de GPS';

  @override
  String get noticeWaitingForGps =>
      'El seguimiento se inició, pero los satélites todavía están obteniendo tu posición inicial.';

  @override
  String get noticeTrackingAtRiskTitle => 'Seguimiento en riesgo';

  @override
  String get noticeTrackingAtRisk =>
      'El dispositivo está restringiendo MonAmie en segundo plano. El seguimiento se detendrá cuando salgas de la app.';

  @override
  String get noticeTrackingStopUnconfirmedTitle => 'Seguimiento';

  @override
  String get noticeTrackingStopUnconfirmed =>
      'No se pudo confirmar que el seguimiento se detuvo. Se detendrá automáticamente en unos instantes.';

  @override
  String get noticeBackgroundStillRestrictedTitle =>
      'Uso en segundo plano aún restringido';

  @override
  String get noticeBackgroundStillRestricted =>
      'El cambio no se aplicó. Toca \'Permitir uso en segundo plano\' y, si el interruptor ya está activado, desactívalo y vuelve a activarlo.';

  @override
  String get sharingNotificationTitle => 'Tu ubicación se está compartiendo';

  @override
  String get sharingNotificationContent =>
      'Compartir ubicación está activado. Para proteger tu privacidad, asegúrate de desactivarlo en cuanto termines tus actividades.';

  @override
  String get groupUnnamed => 'Grupo sin nombre';

  @override
  String get inviteGroupFallback => 'Grupo';

  @override
  String get creationPreviewName => 'Organización';

  @override
  String get failureResumeOptionNotSaved =>
      'No se pudo guardar la opción. Inténtalo de nuevo.';

  @override
  String get resumeOnRestartTitle => 'Reanudar al reiniciar';

  @override
  String get resumeOnRestartSubtitle =>
      'Si estás compartiendo cuando el dispositivo se apaga o la app se actualiza, compartir vuelve a activarse solo.';

  @override
  String get resumeOnRestartNeedsAlwaysLocation =>
      'Para reanudar, la ubicación debe estar permitida todo el tiempo. Toca para permitirla.';

  @override
  String get resumeOnRestartBatteryRestricted =>
      'Para reanudar, la batería de la app no puede estar en “Restringido”. Toca para cambiarlo.';

  @override
  String get resumeWaitingForGps =>
      'Compartir volvió a activarse y está esperando que se encienda el GPS.';

  @override
  String get resumeFailureChannel => 'Reanudación de compartir';

  @override
  String get resumeFailureTitle => 'Compartir no se reanudó';

  @override
  String get resumeFailureBackgroundLocation =>
      'La ubicación no está permitida todo el tiempo. Toca para abrir la app.';

  @override
  String get resumeFailureBatteryRestricted =>
      'La batería de la app está en “Restringido”. Toca para abrir la app.';

  @override
  String get resumeFailureSignedOut =>
      'Tu cuenta ya no está conectada. Toca para abrir la app.';

  @override
  String get resumeFailureNoGroup =>
      'Ya no compartes tu ubicación en ningún grupo. Toca para abrir la app.';
}
