package org.monamienet.app

import android.app.Application
import android.content.Context
import android.util.Log
import com.google.firebase.FirebaseApp
import com.google.firebase.FirebaseOptions
import org.json.JSONObject

/**
 * Creates the bound partner's FirebaseApp at process start, before any
 * Flutter engine runs.
 *
 * The UI and the background tracking service run in separate Flutter
 * engines of this process, and each reads the list of native Firebase apps
 * only once. If both created `partner-<id>` themselves, the second would fail
 * with "already exists" (the service can be restarted by Android without the
 * UI). Creating it here means both engines just find it.
 *
 * Reads the binding that `SharedPreferencesPartnerBindingStore` writes:
 * file `monamie_partner_binding`, key `binding`, JSON with `id` and
 * `options`.
 */
class MonAmieApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        createPartnerApp()
    }

    private fun createPartnerApp() {
        val json = getSharedPreferences(BINDING_FILE, Context.MODE_PRIVATE)
            .getString(BINDING_KEY, null) ?: return
        try {
            val binding = JSONObject(json)
            val name = "partner-" + binding.getString("id")
            if (FirebaseApp.getApps(this).any { it.name == name }) return
            val options = binding.getJSONObject("options")
            val builder = FirebaseOptions.Builder()
                .setApiKey(options.getString("apiKey"))
                .setApplicationId(options.getString("appId"))
                .setProjectId(options.getString("projectId"))
                .setGcmSenderId(options.getString("messagingSenderId"))
            options.optString("storageBucket").takeIf { it.isNotEmpty() }
                ?.let { builder.setStorageBucket(it) }
            FirebaseApp.initializeApp(this, builder.build(), name)
        } catch (error: Exception) {
            // The Dart side creates the app itself if this fails.
            Log.w(TAG, "Could not create the partner Firebase app", error)
        }
    }

    private companion object {
        const val TAG = "MonAmieApplication"
        const val BINDING_FILE = "monamie_partner_binding"
        const val BINDING_KEY = "binding"
    }
}
