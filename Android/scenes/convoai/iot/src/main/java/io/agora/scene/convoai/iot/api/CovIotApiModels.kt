package io.agora.scene.convoai.iot.api

data class CovIotPreset(
    val preset_name: String,
    val display_name: String,
    val preset_brief: String,
    val preset_type: String,
    val support_languages: List<CovIotLanguage>,
    val call_time_limit_second: Long,
)

data class CovIotTokenModel(
    val agent_url: String,
    val auth_token: String,
)

data class CovIotLanguage(
    val default: Boolean,
    val code: String,
    val name: String
)