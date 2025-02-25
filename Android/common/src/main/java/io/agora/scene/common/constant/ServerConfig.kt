package io.agora.scene.common.constant

import com.google.gson.annotations.SerializedName
import io.agora.scene.common.net.ApiManager

data class EnvConfig(
    @SerializedName("env_name")
    var envName: String = "",
    @SerializedName("toolbox_server_host")
    var toolboxServerHost: String = "",
    @SerializedName("rtc_app_id")
    var rtcAppId: String = "",
    @SerializedName("rtc_app_certificate")
    var rtcAppCertificate: String = ""
)

object ServerConfig {

    const val IS_DEBUG = "is_debug"

//    var isDebug: Boolean = LocalStorageUtil.getBoolean(IS_DEBUG, false)
//        set(newValue) {
//            field = newValue
//            LocalStorageUtil.putBoolean(IS_DEBUG, newValue)
//        }

    @JvmStatic
    val termsOfServicesUrl: String
        get() {
            return if (isMainlandVersion) {
                "https://www.agora.io/en/terms-of-service/"
            } else {
                "https://www.agora.io/en/terms-of-service/"
            }
        }

    @JvmStatic
    val privacyPolicyUrl: String
        get() {
            return if (isMainlandVersion) {
                "https://www.agora.io/en/terms-of-service/"
            } else {
                "https://www.agora.io/en/privacy-policy/"
            }
        }

    @JvmStatic
    var isMainlandVersion: Boolean = false
        private set

    @JvmStatic
    var envName: String = ""
        private set

    @JvmStatic
    var toolBoxUrl: String = ""
        private set

    @JvmStatic
    var rtcAppId: String = ""
        private set

    @JvmStatic
    var rtcAppCert: String = ""
        private set

    private val buildEnvConfig: EnvConfig = EnvConfig()

    fun initBuildConfig(
        isMainland: Boolean, envName: String, toolboxHost: String, rtcAppId: String, rtcAppCert: String
    ) {
        this.isMainlandVersion = isMainland
        buildEnvConfig.apply {
            this.envName = envName
            this.toolboxServerHost = toolboxHost
            this.rtcAppId = rtcAppId
            this.rtcAppCertificate = rtcAppCert
        }
        reset()
    }

    fun updateDebugConfig(debugConfig: EnvConfig) {
        this.envName = debugConfig.envName
        this.toolBoxUrl = debugConfig.toolboxServerHost
        this.rtcAppId = debugConfig.rtcAppId
        this.rtcAppCert = debugConfig.rtcAppCertificate
    }

    fun reset() {
        envName = buildEnvConfig.envName
        toolBoxUrl = buildEnvConfig.toolboxServerHost
        rtcAppId = buildEnvConfig.rtcAppId
        rtcAppCert = buildEnvConfig.rtcAppCertificate
        ApiManager.setBaseURL(toolBoxUrl)
    }
}