import 'package:firebase_core/firebase_core.dart';
import 'package:monamie_app/app/config/organization/organization.dart';
import 'package:monamie_app/app/config/organization/organization_config.dart';
import 'package:monamie_app/app/data/firebase/current_organization_firebase.dart';
import 'package:monamie_app/app/data/firebase/firebase_app_organization_firebase.dart';

import 'organization_binding.dart';
import 'organization_binding_store.dart';
import 'shared_preferences_organization_binding_store.dart';

/// Binds, restores and forgets the organization in the current isolate.
///
/// Binding sets [Organization.current] and [CurrentOrganizationFirebase] together, so
/// the branding and the Firebase project always belong to the same
/// organization.
class OrganizationSession {
  OrganizationSession({OrganizationBindingStore? store})
    : _store = store ?? SharedPreferencesOrganizationBindingStore();

  final OrganizationBindingStore _store;

  /// Binds [binding] in this isolate and, when [remember] is true, stores it
  /// so the next launch (and the background isolate) binds it too.
  Future<void> bind(OrganizationBinding binding, {bool remember = true}) async {
    final app = await organizationFirebaseApp(binding);
    CurrentOrganizationFirebase.set(
      FirebaseAppOrganizationFirebase(app, binding.organization.id),
    );
    Organization.bind(binding.organization);
    if (remember) await _store.write(binding);
  }

  /// Binds the stored organization. Returns it, or `null` when none is stored.
  Future<OrganizationBinding?> restore() async {
    final binding = await _store.read();
    if (binding != null) await bind(binding, remember: false);
    return binding;
  }

  /// Stores a newer branding of the bound organization for the next launch.
  ///
  /// The running app keeps its current look, so the theme never changes in
  /// the middle of use.
  Future<void> storeBranding(OrganizationConfig organization) async {
    final binding = await _store.read();
    if (binding == null || binding.organization.id != organization.id) return;
    await _store.write(
      OrganizationBinding(organization: organization, options: binding.options),
    );
  }

  /// Forgets the organization: the stored binding, [Organization.current] and
  /// [CurrentOrganizationFirebase].
  ///
  /// The organization's [FirebaseApp] is left alone on purpose. cloud_firestore
  /// caches instances by app name and never evicts them, so a deleted app
  /// can break Firestore for the whole process. Without a signed-in user the
  /// app reaches no data, and it goes away when the process ends.
  Future<void> forget() async {
    await _store.clear();
    Organization.unbind();
    CurrentOrganizationFirebase.clear();
  }
}

/// The organization's [FirebaseApp], created if this isolate has not seen it.
///
/// On Android `MonAmieApplication` usually created it natively at process
/// start; `initializeApp` then returns that app because the options match.
Future<FirebaseApp> organizationFirebaseApp(OrganizationBinding binding) async {
  for (final app in Firebase.apps) {
    if (app.name == binding.appName) return app;
  }
  return Firebase.initializeApp(
    name: binding.appName,
    options: binding.options,
  );
}
