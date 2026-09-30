package io.agora.scene.convoai.ui.living

import com.google.gson.Gson
import io.agora.rtc2.Constants
import io.agora.scene.convoai.api.CovAgentPreset
import io.agora.scene.convoai.constant.CovAgentManager
import io.agora.scene.convoai.constant.isAvatarEnabledForSession
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class CovLivingDebugOverrideTest {

    @After
    fun tearDown() {
        CovAgentManager.resetData()
    }

    @Test
    fun resolveAudioScenario_usesAiClientForOrdinaryVoice() {
        val scenario = resolveAudioScenario(
            isAvatarEnabled = false,
            isIndependent = false,
            isDebug = false,
            debugAudioScenario = null
        )

        assertEquals(Constants.AUDIO_SCENARIO_AI_CLIENT, scenario)
    }

    @Test
    fun resolveAudioScenario_usesChorusForIndependentVoice() {
        val scenario = resolveAudioScenario(
            isAvatarEnabled = false,
            isIndependent = true,
            isDebug = false,
            debugAudioScenario = null
        )

        assertEquals(Constants.AUDIO_SCENARIO_CHORUS, scenario)
    }

    @Test
    fun resolveAudioScenario_avatarTakesPriorityOverIndependent() {
        val scenario = resolveAudioScenario(
            isAvatarEnabled = true,
            isIndependent = true,
            isDebug = false,
            debugAudioScenario = null
        )

        assertEquals(Constants.AUDIO_SCENARIO_DEFAULT, scenario)
    }

    @Test
    fun resolveAudioScenario_debugOverrideTakesPriorityOverEveryDefault() {
        for (isAvatarEnabled in listOf(false, true)) {
            for (isIndependent in listOf(false, true)) {
                val scenario = resolveAudioScenario(
                    isAvatarEnabled = isAvatarEnabled,
                    isIndependent = isIndependent,
                    isDebug = true,
                    debugAudioScenario = Constants.AUDIO_SCENARIO_GAME_STREAMING
                )

                assertEquals(Constants.AUDIO_SCENARIO_GAME_STREAMING, scenario)
            }
        }
    }

    @Test
    fun resolveAudioScenario_ignoresOverrideOutsideDebugMode() {
        val scenario = resolveAudioScenario(
            isAvatarEnabled = false,
            isIndependent = true,
            isDebug = false,
            debugAudioScenario = Constants.AUDIO_SCENARIO_DEFAULT
        )

        assertEquals(Constants.AUDIO_SCENARIO_CHORUS, scenario)
    }

    @Test
    fun resolveAudioScenario_usesDefaultWhenDebugOverrideIsMissing() {
        val scenario = resolveAudioScenario(
            isAvatarEnabled = false,
            isIndependent = true,
            isDebug = true,
            debugAudioScenario = null
        )

        assertEquals(Constants.AUDIO_SCENARIO_CHORUS, scenario)
    }

    @Test
    fun resolveAudioScenario_customAvatarPresetUsesDefaultWithoutSeparateAvatarSelection() {
        CovAgentManager.setPreset(customPreset(isSupportAvatar = true))

        assertNull(CovAgentManager.avatar)
        assertTrue(CovAgentManager.isEnableAvatar)
        assertEquals(
            Constants.AUDIO_SCENARIO_DEFAULT,
            resolveAudioScenario(
                isAvatarEnabled = CovAgentManager.isEnableAvatar,
                isIndependent = CovAgentManager.getPreset()?.isIndependent == true,
                isDebug = false,
                debugAudioScenario = null
            )
        )
    }

    @Test
    fun resolveAudioScenario_customPresetWithoutAvatarUsesAiClient() {
        CovAgentManager.setPreset(customPreset(isSupportAvatar = false))

        assertNull(CovAgentManager.avatar)
        assertFalse(CovAgentManager.isEnableAvatar)
        assertEquals(
            Constants.AUDIO_SCENARIO_AI_CLIENT,
            resolveAudioScenario(
                isAvatarEnabled = CovAgentManager.isEnableAvatar,
                isIndependent = CovAgentManager.getPreset()?.isIndependent == true,
                isDebug = false,
                debugAudioScenario = null
            )
        )
    }

    @Test
    fun openSourceNeverEnablesAvatarDespiteOldSelectionOrCustomPreset() {
        for (hasSelectedAvatar in listOf(false, true)) {
            for (hasConfiguredCustomAvatar in listOf(false, true)) {
                val enabled = isAvatarEnabledForSession(
                    isOpenSource = true,
                    hasSelectedAvatar = hasSelectedAvatar,
                    hasConfiguredCustomAvatar = hasConfiguredCustomAvatar
                )
                assertFalse(enabled)
                assertEquals(
                    Constants.AUDIO_SCENARIO_AI_CLIENT,
                    resolveAudioScenario(enabled, false, false, null)
                )
            }
        }
    }

    @Test
    fun nonOpenSourceStillEnablesSelectedAndCustomAvatars() {
        assertTrue(isAvatarEnabledForSession(false, true, false))
        assertTrue(isAvatarEnabledForSession(false, false, true))
        assertFalse(isAvatarEnabledForSession(false, false, false))
    }

    @Test
    fun serializedStartRequestParametersNeverContainServerAudioScenario() {
        for (enableMetrics in listOf(true, false)) {
            val parameters = Gson().toJsonTree(
                buildAgentStartParameters(enableMetrics = enableMetrics, enableWords = true)
            ).asJsonObject
            assertFalse(parameters.has("audio_scenario"))
            assertEquals("rtm", parameters.get("data_channel").asString)
            assertEquals(enableMetrics, parameters.get("enable_metrics").asBoolean)
            assertTrue(parameters.has("transcript"))
        }
    }

    private fun customPreset(isSupportAvatar: Boolean) = CovAgentPreset(
        index = 0,
        name = "custom",
        display_name = "Custom",
        preset_type = "custom_private",
        default_language_code = "",
        default_language_name = "",
        support_languages = emptyList(),
        call_time_limit_second = 600L,
        call_time_limit_avatar_second = 300L,
        is_support_vision = false,
        avatar_url = null,
        description = "",
        advanced_features_enable_sal = false,
        is_support_sal = false,
        is_support_avatar = isSupportAvatar,
        avatar_vendor = "spatius"
    )
}
