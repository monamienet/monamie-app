import 'dart:convert';

import 'package:crypto/crypto.dart';

/// The key of a person's documents in Firestore
/// (`organizationMemberships/{key}`, `groupMemberships/{key}`,
/// `positions/{key}`, `accounts/{key}`): the lowercase-hex SHA-256 of the
/// trimmed, lowercased [email], so no e-mail appears in a document name.
///
/// Twin of `personKey()` in `central/functions/person_key.js`,
/// `functions/person_key.js` and the security rules
/// (`hashing.sha256(...)`); all of them must agree on the same key.
String personKey(String email) =>
    sha256.convert(utf8.encode(email.trim().toLowerCase())).toString();
