package org.monamienet.app

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import org.json.JSONException
import org.json.JSONObject

/**
 * The notifications saying sharing could not resume after a restart or an
 * update, and the file that drives resuming.
 *
 * The file is `SharingResumePreferencesService`'s (Dart): keep the names in
 * sync. Its texts come from the app's ARB files, stored by the screen in the
 * app's language, so nothing here holds text for people.
 *
 * Two sources: [ResumeSharingReceiver] calls [show] when it cannot start the
 * service; the tracking service's isolate, which has no way to post a
 * notification, writes the reason under [FAILURE_KEY] and the listener
 * [listen] installs (same process, same SharedPreferences instance) shows
 * it and removes it.
 */
object ResumeFailures {
    const val PREFERENCES_FILE = "monamie_sharing_resume"
    const val OPTION_KEY = "resumeOnRestart"
    const val INTENT_KEY = "intent"
    const val TEXTS_KEY = "texts"
    const val RESUMING_KEY = "resuming"
    const val FAILURE_KEY = "failure"

    private const val TAG = "ResumeFailures"
    private const val CHANNEL_ID = "monamie_resume_failures"
    private const val NOTIFICATION_ID = 7301

    /** Held here: SharedPreferences keeps its listeners weakly. */
    private var listener: SharedPreferences.OnSharedPreferenceChangeListener? = null

    fun preferences(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFERENCES_FILE, Context.MODE_PRIVATE)

    /** Shows the failures the tracking service reports, for as long as the process lives. */
    fun listen(context: Context) {
        val appContext = context.applicationContext
        val preferences = preferences(appContext)
        val onChange = SharedPreferences.OnSharedPreferenceChangeListener { changed, key ->
            if (key == FAILURE_KEY) showReported(appContext, changed)
        }
        listener = onChange
        preferences.registerOnSharedPreferenceChangeListener(onChange)
        // Reported while no listener ran (the process ended first).
        showReported(appContext, preferences)
    }

    private fun showReported(context: Context, preferences: SharedPreferences) {
        val reason = preferences.getString(FAILURE_KEY, null) ?: return
        preferences.edit().remove(FAILURE_KEY).apply()
        show(context, reason)
    }

    /** Tells the person sharing did not resume, for [reason] (a `ResumeFailure` name). */
    fun show(context: Context, reason: String) {
        val texts = texts(preferences(context))
        val text = texts?.optJSONObject("failures")?.optString(reason).orEmpty()
        val title = texts?.optString("failureTitle").orEmpty()
        val channel = texts?.optString("failureChannel").orEmpty()
        if (text.isEmpty() || title.isEmpty() || channel.isEmpty()) {
            Log.w(TAG, "No texts to tell why sharing did not resume ($reason)")
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            Log.w(TAG, "Notifications not allowed; sharing did not resume ($reason)")
            return
        }
        val manager = context.getSystemService(NotificationManager::class.java)
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(CHANNEL_ID, channel, NotificationManager.IMPORTANCE_DEFAULT),
            )
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }
        val open = context.packageManager.getLaunchIntentForPackage(context.packageName)
        builder
            // The sharing notification's icon.
            .setSmallIcon(id.flutter.flutter_background_service.R.drawable.ic_bg_service_small)
            .setContentTitle(title)
            .setContentText(text)
            .setStyle(Notification.BigTextStyle().bigText(text))
            .setAutoCancel(true)
        if (open != null) {
            builder.setContentIntent(
                PendingIntent.getActivity(
                    context,
                    0,
                    open,
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
                ),
            )
        }
        manager.notify(NOTIFICATION_ID, builder.build())
    }

    /** The texts the screen stored, or `null` when there are none. */
    fun texts(preferences: SharedPreferences): JSONObject? {
        val source = preferences.getString(TEXTS_KEY, null) ?: return null
        return try {
            JSONObject(source)
        } catch (error: JSONException) {
            Log.w(TAG, "Unreadable texts", error)
            null
        }
    }
}
