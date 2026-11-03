import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

/// What could not be finished, in a [ConnectionFailure]: the person is told
/// that it failed and to check the connection.
enum FailedAction {
  /// Any other operation ("concluir").
  conclude,
  delete,
  cancel,
  create,
  send,
  accept,
  save,

  /// "Trocar de organização".
  switchOrganization,

  /// Reading *Minha conta*.
  loadAccount,
}

/// What could not be read, in a [LoadFailure].
enum LoadTarget {
  administrators,
  invites,
  groups,
  themes,

  /// The organizations being created.
  creations,

  /// The account's pending deletion.
  accountDeletion,

  /// Whether an organization identifier is free.
  organizationIdCheck,
}

/// What the server refused without explaining why, in an
/// [UnexplainedRefusal].
enum RefusedAction {
  /// Any operation ("concluir").
  conclude,

  /// An account operation, said without a verb.
  any,
  create,
  save,
}

/// Why an organization identifier cannot be used, in an
/// [OrganizationIdFailure].
enum OrganizationIdProblem {
  /// Fewer than 3 letters (or none).
  tooShort,

  /// Something other than lowercase letters a to z.
  notPlainLowercase,

  /// More than [OrganizationIdFailure.maxLength] letters.
  tooLong,

  /// One of the identifiers MonAmie keeps for itself.
  reserved,

  /// The server says it cannot be used, without saying why.
  unusable,
}

/// The step of the entry into an organization that failed, in an
/// [EntryFailure].
enum EntryStage {
  /// Entering after a sign-in ("entrar").
  enter,

  /// Asking again which organizations the person belongs to ("verificar").
  check,

  /// Anything else that went wrong around Google's sign-in.
  unexpected,

  /// Entering after a web sign-in ("carregar seus dados").
  loadData,
}

/// Why an operation failed, as data: the screen that shows it chooses the
/// words, in the device's language (`FailureText` in
/// `lib/ui/core/ui/failure_text.dart`). [Err] carries one; so do the states
/// that show a failure inline.
///
/// One case per distinct thing that can go wrong, with what its text
/// needs. Compared by content (freezed), so a state holding one keeps its
/// value equality.
@freezed
sealed class Failure with _$Failure {
  /// [action] failed, most likely for lack of connection.
  const factory Failure.connection(FailedAction action) = ConnectionFailure;

  /// [target] could not be read.
  const factory Failure.load(LoadTarget target) = LoadFailure;

  /// A Cloud Function refused with its own explanation, [serverMessage]: the
  /// functions write it in pt-BR, and it is shown as it came, in every
  /// language.
  const factory Failure.serverRefusal(String serverMessage) = ServerRefusal;

  /// A Cloud Function refused [action] without an explanation.
  const factory Failure.unexplainedRefusal(RefusedAction action) =
      UnexplainedRefusal;

  /// The server answered something the app cannot read; [creatingGroup]
  /// when it was the answer to a group's creation.
  const factory Failure.unexpectedResponse({
    @Default(false) bool creatingGroup,
  }) = UnexpectedResponse;

  /// An organization identifier that cannot be used; [maxLength] is the
  /// longest one allowed, for [OrganizationIdProblem.tooLong].
  const factory Failure.organizationId(
    OrganizationIdProblem problem, {
    @Default(20) int maxLength,
  }) = OrganizationIdFailure;

  /// A group name with fewer than 2 letters.
  const factory Failure.groupNameTooShort() = GroupNameTooShort;

  /// A group name longer than 40 characters.
  const factory Failure.groupNameTooLong() = GroupNameTooLong;

  /// A group name already taken by [existingName] (ignoring case, accents
  /// and spaces).
  const factory Failure.groupNameTaken(String existingName) = GroupNameTaken;

  /// No role ticked for a person.
  const factory Failure.noRoleChosen() = NoRoleChosen;

  /// An invite's e-mail that is not an e-mail address.
  const factory Failure.invalidEmail() = InvalidEmail;

  /// An invite's [email] already in the list.
  const factory Failure.emailAlreadyListed(String email) = EmailAlreadyListed;

  /// A logo file of [megabytes] MB, over the 10 MB allowed.
  const factory Failure.logoTooLarge(int megabytes) = LogoTooLarge;

  /// A logo file no decoder could open (with the formats accepted).
  const factory Failure.logoUnreadable() = LogoUnreadable;

  /// The logo's PNG could not be produced.
  const factory Failure.logoNotConverted() = LogoNotConverted;

  /// A logo file that could not be opened for any other reason.
  const factory Failure.logoNotOpened() = LogoNotOpened;

  /// Entering an organization failed at [stage]; [detail] is the original
  /// error as text, which the message quotes.
  const factory Failure.entry(EntryStage stage, String detail) = EntryFailure;

  /// Entering [organizationName], picked on *Escolher organização*, failed;
  /// [detail] is the original error as text.
  const factory Failure.organizationEntry(
    String organizationName,
    String detail,
  ) = OrganizationEntryFailure;

  /// A web Google sign-in returned no account.
  const factory Failure.googleAuth() = GoogleAuthFailure;

  /// Google did not renew the sign-in that switching organization needs.
  const factory Failure.googleRenewal() = GoogleRenewalFailure;

  /// Signing out failed; [detail] is the original error as text.
  const factory Failure.signOut(String detail) = SignOutFailure;

  /// The directory lists [organizationName] but the person has no
  /// membership there any more.
  const factory Failure.accessLost(String organizationName) = AccessLost;

  /// The person was removed from the bound organization, [organizationName]
  /// when known.
  const factory Failure.removedFromOrganization(String? organizationName) =
      RemovedFromOrganization;

  /// The person publishes in no group, so sharing cannot start.
  const factory Failure.sharingNotAllowed() = SharingNotAllowed;

  /// Turning sharing on or off failed.
  const factory Failure.sharingNotChanged() = SharingNotChanged;
}
