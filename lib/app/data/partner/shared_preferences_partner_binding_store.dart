import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';

import 'partner_binding.dart';
import 'partner_binding_store.dart';

/// File and key of the binding on Android. `MonAmieApplication.kt` reads
/// them, so keep both in sync.
const partnerBindingPreferencesFile = 'monamie_partner_binding';
const partnerBindingPreferencesKey = 'binding';

/// [PartnerBindingStore] on SharedPreferences.
///
/// Unlike Hive, SharedPreferences is safe to use from the UI isolate and the
/// background tracking isolate at the same time. On Android it uses the
/// classic SharedPreferences file (not DataStore) so the native side can read
/// it at process start.
class SharedPreferencesPartnerBindingStore implements PartnerBindingStore {
  SharedPreferencesPartnerBindingStore({SharedPreferencesAsync? preferences})
    : _preferences =
          preferences ??
          SharedPreferencesAsync(
            options: const SharedPreferencesAsyncAndroidOptions(
              backend: SharedPreferencesAndroidBackendLibrary.SharedPreferences,
              originalSharedPreferencesOptions:
                  AndroidSharedPreferencesStoreOptions(
                    fileName: partnerBindingPreferencesFile,
                  ),
            ),
          );

  final SharedPreferencesAsync _preferences;

  @override
  Future<PartnerBinding?> read() async {
    final source = await _preferences.getString(partnerBindingPreferencesKey);
    if (source == null) return null;
    try {
      return PartnerBinding.fromJson(jsonDecode(source));
    } on FormatException catch (error) {
      debugPrint('Ignoring an unreadable partner binding: $error');
      return null;
    } on ArgumentError catch (error) {
      debugPrint('Ignoring an unreadable partner binding: $error');
      return null;
    }
  }

  @override
  Future<void> write(PartnerBinding binding) => _preferences.setString(
    partnerBindingPreferencesKey,
    jsonEncode(binding.toJson()),
  );

  @override
  Future<void> clear() => _preferences.remove(partnerBindingPreferencesKey);
}
