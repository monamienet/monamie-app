import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';

import 'organization_binding.dart';
import 'organization_binding_store.dart';

/// File and key of the binding on Android. `MonAmieApplication.kt` reads
/// them, so keep both in sync.
const organizationBindingPreferencesFile = 'monamie_organization_binding';
const organizationBindingPreferencesKey = 'binding';

/// [OrganizationBindingStore] on SharedPreferences.
///
/// Unlike Hive, SharedPreferences is safe to use from the UI isolate and the
/// background tracking isolate at the same time. On Android it uses the
/// classic SharedPreferences file (not DataStore) so the native side can read
/// it at process start.
class SharedPreferencesOrganizationBindingStore
    implements OrganizationBindingStore {
  SharedPreferencesOrganizationBindingStore({
    SharedPreferencesAsync? preferences,
  }) : _preferences =
           preferences ??
           SharedPreferencesAsync(
             options: const SharedPreferencesAsyncAndroidOptions(
               backend:
                   SharedPreferencesAndroidBackendLibrary.SharedPreferences,
               originalSharedPreferencesOptions:
                   AndroidSharedPreferencesStoreOptions(
                     fileName: organizationBindingPreferencesFile,
                   ),
             ),
           );

  final SharedPreferencesAsync _preferences;

  @override
  Future<OrganizationBinding?> read() async {
    final source = await _preferences.getString(
      organizationBindingPreferencesKey,
    );
    if (source == null) return null;
    try {
      return OrganizationBinding.fromJson(jsonDecode(source));
    } on FormatException catch (error) {
      debugPrint('Ignoring an unreadable organization binding: $error');
      return null;
    } on ArgumentError catch (error) {
      debugPrint('Ignoring an unreadable organization binding: $error');
      return null;
    }
  }

  @override
  Future<void> write(OrganizationBinding binding) => _preferences.setString(
    organizationBindingPreferencesKey,
    jsonEncode(binding.toJson()),
  );

  @override
  Future<void> clear() =>
      _preferences.remove(organizationBindingPreferencesKey);
}
