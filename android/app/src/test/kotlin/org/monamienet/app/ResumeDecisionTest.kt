package org.monamienet.app

import org.junit.Assert.assertEquals
import org.junit.Test

/** Every branch of [ResumeDecision.decide]. */
class ResumeDecisionTest {
    /** [ResumeDecision.decide] with everything in place unless overridden. */
    private fun decide(
        optionOn: Boolean = true,
        sharing: Boolean = true,
        bound: Boolean = true,
        serviceConfigured: Boolean = true,
        fineLocation: Boolean = true,
        backgroundLocation: Boolean = true,
        backgroundRestricted: Boolean = false,
        locationEnabled: Boolean = true,
    ) = ResumeDecision.decide(
        optionOn = optionOn,
        sharing = sharing,
        bound = bound,
        serviceConfigured = serviceConfigured,
        fineLocation = fineLocation,
        backgroundLocation = backgroundLocation,
        backgroundRestricted = backgroundRestricted,
        locationEnabled = locationEnabled,
    )

    @Test
    fun `starts when everything is in place`() {
        assertEquals(ResumeDecision.Start, decide())
    }

    @Test
    fun `skips silently when the option is off`() {
        assertEquals(ResumeDecision.Skip, decide(optionOn = false))
    }

    @Test
    fun `skips silently when the person was not sharing`() {
        assertEquals(ResumeDecision.Skip, decide(sharing = false))
    }

    @Test
    fun `skips silently when no organization is bound`() {
        assertEquals(ResumeDecision.Skip, decide(bound = false))
    }

    @Test
    fun `skips silently when the service was never configured`() {
        assertEquals(ResumeDecision.Skip, decide(serviceConfigured = false))
    }

    @Test
    fun `skips silently with the option off even when permissions are missing`() {
        assertEquals(
            ResumeDecision.Skip,
            decide(
                optionOn = false,
                fineLocation = false,
                backgroundLocation = false,
                backgroundRestricted = true,
            ),
        )
    }

    @Test
    fun `skips silently when not sharing even with the battery restricted`() {
        assertEquals(
            ResumeDecision.Skip,
            decide(sharing = false, backgroundRestricted = true),
        )
    }

    @Test
    fun `fails on background location when precise location is not allowed`() {
        assertEquals(
            ResumeDecision.Fail(ResumeDecision.BACKGROUND_LOCATION),
            decide(fineLocation = false),
        )
    }

    @Test
    fun `fails on background location when location is not allowed all the time`() {
        assertEquals(
            ResumeDecision.Fail(ResumeDecision.BACKGROUND_LOCATION),
            decide(backgroundLocation = false),
        )
    }

    @Test
    fun `fails on the battery when the app is restricted`() {
        assertEquals(
            ResumeDecision.Fail(ResumeDecision.BATTERY_RESTRICTED),
            decide(backgroundRestricted = true),
        )
    }

    @Test
    fun `names the location before the battery when both fail`() {
        assertEquals(
            ResumeDecision.Fail(ResumeDecision.BACKGROUND_LOCATION),
            decide(backgroundLocation = false, backgroundRestricted = true),
        )
    }

    @Test
    fun `fails on the location when the device's location is off`() {
        assertEquals(
            ResumeDecision.Fail(ResumeDecision.LOCATION_OFF),
            decide(locationEnabled = false),
        )
    }

    @Test
    fun `skips silently with the option off even when the location is off`() {
        assertEquals(
            ResumeDecision.Skip,
            decide(optionOn = false, locationEnabled = false),
        )
    }

    @Test
    fun `skips silently when not sharing even when the location is off`() {
        assertEquals(
            ResumeDecision.Skip,
            decide(sharing = false, locationEnabled = false),
        )
    }

    @Test
    fun `skips silently when no organization is bound even when the location is off`() {
        assertEquals(
            ResumeDecision.Skip,
            decide(bound = false, locationEnabled = false),
        )
    }

    @Test
    fun `skips silently when the service was never configured even when the location is off`() {
        assertEquals(
            ResumeDecision.Skip,
            decide(serviceConfigured = false, locationEnabled = false),
        )
    }

    @Test
    fun `names the missing permission before the location being off`() {
        assertEquals(
            ResumeDecision.Fail(ResumeDecision.BACKGROUND_LOCATION),
            decide(backgroundLocation = false, locationEnabled = false),
        )
        assertEquals(
            ResumeDecision.Fail(ResumeDecision.BACKGROUND_LOCATION),
            decide(fineLocation = false, locationEnabled = false),
        )
    }

    @Test
    fun `names the battery before the location being off`() {
        assertEquals(
            ResumeDecision.Fail(ResumeDecision.BATTERY_RESTRICTED),
            decide(backgroundRestricted = true, locationEnabled = false),
        )
    }

    @Test
    fun `failure reasons are the Dart ResumeFailure names`() {
        assertEquals("backgroundLocation", ResumeDecision.BACKGROUND_LOCATION)
        assertEquals("batteryRestricted", ResumeDecision.BATTERY_RESTRICTED)
        assertEquals("locationOff", ResumeDecision.LOCATION_OFF)
    }
}
