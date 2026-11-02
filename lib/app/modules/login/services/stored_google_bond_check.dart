import 'package:flutter/foundation.dart';
import 'package:monamie_app/app/data/firebase/current_organization_firebase.dart';
import 'package:monamie_app/app/data/repository/user_google_repository.dart';

import 'google_bond_check.dart';

/// [GoogleBondCheck] over the bound organization's Firebase Auth
/// ([CurrentOrganizationFirebase]) and the Google profile kept in Hive.
class StoredGoogleBondCheck implements GoogleBondCheck {
  StoredGoogleBondCheck({UserGoogleRepository? userRepository})
    : _injectedUserRepository = userRepository;

  final UserGoogleRepository? _injectedUserRepository;

  late final UserGoogleRepository _userRepository =
      _injectedUserRepository ?? UserGoogleRepository();

  @override
  Future<bool> hasActiveBond() async {
    try {
      // No bound organization: the user must sign in and pick one first.
      if (!CurrentOrganizationFirebase.isSet) return false;
      final currentUser = CurrentOrganizationFirebase.instance.auth.currentUser;
      final storedUser = await _userRepository.getUserGoogleModel();
      final hasStoredUser = storedUser != null && storedUser.email.isNotEmpty;
      return currentUser != null && hasStoredUser;
    } catch (e) {
      debugPrint("Error checking Google bond: $e");
      return false;
    }
  }
}
