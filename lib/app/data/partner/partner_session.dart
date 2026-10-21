import 'package:firebase_core/firebase_core.dart';
import 'package:monamie_app/app/config/partner/partner.dart';
import 'package:monamie_app/app/config/partner/partner_config.dart';
import 'package:monamie_app/app/data/firebase/current_partner_firebase.dart';
import 'package:monamie_app/app/data/firebase/firebase_app_partner_firebase.dart';

import 'partner_binding.dart';
import 'partner_binding_store.dart';
import 'shared_preferences_partner_binding_store.dart';

/// Binds, restores and forgets the partner in the current isolate.
///
/// Binding sets [Partner.current] and [CurrentPartnerFirebase] together, so
/// the branding, the root group and the Firebase project always belong to
/// the same partner.
class PartnerSession {
  PartnerSession({PartnerBindingStore? store})
    : _store = store ?? SharedPreferencesPartnerBindingStore();

  final PartnerBindingStore _store;

  /// Binds [binding] in this isolate and, when [remember] is true, stores it
  /// so the next launch (and the background isolate) binds it too.
  Future<void> bind(PartnerBinding binding, {bool remember = true}) async {
    final app = await partnerFirebaseApp(binding);
    CurrentPartnerFirebase.set(FirebaseAppPartnerFirebase(app));
    Partner.bind(binding.partner);
    if (remember) await _store.write(binding);
  }

  /// Binds the stored partner. Returns it, or `null` when none is stored.
  Future<PartnerBinding?> restore() async {
    final binding = await _store.read();
    if (binding != null) await bind(binding, remember: false);
    return binding;
  }

  /// Stores a newer branding of the bound partner for the next launch.
  ///
  /// The running app keeps its current look, so the theme never changes in
  /// the middle of use.
  Future<void> storeBranding(PartnerConfig partner) async {
    final binding = await _store.read();
    if (binding == null || binding.partner.id != partner.id) return;
    await _store.write(
      PartnerBinding(partner: partner, options: binding.options),
    );
  }

  /// Forgets the partner: the stored binding, [Partner.current] and
  /// [CurrentPartnerFirebase].
  ///
  /// The partner's [FirebaseApp] is left alone on purpose. cloud_firestore
  /// caches instances by app name and never evicts them, so a deleted app
  /// can break Firestore for the whole process. Without a signed-in user the
  /// app reaches no data, and it goes away when the process ends.
  Future<void> forget() async {
    await _store.clear();
    Partner.unbind();
    CurrentPartnerFirebase.clear();
  }
}

/// The partner's [FirebaseApp], created if this isolate has not seen it.
///
/// On Android `MonAmieApplication` usually created it natively at process
/// start; `initializeApp` then returns that app because the options match.
Future<FirebaseApp> partnerFirebaseApp(PartnerBinding binding) async {
  for (final app in Firebase.apps) {
    if (app.name == binding.appName) return app;
  }
  return Firebase.initializeApp(
    name: binding.appName,
    options: binding.options,
  );
}
