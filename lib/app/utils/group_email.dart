/// Normalizes a group email to its canonical form (trimmed, lowercase).
///
/// Firestore Rules compare `group_roles` map keys case-sensitively, so every
/// `groupId` written or queried must use the same form as the claims
/// produced by the `syncClaims` Cloud Function.
String normalizeGroupEmail(String email) => email.trim().toLowerCase();
