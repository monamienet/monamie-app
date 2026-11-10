package org.monamienet.app

import android.Manifest
import android.app.ActivityManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import id.flutter.flutter_background_service.BackgroundService

/**
 * Resumes sharing after the device restarts or the app is updated, when the
 * person chose so and was sharing ([ResumeDecision]).
 *
 * Ours, not the plugin's `BootReceiver` (its `autoStartOnBoot` stays off):
 * that one starts the service unconditionally, and only the Dart isolate
 * could then find out it should not run. This one decides first, so nothing
 * starts when it should not and a missing permission never reaches
 * `startForeground`.
 *
 * `BOOT_COMPLETED`, not `LOCKED_BOOT_COMPLETED`: Firebase Auth keeps its
 * credentials in credential-encrypted storage, readable only after the first
 * unlock.
 */
class ResumeSharingReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED &&
            intent.action != Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            return
        }
        val preferences = ResumeFailures.preferences(context)
        val decision = ResumeDecision.decide(
            optionOn = preferences.getBoolean(ResumeFailures.OPTION_KEY, false),
            sharing = preferences.contains(ResumeFailures.INTENT_KEY),
            bound = context
                .getSharedPreferences(MonAmieApplication.BINDING_FILE, Context.MODE_PRIVATE)
                .contains(MonAmieApplication.BINDING_KEY),
            serviceConfigured = pluginConfig(context).getLong(PLUGIN_HANDLE_KEY, 0L) != 0L,
            fineLocation = granted(context, Manifest.permission.ACCESS_FINE_LOCATION),
            backgroundLocation = Build.VERSION.SDK_INT < Build.VERSION_CODES.Q ||
                granted(context, Manifest.permission.ACCESS_BACKGROUND_LOCATION),
            backgroundRestricted = Build.VERSION.SDK_INT >= Build.VERSION_CODES.P &&
                context.getSystemService(ActivityManager::class.java).isBackgroundRestricted,
        )
        Log.i(TAG, "${intent.action}: $decision")
        when (decision) {
            is ResumeDecision.Skip -> Unit
            is ResumeDecision.Fail -> ResumeFailures.show(context, decision.reason)
            is ResumeDecision.Start -> start(context)
        }
    }

    private fun start(context: Context) {
        val preferences = ResumeFailures.preferences(context)
        // Tells the service's isolate it resumes with no screen: what stops it
        // from publishing is then shown to the person.
        preferences.edit().putBoolean(ResumeFailures.RESUMING_KEY, true).commit()
        // The notification the service starts with, in the app's language
        // (the plugin keeps the texts of the last start from the screen).
        ResumeFailures.texts(preferences)?.let { texts ->
            val title = texts.optString("notificationTitle")
            val content = texts.optString("notificationContent")
            if (title.isNotEmpty() && content.isNotEmpty()) {
                pluginConfig(context).edit()
                    .putString(PLUGIN_TITLE_KEY, title)
                    .putString(PLUGIN_CONTENT_KEY, content)
                    .commit()
            }
        }
        // As the plugin's BootReceiver: the service releases it once running.
        if (BackgroundService.lockStatic == null) {
            BackgroundService.getLock(context).acquire()
        }
        try {
            context.startForegroundService(Intent(context, BackgroundService::class.java))
        } catch (error: RuntimeException) {
            // E.g. ForegroundServiceStartNotAllowedException on a device that
            // does not treat this broadcast as an exemption.
            Log.w(TAG, "Could not resume sharing", error)
            preferences.edit().remove(ResumeFailures.RESUMING_KEY).apply()
        }
    }

    private fun granted(context: Context, permission: String) =
        context.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED

    /** The plugin's own preferences (`Config.java` in flutter_background_service_android). */
    private fun pluginConfig(context: Context) =
        context.getSharedPreferences(PLUGIN_PREFERENCES, Context.MODE_PRIVATE)

    private companion object {
        const val TAG = "ResumeSharingReceiver"
        const val PLUGIN_PREFERENCES = "id.flutter.background_service"
        const val PLUGIN_HANDLE_KEY = "background_handle"
        const val PLUGIN_TITLE_KEY = "initial_notification_title"
        const val PLUGIN_CONTENT_KEY = "initial_notification_content"
    }
}
