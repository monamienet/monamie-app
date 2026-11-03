// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get loginTagline => 'Sua equipe, no mesmo ponto.';

  @override
  String get commonSignOut => 'Sair';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonOk => 'OK';

  @override
  String get commonSaving => 'Salvando…';

  @override
  String get commonSave => 'Salvar';

  @override
  String get commonSaveChanges => 'Salvar alterações';

  @override
  String get commonChange => 'Alterar';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonBack => 'Voltar';

  @override
  String get commonTryAgain => 'Tentar de novo';

  @override
  String get commonChecking => 'Verificando…';

  @override
  String get commonCreating => 'Criando…';

  @override
  String get commonAdd => 'Adicionar';

  @override
  String get commonRemove => 'Remover';

  @override
  String get commonClose => 'Fechar';

  @override
  String get commonGotIt => 'Entendi';

  @override
  String get commonGenericFailure =>
      'Não foi possível concluir agora. Tente de novo.';

  @override
  String get deletionRestoredAccountTitle => 'Sua conta está de volta';

  @override
  String deletionRestoredOrganizationTitle(String name) {
    return 'A $name está de volta';
  }

  @override
  String deletionPendingAccountTitle(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'em $days dias',
      one: 'em 1 dia',
      zero: 'hoje',
    );
    return 'Sua conta será excluída $_temp0';
  }

  @override
  String deletionPendingOrganizationTitle(String name, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'em $days dias',
      one: 'em 1 dia',
      zero: 'hoje',
    );
    return 'A $name será excluída $_temp0';
  }

  @override
  String get deletionRestoredBody =>
      'Nada foi apagado. Entre para continuar de onde parou.';

  @override
  String deletionPendingAccountBody(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Em $dateString apagamos de vez sua conta e seus dados no MonAmie.';
  }

  @override
  String deletionPendingOrganizationBody(DateTime date, String name) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Em $dateString apagamos de vez a $name, os grupos, o histórico de todos e a sua conta. Até lá ninguém usa a organização.';
  }

  @override
  String get deletionEnter => 'Entrar';

  @override
  String get deletionCancelAccount => 'Cancelar exclusão da conta';

  @override
  String get deletionCancel => 'Cancelar exclusão';

  @override
  String get myAccountTitle => 'Minha conta';

  @override
  String get myAccountDeleteHeading => 'Excluir conta';

  @override
  String myAccountOwnerLeaves(String name) {
    return 'Você é titular da $name, então a organização inteira é excluída junto com a sua conta.';
  }

  @override
  String myAccountMemberLeaves(String name) {
    return 'Você sai da $name agora e deixa de aparecer no mapa.';
  }

  @override
  String myAccountEraseOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Em $dateString apagamos de vez sua conta e seus dados no MonAmie.';
  }

  @override
  String get myAccountUndo =>
      'Até lá, é só entrar de novo e cancelar a exclusão.';

  @override
  String get myAccountDeleteWithOrganization => 'Excluir conta e organização';

  @override
  String get myAccountDelete => 'Excluir conta';

  @override
  String myAccountConfirmPrompt(String id) {
    return 'Para confirmar, digite $id';
  }

  @override
  String get adminOrganizationFallback => 'organização';

  @override
  String get loggingOut => 'Encerrando sessão…';

  @override
  String get switchingOrganization => 'Trocando de organização…';

  @override
  String get administratorsTitle => 'Administradores';

  @override
  String get administratorsIntro =>
      'Quem administra cuida de todos os grupos, dos convites, da aparência e dos ajustes da organização, e vê todos os grupos no mapa. Só você, titular, escolhe quem administra.';

  @override
  String get administratorsOwner => 'Titular';

  @override
  String get administratorsAdministers => 'Administra a organização';

  @override
  String get administratorsMakeMember => 'Tornar membro';

  @override
  String get administratorsNone => 'Ninguém administra a organização.';

  @override
  String get administratorsMembers => 'Membros';

  @override
  String get administratorsMember => 'Membro';

  @override
  String get administratorsMakeAdmin => 'Tornar administrador';

  @override
  String get administratorsNoMembers =>
      'Ninguém mais na organização ainda. Quem aceitar um convite para um grupo aparece aqui.';

  @override
  String administratorsSection(String title, int count) {
    return '$title · $count';
  }

  @override
  String administratorsPromoteTitle(String email) {
    return 'Tornar $email administrador?';
  }

  @override
  String get administratorsPromoteSees =>
      'Passa a ver todos os grupos no mapa e a cuidar dos grupos, dos convites, da aparência e dos ajustes da organização.';

  @override
  String get administratorsUndoLater => 'Você pode desfazer depois.';

  @override
  String administratorsPromoted(String email) {
    return '$email agora administra a organização';
  }

  @override
  String administratorsDemoteTitle(String email) {
    return 'Tornar $email membro?';
  }

  @override
  String get administratorsDemoteStops =>
      'Deixa de administrar a organização e de ver os grupos em que não está.';

  @override
  String get administratorsDemoteStays =>
      'Continua nos grupos em que já está. Se não estiver em nenhum, continua na organização sem ver o mapa até ser convidado para um grupo.';

  @override
  String administratorsDemoted(String email) {
    return '$email agora é membro';
  }

  @override
  String get appearanceTitle => 'Aparência';

  @override
  String get appearanceYouAdminister => 'Você administra esta organização';

  @override
  String get appearanceName => 'Nome';

  @override
  String get appearanceLogo => 'Logo';

  @override
  String get appearanceNoLogo => 'Sem logo · usamos a inicial';

  @override
  String get appearanceLogoSaved => 'PNG quadrado de 512 px';

  @override
  String get appearanceLogoNew => 'Novo logo · salve para aplicar';

  @override
  String get appearanceLogoFormats => 'SVG, PNG, JPEG ou WebP';

  @override
  String get appearanceTheme => 'Tema';

  @override
  String get appearanceNextLaunch =>
      'A equipe vê a nova aparência na próxima vez que abrir o app.';

  @override
  String get appearanceSaved => 'Aparência salva';

  @override
  String get appearanceNameDialog => 'Nome da organização';

  @override
  String get appearanceLogoError => 'Não deu para usar este arquivo';

  @override
  String get appearanceLogoPreview => 'Assim fica o logo';

  @override
  String get appearanceLogoSheet => 'Logo da organização';

  @override
  String get appearanceConverting => 'Convertendo para PNG no seu celular';

  @override
  String get appearanceUseLogo => 'Usar este logo';

  @override
  String get appearanceLogoExplained =>
      'Convertemos o arquivo para um PNG quadrado de 512 px. É assim que ele aparece no topo do app, no menu e na lista de organizações.';

  @override
  String get loginWithGoogle => 'Entrar com o Google';

  @override
  String get loginLookingForOrganization => 'Procurando sua organização…';

  @override
  String loginEntering(String name) {
    return 'Entrando em $name…';
  }

  @override
  String get accountHeaderSwitch => 'Trocar';

  @override
  String get inviteCardTitle => 'Você tem um convite';

  @override
  String get inviteSomeone => 'Alguém';

  @override
  String inviteCardBody(String inviter, String group, String role) {
    String _temp0 = intl.Intl.selectLogic(role, {
      'both': 'em campo e vendo o mapa',
      'publisher': 'em campo',
      'other': 'vendo o mapa',
    });
    return '$inviter chamou você para o grupo $group, $_temp0.';
  }

  @override
  String inviteCardValidUntil(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Vale até $dateString.';
  }

  @override
  String inviteCardEntering(String name) {
    return 'Entrando na $name…';
  }

  @override
  String get inviteCardAccept => 'Aceitar e entrar';

  @override
  String get noOrganizationTitle =>
      'Você ainda não faz parte de uma organização';

  @override
  String get noOrganizationBody =>
      'Crie a da sua equipe agora ou peça para alguém dela adicionar você.';

  @override
  String get noOrganizationFast => 'Nome e tema em menos de 2 minutos';

  @override
  String get noOrganizationYouAdminister =>
      'Você administra e convida a equipe';

  @override
  String get noOrganizationLater =>
      'O logo e a aparência você ajusta depois, no app';

  @override
  String get noOrganizationCreate => 'Criar minha organização';

  @override
  String get noOrganizationRecheck => 'Já me convidaram · verificar de novo';

  @override
  String get pickerTitle => 'Em qual organização você quer entrar?';

  @override
  String pickerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Você participa de $count. Dá para trocar depois pelo menu.',
      one: 'Você participa de 1 organização.',
      zero: 'Você participa de 0. Dá para trocar depois pelo menu.',
    );
    return '$_temp0';
  }

  @override
  String get pickerCreate => 'Criar nova organização';

  @override
  String get creationTitle => 'Nova organização';

  @override
  String creationStep(int step, int count) {
    return '$step de $count';
  }

  @override
  String creationReadyTitle(String name) {
    return 'A $name está pronta';
  }

  @override
  String get creationReadyBody =>
      'O app já aparece com o nome e o tema de vocês. O logo você adiciona quando quiser, em Aparência. Próximo passo: chame sua equipe em Grupos.';

  @override
  String creationReadyEnter(String name) {
    return 'Entrar na $name';
  }

  @override
  String get creationBillingTitle => 'Falta ativar o faturamento';

  @override
  String creationBillingBody(String name, String id) {
    return 'A $name roda num projeto do Google Cloud pago pela sua organização. Entre no Google Cloud com esta mesma Conta Google, escolha ou crie uma conta de faturamento e vincule ao projeto monamienet-$id. O identificador fica reservado por 7 dias.';
  }

  @override
  String creationFailedTitle(String name) {
    return 'Algo deu errado ao criar a $name';
  }

  @override
  String creationFailedBody(String id) {
    return 'Não é nada que você precise fazer. A equipe do MonAmie já foi avisada e vai terminar a criação. O identificador $id continua reservado para vocês enquanto isso.';
  }

  @override
  String get creationNameTitle => 'Como sua organização se chama?';

  @override
  String get creationNameSubtitle =>
      'Use o nome que a equipe reconhece: da empresa, do grupo ou do projeto.';

  @override
  String get creationNameLabel => 'Nome da organização';

  @override
  String creationNamePreview(String name) {
    return 'Sua equipe vai ver $name no topo do app';
  }

  @override
  String get creationIdLabel => 'Identificador';

  @override
  String get creationIdAdjusted =>
      'Ajustamos para letras minúsculas, sem acentos, espaços ou números.';

  @override
  String get creationIdRules =>
      'Só letras minúsculas, sem acentos, espaços ou números. É o código da organização no MonAmie.';

  @override
  String get creationIdPermanent =>
      'O identificador não muda depois. O nome pode mudar.';

  @override
  String get creationIdTooShort => 'Mínimo 3 letras';

  @override
  String get creationIdAvailable => 'Disponível';

  @override
  String get planCommunity => 'Community';

  @override
  String get planStandard => 'Standard';

  @override
  String get creationPlanTitle => 'Escolha um plano';

  @override
  String creationPlanSubtitle(String name) {
    return 'Os dois têm o mapa, os grupos e a aparência da $name. Muda onde os dados ficam e quem paga.';
  }

  @override
  String get creationPlanFree => 'Grátis';

  @override
  String get creationPlanCommunityTagline =>
      'Para começar agora, sem cadastrar pagamento.';

  @override
  String get creationPlanCommunityReady => 'Pronta em instantes';

  @override
  String get creationPlanCommunityData =>
      'Dados guardados pela MonAmie, separados das outras organizações';

  @override
  String get creationPlanCommunityInterval =>
      'Localização enviada a cada 15 min (perfil Economia)';

  @override
  String get creationPlanGoogleUsage => 'Uso no Google';

  @override
  String get creationPlanStandardTagline =>
      'Para quem quer o próprio espaço de dados e mais precisão.';

  @override
  String creationPlanStandardProject(String name) {
    return 'Projeto Firebase só da $name';
  }

  @override
  String get creationPlanStandardProfiles =>
      'Todos os perfis de acompanhamento, até a cada 1 min';

  @override
  String get creationPlanStandardBilling =>
      'Pede uma conta de faturamento do Google Cloud; vocês pagam o uso direto ao Google';

  @override
  String get creationPlanSwitchLater =>
      'Dá para passar do Community para o Standard depois, sem perder grupos nem histórico.';

  @override
  String creationPlanContinue(String plan) {
    return 'Continuar com $plan';
  }

  @override
  String get creationReviewTitle => 'Tudo certo?';

  @override
  String get creationReviewTeamSees => 'Sua equipe vai ver';

  @override
  String get creationReviewName => 'Nome';

  @override
  String get creationReviewTheme => 'Tema';

  @override
  String get creationReviewPlan => 'Plano';

  @override
  String get creationReviewOwnerTitle => 'Você será titular';

  @override
  String creationReviewOwnerBody(String email) {
    return '$email vai administrar a organização: convidar pessoas, criar grupos, mudar a aparência e adicionar o logo. Depois, outras pessoas também podem administrar.';
  }

  @override
  String creationTermsAccept(String terms) {
    return 'Li e aceito os $terms.';
  }

  @override
  String get creationTerms => 'Termos para organizações';

  @override
  String get creationCreate => 'Criar organização';

  @override
  String get creationThemeTitle => 'Escolha um tema';

  @override
  String get creationThemeSubtitle =>
      'Cada tema já traz os tons do app, com contraste garantido para textos e botões.';

  @override
  String get creationThemePreview => 'Prévia do app com o tema';

  @override
  String get creationPreviewGroup => 'Motoristas';

  @override
  String get creationPreviewSharing => 'Compartilhando';

  @override
  String get createGroupTitle => 'Novo grupo';

  @override
  String get createGroupHeading => 'Criar um grupo';

  @override
  String get groupNameLabel => 'Nome do grupo';

  @override
  String get groupNameHint => 'Ex.: Motoristas';

  @override
  String get groupNameHelper =>
      'É assim que o grupo aparece no mapa e nos convites.';

  @override
  String get createGroupNote =>
      'Você administra a organização, então já vê todos os grupos no mapa. O grupo nasce vazio: depois de criar, convide quem vai fazer parte dele.';

  @override
  String get createGroupButton => 'Criar grupo';

  @override
  String get createGroupDone => 'Grupo criado';

  @override
  String createGroupDoneBody(String group) {
    return '$group ainda não tem ninguém. Convide as pessoas que vão trabalhar nele e escolha o que cada uma faz no app.';
  }

  @override
  String get createGroupOpen => 'Ver o grupo';

  @override
  String get rolePublisher => 'Em campo';

  @override
  String get rolePublisherDescription => 'Compartilha a própria localização';

  @override
  String get roleSubscriber => 'Vê o mapa';

  @override
  String get roleSubscriberDescription => 'Vê quem está em campo';

  @override
  String get roleMaintainer => 'Gestor do grupo';

  @override
  String get roleMaintainerDescription =>
      'Cuida das pessoas e dos convites do grupo';

  @override
  String peopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pessoas',
      one: '1 pessoa',
      zero: 'Ninguém ainda',
    );
    return '$_temp0';
  }

  @override
  String pendingInvites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count convites pendentes',
      one: '1 convite pendente',
      zero: '0 convites pendentes',
    );
    return '$_temp0';
  }

  @override
  String inviteValidUntil(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Vale até $dateString';
  }

  @override
  String get inviteExpired => 'Expirado';

  @override
  String inviteExpiredOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Expirado · venceu em $dateString';
  }

  @override
  String get invitesResend => 'Reenviar';

  @override
  String get invitesNone => 'Nenhum convite pendente.';

  @override
  String get invitesResendTitle => 'Reenviar o convite?';

  @override
  String get invitesResendConfirm => 'Reenviar convite';

  @override
  String get invitesResending => 'Reenviando…';

  @override
  String invitesResendEmail(String email) {
    return '$email recebe um novo e-mail.';
  }

  @override
  String get invitesResendValid => 'O novo convite vale por 14 dias.';

  @override
  String get invitesResent => 'Convite reenviado';

  @override
  String get invitesCancelTitle => 'Cancelar o convite?';

  @override
  String get invitesCancelConfirm => 'Cancelar convite';

  @override
  String get invitesCancelling => 'Cancelando…';

  @override
  String invitesCancelLink(String email) {
    return 'O link enviado para $email deixa de funcionar.';
  }

  @override
  String get invitesInviteAgain => 'Você pode convidar de novo depois.';

  @override
  String get invitesCancelled => 'Convite cancelado';

  @override
  String groupPersonEditRoles(String name) {
    return 'Mudar o que $name faz';
  }

  @override
  String groupDeletionLoses(int count, String organization) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count pessoas só estavam neste grupo e perdem o acesso à $organization.',
      one: '1 pessoa só estava neste grupo e perde o acesso à $organization.',
      zero:
          '0 pessoas só estavam neste grupo e perdem o acesso à $organization.',
    );
    return '$_temp0';
  }

  @override
  String groupDeletionStays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pessoas continuam nos outros grupos.',
      one: '1 pessoa continua nos outros grupos.',
      zero: '0 pessoas continuam nos outros grupos.',
    );
    return '$_temp0';
  }

  @override
  String groupDeletionInvites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Os $count convites pendentes são cancelados.',
      one: 'O convite pendente é cancelado.',
      zero: 'Os 0 convites pendentes são cancelados.',
    );
    return '$_temp0';
  }

  @override
  String get groupDeletionTrails =>
      'Os trajetos publicados neste grupo são apagados junto. Não dá para desfazer.';

  @override
  String groupDeletedLost(int count, String organization) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pessoas perderam o acesso à $organization.',
      one: '1 pessoa perdeu o acesso à $organization.',
      zero: '0 pessoas perderam o acesso à $organization.',
    );
    return '$_temp0';
  }

  @override
  String get groupDeletedOthersStay =>
      'Quem estava em outros grupos continua neles.';

  @override
  String get presetEconomia => 'Economia';

  @override
  String get presetEquilibrio => 'Equilíbrio';

  @override
  String get presetPrecisao => 'Precisão';

  @override
  String get presetPersonalizado => 'Personalizado';

  @override
  String get groupPeopleEmpty =>
      'Ninguém neste grupo ainda. Convide quem vai trabalhar nele.';

  @override
  String groupRolesTitle(String email) {
    return 'O que $email faz';
  }

  @override
  String get groupRolesImmediate => 'A mudança vale na hora.';

  @override
  String get groupRolesUpdated => 'Papel atualizado';

  @override
  String groupRemoveTitle(String email, String group) {
    return 'Remover $email de $group?';
  }

  @override
  String get groupRemoving => 'Removendo…';

  @override
  String groupRemoveAccess(String organization) {
    return 'Se este for o único grupo da pessoa, o acesso à $organization acaba (a não ser que ela administre a organização).';
  }

  @override
  String get groupRemoveMap =>
      'Deixa de aparecer no mapa deste grupo e de ver quem está nele.';

  @override
  String get groupRemoveHistory =>
      'Os trajetos antigos continuam no histórico.';

  @override
  String groupRemoved(String email) {
    return '$email não faz mais parte do grupo';
  }

  @override
  String get groupTitle => 'Grupo';

  @override
  String get groupNotFound => 'Grupo não encontrado.';

  @override
  String get groupRename => 'Renomear';

  @override
  String groupTabPeople(int count) {
    return 'No grupo · $count';
  }

  @override
  String groupTabInvited(String count) {
    return 'Convidados · $count';
  }

  @override
  String get groupInvite => 'Convidar para este grupo';

  @override
  String get groupDelete => 'Excluir grupo';

  @override
  String get groupDeleted => 'Grupo excluído';

  @override
  String get groupSeeGroups => 'Ver grupos';

  @override
  String get groupRenameTitle => 'Renomear grupo';

  @override
  String get groupRenameConfirm => 'Salvar nome';

  @override
  String get groupRenameNote => 'As pessoas do grupo veem o novo nome na hora.';

  @override
  String get groupRenamed => 'Grupo renomeado';

  @override
  String groupDeleteTitle(String group) {
    return 'Excluir $group?';
  }

  @override
  String get groupDeleting => 'Excluindo…';

  @override
  String get groupsTitle => 'Grupos';

  @override
  String get groupsEmptyAdmin =>
      'Sua organização ainda não tem grupos. Crie o primeiro e convide quem vai trabalhar nele.';

  @override
  String get groupsEmptyMaintainer =>
      'Você não é gestor de nenhum grupo agora.';

  @override
  String get calendarPreviousMonth => 'Mês anterior';

  @override
  String get calendarNextMonth => 'Próximo mês';

  @override
  String get calendarDaysWithTrails => 'Dias com trajetos';

  @override
  String calendarDayLabel(DateTime date, String today, String status) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    String _temp0 = intl.Intl.selectLogic(today, {
      'yes': ', hoje',
      'other': '',
    });
    String _temp1 = intl.Intl.selectLogic(status, {
      'future': ', ainda não chegou',
      'trails': ', com trajetos',
      'other': ', sem trajetos',
    });
    return '$dateString$_temp0$_temp1';
  }

  @override
  String get permissionBackgroundUsage =>
      'O seu aparelho está restringindo o aplicativo em segundo plano. Assim, o rastreamento é desabilitado quando você sai do aplicativo ou desliga a tela.\n\nComo ajustar:\n1. Toque em \'Prosseguir\'.\n2. Ative \'Permitir o uso em segundo plano\' (ou escolha \'Sem restrições\').\n3. Volte para o aplicativo.\n\nSe abrir a tela de informações do app, toque antes em \'Uso da bateria pelo app\' (ou \'Bateria\'). Se o interruptor já aparecer ativado, desative-o e ative-o novamente.';

  @override
  String get permissionBackgroundLocation =>
      'O app deseja coletar dados de localização mesmo quando o aplicativo estiver fechado ou não estiver em uso.\n\nEsses dados permitem que um grupo de pessoas, determinado e gerenciado pela sua empresa, visualize sua posição em tempo real.\n\nComo ativar:\n1. Toque em \'Prosseguir\'.\n2. Em Permissões > Localização.\n3. Selecione \'Permitir o tempo todo\'.';

  @override
  String get permissionGpsOffTitle => 'O GPS está desativado';

  @override
  String get permissionGpsOffBody => 'Por favor, ative o GPS para continuar.';

  @override
  String get permissionGotIt => 'ENTENDI';

  @override
  String get permissionAttention => 'Atenção';

  @override
  String get permissionNotNow => 'AGORA NÃO';

  @override
  String get permissionContinue => 'PROSSEGUIR';

  @override
  String mapGroupChip(String group) {
    return 'Grupo no mapa: $group';
  }

  @override
  String get mapSeeOnMap => 'VER NO MAPA';

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
  String get mapNoGroups => 'Nenhum grupo disponível';

  @override
  String memberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pessoas',
      one: '1 pessoa',
      zero: '0 pessoas',
    );
    return '$_temp0';
  }

  @override
  String get homeMenuTooltip => 'Menu';

  @override
  String homeGroupChip(String group) {
    return 'Grupo: $group';
  }

  @override
  String homeDayChip(String day) {
    return 'Histórico por data, $day';
  }

  @override
  String get homeBackToToday => 'Voltar para hoje';

  @override
  String get dayToday => 'Hoje';

  @override
  String get dayYesterday => 'Ontem';

  @override
  String get homeChooseGroup => 'Escolher grupo';

  @override
  String get homeNoGroup => 'Sem grupo';

  @override
  String homeMoreGroups(String group, int more) {
    return '$group +$more';
  }

  @override
  String get menuAdministers => 'Administra a organização';

  @override
  String get menuWatchesAndShares => 'Acompanha e compartilha';

  @override
  String get menuWatches => 'Acompanha o mapa';

  @override
  String menuInTheField(String group) {
    return '$group · em campo';
  }

  @override
  String get menuSwitchOrganization => 'Trocar de organização';

  @override
  String get menuMyAccount => 'Minha conta';

  @override
  String get menuGroupManagement => 'GESTÃO DE GRUPOS';

  @override
  String get menuMyGroups => 'Meus grupos';

  @override
  String get menuAdministration => 'ADMINISTRAÇÃO';

  @override
  String get menuAppearance => 'Aparência da organização';

  @override
  String get menuTrackingSettings => 'Ajustes de acompanhamento';

  @override
  String homeLoadingGroup(String group) {
    return 'Carregando $group…';
  }

  @override
  String get homeAllowNotification => 'Permitir notificação';

  @override
  String get homeAllowLocationWhileInUse =>
      'Permitir localização (durante uso)';

  @override
  String get homeAllowLocationAlways => 'Permitir localização (sempre)';

  @override
  String get homeAllowBackground => 'Permitir uso em segundo plano';

  @override
  String get mapAttribution => 'OpenStreetMap contributors';

  @override
  String get sheetShowList => 'Mostrar a lista do grupo';

  @override
  String get sheetHideList => 'Recolher a lista do grupo';

  @override
  String get sheetNoGroup => 'Nenhum grupo escolhido';

  @override
  String get sheetEmptyGroup =>
      'Ninguém neste grupo ainda. Convide quem vai trabalhar nele para ver todos no mapa.';

  @override
  String get invitePeople => 'Convidar pessoas';

  @override
  String personHideTrail(String name) {
    return 'Esconder trajeto de $name';
  }

  @override
  String personShowTrail(String name) {
    return 'Mostrar trajeto de $name';
  }

  @override
  String personTrailVisible(String presence) {
    return '$presence · trajeto visível';
  }

  @override
  String personCallOnMeet(String name) {
    return 'Chamar $name no Meet';
  }

  @override
  String get presenceNever => 'Ainda não ativou a localização';

  @override
  String get presenceOff => 'Localização desligada';

  @override
  String presenceOffSeen(String ago) {
    return 'Localização desligada · visto $ago';
  }

  @override
  String get presenceLive => 'Agora';

  @override
  String get agoNow => 'agora';

  @override
  String agoMinutes(int minutes) {
    return 'há $minutes min';
  }

  @override
  String agoHours(int hours) {
    return 'há $hours h';
  }

  @override
  String get agoYesterday => 'ontem';

  @override
  String agoDays(int days) {
    return 'há $days dias';
  }

  @override
  String get presenceDayPoints => 'Tem posições neste dia';

  @override
  String get presenceDayNoPoints => 'Sem posições neste dia';

  @override
  String get shareStopping => 'Desativando compartilhamento…';

  @override
  String get shareStarting => 'Ativando compartilhamento…';

  @override
  String get shareWait => 'Aguarde um instante';

  @override
  String get shareOn => 'Compartilhando sua localização';

  @override
  String get shareOnSubtitle => 'Seus grupos veem você no mapa';

  @override
  String get shareOff => 'Localização desligada';

  @override
  String get shareOffSubtitle => 'Seus grupos não veem você no mapa';

  @override
  String get inviteFirstGroupTitle => 'Crie seu primeiro grupo';

  @override
  String get inviteFirstGroupBody =>
      'Toda pessoa entra num grupo. Dê um nome para o primeiro; você cria outros depois, em Grupos.';

  @override
  String get inviteWhichGroup => 'Para qual grupo?';

  @override
  String inviteGroupOption(String group, String people) {
    return '$group · $people';
  }

  @override
  String get inviteWho => 'Quem você quer chamar?';

  @override
  String get inviteEmailHint => 'email@exemplo.com';

  @override
  String get inviteRolesQuestion => 'O que cada pessoa faz? Uma ou as duas.';

  @override
  String get inviteRolesExplained =>
      'Em campo compartilha a própria localização. Vê o mapa vê quem está em campo.';

  @override
  String get inviteHowItWorks =>
      'Cada pessoa recebe um e-mail e entra no app com essa Conta Google. A localização só é compartilhada depois que ela ativar no próprio celular.';

  @override
  String get inviteSending => 'Enviando…';

  @override
  String inviteSend(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Enviar $count convites',
      one: 'Enviar convite',
      zero: 'Enviar convite',
    );
    return '$_temp0';
  }

  @override
  String inviteRemovePerson(String email) {
    return 'Tirar $email';
  }

  @override
  String get inviteNoRole => 'Marque pelo menos uma opção.';

  @override
  String inviteSent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count convites enviados',
      one: 'Convite enviado',
      zero: '0 convites enviados',
    );
    return '$_temp0';
  }

  @override
  String inviteSentBody(String group) {
    return 'Para $group. Vale por 14 dias; acompanhe em Grupos.';
  }

  @override
  String get inviteNotEmailed =>
      'O e-mail não saiu agora; a pessoa vê o convite ao entrar no app com essa conta.';

  @override
  String get inviteMore => 'Convidar mais pessoas';

  @override
  String welcomeJoined(String name) {
    return 'Você entrou na $name';
  }

  @override
  String welcomeInvitedBy(String group, String inviter) {
    return '$group · convite de $inviter';
  }

  @override
  String get welcomeWhatYouDo => 'O que você faz no app';

  @override
  String get welcomePublisher =>
      'Seus grupos veem onde você está enquanto o compartilhamento estiver ligado. Você liga e desliga quando quiser.';

  @override
  String welcomeSubscriber(String group) {
    return 'Você acompanha no mapa quem está em campo em $group.';
  }

  @override
  String get welcomeTurnOnLocation => 'Ativar minha localização';

  @override
  String get welcomeOpenMap => 'Abrir o mapa';

  @override
  String get welcomeLater => 'Ativar depois';

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
      'Com que frequência a equipe envia a localização?';

  @override
  String trackingAppliesTo(String name) {
    return 'Vale para todos da $name que estão em campo.';
  }

  @override
  String trackingCommunityLimit(int minutes) {
    return 'No plano Community, a localização é enviada no máximo a cada $minutes min.';
  }

  @override
  String get trackingInterval => 'Intervalo';

  @override
  String trackingEvery(String interval) {
    return 'a cada $interval';
  }

  @override
  String get trackingDistance => 'Distância mínima';

  @override
  String trackingMeters(int meters) {
    return '$meters m';
  }

  @override
  String trackingPositionsPerHour(int count, int meters) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Até $count posições',
      one: 'Até 1 posição',
      zero: 'Até 0 posições',
    );
    return '$_temp0 por hora, só quando a pessoa se mover $meters m ou mais.';
  }

  @override
  String trackingLeavesMap(String duration) {
    return 'Quem ficar $duration sem dar notícia sai do mapa.';
  }

  @override
  String trackingBattery(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      'low': 'Baixo',
      'medium': 'Médio',
      'other': 'Alto',
    });
    return 'Uso de bateria: $_temp0';
  }

  @override
  String get trackingSaved =>
      'Salvo. A equipe recebe em instantes, sem desligar o compartilhamento.';

  @override
  String get trackingNoChanges => 'Nenhuma alteração';

  @override
  String get trackingCustomDescription => 'Você escolhe intervalo e distância';

  @override
  String trackingPresetDescription(int minutes, int meters) {
    return 'A cada $minutes min, se andar $meters m';
  }

  @override
  String get trackingInUse => 'Em uso';
}
