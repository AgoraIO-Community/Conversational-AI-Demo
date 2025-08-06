package io.agora.scene.convoai.constant

import io.agora.scene.common.BuildConfig
import io.agora.scene.common.debugMode.DebugConfigSettings
import io.agora.scene.convoai.api.CovAgentLanguage
import io.agora.scene.convoai.api.CovAgentPreset
import io.agora.scene.convoai.api.CovAvatar
import io.agora.scene.convoai.ui.CovRenderMode
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
    private var preset: CovAgentPreset? = null
    var language: CovAgentLanguage? = null
    var avatar: CovAvatar? = null
    var renderMode: Int = CovRenderMode.WORD

    var enableAiVad = false
    val enableBHVS = true

    // Preset change reminder setting, follows app lifecycle
    private var showPresetChangeReminder = true

    // values
    val uid = Random.nextInt(10000, 100000000)
    val agentUID = Random.nextInt(10000, 100000000)
    val avatarUID = Random.nextInt(10000, 100000000)
    var channelName: String = ""

    // room expire time sec
    var roomExpireTime = 600L
        get() {
            return if (isEnableAvatar) {
                // If call_time_limit_avatar_second is null or <= 0, use 300L as default
                val limit = preset?.call_time_limit_avatar_second ?: 0L
                if (limit > 0) limit else 300L
            } else {
                // If call_time_limit_second is null or <= 0, use 300L as default
                val limit = preset?.call_time_limit_second ?: 0L
                if (limit > 0) limit else 600L
            }
        }

    fun setPreset(p: CovAgentPreset?) {
        preset = p
        language = if (p?.default_language_code?.isNotEmpty() == true) {
            p.support_languages.firstOrNull { it.language_code == p.default_language_code }
        } else {
            p?.support_languages?.firstOrNull()
        }
    }

    fun getLanguages(): List<CovAgentLanguage>? {
        return preset?.support_languages
    }

    fun getPreset(): CovAgentPreset? {
        return preset
    }

    fun getAvatars(): List<CovAvatar> {
        return preset?.getAvatarsForLang(language?.language_code) ?: emptyList()
    }

    val isEnableAvatar: Boolean
        get() {
            return avatar != null || BuildConfig.AVATAR_ENABLE
        }

    // Preset change reminder management methods
    fun shouldShowPresetChangeReminder(): Boolean {
        return showPresetChangeReminder
    }

    fun setShowPresetChangeReminder(show: Boolean) {
        showPresetChangeReminder = show
    }

    val isWordRenderMode: Boolean
        get() {
            return renderMode == CovRenderMode.WORD && !isEnableAvatar
        }

    fun resetData() {
        enableAiVad = false
        preset = null
        language = null
        avatar = null
    }
}