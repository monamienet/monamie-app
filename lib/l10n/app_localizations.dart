import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  /// MonAmie's tagline under its logo on the sign-in screen.
  ///
  /// In pt, this message translates to:
  /// **'Sua equipe, no mesmo ponto.'**
  String get loginTagline;

  /// Button or menu item that signs the person out of the app.
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get commonSignOut;

  /// Button that closes a dialog or sheet without doing anything.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// Button that confirms a short dialog.
  ///
  /// In pt, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// Label of a save button while the change is being saved.
  ///
  /// In pt, this message translates to:
  /// **'Salvando…'**
  String get commonSaving;

  /// Button that saves a change.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get commonSave;

  /// Button that saves the changes made on a settings screen.
  ///
  /// In pt, this message translates to:
  /// **'Salvar alterações'**
  String get commonSaveChanges;

  /// Small button that opens an editor for a value.
  ///
  /// In pt, this message translates to:
  /// **'Alterar'**
  String get commonChange;

  /// Button that moves to the next step of a wizard.
  ///
  /// In pt, this message translates to:
  /// **'Continuar'**
  String get commonContinue;

  /// Button or tooltip that goes back to the previous screen or step.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get commonBack;

  /// Button that retries an action that failed.
  ///
  /// In pt, this message translates to:
  /// **'Tentar de novo'**
  String get commonTryAgain;

  /// Shown while something is being checked with the server.
  ///
  /// In pt, this message translates to:
  /// **'Verificando…'**
  String get commonChecking;

  /// Label of a create button while the item is being created.
  ///
  /// In pt, this message translates to:
  /// **'Criando…'**
  String get commonCreating;

  /// Button that adds an item (a logo, a person to a list).
  ///
  /// In pt, this message translates to:
  /// **'Adicionar'**
  String get commonAdd;

  /// Button that removes an item.
  ///
  /// In pt, this message translates to:
  /// **'Remover'**
  String get commonRemove;

  /// Button that closes a sheet.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get commonClose;

  /// Button that dismisses an informative message.
  ///
  /// In pt, this message translates to:
  /// **'Entendi'**
  String get commonGotIt;

  /// Shown in a confirmation sheet when the action failed without a message of its own.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível concluir agora. Tente de novo.'**
  String get commonGenericFailure;

  /// Title after a person cancels the deletion of their account.
  ///
  /// In pt, this message translates to:
  /// **'Sua conta está de volta'**
  String get deletionRestoredAccountTitle;

  /// Title after the owner cancels the deletion of their account and organization.
  ///
  /// In pt, this message translates to:
  /// **'A {name} está de volta'**
  String deletionRestoredOrganizationTitle(String name);

  /// Title while a person's account waits to be deleted; days is how many days are left.
  ///
  /// In pt, this message translates to:
  /// **'Sua conta será excluída {days, plural, =0{hoje} =1{em 1 dia} other{em {days} dias}}'**
  String deletionPendingAccountTitle(int days);

  /// Title while the owner's organization waits to be deleted with their account; days is how many days are left.
  ///
  /// In pt, this message translates to:
  /// **'A {name} será excluída {days, plural, =0{hoje} =1{em 1 dia} other{em {days} dias}}'**
  String deletionPendingOrganizationTitle(String name, int days);

  /// Text under the title after a deletion is cancelled.
  ///
  /// In pt, this message translates to:
  /// **'Nada foi apagado. Entre para continuar de onde parou.'**
  String get deletionRestoredBody;

  /// Text under the title while a person's account waits to be deleted.
  ///
  /// In pt, this message translates to:
  /// **'Em {date} apagamos de vez sua conta e seus dados no MonAmie.'**
  String deletionPendingAccountBody(DateTime date);

  /// Text under the title while the owner's organization waits to be deleted.
  ///
  /// In pt, this message translates to:
  /// **'Em {date} apagamos de vez a {name}, os grupos, o histórico de todos e a sua conta. Até lá ninguém usa a organização.'**
  String deletionPendingOrganizationBody(DateTime date, String name);

  /// Button that enters the app after a deletion was cancelled.
  ///
  /// In pt, this message translates to:
  /// **'Entrar'**
  String get deletionEnter;

  /// Button that cancels the pending deletion of the person's account.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar exclusão da conta'**
  String get deletionCancelAccount;

  /// Button that cancels the pending deletion of the account and the organization.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar exclusão'**
  String get deletionCancel;

  /// Title of the account screen.
  ///
  /// In pt, this message translates to:
  /// **'Minha conta'**
  String get myAccountTitle;

  /// Heading of the account deletion section.
  ///
  /// In pt, this message translates to:
  /// **'Excluir conta'**
  String get myAccountDeleteHeading;

  /// Explains to the owner what deleting their account does.
  ///
  /// In pt, this message translates to:
  /// **'Você é titular da {name}, então a organização inteira é excluída junto com a sua conta.'**
  String myAccountOwnerLeaves(String name);

  /// Explains to a member what deleting their account does.
  ///
  /// In pt, this message translates to:
  /// **'Você sai da {name} agora e deixa de aparecer no mapa.'**
  String myAccountMemberLeaves(String name);

  /// When the account is erased for good, 30 days from now.
  ///
  /// In pt, this message translates to:
  /// **'Em {date} apagamos de vez sua conta e seus dados no MonAmie.'**
  String myAccountEraseOn(DateTime date);

  /// How to undo an account deletion.
  ///
  /// In pt, this message translates to:
  /// **'Até lá, é só entrar de novo e cancelar a exclusão.'**
  String get myAccountUndo;

  /// Button that deletes the owner's account and organization.
  ///
  /// In pt, this message translates to:
  /// **'Excluir conta e organização'**
  String get myAccountDeleteWithOrganization;

  /// Button that deletes the person's account.
  ///
  /// In pt, this message translates to:
  /// **'Excluir conta'**
  String get myAccountDelete;

  /// Asks the owner to type the organization's id to confirm the deletion.
  ///
  /// In pt, this message translates to:
  /// **'Para confirmar, digite {id}'**
  String myAccountConfirmPrompt(String id);

  /// Stands for the organization's name in a sentence before one is bound.
  ///
  /// In pt, this message translates to:
  /// **'organização'**
  String get adminOrganizationFallback;

  /// Overlay shown while the person signs out.
  ///
  /// In pt, this message translates to:
  /// **'Encerrando sessão…'**
  String get loggingOut;

  /// Overlay shown while the person switches to another organization.
  ///
  /// In pt, this message translates to:
  /// **'Trocando de organização…'**
  String get switchingOrganization;

  /// Title of the screen where the owner chooses who administers the organization, and of its first section.
  ///
  /// In pt, this message translates to:
  /// **'Administradores'**
  String get administratorsTitle;

  /// Explains on Administradores what administrators do.
  ///
  /// In pt, this message translates to:
  /// **'Quem administra cuida de todos os grupos, dos convites, da aparência e dos ajustes da organização, e vê todos os grupos no mapa. Só você, titular, escolhe quem administra.'**
  String get administratorsIntro;

  /// Under the owner's e-mail: the person who created the organization. Gender-neutral in Portuguese.
  ///
  /// In pt, this message translates to:
  /// **'Titular'**
  String get administratorsOwner;

  /// Under an administrator's e-mail.
  ///
  /// In pt, this message translates to:
  /// **'Administra a organização'**
  String get administratorsAdministers;

  /// Button that turns an administrator back into a member.
  ///
  /// In pt, this message translates to:
  /// **'Tornar membro'**
  String get administratorsMakeMember;

  /// Shown when the administrators list is empty.
  ///
  /// In pt, this message translates to:
  /// **'Ninguém administra a organização.'**
  String get administratorsNone;

  /// Section of the people who belong to the organization without administering it.
  ///
  /// In pt, this message translates to:
  /// **'Membros'**
  String get administratorsMembers;

  /// Under a member's e-mail.
  ///
  /// In pt, this message translates to:
  /// **'Membro'**
  String get administratorsMember;

  /// Button that makes a member an administrator.
  ///
  /// In pt, this message translates to:
  /// **'Tornar administrador'**
  String get administratorsMakeAdmin;

  /// Shown when the members list is empty.
  ///
  /// In pt, this message translates to:
  /// **'Ninguém mais na organização ainda. Quem aceitar um convite para um grupo aparece aqui.'**
  String get administratorsNoMembers;

  /// A section heading with how many people it lists; title is already in capitals.
  ///
  /// In pt, this message translates to:
  /// **'{title} · {count}'**
  String administratorsSection(String title, int count);

  /// Title of the sheet that confirms making a member an administrator.
  ///
  /// In pt, this message translates to:
  /// **'Tornar {email} administrador?'**
  String administratorsPromoteTitle(String email);

  /// What changes when a member becomes an administrator.
  ///
  /// In pt, this message translates to:
  /// **'Passa a ver todos os grupos no mapa e a cuidar dos grupos, dos convites, da aparência e dos ajustes da organização.'**
  String get administratorsPromoteSees;

  /// Reassures that a change of administrator can be undone.
  ///
  /// In pt, this message translates to:
  /// **'Você pode desfazer depois.'**
  String get administratorsUndoLater;

  /// Toast after making a member an administrator.
  ///
  /// In pt, this message translates to:
  /// **'{email} agora administra a organização'**
  String administratorsPromoted(String email);

  /// Title of the sheet that confirms turning an administrator back into a member.
  ///
  /// In pt, this message translates to:
  /// **'Tornar {email} membro?'**
  String administratorsDemoteTitle(String email);

  /// What changes when an administrator becomes a member.
  ///
  /// In pt, this message translates to:
  /// **'Deixa de administrar a organização e de ver os grupos em que não está.'**
  String get administratorsDemoteStops;

  /// What stays the same when an administrator becomes a member.
  ///
  /// In pt, this message translates to:
  /// **'Continua nos grupos em que já está. Se não estiver em nenhum, continua na organização sem ver o mapa até ser convidado para um grupo.'**
  String get administratorsDemoteStays;

  /// Toast after turning an administrator back into a member.
  ///
  /// In pt, this message translates to:
  /// **'{email} agora é membro'**
  String administratorsDemoted(String email);

  /// Title of the screen where an administrator changes the organization's name, theme and logo.
  ///
  /// In pt, this message translates to:
  /// **'Aparência'**
  String get appearanceTitle;

  /// Under the organization's name on Aparência.
  ///
  /// In pt, this message translates to:
  /// **'Você administra esta organização'**
  String get appearanceYouAdminister;

  /// Label of the organization's name row.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get appearanceName;

  /// Label of the organization's logo row.
  ///
  /// In pt, this message translates to:
  /// **'Logo'**
  String get appearanceLogo;

  /// Logo row when the organization has no logo.
  ///
  /// In pt, this message translates to:
  /// **'Sem logo · usamos a inicial'**
  String get appearanceNoLogo;

  /// Logo row when the saved logo is shown.
  ///
  /// In pt, this message translates to:
  /// **'PNG quadrado de 512 px'**
  String get appearanceLogoSaved;

  /// Logo row when a new logo was picked but not saved yet.
  ///
  /// In pt, this message translates to:
  /// **'Novo logo · salve para aplicar'**
  String get appearanceLogoNew;

  /// Hint with the image formats accepted for the logo.
  ///
  /// In pt, this message translates to:
  /// **'SVG, PNG, JPEG ou WebP'**
  String get appearanceLogoFormats;

  /// Heading of the theme picker.
  ///
  /// In pt, this message translates to:
  /// **'Tema'**
  String get appearanceTheme;

  /// Note on when the changes reach the team; also the text of the toast after saving.
  ///
  /// In pt, this message translates to:
  /// **'A equipe vê a nova aparência na próxima vez que abrir o app.'**
  String get appearanceNextLaunch;

  /// Title of the toast after saving the appearance.
  ///
  /// In pt, this message translates to:
  /// **'Aparência salva'**
  String get appearanceSaved;

  /// Title of the dialog that edits the organization's name.
  ///
  /// In pt, this message translates to:
  /// **'Nome da organização'**
  String get appearanceNameDialog;

  /// Title of the logo sheet when the file could not be converted.
  ///
  /// In pt, this message translates to:
  /// **'Não deu para usar este arquivo'**
  String get appearanceLogoError;

  /// Title of the logo sheet showing the converted logo.
  ///
  /// In pt, this message translates to:
  /// **'Assim fica o logo'**
  String get appearanceLogoPreview;

  /// Title of the logo sheet while it converts the file.
  ///
  /// In pt, this message translates to:
  /// **'Logo da organização'**
  String get appearanceLogoSheet;

  /// Shown while the picked file is converted to a PNG.
  ///
  /// In pt, this message translates to:
  /// **'Convertendo para PNG no seu celular'**
  String get appearanceConverting;

  /// Button that keeps the converted logo.
  ///
  /// In pt, this message translates to:
  /// **'Usar este logo'**
  String get appearanceUseLogo;

  /// Explains the converted logo under its preview.
  ///
  /// In pt, this message translates to:
  /// **'Convertemos o arquivo para um PNG quadrado de 512 px. É assim que ele aparece no topo do app, no menu e na lista de organizações.'**
  String get appearanceLogoExplained;

  /// Text of the Google sign-in button (Android).
  ///
  /// In pt, this message translates to:
  /// **'Entrar com o Google'**
  String get loginWithGoogle;

  /// Shown on the sign-in screen while the person's organizations are looked up.
  ///
  /// In pt, this message translates to:
  /// **'Procurando sua organização…'**
  String get loginLookingForOrganization;

  /// Shown on the sign-in screen while the remembered organization opens.
  ///
  /// In pt, this message translates to:
  /// **'Entrando em {name}…'**
  String loginEntering(String name);

  /// Button next to the signed-in Google account that picks another account.
  ///
  /// In pt, this message translates to:
  /// **'Trocar'**
  String get accountHeaderSwitch;

  /// Small heading of an invite card on the organization screens.
  ///
  /// In pt, this message translates to:
  /// **'Você tem um convite'**
  String get inviteCardTitle;

  /// Stands for the inviter when their name is unknown.
  ///
  /// In pt, this message translates to:
  /// **'Alguém'**
  String get inviteSomeone;

  /// What an invite is for. role is both (shares their location and sees the map), publisher (shares their location) or subscriber (sees the map).
  ///
  /// In pt, this message translates to:
  /// **'{inviter} chamou você para o grupo {group}, {role, select, both{em campo e vendo o mapa} publisher{em campo} other{vendo o mapa}}.'**
  String inviteCardBody(String inviter, String group, String role);

  /// Sentence after an invite's text with the day it expires.
  ///
  /// In pt, this message translates to:
  /// **'Vale até {date}.'**
  String inviteCardValidUntil(DateTime date);

  /// Accept button while the invite is being accepted.
  ///
  /// In pt, this message translates to:
  /// **'Entrando na {name}…'**
  String inviteCardEntering(String name);

  /// Button that accepts an invite and opens the organization.
  ///
  /// In pt, this message translates to:
  /// **'Aceitar e entrar'**
  String get inviteCardAccept;

  /// Title of the screen for a person who belongs to no organization.
  ///
  /// In pt, this message translates to:
  /// **'Você ainda não faz parte de uma organização'**
  String get noOrganizationTitle;

  /// Text under the title of the no-organization screen.
  ///
  /// In pt, this message translates to:
  /// **'Crie a da sua equipe agora ou peça para alguém dela adicionar você.'**
  String get noOrganizationBody;

  /// First bullet about creating an organization.
  ///
  /// In pt, this message translates to:
  /// **'Nome e tema em menos de 2 minutos'**
  String get noOrganizationFast;

  /// Second bullet about creating an organization.
  ///
  /// In pt, this message translates to:
  /// **'Você administra e convida a equipe'**
  String get noOrganizationYouAdminister;

  /// Third bullet about creating an organization.
  ///
  /// In pt, this message translates to:
  /// **'O logo e a aparência você ajusta depois, no app'**
  String get noOrganizationLater;

  /// Button that starts creating an organization.
  ///
  /// In pt, this message translates to:
  /// **'Criar minha organização'**
  String get noOrganizationCreate;

  /// Button that looks up the person's organizations and invites again.
  ///
  /// In pt, this message translates to:
  /// **'Já me convidaram · verificar de novo'**
  String get noOrganizationRecheck;

  /// Title of the organization picker.
  ///
  /// In pt, this message translates to:
  /// **'Em qual organização você quer entrar?'**
  String get pickerTitle;

  /// Under the picker's title: how many organizations the person belongs to.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{Você participa de 0. Dá para trocar depois pelo menu.} =1{Você participa de 1 organização.} other{Você participa de {count}. Dá para trocar depois pelo menu.}}'**
  String pickerCount(int count);

  /// Button at the bottom of the picker that starts creating an organization.
  ///
  /// In pt, this message translates to:
  /// **'Criar nova organização'**
  String get pickerCreate;

  /// Title at the top of the organization creation wizard.
  ///
  /// In pt, this message translates to:
  /// **'Nova organização'**
  String get creationTitle;

  /// Which step of the creation wizard is shown.
  ///
  /// In pt, this message translates to:
  /// **'{step} de {count}'**
  String creationStep(int step, int count);

  /// Title after the organization was created and is active.
  ///
  /// In pt, this message translates to:
  /// **'A {name} está pronta'**
  String creationReadyTitle(String name);

  /// Text after the organization was created. Aparência and Grupos are names of screens in the menu.
  ///
  /// In pt, this message translates to:
  /// **'O app já aparece com o nome e o tema de vocês. O logo você adiciona quando quiser, em Aparência. Próximo passo: chame sua equipe em Grupos.'**
  String get creationReadyBody;

  /// Button that opens the newly created organization.
  ///
  /// In pt, this message translates to:
  /// **'Entrar na {name}'**
  String creationReadyEnter(String name);

  /// Title after a Standard organization was created but has no billing account yet.
  ///
  /// In pt, this message translates to:
  /// **'Falta ativar o faturamento'**
  String get creationBillingTitle;

  /// What to do so that a Standard organization can start.
  ///
  /// In pt, this message translates to:
  /// **'A {name} roda num projeto do Google Cloud pago pela sua organização. Entre no Google Cloud com esta mesma Conta Google, escolha ou crie uma conta de faturamento e vincule ao projeto monamienet-{id}. O identificador fica reservado por 7 dias.'**
  String creationBillingBody(String name, String id);

  /// Title when the creation of the organization failed on the server.
  ///
  /// In pt, this message translates to:
  /// **'Algo deu errado ao criar a {name}'**
  String creationFailedTitle(String name);

  /// Text when the creation of the organization failed on the server.
  ///
  /// In pt, this message translates to:
  /// **'Não é nada que você precise fazer. A equipe do MonAmie já foi avisada e vai terminar a criação. O identificador {id} continua reservado para vocês enquanto isso.'**
  String creationFailedBody(String id);

  /// Title of the name step of the creation wizard.
  ///
  /// In pt, this message translates to:
  /// **'Como sua organização se chama?'**
  String get creationNameTitle;

  /// Subtitle of the name step.
  ///
  /// In pt, this message translates to:
  /// **'Use o nome que a equipe reconhece: da empresa, do grupo ou do projeto.'**
  String get creationNameSubtitle;

  /// Label of the organization name field.
  ///
  /// In pt, this message translates to:
  /// **'Nome da organização'**
  String get creationNameLabel;

  /// Under the name field; name is drawn in bold.
  ///
  /// In pt, this message translates to:
  /// **'Sua equipe vai ver {name} no topo do app'**
  String creationNamePreview(String name);

  /// Label of the organization identifier field.
  ///
  /// In pt, this message translates to:
  /// **'Identificador'**
  String get creationIdLabel;

  /// Shown when the typed identifier was adjusted.
  ///
  /// In pt, this message translates to:
  /// **'Ajustamos para letras minúsculas, sem acentos, espaços ou números.'**
  String get creationIdAdjusted;

  /// Rules of the organization identifier.
  ///
  /// In pt, this message translates to:
  /// **'Só letras minúsculas, sem acentos, espaços ou números. É o código da organização no MonAmie.'**
  String get creationIdRules;

  /// Note that the identifier is permanent.
  ///
  /// In pt, this message translates to:
  /// **'O identificador não muda depois. O nome pode mudar.'**
  String get creationIdPermanent;

  /// Status next to the identifier field when it is too short.
  ///
  /// In pt, this message translates to:
  /// **'Mínimo 3 letras'**
  String get creationIdTooShort;

  /// Status next to the identifier field when no other organization uses it.
  ///
  /// In pt, this message translates to:
  /// **'Disponível'**
  String get creationIdAvailable;

  /// Name of the free plan (a product name, the same in every language).
  ///
  /// In pt, this message translates to:
  /// **'Community'**
  String get planCommunity;

  /// Name of the paid plan (a product name, the same in every language).
  ///
  /// In pt, this message translates to:
  /// **'Standard'**
  String get planStandard;

  /// Title of the plan step of the creation wizard.
  ///
  /// In pt, this message translates to:
  /// **'Escolha um plano'**
  String get creationPlanTitle;

  /// Subtitle of the plan step.
  ///
  /// In pt, this message translates to:
  /// **'Os dois têm o mapa, os grupos e a aparência da {name}. Muda onde os dados ficam e quem paga.'**
  String creationPlanSubtitle(String name);

  /// Price tag of the Community plan.
  ///
  /// In pt, this message translates to:
  /// **'Grátis'**
  String get creationPlanFree;

  /// Who the Community plan is for.
  ///
  /// In pt, this message translates to:
  /// **'Para começar agora, sem cadastrar pagamento.'**
  String get creationPlanCommunityTagline;

  /// First point of the Community plan.
  ///
  /// In pt, this message translates to:
  /// **'Pronta em instantes'**
  String get creationPlanCommunityReady;

  /// Second point of the Community plan.
  ///
  /// In pt, this message translates to:
  /// **'Dados guardados pela MonAmie, separados das outras organizações'**
  String get creationPlanCommunityData;

  /// Third point of the Community plan; Economia is the name of a tracking profile.
  ///
  /// In pt, this message translates to:
  /// **'Localização enviada a cada 15 min (perfil Economia)'**
  String get creationPlanCommunityInterval;

  /// Price tag of the Standard plan: the organization pays Google for what it uses.
  ///
  /// In pt, this message translates to:
  /// **'Uso no Google'**
  String get creationPlanGoogleUsage;

  /// Who the Standard plan is for.
  ///
  /// In pt, this message translates to:
  /// **'Para quem quer o próprio espaço de dados e mais precisão.'**
  String get creationPlanStandardTagline;

  /// First point of the Standard plan.
  ///
  /// In pt, this message translates to:
  /// **'Projeto Firebase só da {name}'**
  String creationPlanStandardProject(String name);

  /// Second point of the Standard plan.
  ///
  /// In pt, this message translates to:
  /// **'Todos os perfis de acompanhamento, até a cada 1 min'**
  String get creationPlanStandardProfiles;

  /// Third point of the Standard plan.
  ///
  /// In pt, this message translates to:
  /// **'Pede uma conta de faturamento do Google Cloud; vocês pagam o uso direto ao Google'**
  String get creationPlanStandardBilling;

  /// Note under the plans.
  ///
  /// In pt, this message translates to:
  /// **'Dá para passar do Community para o Standard depois, sem perder grupos nem histórico.'**
  String get creationPlanSwitchLater;

  /// Button of the plan step; plan is the chosen plan's name.
  ///
  /// In pt, this message translates to:
  /// **'Continuar com {plan}'**
  String creationPlanContinue(String plan);

  /// Title of the review step of the creation wizard.
  ///
  /// In pt, this message translates to:
  /// **'Tudo certo?'**
  String get creationReviewTitle;

  /// Small text above the organization's name in the review preview.
  ///
  /// In pt, this message translates to:
  /// **'Sua equipe vai ver'**
  String get creationReviewTeamSees;

  /// Label of the name row of the review.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get creationReviewName;

  /// Label of the theme row of the review.
  ///
  /// In pt, this message translates to:
  /// **'Tema'**
  String get creationReviewTheme;

  /// Label of the plan row of the review.
  ///
  /// In pt, this message translates to:
  /// **'Plano'**
  String get creationReviewPlan;

  /// Heading of the note about the person who creates the organization. Titular is gender-neutral.
  ///
  /// In pt, this message translates to:
  /// **'Você será titular'**
  String get creationReviewOwnerTitle;

  /// What the owner does.
  ///
  /// In pt, this message translates to:
  /// **'{email} vai administrar a organização: convidar pessoas, criar grupos, mudar a aparência e adicionar o logo. Depois, outras pessoas também podem administrar.'**
  String creationReviewOwnerBody(String email);

  /// Checkbox to accept the terms; terms is creationTerms, drawn in bold.
  ///
  /// In pt, this message translates to:
  /// **'Li e aceito os {terms}.'**
  String creationTermsAccept(String terms);

  /// Name of the terms an organization accepts.
  ///
  /// In pt, this message translates to:
  /// **'Termos para organizações'**
  String get creationTerms;

  /// Button that creates the organization.
  ///
  /// In pt, this message translates to:
  /// **'Criar organização'**
  String get creationCreate;

  /// Title of the theme step of the creation wizard.
  ///
  /// In pt, this message translates to:
  /// **'Escolha um tema'**
  String get creationThemeTitle;

  /// Subtitle of the theme step.
  ///
  /// In pt, this message translates to:
  /// **'Cada tema já traz os tons do app, com contraste garantido para textos e botões.'**
  String get creationThemeSubtitle;

  /// Screen reader label of the theme preview.
  ///
  /// In pt, this message translates to:
  /// **'Prévia do app com o tema'**
  String get creationThemePreview;

  /// Sample group name shown in the theme preview.
  ///
  /// In pt, this message translates to:
  /// **'Motoristas'**
  String get creationPreviewGroup;

  /// Sample sharing pill shown in the theme preview.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhando'**
  String get creationPreviewSharing;

  /// Title of the screen that creates a group.
  ///
  /// In pt, this message translates to:
  /// **'Novo grupo'**
  String get createGroupTitle;

  /// Heading of the create group form.
  ///
  /// In pt, this message translates to:
  /// **'Criar um grupo'**
  String get createGroupHeading;

  /// Label of the group name field.
  ///
  /// In pt, this message translates to:
  /// **'Nome do grupo'**
  String get groupNameLabel;

  /// Example group name in an empty group name field.
  ///
  /// In pt, this message translates to:
  /// **'Ex.: Motoristas'**
  String get groupNameHint;

  /// Help under the group name field.
  ///
  /// In pt, this message translates to:
  /// **'É assim que o grupo aparece no mapa e nos convites.'**
  String get groupNameHelper;

  /// Note on the create group form.
  ///
  /// In pt, this message translates to:
  /// **'Você administra a organização, então já vê todos os grupos no mapa. O grupo nasce vazio: depois de criar, convide quem vai fazer parte dele.'**
  String get createGroupNote;

  /// Button that creates a group.
  ///
  /// In pt, this message translates to:
  /// **'Criar grupo'**
  String get createGroupButton;

  /// Title after a group was created.
  ///
  /// In pt, this message translates to:
  /// **'Grupo criado'**
  String get createGroupDone;

  /// Text after a group was created.
  ///
  /// In pt, this message translates to:
  /// **'{group} ainda não tem ninguém. Convide as pessoas que vão trabalhar nele e escolha o que cada uma faz no app.'**
  String createGroupDoneBody(String group);

  /// Button that opens the group just created.
  ///
  /// In pt, this message translates to:
  /// **'Ver o grupo'**
  String get createGroupOpen;

  /// Name of the role of a person who shares their own location in a group.
  ///
  /// In pt, this message translates to:
  /// **'Em campo'**
  String get rolePublisher;

  /// One line under the in-the-field role in the role pickers.
  ///
  /// In pt, this message translates to:
  /// **'Compartilha a própria localização'**
  String get rolePublisherDescription;

  /// Name of the role of a person who sees the group on the map.
  ///
  /// In pt, this message translates to:
  /// **'Vê o mapa'**
  String get roleSubscriber;

  /// One line under the sees-the-map role in the role pickers.
  ///
  /// In pt, this message translates to:
  /// **'Vê quem está em campo'**
  String get roleSubscriberDescription;

  /// Name of the role of a person who manages a group's people and invites.
  ///
  /// In pt, this message translates to:
  /// **'Gestor do grupo'**
  String get roleMaintainer;

  /// One line under the group manager role in the role pickers.
  ///
  /// In pt, this message translates to:
  /// **'Cuida das pessoas e dos convites do grupo'**
  String get roleMaintainerDescription;

  /// How many people a group has.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{Ninguém ainda} =1{1 pessoa} other{{count} pessoas}}'**
  String peopleCount(int count);

  /// How many invites of a group wait for an answer (never shown for none).
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{0 convites pendentes} =1{1 convite pendente} other{{count} convites pendentes}}'**
  String pendingInvites(int count);

  /// Status of a pending invite with the day it expires.
  ///
  /// In pt, this message translates to:
  /// **'Vale até {date}'**
  String inviteValidUntil(DateTime date);

  /// Status of an expired invite whose date is unknown.
  ///
  /// In pt, this message translates to:
  /// **'Expirado'**
  String get inviteExpired;

  /// Status of an expired invite with the day it expired.
  ///
  /// In pt, this message translates to:
  /// **'Expirado · venceu em {date}'**
  String inviteExpiredOn(DateTime date);

  /// Button that sends an expired invite again.
  ///
  /// In pt, this message translates to:
  /// **'Reenviar'**
  String get invitesResend;

  /// Shown when a group has no pending invites.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum convite pendente.'**
  String get invitesNone;

  /// Title of the sheet that confirms resending an invite.
  ///
  /// In pt, this message translates to:
  /// **'Reenviar o convite?'**
  String get invitesResendTitle;

  /// Button that resends an invite.
  ///
  /// In pt, this message translates to:
  /// **'Reenviar convite'**
  String get invitesResendConfirm;

  /// Resend button while the invite is being resent.
  ///
  /// In pt, this message translates to:
  /// **'Reenviando…'**
  String get invitesResending;

  /// What resending an invite does.
  ///
  /// In pt, this message translates to:
  /// **'{email} recebe um novo e-mail.'**
  String invitesResendEmail(String email);

  /// How long a resent invite is valid.
  ///
  /// In pt, this message translates to:
  /// **'O novo convite vale por 14 dias.'**
  String get invitesResendValid;

  /// Toast after resending an invite.
  ///
  /// In pt, this message translates to:
  /// **'Convite reenviado'**
  String get invitesResent;

  /// Title of the sheet that confirms cancelling an invite.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar o convite?'**
  String get invitesCancelTitle;

  /// Button that cancels an invite.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar convite'**
  String get invitesCancelConfirm;

  /// Cancel button while the invite is being cancelled.
  ///
  /// In pt, this message translates to:
  /// **'Cancelando…'**
  String get invitesCancelling;

  /// What cancelling an invite does.
  ///
  /// In pt, this message translates to:
  /// **'O link enviado para {email} deixa de funcionar.'**
  String invitesCancelLink(String email);

  /// Reassures that a cancelled invite can be sent again.
  ///
  /// In pt, this message translates to:
  /// **'Você pode convidar de novo depois.'**
  String get invitesInviteAgain;

  /// Toast after cancelling an invite.
  ///
  /// In pt, this message translates to:
  /// **'Convite cancelado'**
  String get invitesCancelled;

  /// Screen reader label of a person row that opens their roles.
  ///
  /// In pt, this message translates to:
  /// **'Mudar o que {name} faz'**
  String groupPersonEditRoles(String name);

  /// Line of the delete group sheet: people in no other group.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{0 pessoas só estavam neste grupo e perdem o acesso à {organization}.} =1{1 pessoa só estava neste grupo e perde o acesso à {organization}.} other{{count} pessoas só estavam neste grupo e perdem o acesso à {organization}.}}'**
  String groupDeletionLoses(int count, String organization);

  /// Line of the delete group sheet: people who are also in other groups.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{0 pessoas continuam nos outros grupos.} =1{1 pessoa continua nos outros grupos.} other{{count} pessoas continuam nos outros grupos.}}'**
  String groupDeletionStays(int count);

  /// Line of the delete group sheet: the group's pending invites.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{Os 0 convites pendentes são cancelados.} =1{O convite pendente é cancelado.} other{Os {count} convites pendentes são cancelados.}}'**
  String groupDeletionInvites(int count);

  /// Last line of the delete group sheet.
  ///
  /// In pt, this message translates to:
  /// **'Os trajetos publicados neste grupo são apagados junto. Não dá para desfazer.'**
  String get groupDeletionTrails;

  /// After deleting a group: how many people lost access to the organization.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{0 pessoas perderam o acesso à {organization}.} =1{1 pessoa perdeu o acesso à {organization}.} other{{count} pessoas perderam o acesso à {organization}.}}'**
  String groupDeletedLost(int count, String organization);

  /// After deleting a group: what happens to the others.
  ///
  /// In pt, this message translates to:
  /// **'Quem estava em outros grupos continua neles.'**
  String get groupDeletedOthersStay;

  /// Name of the tracking profile that saves the most battery.
  ///
  /// In pt, this message translates to:
  /// **'Economia'**
  String get presetEconomia;

  /// Name of the balanced tracking profile.
  ///
  /// In pt, this message translates to:
  /// **'Equilíbrio'**
  String get presetEquilibrio;

  /// Name of the most precise tracking profile.
  ///
  /// In pt, this message translates to:
  /// **'Precisão'**
  String get presetPrecisao;

  /// Name of the tracking profile where the administrator picks interval and distance.
  ///
  /// In pt, this message translates to:
  /// **'Personalizado'**
  String get presetPersonalizado;

  /// Shown when a group has no people.
  ///
  /// In pt, this message translates to:
  /// **'Ninguém neste grupo ainda. Convide quem vai trabalhar nele.'**
  String get groupPeopleEmpty;

  /// Title of the sheet that changes a person's roles in a group.
  ///
  /// In pt, this message translates to:
  /// **'O que {email} faz'**
  String groupRolesTitle(String email);

  /// Note in the roles sheet.
  ///
  /// In pt, this message translates to:
  /// **'A mudança vale na hora.'**
  String get groupRolesImmediate;

  /// Toast after changing a person's roles.
  ///
  /// In pt, this message translates to:
  /// **'Papel atualizado'**
  String get groupRolesUpdated;

  /// Title of the sheet that confirms removing a person from a group.
  ///
  /// In pt, this message translates to:
  /// **'Remover {email} de {group}?'**
  String groupRemoveTitle(String email, String group);

  /// Remove button while the person is being removed.
  ///
  /// In pt, this message translates to:
  /// **'Removendo…'**
  String get groupRemoving;

  /// What removing a person does to their access.
  ///
  /// In pt, this message translates to:
  /// **'Se este for o único grupo da pessoa, o acesso à {organization} acaba (a não ser que ela administre a organização).'**
  String groupRemoveAccess(String organization);

  /// What removing a person does on the map.
  ///
  /// In pt, this message translates to:
  /// **'Deixa de aparecer no mapa deste grupo e de ver quem está nele.'**
  String get groupRemoveMap;

  /// What removing a person keeps.
  ///
  /// In pt, this message translates to:
  /// **'Os trajetos antigos continuam no histórico.'**
  String get groupRemoveHistory;

  /// Toast after removing a person from a group.
  ///
  /// In pt, this message translates to:
  /// **'{email} não faz mais parte do grupo'**
  String groupRemoved(String email);

  /// Title of the screen of one group.
  ///
  /// In pt, this message translates to:
  /// **'Grupo'**
  String get groupTitle;

  /// Shown when the group no longer exists.
  ///
  /// In pt, this message translates to:
  /// **'Grupo não encontrado.'**
  String get groupNotFound;

  /// Button that opens the rename group sheet.
  ///
  /// In pt, this message translates to:
  /// **'Renomear'**
  String get groupRename;

  /// Tab with the group's people and how many they are.
  ///
  /// In pt, this message translates to:
  /// **'No grupo · {count}'**
  String groupTabPeople(int count);

  /// Tab with the group's pending invites; count is a number, or … while it loads.
  ///
  /// In pt, this message translates to:
  /// **'Convidados · {count}'**
  String groupTabInvited(String count);

  /// Button that opens the invite screen for this group.
  ///
  /// In pt, this message translates to:
  /// **'Convidar para este grupo'**
  String get groupInvite;

  /// Button that deletes the group, and the confirm button of its sheet.
  ///
  /// In pt, this message translates to:
  /// **'Excluir grupo'**
  String get groupDelete;

  /// Title after a group was deleted.
  ///
  /// In pt, this message translates to:
  /// **'Grupo excluído'**
  String get groupDeleted;

  /// Button that goes back to the list of groups after deleting one.
  ///
  /// In pt, this message translates to:
  /// **'Ver grupos'**
  String get groupSeeGroups;

  /// Title of the rename group sheet.
  ///
  /// In pt, this message translates to:
  /// **'Renomear grupo'**
  String get groupRenameTitle;

  /// Button that saves the new group name.
  ///
  /// In pt, this message translates to:
  /// **'Salvar nome'**
  String get groupRenameConfirm;

  /// Note under the group name field in the rename sheet.
  ///
  /// In pt, this message translates to:
  /// **'As pessoas do grupo veem o novo nome na hora.'**
  String get groupRenameNote;

  /// Toast after renaming a group.
  ///
  /// In pt, this message translates to:
  /// **'Grupo renomeado'**
  String get groupRenamed;

  /// Title of the sheet that confirms deleting a group.
  ///
  /// In pt, this message translates to:
  /// **'Excluir {group}?'**
  String groupDeleteTitle(String group);

  /// Delete button while the group is being deleted.
  ///
  /// In pt, this message translates to:
  /// **'Excluindo…'**
  String get groupDeleting;

  /// Title of the screen that lists the organization's groups, and its menu item.
  ///
  /// In pt, this message translates to:
  /// **'Grupos'**
  String get groupsTitle;

  /// Shown to an administrator when there are no groups.
  ///
  /// In pt, this message translates to:
  /// **'Sua organização ainda não tem grupos. Crie o primeiro e convide quem vai trabalhar nele.'**
  String get groupsEmptyAdmin;

  /// Shown to a group manager who manages no group.
  ///
  /// In pt, this message translates to:
  /// **'Você não é gestor de nenhum grupo agora.'**
  String get groupsEmptyMaintainer;

  /// Tooltip of the arrow that shows the previous month in the history calendar.
  ///
  /// In pt, this message translates to:
  /// **'Mês anterior'**
  String get calendarPreviousMonth;

  /// Tooltip of the arrow that shows the next month in the history calendar.
  ///
  /// In pt, this message translates to:
  /// **'Próximo mês'**
  String get calendarNextMonth;

  /// Legend of the dot that marks days with trails.
  ///
  /// In pt, this message translates to:
  /// **'Dias com trajetos'**
  String get calendarDaysWithTrails;

  /// Screen reader label of a day in the history calendar. today is yes or no; status is future, trails or none.
  ///
  /// In pt, this message translates to:
  /// **'{date}{today, select, yes{, hoje} other{}}{status, select, future{, ainda não chegou} trails{, com trajetos} other{, sem trajetos}}'**
  String calendarDayLabel(DateTime date, String today, String status);

  /// Dialog asking to lift Android's background restriction. The quoted names are Android settings as Android shows them in each language; Prosseguir is permissionContinue.
  ///
  /// In pt, this message translates to:
  /// **'O seu aparelho está restringindo o aplicativo em segundo plano. Assim, o rastreamento é desabilitado quando você sai do aplicativo ou desliga a tela.\n\nComo ajustar:\n1. Toque em \'Prosseguir\'.\n2. Ative \'Permitir o uso em segundo plano\' (ou escolha \'Sem restrições\').\n3. Volte para o aplicativo.\n\nSe abrir a tela de informações do app, toque antes em \'Uso da bateria pelo app\' (ou \'Bateria\'). Se o interruptor já aparecer ativado, desative-o e ative-o novamente.'**
  String get permissionBackgroundUsage;

  /// Prominent disclosure before asking for background location (required by Google Play). The quoted names are Android settings as Android shows them in each language.
  ///
  /// In pt, this message translates to:
  /// **'O app deseja coletar dados de localização mesmo quando o aplicativo estiver fechado ou não estiver em uso.\n\nEsses dados permitem que um grupo de pessoas, determinado e gerenciado pela sua empresa, visualize sua posição em tempo real.\n\nComo ativar:\n1. Toque em \'Prosseguir\'.\n2. Em Permissões > Localização.\n3. Selecione \'Permitir o tempo todo\'.'**
  String get permissionBackgroundLocation;

  /// Title of the dialog shown when the device's location is off.
  ///
  /// In pt, this message translates to:
  /// **'O GPS está desativado'**
  String get permissionGpsOffTitle;

  /// Text of the dialog shown when the device's location is off.
  ///
  /// In pt, this message translates to:
  /// **'Por favor, ative o GPS para continuar.'**
  String get permissionGpsOffBody;

  /// Button that closes the GPS dialog, in capitals.
  ///
  /// In pt, this message translates to:
  /// **'ENTENDI'**
  String get permissionGotIt;

  /// Title of the permission dialogs.
  ///
  /// In pt, this message translates to:
  /// **'Atenção'**
  String get permissionAttention;

  /// Button that declines a permission dialog, in capitals.
  ///
  /// In pt, this message translates to:
  /// **'AGORA NÃO'**
  String get permissionNotNow;

  /// Button that goes on to the permission or settings screen, in capitals.
  ///
  /// In pt, this message translates to:
  /// **'PROSSEGUIR'**
  String get permissionContinue;

  /// Screen reader label of the button that picks the group shown on the map.
  ///
  /// In pt, this message translates to:
  /// **'Grupo no mapa: {group}'**
  String mapGroupChip(String group);

  /// Heading of the group picker over the map, in capitals.
  ///
  /// In pt, this message translates to:
  /// **'VER NO MAPA'**
  String get mapSeeOnMap;

  /// How many groups the group picker lists.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{0 grupos} =1{1 grupo} other{{count} grupos}}'**
  String groupCount(int count);

  /// Shown in the group picker when the person sees no group.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum grupo disponível'**
  String get mapNoGroups;

  /// How many people a group on the map has.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{0 pessoas} =1{1 pessoa} other{{count} pessoas}}'**
  String memberCount(int count);

  /// Tooltip of the button that opens the side menu.
  ///
  /// In pt, this message translates to:
  /// **'Menu'**
  String get homeMenuTooltip;

  /// Screen reader label of the chip with the group(s) a person shares with.
  ///
  /// In pt, this message translates to:
  /// **'Grupo: {group}'**
  String homeGroupChip(String group);

  /// Screen reader label of the chip that opens the history calendar; day is the chip's text.
  ///
  /// In pt, this message translates to:
  /// **'Histórico por data, {day}'**
  String homeDayChip(String day);

  /// Chip that goes back to today's map.
  ///
  /// In pt, this message translates to:
  /// **'Voltar para hoje'**
  String get homeBackToToday;

  /// The observed day when it is today.
  ///
  /// In pt, this message translates to:
  /// **'Hoje'**
  String get dayToday;

  /// The observed day when it is yesterday.
  ///
  /// In pt, this message translates to:
  /// **'Ontem'**
  String get dayYesterday;

  /// Group chip before the person picks the group to see.
  ///
  /// In pt, this message translates to:
  /// **'Escolher grupo'**
  String get homeChooseGroup;

  /// Group chip of a person who shares with no group.
  ///
  /// In pt, this message translates to:
  /// **'Sem grupo'**
  String get homeNoGroup;

  /// Group chip of a person who shares with several groups: the first one and how many more.
  ///
  /// In pt, this message translates to:
  /// **'{group} +{more}'**
  String homeMoreGroups(String group, int more);

  /// Line under the organization's name in the menu, for an administrator.
  ///
  /// In pt, this message translates to:
  /// **'Administra a organização'**
  String get menuAdministers;

  /// Line under the organization's name in the menu, for a person who sees the map and shares their location.
  ///
  /// In pt, this message translates to:
  /// **'Acompanha e compartilha'**
  String get menuWatchesAndShares;

  /// Line under the organization's name in the menu, for a person who only sees the map.
  ///
  /// In pt, this message translates to:
  /// **'Acompanha o mapa'**
  String get menuWatches;

  /// Line under the organization's name in the menu, for a person who only shares their location.
  ///
  /// In pt, this message translates to:
  /// **'{group} · em campo'**
  String menuInTheField(String group);

  /// The language's own name, in the language picker and on the menu item: each ARB file writes its own language here, so it never changes with the app's language.
  ///
  /// In pt, this message translates to:
  /// **'Português'**
  String get languageName;

  /// Title of the language picker and label of the menu item that opens it.
  ///
  /// In pt, this message translates to:
  /// **'Idioma'**
  String get languageTitle;

  /// Accessibility label of the globe button on the entry screens, which opens the language picker; {language} is the language in use.
  ///
  /// In pt, this message translates to:
  /// **'Idioma: {language}'**
  String languageButtonLabel(String language);

  /// Menu item that goes back to the organization picker.
  ///
  /// In pt, this message translates to:
  /// **'Trocar de organização'**
  String get menuSwitchOrganization;

  /// Screen reader label of the account card in the menu.
  ///
  /// In pt, this message translates to:
  /// **'Minha conta'**
  String get menuMyAccount;

  /// Menu section for group managers, in capitals.
  ///
  /// In pt, this message translates to:
  /// **'GESTÃO DE GRUPOS'**
  String get menuGroupManagement;

  /// Menu item that opens the groups a group manager manages.
  ///
  /// In pt, this message translates to:
  /// **'Meus grupos'**
  String get menuMyGroups;

  /// Menu section for administrators, in capitals.
  ///
  /// In pt, this message translates to:
  /// **'ADMINISTRAÇÃO'**
  String get menuAdministration;

  /// Menu item that opens Aparência.
  ///
  /// In pt, this message translates to:
  /// **'Aparência da organização'**
  String get menuAppearance;

  /// Menu item that opens the tracking settings, and that screen's title.
  ///
  /// In pt, this message translates to:
  /// **'Ajustes de acompanhamento'**
  String get menuTrackingSettings;

  /// Banner over the map while the picked group's people load.
  ///
  /// In pt, this message translates to:
  /// **'Carregando {group}…'**
  String homeLoadingGroup(String group);

  /// Button that asks for the notification permission.
  ///
  /// In pt, this message translates to:
  /// **'Permitir notificação'**
  String get homeAllowNotification;

  /// Button that asks for the location permission while the app is in use.
  ///
  /// In pt, this message translates to:
  /// **'Permitir localização (durante uso)'**
  String get homeAllowLocationWhileInUse;

  /// Button that asks for the location permission all the time.
  ///
  /// In pt, this message translates to:
  /// **'Permitir localização (sempre)'**
  String get homeAllowLocationAlways;

  /// Button that opens the settings that lift Android's background restriction.
  ///
  /// In pt, this message translates to:
  /// **'Permitir uso em segundo plano'**
  String get homeAllowBackground;

  /// Credit the OpenStreetMap licence requires on the map; kept in English in Portuguese, as OpenStreetMap shows it.
  ///
  /// In pt, this message translates to:
  /// **'OpenStreetMap contributors'**
  String get mapAttribution;

  /// Screen reader label of the handle that opens the group's list under the map.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar a lista do grupo'**
  String get sheetShowList;

  /// Screen reader label of the handle that collapses the group's list under the map.
  ///
  /// In pt, this message translates to:
  /// **'Recolher a lista do grupo'**
  String get sheetHideList;

  /// Shown under the map before a group is picked.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum grupo escolhido'**
  String get sheetNoGroup;

  /// Shown under the map when the group has no people.
  ///
  /// In pt, this message translates to:
  /// **'Ninguém neste grupo ainda. Convide quem vai trabalhar nele para ver todos no mapa.'**
  String get sheetEmptyGroup;

  /// Button that invites people, and the title of the invite screen.
  ///
  /// In pt, this message translates to:
  /// **'Convidar pessoas'**
  String get invitePeople;

  /// Screen reader label of the button that hides a person's trail on the map.
  ///
  /// In pt, this message translates to:
  /// **'Esconder trajeto de {name}'**
  String personHideTrail(String name);

  /// Screen reader label of the button that shows a person's trail on the map.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar trajeto de {name}'**
  String personShowTrail(String name);

  /// Line under a person's name when their trail is drawn; presence is how fresh their position is.
  ///
  /// In pt, this message translates to:
  /// **'{presence} · trajeto visível'**
  String personTrailVisible(String presence);

  /// Screen reader label of the button that calls a person on Google Meet.
  ///
  /// In pt, this message translates to:
  /// **'Chamar {name} no Meet'**
  String personCallOnMeet(String name);

  /// Under the name of a person who never shared their location.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não ativou a localização'**
  String get presenceNever;

  /// Under the name of a person who turned their location off.
  ///
  /// In pt, this message translates to:
  /// **'Localização desligada'**
  String get presenceOff;

  /// Under the name of a person who turned their location off; ago is presenceAgo.
  ///
  /// In pt, this message translates to:
  /// **'Localização desligada · visto {ago}'**
  String presenceOffSeen(String ago);

  /// Under the name of a person whose position is fresh.
  ///
  /// In pt, this message translates to:
  /// **'Agora'**
  String get presenceLive;

  /// How long ago a person was seen: less than a minute.
  ///
  /// In pt, this message translates to:
  /// **'agora'**
  String get agoNow;

  /// How long ago a person was seen, in minutes.
  ///
  /// In pt, this message translates to:
  /// **'há {minutes} min'**
  String agoMinutes(int minutes);

  /// How long ago a person was seen, in hours.
  ///
  /// In pt, this message translates to:
  /// **'há {hours} h'**
  String agoHours(int hours);

  /// How long ago a person was seen: yesterday.
  ///
  /// In pt, this message translates to:
  /// **'ontem'**
  String get agoYesterday;

  /// How long ago a person was seen, in days (2 or more).
  ///
  /// In pt, this message translates to:
  /// **'há {days} dias'**
  String agoDays(int days);

  /// Under a person's name on a past day when they shared their location that day.
  ///
  /// In pt, this message translates to:
  /// **'Tem posições neste dia'**
  String get presenceDayPoints;

  /// Under a person's name on a past day when they did not share their location that day.
  ///
  /// In pt, this message translates to:
  /// **'Sem posições neste dia'**
  String get presenceDayNoPoints;

  /// Sharing card while location sharing turns off.
  ///
  /// In pt, this message translates to:
  /// **'Desativando compartilhamento…'**
  String get shareStopping;

  /// Sharing card while location sharing turns on.
  ///
  /// In pt, this message translates to:
  /// **'Ativando compartilhamento…'**
  String get shareStarting;

  /// Under the sharing card's title while it turns on or off.
  ///
  /// In pt, this message translates to:
  /// **'Aguarde um instante'**
  String get shareWait;

  /// Sharing card while location sharing is on.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhando sua localização'**
  String get shareOn;

  /// Under the sharing card's title while sharing is on.
  ///
  /// In pt, this message translates to:
  /// **'Seus grupos veem você no mapa'**
  String get shareOnSubtitle;

  /// Sharing card while location sharing is off.
  ///
  /// In pt, this message translates to:
  /// **'Localização desligada'**
  String get shareOff;

  /// Under the sharing card's title while sharing is off.
  ///
  /// In pt, this message translates to:
  /// **'Seus grupos não veem você no mapa'**
  String get shareOffSubtitle;

  /// Heading on the invite screen when the organization has no group yet.
  ///
  /// In pt, this message translates to:
  /// **'Crie seu primeiro grupo'**
  String get inviteFirstGroupTitle;

  /// Explains why the first invite also creates a group. Grupos is the name of a screen in the menu.
  ///
  /// In pt, this message translates to:
  /// **'Toda pessoa entra num grupo. Dê um nome para o primeiro; você cria outros depois, em Grupos.'**
  String get inviteFirstGroupBody;

  /// Label of the group picker on the invite screen.
  ///
  /// In pt, this message translates to:
  /// **'Para qual grupo?'**
  String get inviteWhichGroup;

  /// An option of the group picker: the group's name and how many people it has (peopleCount).
  ///
  /// In pt, this message translates to:
  /// **'{group} · {people}'**
  String inviteGroupOption(String group, String people);

  /// Label of the e-mail field on the invite screen.
  ///
  /// In pt, this message translates to:
  /// **'Quem você quer chamar?'**
  String get inviteWho;

  /// Example e-mail in the empty e-mail field.
  ///
  /// In pt, this message translates to:
  /// **'email@exemplo.com'**
  String get inviteEmailHint;

  /// Heading over the list of people to invite.
  ///
  /// In pt, this message translates to:
  /// **'O que cada pessoa faz? Uma ou as duas.'**
  String get inviteRolesQuestion;

  /// Explains the two roles; Em campo and Vê o mapa are rolePublisher and roleSubscriber.
  ///
  /// In pt, this message translates to:
  /// **'Em campo compartilha a própria localização. Vê o mapa vê quem está em campo.'**
  String get inviteRolesExplained;

  /// Note at the bottom of the invite screen.
  ///
  /// In pt, this message translates to:
  /// **'Cada pessoa recebe um e-mail e entra no app com essa Conta Google. A localização só é compartilhada depois que ela ativar no próprio celular.'**
  String get inviteHowItWorks;

  /// Send button while the invites are being sent.
  ///
  /// In pt, this message translates to:
  /// **'Enviando…'**
  String get inviteSending;

  /// Button that sends the invites; count is how many people are in the list.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{Enviar convite} =1{Enviar convite} other{Enviar {count} convites}}'**
  String inviteSend(int count);

  /// Tooltip of the button that takes a person off the invite list.
  ///
  /// In pt, this message translates to:
  /// **'Tirar {email}'**
  String inviteRemovePerson(String email);

  /// Shown under a person on the invite list who has no role.
  ///
  /// In pt, this message translates to:
  /// **'Marque pelo menos uma opção.'**
  String get inviteNoRole;

  /// Title after the invites were sent.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{0 convites enviados} =1{Convite enviado} other{{count} convites enviados}}'**
  String inviteSent(int count);

  /// Under the title after the invites were sent. Grupos is the name of a screen in the menu.
  ///
  /// In pt, this message translates to:
  /// **'Para {group}. Vale por 14 dias; acompanhe em Grupos.'**
  String inviteSentBody(String group);

  /// Under an invited e-mail whose message could not be sent.
  ///
  /// In pt, this message translates to:
  /// **'O e-mail não saiu agora; a pessoa vê o convite ao entrar no app com essa conta.'**
  String get inviteNotEmailed;

  /// Button that goes back to the invite form after sending.
  ///
  /// In pt, this message translates to:
  /// **'Convidar mais pessoas'**
  String get inviteMore;

  /// Title of the welcome screen after accepting an invite.
  ///
  /// In pt, this message translates to:
  /// **'Você entrou na {name}'**
  String welcomeJoined(String name);

  /// Under the welcome title: the group and who sent the invite.
  ///
  /// In pt, this message translates to:
  /// **'{group} · convite de {inviter}'**
  String welcomeInvitedBy(String group, String inviter);

  /// Heading of the welcome screen's roles.
  ///
  /// In pt, this message translates to:
  /// **'O que você faz no app'**
  String get welcomeWhatYouDo;

  /// What the in-the-field role means, on the welcome screen.
  ///
  /// In pt, this message translates to:
  /// **'Seus grupos veem onde você está enquanto o compartilhamento estiver ligado. Você liga e desliga quando quiser.'**
  String get welcomePublisher;

  /// What the sees-the-map role means, on the welcome screen.
  ///
  /// In pt, this message translates to:
  /// **'Você acompanha no mapa quem está em campo em {group}.'**
  String welcomeSubscriber(String group);

  /// Welcome button for a person in the field.
  ///
  /// In pt, this message translates to:
  /// **'Ativar minha localização'**
  String get welcomeTurnOnLocation;

  /// Welcome button for a person who only sees the map.
  ///
  /// In pt, this message translates to:
  /// **'Abrir o mapa'**
  String get welcomeOpenMap;

  /// Welcome button that opens the map without turning on the location.
  ///
  /// In pt, this message translates to:
  /// **'Ativar depois'**
  String get welcomeLater;

  /// A number of minutes, short.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{0 min} =1{1 min} other{{count} min}}'**
  String trackingMinutes(int count);

  /// Heading of the tracking settings.
  ///
  /// In pt, this message translates to:
  /// **'Com que frequência a equipe envia a localização?'**
  String get trackingQuestion;

  /// Who the tracking settings apply to.
  ///
  /// In pt, this message translates to:
  /// **'Vale para todos da {name} que estão em campo.'**
  String trackingAppliesTo(String name);

  /// Limit of the free plan.
  ///
  /// In pt, this message translates to:
  /// **'No plano Community, a localização é enviada no máximo a cada {minutes} min.'**
  String trackingCommunityLimit(int minutes);

  /// Label of the interval slider.
  ///
  /// In pt, this message translates to:
  /// **'Intervalo'**
  String get trackingInterval;

  /// Value of the interval slider; interval is trackingMinutes.
  ///
  /// In pt, this message translates to:
  /// **'a cada {interval}'**
  String trackingEvery(String interval);

  /// Label of the distance slider.
  ///
  /// In pt, this message translates to:
  /// **'Distância mínima'**
  String get trackingDistance;

  /// A distance in meters, short.
  ///
  /// In pt, this message translates to:
  /// **'{meters} m'**
  String trackingMeters(int meters);

  /// What the chosen settings mean in positions per hour.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{Até 0 posições} =1{Até 1 posição} other{Até {count} posições}} por hora, só quando a pessoa se mover {meters} m ou mais.'**
  String trackingPositionsPerHour(int count, int meters);

  /// How long until a silent person leaves the map; duration is trackingMinutes.
  ///
  /// In pt, this message translates to:
  /// **'Quem ficar {duration} sem dar notícia sai do mapa.'**
  String trackingLeavesMap(String duration);

  /// Battery use of the chosen settings; level is low, medium or high.
  ///
  /// In pt, this message translates to:
  /// **'Uso de bateria: {level, select, low{Baixo} medium{Médio} other{Alto}}'**
  String trackingBattery(String level);

  /// Shown after saving the tracking settings.
  ///
  /// In pt, this message translates to:
  /// **'Salvo. A equipe recebe em instantes, sem desligar o compartilhamento.'**
  String get trackingSaved;

  /// Disabled save button when nothing changed.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma alteração'**
  String get trackingNoChanges;

  /// Description of the custom tracking profile.
  ///
  /// In pt, this message translates to:
  /// **'Você escolhe intervalo e distância'**
  String get trackingCustomDescription;

  /// Description of a tracking profile.
  ///
  /// In pt, this message translates to:
  /// **'A cada {minutes} min, se andar {meters} m'**
  String trackingPresetDescription(int minutes, int meters);

  /// Tag next to the tracking profile saved now.
  ///
  /// In pt, this message translates to:
  /// **'Em uso'**
  String get trackingInUse;

  /// An operation failed, most likely for lack of connection.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível concluir agora. Verifique a conexão e tente de novo.'**
  String get failureConnectionConclude;

  /// Deleting failed, most likely for lack of connection.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível excluir agora. Verifique a conexão e tente de novo.'**
  String get failureConnectionDelete;

  /// Cancelling (e.g. the account deletion) failed, most likely for lack of connection.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível cancelar agora. Verifique a conexão e tente de novo.'**
  String get failureConnectionCancel;

  /// Creating an organization failed, most likely for lack of connection.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível criar agora. Verifique a conexão e tente de novo.'**
  String get failureConnectionCreate;

  /// Sending invites failed, most likely for lack of connection.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível enviar agora. Verifique a conexão e tente de novo.'**
  String get failureConnectionSend;

  /// Accepting an invite failed, most likely for lack of connection.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível aceitar agora. Verifique a conexão e tente de novo.'**
  String get failureConnectionAccept;

  /// Saving a change failed, most likely for lack of connection.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar agora. Verifique a conexão e tente de novo.'**
  String get failureConnectionSave;

  /// Switching organization failed, most likely for lack of connection.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível trocar agora. Verifique a conexão e tente de novo.'**
  String get failureConnectionSwitch;

  /// The account screen could not read whether the person owns the organization.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar sua conta. Verifique a conexão e tente de novo.'**
  String get failureConnectionLoadAccount;

  /// The list of administrators could not be read.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar os administradores.'**
  String get failureLoadAdministrators;

  /// The invites could not be read.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar os convites.'**
  String get failureLoadInvites;

  /// The groups could not be read.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar os grupos.'**
  String get failureLoadGroups;

  /// The theme catalog could not be read.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar os temas.'**
  String get failureLoadThemes;

  /// The organizations being created could not be read.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar as organizações em criação.'**
  String get failureLoadCreations;

  /// The account's pending deletion could not be read.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível ler a exclusão da conta.'**
  String get failureLoadAccountDeletion;

  /// Whether an organization identifier is free could not be checked.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível verificar agora.'**
  String get failureLoadOrganizationIdCheck;

  /// The server refused an operation without saying why.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível concluir.'**
  String get failureRefusedConclude;

  /// The server refused an account operation without saying why.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível agora.'**
  String get failureRefusedAny;

  /// The server refused to create the organization without saying why.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível criar.'**
  String get failureRefusedCreate;

  /// The server refused to save the appearance without saying why.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar.'**
  String get failureRefusedSave;

  /// The server answered something the app cannot read.
  ///
  /// In pt, this message translates to:
  /// **'Resposta inesperada do servidor.'**
  String get failureUnexpectedResponse;

  /// The server's answer to a group's creation could not be read.
  ///
  /// In pt, this message translates to:
  /// **'Resposta inesperada ao criar o grupo.'**
  String get failureUnexpectedGroupResponse;

  /// An organization identifier with characters other than a to z.
  ///
  /// In pt, this message translates to:
  /// **'Use só letras minúsculas, sem acentos nem espaços.'**
  String get failureOrganizationIdNotPlain;

  /// An organization identifier that is too long.
  ///
  /// In pt, this message translates to:
  /// **'Use no máximo {max} letras.'**
  String failureOrganizationIdTooLong(int max);

  /// An organization identifier MonAmie keeps for itself.
  ///
  /// In pt, this message translates to:
  /// **'Esse identificador é reservado.'**
  String get failureOrganizationIdReserved;

  /// The server says an organization identifier cannot be used, without saying why.
  ///
  /// In pt, this message translates to:
  /// **'Esse identificador não pode ser usado.'**
  String get failureOrganizationIdUnusable;

  /// A group name with fewer than 2 letters.
  ///
  /// In pt, this message translates to:
  /// **'Use pelo menos 2 letras.'**
  String get failureGroupNameTooShort;

  /// A group name longer than 40 characters.
  ///
  /// In pt, this message translates to:
  /// **'Use no máximo 40 caracteres.'**
  String get failureGroupNameTooLong;

  /// A group name already taken by another group.
  ///
  /// In pt, this message translates to:
  /// **'Já existe o grupo {name}.'**
  String failureGroupNameTaken(String name);

  /// No role ticked for a person in a group.
  ///
  /// In pt, this message translates to:
  /// **'Marque pelo menos uma opção.'**
  String get failureNoRoleChosen;

  /// An invite's e-mail that is not an e-mail address.
  ///
  /// In pt, this message translates to:
  /// **'Digite um e-mail válido.'**
  String get failureInvalidEmail;

  /// An invite's e-mail already in the list.
  ///
  /// In pt, this message translates to:
  /// **'{email} já está na lista.'**
  String failureEmailAlreadyListed(String email);

  /// A logo file over the 10 MB allowed.
  ///
  /// In pt, this message translates to:
  /// **'O arquivo tem {megabytes} MB. Envie um de até 10 MB.'**
  String failureLogoTooLarge(int megabytes);

  /// A logo file no decoder could open.
  ///
  /// In pt, this message translates to:
  /// **'Não deu para abrir este arquivo. Envie em PNG, JPEG, WebP ou SVG.'**
  String get failureLogoUnreadable;

  /// The logo's PNG could not be produced.
  ///
  /// In pt, this message translates to:
  /// **'Não deu para gerar o PNG do logo.'**
  String get failureLogoNotConverted;

  /// A logo file that could not be opened for any other reason.
  ///
  /// In pt, this message translates to:
  /// **'Não deu para abrir este arquivo.'**
  String get failureLogoNotOpened;

  /// Entering an organization failed; detail is the original error.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível entrar agora: {detail}'**
  String failureEntryEnter(String detail);

  /// Asking again which organizations the person belongs to failed; detail is the original error.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível verificar agora: {detail}'**
  String failureEntryCheck(String detail);

  /// Signing in with Google failed; detail is the original error.
  ///
  /// In pt, this message translates to:
  /// **'Ocorreu um erro inesperado: {detail}'**
  String failureEntryUnexpected(String detail);

  /// Entering after a web sign-in failed; detail is the original error.
  ///
  /// In pt, this message translates to:
  /// **'Ocorreu um erro ao carregar seus dados: {detail}'**
  String failureEntryLoadData(String detail);

  /// Entering the organization picked failed; detail is the original error.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível entrar em {organization}: {detail}'**
  String failureEntryOrganization(String organization, String detail);

  /// A web Google sign-in returned no account.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao autenticar o usuário. Verifique sua conta Google e tente novamente.'**
  String get failureGoogleAuth;

  /// Google did not renew the sign-in needed to switch organization.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível renovar o acesso com o Google. Tente de novo.'**
  String get failureGoogleRenewal;

  /// Signing out failed; detail is the original error.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível encerrar a sessão. Tente novamente.\nErro: {detail}'**
  String failureSignOut(String detail);

  /// Why the person is on the no-organization screen: no membership in the organization any more.
  ///
  /// In pt, this message translates to:
  /// **'Sua conta não tem mais acesso à {organization}.'**
  String failureAccessLost(String organization);

  /// Why the person is on the no-organization screen: removed from the organization.
  ///
  /// In pt, this message translates to:
  /// **'Você não faz mais parte da {organization}.'**
  String failureRemovedFromOrganization(String organization);

  /// Why the person is on the no-organization screen: removed from an organization whose name is unknown.
  ///
  /// In pt, this message translates to:
  /// **'Você não faz mais parte desta organização.'**
  String get failureRemovedFromUnnamedOrganization;

  /// Sharing cannot start: the person publishes in no group.
  ///
  /// In pt, this message translates to:
  /// **'Você não está em campo em nenhum grupo. Peça a um administrador para liberar o compartilhamento da sua localização.'**
  String get failureSharingNotAllowed;

  /// Turning sharing on or off failed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível alterar o compartilhamento agora. Tente de novo.'**
  String get failureSharingNotChanged;

  /// The language the person chose could not be stored on the device.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível guardar o idioma. Tente de novo.'**
  String get failureLanguageNotSaved;

  /// Title of the messages about a failed sign-in or entry.
  ///
  /// In pt, this message translates to:
  /// **'Erro de Login'**
  String get failureTitleSignIn;

  /// Title of the messages about a failed switch of organization.
  ///
  /// In pt, this message translates to:
  /// **'Trocar de organização'**
  String get failureTitleSwitchOrganization;

  /// Title of the message about a failed sign-out.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao sair'**
  String get failureTitleSignOut;

  /// Title of the message saying the person may not share.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhamento não autorizado'**
  String get failureTitleSharingNotAllowed;

  /// Title of the message about a failed change of sharing.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhamento'**
  String get failureTitleSharing;

  /// Title of the remark shown when sharing started without a GPS fix.
  ///
  /// In pt, this message translates to:
  /// **'Aguardando sinal de GPS'**
  String get noticeWaitingForGpsTitle;

  /// Remark shown when sharing started without a GPS fix.
  ///
  /// In pt, this message translates to:
  /// **'O monitoramento foi iniciado, mas a sua posição inicial ainda está sendo obtida pelos satélites.'**
  String get noticeWaitingForGps;

  /// Title of the warning that the device restricts the app in the background.
  ///
  /// In pt, this message translates to:
  /// **'Rastreamento em risco'**
  String get noticeTrackingAtRiskTitle;

  /// Warning that the device started restricting the app in the background while sharing is on.
  ///
  /// In pt, this message translates to:
  /// **'O aparelho está restringindo o MonAmie em segundo plano. O rastreamento vai parar quando você sair do aplicativo.'**
  String get noticeTrackingAtRisk;

  /// Title of the warning that the tracking did not confirm it stopped.
  ///
  /// In pt, this message translates to:
  /// **'Rastreamento'**
  String get noticeTrackingStopUnconfirmedTitle;

  /// Warning that the tracking service did not confirm it stopped.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível confirmar o encerramento do rastreamento. Ele será encerrado automaticamente em instantes.'**
  String get noticeTrackingStopUnconfirmed;

  /// Title of the warning shown back from the battery settings when the restriction is still on.
  ///
  /// In pt, this message translates to:
  /// **'Uso em segundo plano ainda restrito'**
  String get noticeBackgroundStillRestrictedTitle;

  /// Warning shown back from the battery settings when the restriction is still on. The quoted text is the Android setting's name.
  ///
  /// In pt, this message translates to:
  /// **'A alteração não foi aplicada. Toque em \'Permitir uso em segundo plano\' e, se o interruptor já estiver ativado, desative-o e ative-o novamente.'**
  String get noticeBackgroundStillRestricted;

  /// Title of the system notification shown while sharing is on.
  ///
  /// In pt, this message translates to:
  /// **'Sua localização está sendo compartilhada'**
  String get sharingNotificationTitle;

  /// Text of the system notification shown while sharing is on.
  ///
  /// In pt, this message translates to:
  /// **'O compartilhamento está ligado. Para preservar sua privacidade, certifique-se de desativá-lo assim que terminar suas atividades.'**
  String get sharingNotificationContent;

  /// Name shown for a group whose name is blank.
  ///
  /// In pt, this message translates to:
  /// **'Grupo sem nome'**
  String get groupUnnamed;

  /// Name shown for an invite's group when the server sent none.
  ///
  /// In pt, this message translates to:
  /// **'Grupo'**
  String get inviteGroupFallback;

  /// Placeholder name of the organization being created, before one is typed.
  ///
  /// In pt, this message translates to:
  /// **'Organização'**
  String get creationPreviewName;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
