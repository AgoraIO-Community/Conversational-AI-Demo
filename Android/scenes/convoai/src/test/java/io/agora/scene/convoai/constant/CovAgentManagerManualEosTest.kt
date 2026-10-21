package io.agora.scene.convoai.constant

import io.agora.scene.convoai.api.CovAgentLanguage
import io.agora.scene.convoai.api.CovAgentPreset
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

class CovAgentManagerManualEosTest {
    private val full = language("en-US", aiVad = true, pause = true)
    private val vadOff = language("ja-JP", aiVad = false, pause = true)
    private val standard = preset("standard_a", "en-US", listOf(full, vadOff))
    private val standardB = preset("standard_b", "", listOf(vadOff, full))

    @Before fun setUp() = CovAgentManager.resetData()
    @After fun tearDown() = CovAgentManager.resetData()

    private fun language(code: String, aiVad: Boolean, pause: Boolean) = CovAgentLanguage(
        language_code = code, language_name = code, aivad_supported = true,
        aivad_enabled_by_default = aiVad, pause_state_enabled_by_default = pause
    )

    private fun preset(name: String, defaultCode: String, languages: List<CovAgentLanguage>) = CovAgentPreset(
        index = 0, name = name, display_name = name, preset_type = "standard",
        default_language_code = defaultCode, default_language_name = "", support_languages = languages,
        call_time_limit_second = 0, call_time_limit_avatar_second = 0, is_support_vision = false,
        avatar_url = null, description = "", advanced_features_enable_sal = false, is_support_sal = null
    )

    private fun stored() = CovAgentManager.enableAiVad to CovAgentManager.enableAiPause

    @Test fun switchMasksAiVadAndPauseAndOffRestoresStoredValues() {
        CovAgentManager.setPreset(standard)
        CovAgentManager.enableManualEos = true
        // Open-source builds have no Walkie-Talkie Mode, so nothing is masked there.
        assertEquals(!CovAgentManager.isOpenSource, CovAgentManager.isManualEosActive)
        assertEquals(true to true, stored())
        CovAgentManager.enableManualEos = false
        assertFalse(CovAgentManager.isManualEosActive)
        assertEquals(true to true, stored())
    }

    @Test fun presetChangeTurnsSwitchOffBeforeLanguageDefaults() {
        CovAgentManager.setPreset(standard)
        CovAgentManager.enableManualEos = true
        CovAgentManager.setPreset(standard.copy())
        assertTrue(CovAgentManager.enableManualEos)
        CovAgentManager.setPreset(standardB)
        assertFalse(CovAgentManager.enableManualEos)
        assertEquals(vadOff, CovAgentManager.language)
        assertEquals(false to false, stored())
    }
}
