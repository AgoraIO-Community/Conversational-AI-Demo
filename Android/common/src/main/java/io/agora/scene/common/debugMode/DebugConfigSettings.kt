package io.agora.scene.common.debugMode

import android.content.Context
import com.google.gson.Gson
import io.agora.scene.common.AgentApp
import io.agora.scene.common.constant.EnvConfig
import java.io.BufferedReader

data class DevEnvConfig(
    val china: List<EnvConfig>,
    val global: List<EnvConfig>
)

object DebugConfigSettings {

    private const val DEV_CONFIG_FILE = "dev_env_config.json"
    private var instance: DevEnvConfig? = null
    private var isMainLand: Boolean = true

    var graphId: String = ""
        private set

    fun updateGraphId(graphId:String){
        this.graphId = graphId
    }

    var isDebug: Boolean = false
        private set

    fun enableDebugMode(isDebug: Boolean) {
        this.isDebug = isDebug
    }

    var isAudioDumpEnabled: Boolean = true
        private set

    fun enableAudioDump(isAudioDumpEnabled: Boolean) {
        this.isAudioDumpEnabled = isAudioDumpEnabled
    }

    var isSeamlessPlayMode: Boolean = false
        private set

    fun enableSeamlessPlayMode(isSeamlessPlayMode: Boolean) {
        this.isSeamlessPlayMode = isSeamlessPlayMode
    }

    @JvmStatic
    fun init(context: Context, isMainLand: Boolean) {
        if (instance != null) return
        this.isMainLand = isMainLand
        try {
            val jsonString = context.assets.open(DEV_CONFIG_FILE).bufferedReader().use(BufferedReader::readText)
            instance = Gson().fromJson(jsonString, DevEnvConfig::class.java)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    @JvmStatic
    fun getServerConfig(): List<EnvConfig> {
        val envConfigList = if (isMainLand) instance?.china else instance?.global
        return envConfigList ?: emptyList()
    }

    fun reset() {
        graphId = ""
        isDebug = false
        isAudioDumpEnabled = false
    }

    // Counter for debug mode activation
    private var counts = 0
    private val debugModeOpenTime: Long = 2000
    private var beginTime: Long = 0

    fun checkClickDebug() {
        if (isDebug) return
        if (counts == 0 || System.currentTimeMillis() - beginTime > debugModeOpenTime) {
            beginTime = System.currentTimeMillis()
            counts = 0
        }
        counts++
        if (counts > 7) {
            counts = 0
            enableDebugMode(true)
            DebugButton.getInstance(AgentApp.instance()).show()
        }
    }
}