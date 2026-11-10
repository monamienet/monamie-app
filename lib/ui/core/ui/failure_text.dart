import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/utils/failure.dart';
import 'package:monamie_app/utils/user_notice.dart';

/// The words for a [Failure], in [AppLocalizations]' language: the one
/// place where a failure becomes text. A [ServerRefusal] is the exception:
/// the Cloud Functions write their explanations in pt-BR, and they are
/// shown as they came.
extension FailureText on Failure {
  /// What the person reads.
  String message(AppLocalizations l10n) => switch (this) {
    ConnectionFailure(:final action) => switch (action) {
      FailedAction.conclude => l10n.failureConnectionConclude,
      FailedAction.delete => l10n.failureConnectionDelete,
      FailedAction.cancel => l10n.failureConnectionCancel,
      FailedAction.create => l10n.failureConnectionCreate,
      FailedAction.send => l10n.failureConnectionSend,
      FailedAction.accept => l10n.failureConnectionAccept,
      FailedAction.save => l10n.failureConnectionSave,
      FailedAction.switchOrganization => l10n.failureConnectionSwitch,
      FailedAction.loadAccount => l10n.failureConnectionLoadAccount,
    },
    LoadFailure(:final target) => switch (target) {
      LoadTarget.administrators => l10n.failureLoadAdministrators,
      LoadTarget.invites => l10n.failureLoadInvites,
      LoadTarget.groups => l10n.failureLoadGroups,
      LoadTarget.themes => l10n.failureLoadThemes,
      LoadTarget.creations => l10n.failureLoadCreations,
      LoadTarget.accountDeletion => l10n.failureLoadAccountDeletion,
      LoadTarget.organizationIdCheck => l10n.failureLoadOrganizationIdCheck,
    },
    ServerRefusal(:final serverMessage) => serverMessage,
    UnexplainedRefusal(:final action) => switch (action) {
      RefusedAction.conclude => l10n.failureRefusedConclude,
      RefusedAction.any => l10n.failureRefusedAny,
      RefusedAction.create => l10n.failureRefusedCreate,
      RefusedAction.save => l10n.failureRefusedSave,
    },
    UnexpectedResponse(:final creatingGroup) =>
      creatingGroup
          ? l10n.failureUnexpectedGroupResponse
          : l10n.failureUnexpectedResponse,
    OrganizationIdFailure(:final problem, :final maxLength) =>
      switch (problem) {
        OrganizationIdProblem.tooShort => l10n.creationIdTooShort,
        OrganizationIdProblem.notPlainLowercase =>
          l10n.failureOrganizationIdNotPlain,
        OrganizationIdProblem.tooLong => l10n.failureOrganizationIdTooLong(
          maxLength,
        ),
        OrganizationIdProblem.reserved => l10n.failureOrganizationIdReserved,
        OrganizationIdProblem.unusable => l10n.failureOrganizationIdUnusable,
      },
    GroupNameTooShort() => l10n.failureGroupNameTooShort,
    GroupNameTooLong() => l10n.failureGroupNameTooLong,
    GroupNameTaken(:final existingName) => l10n.failureGroupNameTaken(
      existingName,
    ),
    NoRoleChosen() => l10n.failureNoRoleChosen,
    InvalidEmail() => l10n.failureInvalidEmail,
    EmailAlreadyListed(:final email) => l10n.failureEmailAlreadyListed(email),
    LogoTooLarge(:final megabytes) => l10n.failureLogoTooLarge(megabytes),
    LogoUnreadable() => l10n.failureLogoUnreadable,
    LogoNotConverted() => l10n.failureLogoNotConverted,
    LogoNotOpened() => l10n.failureLogoNotOpened,
    EntryFailure(:final stage, :final detail) => switch (stage) {
      EntryStage.enter => l10n.failureEntryEnter(detail),
      EntryStage.check => l10n.failureEntryCheck(detail),
      EntryStage.unexpected => l10n.failureEntryUnexpected(detail),
      EntryStage.loadData => l10n.failureEntryLoadData(detail),
    },
    OrganizationEntryFailure(:final organizationName, :final detail) =>
      l10n.failureEntryOrganization(organizationName, detail),
    GoogleAuthFailure() => l10n.failureGoogleAuth,
    GoogleRenewalFailure() => l10n.failureGoogleRenewal,
    SignOutFailure(:final detail) => l10n.failureSignOut(detail),
    AccessLost(:final organizationName) => l10n.failureAccessLost(
      organizationName,
    ),
    RemovedFromOrganization(:final organizationName) =>
      organizationName == null
          ? l10n.failureRemovedFromUnnamedOrganization
          : l10n.failureRemovedFromOrganization(organizationName),
    SharingNotAllowed() => l10n.failureSharingNotAllowed,
    SharingNotChanged() => l10n.failureSharingNotChanged,
    LanguageNotSaved() => l10n.failureLanguageNotSaved,
    ResumeOptionNotSaved() => l10n.failureResumeOptionNotSaved,
  };

  /// The bold line above [message] in a `SnackBar`, or `null` for none.
  String? title(AppLocalizations l10n) => switch (this) {
    EntryFailure() ||
    OrganizationEntryFailure() ||
    GoogleAuthFailure() => l10n.failureTitleSignIn,
    GoogleRenewalFailure() ||
    ConnectionFailure(
      action: FailedAction.switchOrganization,
    ) => l10n.failureTitleSwitchOrganization,
    SignOutFailure() => l10n.failureTitleSignOut,
    SharingNotAllowed() => l10n.failureTitleSharingNotAllowed,
    SharingNotChanged() => l10n.failureTitleSharing,
    _ => null,
  };
}

/// The words for a [UserNotice], in [AppLocalizations]' language.
extension UserNoticeText on UserNotice {
  String message(AppLocalizations l10n) => switch (this) {
    WaitingForGpsNotice() => l10n.noticeWaitingForGps,
    TrackingAtRiskNotice() => l10n.noticeTrackingAtRisk,
    TrackingStopUnconfirmedNotice() => l10n.noticeTrackingStopUnconfirmed,
    BackgroundStillRestrictedNotice() => l10n.noticeBackgroundStillRestricted,
    FailureNotice(:final failure) => failure.message(l10n),
  };

  /// The bold line above [message], or `null` for none.
  String? title(AppLocalizations l10n) => switch (this) {
    WaitingForGpsNotice() => l10n.noticeWaitingForGpsTitle,
    TrackingAtRiskNotice() => l10n.noticeTrackingAtRiskTitle,
    TrackingStopUnconfirmedNotice() => l10n.noticeTrackingStopUnconfirmedTitle,
    BackgroundStillRestrictedNotice() =>
      l10n.noticeBackgroundStillRestrictedTitle,
    FailureNotice(:final failure) => failure.title(l10n),
  };
}
