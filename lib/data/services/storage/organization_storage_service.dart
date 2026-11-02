import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:monamie_app/data/services/firebase/current_organization_firebase.dart';

/// The bound organization's Cloud Storage, resolved at each call (the bound
/// organization changes at runtime). It holds no state and throws what the
/// plugin throws.
class OrganizationStorageService {
  const OrganizationStorageService();

  Reference _ref(String path) =>
      CurrentOrganizationFirebase.instance.storage.ref(path);

  /// Writes [bytes] at [path] with [contentType].
  Future<void> upload(
    String path,
    Uint8List bytes, {
    required String contentType,
  }) async {
    await _ref(path).putData(bytes, SettableMetadata(contentType: contentType));
  }

  /// Deletes the object at [path]; nothing happens when there is none.
  Future<void> delete(String path) async {
    try {
      await _ref(path).delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') rethrow;
    }
  }
}
