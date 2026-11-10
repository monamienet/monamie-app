// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get loginTagline => 'Your team, on the same page.';

  @override
  String get commonSignOut => 'Sign out';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonOk => 'OK';

  @override
  String get commonSaving => 'Saving…';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSaveChanges => 'Save changes';

  @override
  String get commonChange => 'Change';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonBack => 'Back';

  @override
  String get commonTryAgain => 'Try again';

  @override
  String get commonChecking => 'Checking…';

  @override
  String get commonCreating => 'Creating…';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonRemove => 'Remove';

  @override
  String get commonClose => 'Close';

  @override
  String get commonGotIt => 'Got it';

  @override
  String get commonGenericFailure =>
      'Could not finish this right now. Please try again.';

  @override
  String get deletionRestoredAccountTitle => 'Your account is back';

  @override
  String deletionRestoredOrganizationTitle(String name) {
    return '$name is back';
  }

  @override
  String deletionPendingAccountTitle(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'in $days days',
      one: 'in 1 day',
      zero: 'today',
    );
    return 'Your account will be deleted $_temp0';
  }

  @override
  String deletionPendingOrganizationTitle(String name, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'in $days days',
      one: 'in 1 day',
      zero: 'today',
    );
    return '$name will be deleted $_temp0';
  }

  @override
  String get deletionRestoredBody =>
      'Nothing was erased. Sign in to pick up where you left off.';

  @override
  String deletionPendingAccountBody(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'On $dateString we permanently erase your account and your data in MonAmie.';
  }

  @override
  String deletionPendingOrganizationBody(DateTime date, String name) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'On $dateString we permanently erase $name, its groups, everyone\'s history and your account. Until then, no one can use the organization.';
  }

  @override
  String get deletionEnter => 'Sign in';

  @override
  String get deletionCancelAccount => 'Cancel account deletion';

  @override
  String get deletionCancel => 'Cancel deletion';

  @override
  String get myAccountTitle => 'My account';

  @override
  String get myAccountDeleteHeading => 'Delete account';

  @override
  String myAccountOwnerLeaves(String name) {
    return 'You own $name, so the whole organization is deleted along with your account.';
  }

  @override
  String myAccountMemberLeaves(String name) {
    return 'You leave $name right away and stop showing on the map.';
  }

  @override
  String myAccountEraseOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'On $dateString we permanently erase your account and your data in MonAmie.';
  }

  @override
  String get myAccountUndo =>
      'Until then, just sign in again and cancel the deletion.';

  @override
  String get myAccountDeleteWithOrganization =>
      'Delete account and organization';

  @override
  String get myAccountDelete => 'Delete account';

  @override
  String myAccountConfirmPrompt(String id) {
    return 'To confirm, type $id';
  }

  @override
  String get adminOrganizationFallback => 'organization';

  @override
  String get loggingOut => 'Signing out…';

  @override
  String get switchingOrganization => 'Switching organization…';

  @override
  String get administratorsTitle => 'Administrators';

  @override
  String get administratorsIntro =>
      'Administrators look after every group, the invites, the look and the settings of the organization, and see every group on the map. Only you, the owner, choose who administers.';

  @override
  String get administratorsOwner => 'Owner';

  @override
  String get administratorsAdministers => 'Administers the organization';

  @override
  String get administratorsMakeMember => 'Make member';

  @override
  String get administratorsNone => 'No one administers the organization.';

  @override
  String get administratorsMembers => 'Members';

  @override
  String get administratorsMember => 'Member';

  @override
  String get administratorsMakeAdmin => 'Make administrator';

  @override
  String get administratorsNoMembers =>
      'No one else in the organization yet. People who accept an invite to a group show up here.';

  @override
  String administratorsSection(String title, int count) {
    return '$title · $count';
  }

  @override
  String administratorsPromoteTitle(String email) {
    return 'Make $email an administrator?';
  }

  @override
  String get administratorsPromoteSees =>
      'They start seeing every group on the map and looking after the groups, the invites, the look and the settings of the organization.';

  @override
  String get administratorsUndoLater => 'You can undo this later.';

  @override
  String administratorsPromoted(String email) {
    return '$email now administers the organization';
  }

  @override
  String administratorsDemoteTitle(String email) {
    return 'Make $email a member?';
  }

  @override
  String get administratorsDemoteStops =>
      'They stop administering the organization and seeing the groups they are not in.';

  @override
  String get administratorsDemoteStays =>
      'They stay in the groups they are already in. If they are in none, they stay in the organization without seeing the map until invited to a group.';

  @override
  String administratorsDemoted(String email) {
    return '$email is now a member';
  }

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get appearanceYouAdminister => 'You administer this organization';

  @override
  String get appearanceName => 'Name';

  @override
  String get appearanceLogo => 'Logo';

  @override
  String get appearanceNoLogo => 'No logo · we use the initial';

  @override
  String get appearanceLogoSaved => 'Square 512 px PNG';

  @override
  String get appearanceLogoNew => 'New logo · save to apply';

  @override
  String get appearanceLogoFormats => 'SVG, PNG, JPEG or WebP';

  @override
  String get appearanceTheme => 'Theme';

  @override
  String get appearanceNextLaunch =>
      'The team sees the new look the next time they open the app.';

  @override
  String get appearanceSaved => 'Look saved';

  @override
  String get appearanceNameDialog => 'Organization name';

  @override
  String get appearanceLogoError => 'Could not use this file';

  @override
  String get appearanceLogoPreview => 'This is how the logo looks';

  @override
  String get appearanceLogoSheet => 'Organization logo';

  @override
  String get appearanceConverting => 'Converting to PNG on your phone';

  @override
  String get appearanceUseLogo => 'Use this logo';

  @override
  String get appearanceLogoExplained =>
      'We converted the file to a square 512 px PNG. This is how it shows at the top of the app, in the menu and in the list of organizations.';

  @override
  String get loginWithGoogle => 'Sign in with Google';

  @override
  String get loginLookingForOrganization => 'Looking for your organization…';

  @override
  String loginEntering(String name) {
    return 'Opening $name…';
  }

  @override
  String get accountHeaderSwitch => 'Switch';

  @override
  String get inviteCardTitle => 'You have an invite';

  @override
  String get inviteSomeone => 'Someone';

  @override
  String inviteCardBody(String inviter, String group, String role) {
    String _temp0 = intl.Intl.selectLogic(role, {
      'both': 'in the field and watching the map',
      'publisher': 'in the field',
      'other': 'watching the map',
    });
    return '$inviter invited you to the group $group, $_temp0.';
  }

  @override
  String inviteCardValidUntil(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Valid until $dateString.';
  }

  @override
  String inviteCardEntering(String name) {
    return 'Joining $name…';
  }

  @override
  String get inviteCardAccept => 'Accept and join';

  @override
  String get noOrganizationTitle => 'You are not part of an organization yet';

  @override
  String get noOrganizationBody =>
      'Create one for your team now, or ask someone in it to add you.';

  @override
  String get noOrganizationFast => 'Name and theme in under 2 minutes';

  @override
  String get noOrganizationYouAdminister =>
      'You administer it and invite the team';

  @override
  String get noOrganizationLater =>
      'You adjust the logo and the look later, in the app';

  @override
  String get noOrganizationCreate => 'Create my organization';

  @override
  String get noOrganizationRecheck => 'I was invited · check again';

  @override
  String get pickerTitle => 'Which organization do you want to open?';

  @override
  String pickerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You belong to $count. You can switch later from the menu.',
      one: 'You belong to 1 organization.',
      zero: 'You belong to 0. You can switch later from the menu.',
    );
    return '$_temp0';
  }

  @override
  String get pickerCreate => 'Create a new organization';

  @override
  String get creationTitle => 'New organization';

  @override
  String creationStep(int step, int count) {
    return '$step of $count';
  }

  @override
  String creationReadyTitle(String name) {
    return '$name is ready';
  }

  @override
  String get creationReadyBody =>
      'The app already shows your name and theme. Add the logo whenever you like, in Appearance. Next step: invite your team in Groups.';

  @override
  String creationReadyEnter(String name) {
    return 'Open $name';
  }

  @override
  String get creationBillingTitle => 'Billing still needs to be turned on';

  @override
  String creationBillingBody(String name, String id) {
    return '$name runs in a Google Cloud project paid for by your organization. Sign in to Google Cloud with this same Google Account, choose or create a billing account and link it to the project monamienet-$id. The identifier stays reserved for 7 days.';
  }

  @override
  String creationFailedTitle(String name) {
    return 'Something went wrong while creating $name';
  }

  @override
  String creationFailedBody(String id) {
    return 'There is nothing you need to do. The MonAmie team has been notified and will finish the creation. The identifier $id stays reserved for you in the meantime.';
  }

  @override
  String get creationNameTitle => 'What is your organization called?';

  @override
  String get creationNameSubtitle =>
      'Use the name your team knows: the company\'s, the group\'s or the project\'s.';

  @override
  String get creationNameLabel => 'Organization name';

  @override
  String creationNamePreview(String name) {
    return 'Your team will see $name at the top of the app';
  }

  @override
  String get creationIdLabel => 'Identifier';

  @override
  String get creationIdAdjusted =>
      'We changed it to lowercase letters, without accents, spaces or numbers.';

  @override
  String get creationIdRules =>
      'Lowercase letters only, without accents, spaces or numbers. It is the organization\'s code in MonAmie.';

  @override
  String get creationIdPermanent =>
      'The identifier cannot change later. The name can.';

  @override
  String get creationIdTooShort => 'At least 3 letters';

  @override
  String get creationIdAvailable => 'Available';

  @override
  String get planCommunity => 'Community';

  @override
  String get planStandard => 'Standard';

  @override
  String get creationPlanTitle => 'Choose a plan';

  @override
  String creationPlanSubtitle(String name) {
    return 'Both have the map, the groups and the look of $name. What changes is where the data is kept and who pays.';
  }

  @override
  String get creationPlanFree => 'Free';

  @override
  String get creationPlanCommunityTagline =>
      'To start right now, with no payment details.';

  @override
  String get creationPlanCommunityReady => 'Ready in moments';

  @override
  String get creationPlanCommunityData =>
      'Data kept by MonAmie, apart from other organizations';

  @override
  String get creationPlanCommunityInterval =>
      'Location sent every 15 min (Economy profile)';

  @override
  String get creationPlanGoogleUsage => 'Usage on Google';

  @override
  String get creationPlanStandardTagline =>
      'For those who want their own data space and more precision.';

  @override
  String creationPlanStandardProject(String name) {
    return 'A Firebase project for $name alone';
  }

  @override
  String get creationPlanStandardProfiles =>
      'Every tracking profile, down to every 1 min';

  @override
  String get creationPlanStandardBilling =>
      'Needs a Google Cloud billing account; you pay Google directly for what you use';

  @override
  String get creationPlanSwitchLater =>
      'You can move from Community to Standard later, without losing groups or history.';

  @override
  String creationPlanContinue(String plan) {
    return 'Continue with $plan';
  }

  @override
  String get creationReviewTitle => 'All set?';

  @override
  String get creationReviewTeamSees => 'Your team will see';

  @override
  String get creationReviewName => 'Name';

  @override
  String get creationReviewTheme => 'Theme';

  @override
  String get creationReviewPlan => 'Plan';

  @override
  String get creationReviewOwnerTitle => 'You will be the owner';

  @override
  String creationReviewOwnerBody(String email) {
    return '$email will administer the organization: invite people, create groups, change the look and add the logo. Later, other people can administer it too.';
  }

  @override
  String creationTermsAccept(String terms) {
    return 'I have read and accept the $terms.';
  }

  @override
  String get creationTerms => 'Terms for organizations';

  @override
  String get creationCreate => 'Create organization';

  @override
  String get creationThemeTitle => 'Choose a theme';

  @override
  String get creationThemeSubtitle =>
      'Each theme comes with the app\'s shades, with guaranteed contrast for text and buttons.';

  @override
  String get creationThemePreview => 'Preview of the app with the theme';

  @override
  String get creationPreviewGroup => 'Drivers';

  @override
  String get creationPreviewSharing => 'Sharing';

  @override
  String get createGroupTitle => 'New group';

  @override
  String get createGroupHeading => 'Create a group';

  @override
  String get groupNameLabel => 'Group name';

  @override
  String get groupNameHint => 'E.g. Drivers';

  @override
  String get groupNameHelper =>
      'This is how the group shows on the map and in invites.';

  @override
  String get createGroupNote =>
      'You administer the organization, so you already see every group on the map. The group starts empty: after creating it, invite the people who will be in it.';

  @override
  String get createGroupButton => 'Create group';

  @override
  String get createGroupDone => 'Group created';

  @override
  String createGroupDoneBody(String group) {
    return '$group has no one yet. Invite the people who will work in it and choose what each of them does in the app.';
  }

  @override
  String get createGroupOpen => 'Open the group';

  @override
  String get rolePublisher => 'In the field';

  @override
  String get rolePublisherDescription => 'Shares their own location';

  @override
  String get roleSubscriber => 'Sees the map';

  @override
  String get roleSubscriberDescription => 'Sees who is in the field';

  @override
  String get roleMaintainer => 'Group manager';

  @override
  String get roleMaintainerDescription =>
      'Looks after the group\'s people and invites';

  @override
  String peopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
      zero: 'No one yet',
    );
    return '$_temp0';
  }

  @override
  String pendingInvites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pending invites',
      one: '1 pending invite',
      zero: '0 pending invites',
    );
    return '$_temp0';
  }

  @override
  String inviteValidUntil(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Valid until $dateString';
  }

  @override
  String get inviteExpired => 'Expired';

  @override
  String inviteExpiredOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Expired · ended on $dateString';
  }

  @override
  String get invitesResend => 'Resend';

  @override
  String get invitesNone => 'No pending invites.';

  @override
  String get invitesResendTitle => 'Resend the invite?';

  @override
  String get invitesResendConfirm => 'Resend invite';

  @override
  String get invitesResending => 'Resending…';

  @override
  String invitesResendEmail(String email) {
    return '$email gets a new e-mail.';
  }

  @override
  String get invitesResendValid => 'The new invite is valid for 14 days.';

  @override
  String get invitesResent => 'Invite resent';

  @override
  String get invitesCancelTitle => 'Cancel the invite?';

  @override
  String get invitesCancelConfirm => 'Cancel invite';

  @override
  String get invitesCancelling => 'Cancelling…';

  @override
  String invitesCancelLink(String email) {
    return 'The link sent to $email stops working.';
  }

  @override
  String get invitesInviteAgain => 'You can invite them again later.';

  @override
  String get invitesCancelled => 'Invite cancelled';

  @override
  String groupPersonEditRoles(String name) {
    return 'Change what $name does';
  }

  @override
  String groupDeletionLoses(int count, String organization) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count people were only in this group and lose access to $organization.',
      one: '1 person was only in this group and loses access to $organization.',
      zero:
          '0 people were only in this group and lose access to $organization.',
    );
    return '$_temp0';
  }

  @override
  String groupDeletionStays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people stay in the other groups.',
      one: '1 person stays in the other groups.',
      zero: '0 people stay in the other groups.',
    );
    return '$_temp0';
  }

  @override
  String groupDeletionInvites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'The $count pending invites are cancelled.',
      one: 'The pending invite is cancelled.',
      zero: 'The 0 pending invites are cancelled.',
    );
    return '$_temp0';
  }

  @override
  String get groupDeletionTrails =>
      'The trails published in this group are erased with it. This cannot be undone.';

  @override
  String groupDeletedLost(int count, String organization) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people lost access to $organization.',
      one: '1 person lost access to $organization.',
      zero: '0 people lost access to $organization.',
    );
    return '$_temp0';
  }

  @override
  String get groupDeletedOthersStay =>
      'People who were in other groups stay in them.';

  @override
  String get presetEconomia => 'Economy';

  @override
  String get presetEquilibrio => 'Balanced';

  @override
  String get presetPrecisao => 'Precision';

  @override
  String get presetPersonalizado => 'Custom';

  @override
  String get groupPeopleEmpty =>
      'No one in this group yet. Invite the people who will work in it.';

  @override
  String groupRolesTitle(String email) {
    return 'What $email does';
  }

  @override
  String get groupRolesImmediate => 'The change applies right away.';

  @override
  String get groupRolesUpdated => 'Role updated';

  @override
  String groupRemoveTitle(String email, String group) {
    return 'Remove $email from $group?';
  }

  @override
  String get groupRemoving => 'Removing…';

  @override
  String groupRemoveAccess(String organization) {
    return 'If this is the person\'s only group, their access to $organization ends (unless they administer the organization).';
  }

  @override
  String get groupRemoveMap =>
      'They stop showing on this group\'s map and seeing who is in it.';

  @override
  String get groupRemoveHistory => 'Their past trails stay in the history.';

  @override
  String groupRemoved(String email) {
    return '$email is no longer in the group';
  }

  @override
  String get groupTitle => 'Group';

  @override
  String get groupNotFound => 'Group not found.';

  @override
  String get groupRename => 'Rename';

  @override
  String groupTabPeople(int count) {
    return 'In the group · $count';
  }

  @override
  String groupTabInvited(String count) {
    return 'Invited · $count';
  }

  @override
  String get groupInvite => 'Invite to this group';

  @override
  String get groupDelete => 'Delete group';

  @override
  String get groupDeleted => 'Group deleted';

  @override
  String get groupSeeGroups => 'See groups';

  @override
  String get groupRenameTitle => 'Rename group';

  @override
  String get groupRenameConfirm => 'Save name';

  @override
  String get groupRenameNote =>
      'People in the group see the new name right away.';

  @override
  String get groupRenamed => 'Group renamed';

  @override
  String groupDeleteTitle(String group) {
    return 'Delete $group?';
  }

  @override
  String get groupDeleting => 'Deleting…';

  @override
  String get groupsTitle => 'Groups';

  @override
  String get groupsEmptyAdmin =>
      'Your organization has no groups yet. Create the first one and invite the people who will work in it.';

  @override
  String get groupsEmptyMaintainer => 'You do not manage any group right now.';

  @override
  String get calendarPreviousMonth => 'Previous month';

  @override
  String get calendarNextMonth => 'Next month';

  @override
  String get calendarDaysWithTrails => 'Days with trails';

  @override
  String calendarDayLabel(DateTime date, String today, String status) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.MMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    String _temp0 = intl.Intl.selectLogic(today, {
      'yes': ', today',
      'other': '',
    });
    String _temp1 = intl.Intl.selectLogic(status, {
      'future': ', not here yet',
      'trails': ', with trails',
      'other': ', no trails',
    });
    return '$dateString$_temp0$_temp1';
  }

  @override
  String get permissionBackgroundUsage =>
      'Your device is restricting the app in the background, so tracking stops when you leave the app or turn off the screen.\n\nHow to fix it:\n1. Tap \'Continue\'.\n2. Turn on \'Allow background usage\' (or choose \'Unrestricted\').\n3. Come back to the app.\n\nIf the app info screen opens, first tap \'App battery usage\' (or \'Battery\'). If the switch is already on, turn it off and on again.';

  @override
  String get permissionBackgroundLocation =>
      'The app wants to collect location data even when the app is closed or not in use.\n\nThis data lets a group of people, chosen and managed by your company, see your position in real time.\n\nHow to turn it on:\n1. Tap \'Continue\'.\n2. Go to Permissions > Location.\n3. Select \'Allow all the time\'.';

  @override
  String get permissionGpsOffTitle => 'GPS is turned off';

  @override
  String get permissionGpsOffBody => 'Please turn on GPS to continue.';

  @override
  String get permissionGotIt => 'GOT IT';

  @override
  String get permissionAttention => 'Attention';

  @override
  String get permissionNotNow => 'NOT NOW';

  @override
  String get permissionContinue => 'CONTINUE';

  @override
  String mapGroupChip(String group) {
    return 'Group on the map: $group';
  }

  @override
  String get mapSeeOnMap => 'SHOW ON THE MAP';

  @override
  String groupCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count groups',
      one: '1 group',
      zero: '0 groups',
    );
    return '$_temp0';
  }

  @override
  String get mapNoGroups => 'No groups available';

  @override
  String memberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
      zero: '0 people',
    );
    return '$_temp0';
  }

  @override
  String get homeMenuTooltip => 'Menu';

  @override
  String homeGroupChip(String group) {
    return 'Group: $group';
  }

  @override
  String homeDayChip(String day) {
    return 'History by date, $day';
  }

  @override
  String get homeBackToToday => 'Back to today';

  @override
  String get dayToday => 'Today';

  @override
  String get dayYesterday => 'Yesterday';

  @override
  String get homeChooseGroup => 'Choose group';

  @override
  String get homeNoGroup => 'No group';

  @override
  String homeMoreGroups(String group, int more) {
    return '$group +$more';
  }

  @override
  String get menuAdministers => 'Administers the organization';

  @override
  String get menuWatchesAndShares => 'Watches and shares';

  @override
  String get menuWatches => 'Watches the map';

  @override
  String menuInTheField(String group) {
    return '$group · in the field';
  }

  @override
  String get languageName => 'English';

  @override
  String get languageTitle => 'Language';

  @override
  String languageButtonLabel(String language) {
    return 'Language: $language';
  }

  @override
  String get menuSwitchOrganization => 'Switch organization';

  @override
  String get menuMyAccount => 'My account';

  @override
  String get menuGroupManagement => 'GROUP MANAGEMENT';

  @override
  String get menuMyGroups => 'My groups';

  @override
  String get menuAdministration => 'ADMINISTRATION';

  @override
  String get menuAppearance => 'Organization appearance';

  @override
  String get menuTrackingSettings => 'Tracking settings';

  @override
  String homeLoadingGroup(String group) {
    return 'Loading $group…';
  }

  @override
  String get homeAllowNotification => 'Allow notifications';

  @override
  String get homeAllowLocationWhileInUse => 'Allow location (while in use)';

  @override
  String get homeAllowLocationAlways => 'Allow location (all the time)';

  @override
  String get homeAllowBackground => 'Allow background usage';

  @override
  String get mapAttribution => 'OpenStreetMap contributors';

  @override
  String get sheetShowList => 'Show the group\'s list';

  @override
  String get sheetHideList => 'Collapse the group\'s list';

  @override
  String get sheetNoGroup => 'No group chosen';

  @override
  String get sheetEmptyGroup =>
      'No one in this group yet. Invite the people who will work in it to see everyone on the map.';

  @override
  String get invitePeople => 'Invite people';

  @override
  String personHideTrail(String name) {
    return 'Hide $name\'s trail';
  }

  @override
  String personShowTrail(String name) {
    return 'Show $name\'s trail';
  }

  @override
  String personTrailVisible(String presence) {
    return '$presence · trail shown';
  }

  @override
  String personCallOnMeet(String name) {
    return 'Call $name on Meet';
  }

  @override
  String get presenceNever => 'Has not turned on location yet';

  @override
  String get presenceOff => 'Location off';

  @override
  String presenceOffSeen(String ago) {
    return 'Location off · seen $ago';
  }

  @override
  String get presenceLive => 'Now';

  @override
  String get agoNow => 'just now';

  @override
  String agoMinutes(int minutes) {
    return '$minutes min ago';
  }

  @override
  String agoHours(int hours) {
    return '$hours h ago';
  }

  @override
  String get agoYesterday => 'yesterday';

  @override
  String agoDays(int days) {
    return '$days days ago';
  }

  @override
  String get presenceDayPoints => 'Has positions on this day';

  @override
  String get presenceDayNoPoints => 'No positions on this day';

  @override
  String get shareStopping => 'Turning off sharing…';

  @override
  String get shareStarting => 'Turning on sharing…';

  @override
  String get shareWait => 'Just a moment';

  @override
  String get shareOn => 'Sharing your location';

  @override
  String get shareOnSubtitle => 'Your groups see you on the map';

  @override
  String get shareOff => 'Location off';

  @override
  String get shareOffSubtitle => 'Your groups do not see you on the map';

  @override
  String get inviteFirstGroupTitle => 'Create your first group';

  @override
  String get inviteFirstGroupBody =>
      'Everyone joins a group. Name the first one; you create others later, in Groups.';

  @override
  String get inviteWhichGroup => 'To which group?';

  @override
  String inviteGroupOption(String group, String people) {
    return '$group · $people';
  }

  @override
  String get inviteWho => 'Who do you want to invite?';

  @override
  String get inviteEmailHint => 'email@example.com';

  @override
  String get inviteRolesQuestion => 'What does each person do? One or both.';

  @override
  String get inviteRolesExplained =>
      'In the field shares their own location. Sees the map sees who is in the field.';

  @override
  String get inviteHowItWorks =>
      'Each person gets an e-mail and signs in to the app with that Google Account. Their location is shared only after they turn it on on their own phone.';

  @override
  String get inviteSending => 'Sending…';

  @override
  String inviteSend(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Send $count invites',
      one: 'Send invite',
      zero: 'Send invite',
    );
    return '$_temp0';
  }

  @override
  String inviteRemovePerson(String email) {
    return 'Remove $email';
  }

  @override
  String get inviteNoRole => 'Check at least one option.';

  @override
  String inviteSent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count invites sent',
      one: 'Invite sent',
      zero: '0 invites sent',
    );
    return '$_temp0';
  }

  @override
  String inviteSentBody(String group) {
    return 'To $group. Valid for 14 days; follow them in Groups.';
  }

  @override
  String get inviteNotEmailed =>
      'The e-mail did not go out now; the person sees the invite when they sign in to the app with that account.';

  @override
  String get inviteMore => 'Invite more people';

  @override
  String welcomeJoined(String name) {
    return 'You joined $name';
  }

  @override
  String welcomeInvitedBy(String group, String inviter) {
    return '$group · invited by $inviter';
  }

  @override
  String get welcomeWhatYouDo => 'What you do in the app';

  @override
  String get welcomePublisher =>
      'Your groups see where you are while sharing is on. You turn it on and off whenever you like.';

  @override
  String welcomeSubscriber(String group) {
    return 'You follow on the map who is in the field in $group.';
  }

  @override
  String get welcomeTurnOnLocation => 'Turn on my location';

  @override
  String get welcomeOpenMap => 'Open the map';

  @override
  String get welcomeLater => 'Turn on later';

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
  String get trackingQuestion => 'How often does the team send their location?';

  @override
  String trackingAppliesTo(String name) {
    return 'Applies to everyone in $name who is in the field.';
  }

  @override
  String trackingCommunityLimit(int minutes) {
    return 'On the Community plan, the location is sent at most every $minutes min.';
  }

  @override
  String get trackingInterval => 'Interval';

  @override
  String trackingEvery(String interval) {
    return 'every $interval';
  }

  @override
  String get trackingDistance => 'Minimum distance';

  @override
  String trackingMeters(int meters) {
    return '$meters m';
  }

  @override
  String trackingPositionsPerHour(int count, int meters) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Up to $count positions',
      one: 'Up to 1 position',
      zero: 'Up to 0 positions',
    );
    return '$_temp0 per hour, only when the person moves $meters m or more.';
  }

  @override
  String trackingLeavesMap(String duration) {
    return 'Anyone silent for $duration leaves the map.';
  }

  @override
  String trackingBattery(String level) {
    String _temp0 = intl.Intl.selectLogic(level, {
      'low': 'Low',
      'medium': 'Medium',
      'other': 'High',
    });
    return 'Battery use: $_temp0';
  }

  @override
  String get trackingSaved =>
      'Saved. The team gets it in moments, without turning off sharing.';

  @override
  String get trackingNoChanges => 'No changes';

  @override
  String get trackingCustomDescription =>
      'You choose the interval and distance';

  @override
  String trackingPresetDescription(int minutes, int meters) {
    return 'Every $minutes min, if they move $meters m';
  }

  @override
  String get trackingInUse => 'In use';

  @override
  String get failureConnectionConclude =>
      'Could not finish right now. Check the connection and try again.';

  @override
  String get failureConnectionDelete =>
      'Could not delete right now. Check the connection and try again.';

  @override
  String get failureConnectionCancel =>
      'Could not cancel right now. Check the connection and try again.';

  @override
  String get failureConnectionCreate =>
      'Could not create right now. Check the connection and try again.';

  @override
  String get failureConnectionSend =>
      'Could not send right now. Check the connection and try again.';

  @override
  String get failureConnectionAccept =>
      'Could not accept right now. Check the connection and try again.';

  @override
  String get failureConnectionSave =>
      'Could not save right now. Check the connection and try again.';

  @override
  String get failureConnectionSwitch =>
      'Could not switch right now. Check the connection and try again.';

  @override
  String get failureConnectionLoadAccount =>
      'Could not load your account. Check the connection and try again.';

  @override
  String get failureLoadAdministrators => 'Could not load the administrators.';

  @override
  String get failureLoadInvites => 'Could not load the invites.';

  @override
  String get failureLoadGroups => 'Could not load the groups.';

  @override
  String get failureLoadThemes => 'Could not load the themes.';

  @override
  String get failureLoadCreations =>
      'Could not load the organizations being created.';

  @override
  String get failureLoadAccountDeletion =>
      'Could not read the account deletion.';

  @override
  String get failureLoadOrganizationIdCheck => 'Could not check right now.';

  @override
  String get failureRefusedConclude => 'Could not finish.';

  @override
  String get failureRefusedAny => 'Not possible right now.';

  @override
  String get failureRefusedCreate => 'Could not create.';

  @override
  String get failureRefusedSave => 'Could not save.';

  @override
  String get failureUnexpectedResponse => 'Unexpected answer from the server.';

  @override
  String get failureUnexpectedGroupResponse =>
      'Unexpected answer when creating the group.';

  @override
  String get failureOrganizationIdNotPlain =>
      'Use lowercase letters only, without accents or spaces.';

  @override
  String failureOrganizationIdTooLong(int max) {
    return 'Use at most $max letters.';
  }

  @override
  String get failureOrganizationIdReserved => 'This identifier is reserved.';

  @override
  String get failureOrganizationIdUnusable => 'This identifier cannot be used.';

  @override
  String get failureGroupNameTooShort => 'Use at least 2 letters.';

  @override
  String get failureGroupNameTooLong => 'Use at most 40 characters.';

  @override
  String failureGroupNameTaken(String name) {
    return 'The group $name already exists.';
  }

  @override
  String get failureNoRoleChosen => 'Tick at least one option.';

  @override
  String get failureInvalidEmail => 'Type a valid e-mail.';

  @override
  String failureEmailAlreadyListed(String email) {
    return '$email is already on the list.';
  }

  @override
  String failureLogoTooLarge(int megabytes) {
    return 'The file has $megabytes MB. Send one of up to 10 MB.';
  }

  @override
  String get failureLogoUnreadable =>
      'This file could not be opened. Send a PNG, JPEG, WebP or SVG.';

  @override
  String get failureLogoNotConverted => 'The logo\'s PNG could not be made.';

  @override
  String get failureLogoNotOpened => 'This file could not be opened.';

  @override
  String failureEntryEnter(String detail) {
    return 'Could not enter right now: $detail';
  }

  @override
  String failureEntryCheck(String detail) {
    return 'Could not check right now: $detail';
  }

  @override
  String failureEntryUnexpected(String detail) {
    return 'An unexpected error happened: $detail';
  }

  @override
  String failureEntryLoadData(String detail) {
    return 'An error happened while loading your data: $detail';
  }

  @override
  String failureEntryOrganization(String organization, String detail) {
    return 'Could not enter $organization: $detail';
  }

  @override
  String get failureGoogleAuth =>
      'Could not authenticate the user. Check your Google account and try again.';

  @override
  String get failureGoogleRenewal =>
      'Could not renew the access with Google. Try again.';

  @override
  String failureSignOut(String detail) {
    return 'Could not end the session. Try again.\nError: $detail';
  }

  @override
  String failureAccessLost(String organization) {
    return 'Your account no longer has access to $organization.';
  }

  @override
  String failureRemovedFromOrganization(String organization) {
    return 'You are no longer part of $organization.';
  }

  @override
  String get failureRemovedFromUnnamedOrganization =>
      'You are no longer part of this organization.';

  @override
  String get failureSharingNotAllowed =>
      'You are not in the field in any group. Ask an administrator to allow sharing your location.';

  @override
  String get failureSharingNotChanged =>
      'Could not change sharing right now. Try again.';

  @override
  String get failureLanguageNotSaved =>
      'Could not save the language. Try again.';

  @override
  String get failureTitleSignIn => 'Sign-in error';

  @override
  String get failureTitleSwitchOrganization => 'Switch organization';

  @override
  String get failureTitleSignOut => 'Sign-out error';

  @override
  String get failureTitleSharingNotAllowed => 'Sharing not allowed';

  @override
  String get failureTitleSharing => 'Sharing';

  @override
  String get noticeWaitingForGpsTitle => 'Waiting for GPS signal';

  @override
  String get noticeWaitingForGps =>
      'Tracking started, but your first position is still being obtained from the satellites.';

  @override
  String get noticeTrackingAtRiskTitle => 'Tracking at risk';

  @override
  String get noticeTrackingAtRisk =>
      'The device is restricting MonAmie in the background. Tracking will stop when you leave the app.';

  @override
  String get noticeTrackingStopUnconfirmedTitle => 'Tracking';

  @override
  String get noticeTrackingStopUnconfirmed =>
      'Could not confirm that tracking stopped. It will stop by itself in a moment.';

  @override
  String get noticeBackgroundStillRestrictedTitle =>
      'Background use still restricted';

  @override
  String get noticeBackgroundStillRestricted =>
      'The change was not applied. Tap \'Allow background usage\' and, if the switch is already on, turn it off and on again.';

  @override
  String get sharingNotificationTitle => 'Your location is being shared';

  @override
  String get sharingNotificationContent =>
      'Sharing is on. To protect your privacy, make sure to turn it off as soon as you finish your activities.';

  @override
  String get groupUnnamed => 'Unnamed group';

  @override
  String get inviteGroupFallback => 'Group';

  @override
  String get creationPreviewName => 'Organization';

  @override
  String get failureResumeOptionNotSaved =>
      'Could not save the option. Try again.';

  @override
  String get resumeOnRestartTitle => 'Resume after restart';

  @override
  String get resumeOnRestartSubtitle =>
      'If you are sharing when the device turns off or the app is updated, sharing comes back on by itself.';

  @override
  String get resumeOnRestartNeedsAlwaysLocation =>
      'To resume, location must be allowed all the time. Tap to allow.';

  @override
  String get resumeOnRestartBatteryRestricted =>
      'To resume, the app\'s battery use cannot be “Restricted”. Tap to change it.';

  @override
  String get resumeWaitingForGps =>
      'Sharing is back on and waiting for the GPS to be turned on.';

  @override
  String get resumeFailureChannel => 'Resuming sharing';

  @override
  String get resumeFailureTitle => 'Sharing did not resume';

  @override
  String get resumeFailureBackgroundLocation =>
      'Location is not allowed all the time. Tap to open the app.';

  @override
  String get resumeFailureBatteryRestricted =>
      'The app\'s battery use is “Restricted”. Tap to open the app.';

  @override
  String get resumeFailureSignedOut =>
      'Your account is no longer signed in. Tap to open the app.';

  @override
  String get resumeFailureNoGroup =>
      'You no longer share your location in any group. Tap to open the app.';
}
