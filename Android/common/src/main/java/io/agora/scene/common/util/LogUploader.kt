package io.agora.scene.common.util

import android.util.Log
import io.agora.scene.common.AgentApp
import io.agora.scene.common.constant.SSOUserManager
import io.agora.scene.common.constant.ServerConfig
import io.agora.scene.common.net.ApiManager
import io.agora.scene.common.net.ApiManagerService
import io.agora.scene.common.net.BaseResponse
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.MultipartBody
import okhttp3.RequestBody
import okhttp3.RequestBody.Companion.asRequestBody
import java.io.File
import org.json.JSONObject

object LogUploader {

    private const val TAG = "LogUploader"

    private fun getApiService() = ApiManager.getService(ApiManagerService::class.java)

    private val scope = CoroutineScope(Job() + Dispatchers.Main)

    // Get all log file paths
    private fun getAllLogFiles(): List<String> {
        val filesDir = AgentApp.instance().getExternalFilesDir("") ?: return emptyList()
        val logPaths = mutableListOf<String>()
        collectFiles(filesDir, logPaths)
        return logPaths
    }

    // Recursively collect files
    private fun collectFiles(directory: File, paths: MutableList<String>) {
        try {
            directory.listFiles()?.forEach { file ->
                // Skip files/compressed directory
                if (file.absolutePath.contains("compressed")) {
                    return@forEach // Skip this file/directory
                }
                
                when {
                    file.isFile -> {
                        // Only collect .log files and .wav files with "predump" in the name
                        if (file.name.endsWith(".log") || 
                            (file.name.endsWith(".wav") && file.name.contains("predump"))) {
                            paths.add(file.absolutePath)
                        }
                    }
                    file.isDirectory -> collectFiles(file, paths)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to collect files: ${e.message}")
        }
    }

    @Volatile
    private var isUploading = false

    fun uploadLog(agentId: String, channelName: String, completion: ((error: Exception?) -> Unit)? = null) {
        if (isUploading) return
        isUploading = true

        CommonLogger.d(TAG,"start compress")
        val filesDir = AgentApp.instance().getExternalFilesDir("") ?: return

        // Delete all existing zip files in the directory
        filesDir.listFiles()?.forEach { file ->
            if (file.name.endsWith(".zip")) {
                FileUtils.deleteFile(file.absolutePath)
            }
        }

        // Handle agentId, if it contains a colon, only take the content before the colon.
        val processedAgentId = agentId.split(":").first()
        val zipFileName = "${processedAgentId}_${channelName}"
        val allLogZipFile = File(filesDir, "${zipFileName}.zip")

        // Get all log file paths
        val logPaths = getAllLogFiles()
        if (logPaths.isEmpty()) {
            isUploading = false
            Log.w(TAG, "No log files found")
            return
        }

        // Compress all files
        FileUtils.compressFiles(logPaths, allLogZipFile.absolutePath, object : FileUtils.ZipCallback {
            override fun onSuccess(path: String) {
                CommonLogger.d(TAG,"compress end")
                requestUploadLog(agentId, channelName, File(path),
                    onSuccess = {
                        FileUtils.deleteFile(allLogZipFile.absolutePath)
                        completion?.invoke(null)
                        isUploading = false
                    },
                    onError = {
                        FileUtils.deleteFile(allLogZipFile.absolutePath)
                        isUploading = false
                        completion?.invoke(it)
                    })
            }

            override fun onError(error: Exception) {
                FileUtils.deleteFile(allLogZipFile.absolutePath)
                completion?.invoke(error)
                isUploading = false
                Log.e(TAG, "Upload log compression failed: ${error.message}")
            }
        })
    }

    fun requestUploadLog(
        agentId: String,
        channelName: String,
        file: File,
        onSuccess: () -> Unit,
        onError: (Exception) -> Unit
    ) {
        if (!file.exists()) {
            onError(Exception("Log file not found"))
            return
        }

        try {
            // Create content part
            val contentJson = JSONObject().apply {
                put("appId", ServerConfig.rtcAppId)
                put("channelName", channelName)
                put("agentId", agentId)
                put("payload", JSONObject().apply {
                    put("name", file.name)
                })
            }

            val contentBody = RequestBody.create(
                "text/plain".toMediaTypeOrNull(),
                contentJson.toString()
            )

            // Create file part
            val fileBody = file.asRequestBody("application/octet-stream".toMediaTypeOrNull())
            val filePart = MultipartBody.Part.createFormData("file", file.name, fileBody)

            // Get token for authorization
            val token = "Bearer ${SSOUserManager.getToken()}"
            requestNoData(
                block = {
                    getApiService().requestUploadLog(token, contentBody, filePart)
                },
                onSuccess = onSuccess,
                onError = onError
            )
        } catch (e: Exception) {
            onError(e)
            Log.e(TAG, "Failed to prepare upload request: ${e.message}")
        }
    }

    fun <T : Any> requestWithData(
        block: suspend () -> BaseResponse<T>,
        onSuccess: (T) -> Unit,
        onError: (Exception) -> Unit = {},
    ): Job {
        return scope.launch(Dispatchers.Main) {
            runCatching {
                block()
            }.onSuccess { response ->
                runCatching {
                    if (response.isSuccess) {
                        response.data?.let {
                            onSuccess(it)
                        } ?: run {
                            onError(Exception("Response data is null"))
                        }
                    } else {
                        onError(Exception("Error: ${response.message} (Code: ${response.code})"))
                    }
                }.onFailure { exception ->
                    Log.e(TAG, "Request failed: ${exception.localizedMessage}", exception)
                    onError(Exception("Request failed due to: ${exception.localizedMessage}"))
                }
            }.onFailure { exception ->
                Log.e(TAG, "Request failed: ${exception.localizedMessage}", exception)
                onError(Exception("Request failed due to: ${exception.localizedMessage}"))
            }
        }
    }

    fun requestNoData(
        block: suspend () -> BaseResponse<Unit>,
        onSuccess: () -> Unit,
        onError: (Exception) -> Unit = {},
    ): Job {
        return scope.launch(Dispatchers.Main) {
            runCatching {
                block()
            }.onSuccess { response ->
                runCatching {
                    if (response.isSuccess) {
                        onSuccess()
                    } else {
                        onError(Exception("Error: ${response.message} (Code: ${response.code})"))
                    }
                }.onFailure { exception ->
                    Log.e(TAG, "Request failed: ${exception.localizedMessage}", exception)
                    onError(Exception("Request failed due to: ${exception.localizedMessage}"))
                }
            }.onFailure { exception ->
                Log.e(TAG, "Request failed: ${exception.localizedMessage}", exception)
                onError(Exception("Request failed due to: ${exception.localizedMessage}"))
            }
        }
    }
}