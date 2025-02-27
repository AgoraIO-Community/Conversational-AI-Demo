package io.agora.scene.convoai.api

import org.json.JSONObject

data class AgentRequestParams(
    val appId: String,
    val appCert: String? = null,
    val basicAuthKey: String? = null,
    val basicAuthSecret: String? = null,
    val presetName: String? = null,
    val graphId: String? = null,
    val channelName: String,
    val agentRtcUid: String,
    val remoteRtcUid: String,
    val idleTimeout: Int? = null,
    val llmUrl: String? = null,
    val llmApiKey: String? = null,
    val llmPrompt: String? = null,
    val llmModel: String? = null,
    val llmGreetingMessage: String? = null,
    val llmStyle: Int? = null,
    val llmMaxHistory: Int? = null,
    val ttsVendor: String? = null,
    val ttsParams: JSONObject? = null,
    val ttsAdjustVolume: Int? = null,
    val asrLanguage: String? = null,
    val asrVendor: String? = null,
    val vadInterruptDurationMs: Int? = null,
    val vadPrefixPaddingMs: Int? = null,
    val vadSilenceDurationMs: Int? = null,
    val vadThreshold: Int? = null,
    val enableAiVad: Boolean? = null,
    val enableBHVS: Boolean? = null,
    val parameters: JSONObject? = null,
)

data class CovAgentPreset(
    val index: Int,
    val name: String,
    val display_name: String,
    val preset_type: String,
    val default_language_code: String,
    val default_language_name: String,
    val support_languages: List<CovAgentLanguage>,
    val call_time_limit_second: Long,
) {
    fun isIndependent(): Boolean {
        return preset_type.startsWith("independent")
    }
}

data class CovAgentLanguage(
    val language_code: String,
    val language_name: String
) {
    fun englishEnvironment(): Boolean {
        return language_code == "en-US"
    }
}