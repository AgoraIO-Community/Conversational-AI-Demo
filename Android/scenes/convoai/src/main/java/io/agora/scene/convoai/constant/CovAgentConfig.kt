package io.agora.scene.convoai.constant

import io.agora.scene.convoai.api.CovAgentLanguage
import io.agora.scene.convoai.api.CovAgentPreset
import kotlin.random.Random

enum class AgentConnectionState() {
    IDLE,
    CONNECTING,
    CONNECTED,
    CONNECTED_INTERRUPT,
    ERROR
}

object CovAgentManager {

    private val TAG = "CovAgentManager"

    // Settings
    private var presetList: List<CovAgentPreset>? = null
    private var preset: CovAgentPreset? = null
    var language: CovAgentLanguage? = null

    var enableAiVad = false
    val enableBHVS = true

    // values
    val uid = Random.nextInt(1000, 10000000)
    const val agentUID = 999
    var channelName: String = ""

    fun setPresetList(l: List<CovAgentPreset>) {
        presetList = l.filter { it.preset_type != "custom" }
        setPreset(presetList?.firstOrNull())
    }

    fun getPresetList(): List<CovAgentPreset>? {
        return presetList
    }

    fun setPreset(p: CovAgentPreset?) {
        preset = p
        if (p?.default_language_code?.isNotEmpty() == true) {
            language = p.support_languages.firstOrNull { it.language_code == p.default_language_code }
        } else {
            language = p?.support_languages?.firstOrNull()
        }
    }

    fun getLanguages(): List<CovAgentLanguage>? {
        return preset?.support_languages
    }

    fun getPreset(): CovAgentPreset? {
        return preset
    }

    fun resetData() {
        enableAiVad = false
    }
}