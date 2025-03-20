package io.agora.scene.convoai.iot.api

import com.google.gson.JsonObject
import io.agora.scene.common.constant.SSOUserManager
import io.agora.scene.common.constant.ServerConfig
import io.agora.scene.common.net.SecureOkHttpClient
import io.agora.scene.common.util.GsonTools
import io.agora.scene.convoai.iot.CovLogger
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import okhttp3.Call
import okhttp3.Callback
import okhttp3.Request
import okhttp3.RequestBody
import okhttp3.Response
import org.json.JSONException
import org.json.JSONObject
import java.io.IOException
import java.util.UUID

object CovIotApiManager {
    private const val TAG = "CovIotApiManager"

    private val mainScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    private fun runOnMainThread(r: Runnable) {
        mainScope.launch {
            r.run()
        }
    }

    private val okHttpClient by lazy {
        SecureOkHttpClient.create()
            .build()
    }

    private const val SERVICE_VERSION = "v1"

    fun fetchPresets(completion: (error: Exception?, List<CovIotPreset>) -> Unit) {
        val requestURL =
            "${ServerConfig.toolBoxUrl}/convoai-iot/$SERVICE_VERSION/presets/list"

        val postBody = JSONObject()
        try {
            postBody.put("request_id", UUID.randomUUID())
        } catch (e: JSONException) {
            CovLogger.e(TAG, "postBody error ${e.message}")
        }
        val requestBody = RequestBody.create(null, postBody.toString())
        val request = buildRequest(requestURL, "POST", requestBody)
        okHttpClient.newCall(request).enqueue(object : Callback {
            override fun onResponse(call: Call, response: Response) {
                val json = response.body.string()
                try {
                    val jsonObject = GsonTools.toBean(json, JsonObject::class.java)
                    if (jsonObject?.get("code")?.asInt == 0) {
                        val data = GsonTools.toList(
                            jsonObject.getAsJsonArray("data").toString(),
                            CovIotPreset::class.java
                        ) ?: emptyList()
                        runOnMainThread {
                            completion.invoke(null, data)
                        }
                    } else {
                        runOnMainThread {
                            completion.invoke(null, emptyList())
                        }
                    }
                } catch (e: Exception) {
                    CovLogger.e(TAG, "Parse presets failed: $e")
                    runOnMainThread {
                        completion.invoke(e, emptyList())
                    }
                }
            }

            override fun onFailure(call: Call, e: IOException) {
                CovLogger.e(TAG, "fetch presets failed: $e")
                runOnMainThread {
                    completion.invoke(e, emptyList())
                }
            }
        })
    }

    fun generatorToken(deviceId: String, completion: (model: CovIotTokenModel?, error: Exception?) -> Unit) {
        if (deviceId.isEmpty()) {
            runOnMainThread {
                completion.invoke(null, Exception("deviceId is null"))
            }
            return
        }

        val requestURL = "${ServerConfig.toolBoxUrl}/convoai-iot/${SERVICE_VERSION}/auth/token/generate"
        val postBody = JSONObject()
        try {
            postBody.put("request_id", UUID.randomUUID())
            postBody.put("device_id", deviceId)
        } catch (e: JSONException) {
            CovLogger.e(TAG, "postBody error ${e.message}")
        }
        val requestBody = RequestBody.create(null, postBody.toString())
        val request = buildRequest(requestURL, "POST", requestBody)

        okHttpClient.newCall(request).enqueue(object : Callback {
            override fun onResponse(call: Call, response: Response) {
                val json = response.body.string()
                try {
                    val jsonObject = GsonTools.toBean(json, JsonObject::class.java)
                    val code = jsonObject?.get("code")?.asInt ?: -1
                    if (code == 0) {
                        // success
                        val data = GsonTools.toBean(jsonObject?.get("data"), CovIotTokenModel::class.java)
                        runOnMainThread {
                            completion.invoke(data, null)
                        }
                    } else {
                        runOnMainThread {
                            completion.invoke(null, Exception("generatorToken failed:$json"))
                        }
                        CovLogger.e(TAG, "generatorToken failed $json")
                    }
                } catch (e: Exception) {
                    CovLogger.e(TAG, "Parse generatorToken failed: $e")
                    runOnMainThread {
                        completion.invoke(null, e)
                    }
                }
            }

            override fun onFailure(call: Call, e: IOException) {
                CovLogger.e(TAG, "generatorToken failed: $e")
                runOnMainThread {
                    completion.invoke(null, e)
                }
            }
        })
    }

    fun updateSettings(
        deviceId: String,
        presetName: String,
        asrLanguage: String,
        enableAiVad: Boolean,
        completion: (error: Exception?) -> Unit) {
        if (deviceId.isEmpty()) {
            runOnMainThread {
                completion.invoke(Exception("deviceId is null"))
            }
            return
        }

        val requestURL = "${ServerConfig.toolBoxUrl}/convoai-iot/${SERVICE_VERSION}/device/preset/update"
        val postBody = JSONObject()
        try {
            postBody.put("request_id", UUID.randomUUID())
            postBody.put("device_id", deviceId)
            postBody.put("preset_name", presetName)
            postBody.put("asr_language", asrLanguage)
            postBody.put("advanced_features_enable_aivad", enableAiVad)
        } catch (e: JSONException) {
            CovLogger.e(TAG, "postBody error ${e.message}")
        }
        val requestBody = RequestBody.create(null, postBody.toString())
        val request = buildRequest(requestURL, "POST", requestBody)

        okHttpClient.newCall(request).enqueue(object : Callback {
            override fun onResponse(call: Call, response: Response) {
                val json = response.body.string()
                try {
                    val jsonObject = GsonTools.toBean(json, JsonObject::class.java)
                    val code = jsonObject?.get("code")?.asInt ?: -1
                    if (code == 0) {
                        // success
                        runOnMainThread {
                            completion.invoke(null)
                        }
                        CovLogger.d(TAG, "updateSettings success")
                    } else {
                        runOnMainThread {
                            completion.invoke(Exception("updateSettings failed:$json"))
                        }
                        CovLogger.e(TAG, "updateSettings failed $json")
                    }
                } catch (e: Exception) {
                    CovLogger.e(TAG, "Parse updateSettings failed: $e")
                    runOnMainThread {
                        completion.invoke(e)
                    }
                }
            }

            override fun onFailure(call: Call, e: IOException) {
                CovLogger.e(TAG, "generatorToken failed: $e")
                runOnMainThread {
                    completion.invoke(e)
                }
            }
        })
    }

    private fun buildRequest(url: String, method: String = "GET", body: RequestBody? = null): Request {
        val builder = Request.Builder()
            .url(url)
            .addHeader("Content-Type", "application/json")
            .addHeader("Authorization", "Bearer ${SSOUserManager.getToken()}")

        when (method.uppercase()) {
            "POST" -> builder.post(body ?: RequestBody.create(null, ""))
            "GET" -> builder.get()
            // Add other methods if needed
        }

        return builder.build()
    }
}