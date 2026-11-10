package org.monamienet.app

/**
 * What [ResumeSharingReceiver] does after the device restarts or the app is
 * updated. Plain Kotlin, so a JVM test checks it without a device.
 */
sealed interface ResumeDecision {
    /** Nothing, silently: the person did not choose to resume or was not sharing. */
    object Skip : ResumeDecision

    /** Not started; a notification tells the person [reason] (a `ResumeFailure` name). */
    data class Fail(val reason: String) : ResumeDecision

    /** The tracking service starts. */
    object Start : ResumeDecision

    companion object {
        /** `ResumeFailure.backgroundLocation` in Dart. */
        const val BACKGROUND_LOCATION = "backgroundLocation"

        /** `ResumeFailure.batteryRestricted` in Dart. */
        const val BATTERY_RESTRICTED = "batteryRestricted"

        /** `ResumeFailure.locationOff` in Dart. */
        const val LOCATION_OFF = "locationOff"

        /**
         * [optionOn]: the person chose to resume; [sharing]: they were sharing
         * (the intent is stored); [bound]: an organization is bound;
         * [serviceConfigured]: the tracking service was configured once (it
         * knows its Dart entry point). Then the checks without which starting
         * would fail: on Android 14+ a `location` foreground service started
         * without location permission throws, and one started from the
         * background only gets positions with background location; a
         * "Restricted" app loses the foreground status as soon as it starts;
         * with the device's location off ([locationEnabled] false) Android
         * refuses a `location` foreground service started from the
         * background, and the process dies without it (seen on Android 15).
         */
        fun decide(
            optionOn: Boolean,
            sharing: Boolean,
            bound: Boolean,
            serviceConfigured: Boolean,
            fineLocation: Boolean,
            backgroundLocation: Boolean,
            backgroundRestricted: Boolean,
            locationEnabled: Boolean,
        ): ResumeDecision = when {
            !optionOn || !sharing || !bound || !serviceConfigured -> Skip
            !fineLocation || !backgroundLocation -> Fail(BACKGROUND_LOCATION)
            backgroundRestricted -> Fail(BATTERY_RESTRICTED)
            !locationEnabled -> Fail(LOCATION_OFF)
            else -> Start
        }
    }
}
