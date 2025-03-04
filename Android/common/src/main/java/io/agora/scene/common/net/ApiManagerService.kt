package io.agora.scene.common.net;

import okhttp3.MultipartBody
import retrofit2.http.GET
import retrofit2.http.Header
import retrofit2.http.Multipart
import retrofit2.http.POST
import retrofit2.http.Part
import retrofit2.http.Query
import okhttp3.RequestBody

interface ApiManagerService {

    companion object{
        const val requestUploadLog = "v1/convoai/upload/log"
        const val ssoUserInfo = "v1/convoai/sso/userInfo"
    }

    @GET(ssoUserInfo)
    suspend fun ssoUserInfo(@Header("Authorization") token: String): BaseResponse<SSOUserInfo>

    @Multipart
    @POST("v1/convoai/upload/log")
    suspend fun requestUploadLog(
        @Header("Authorization") token: String,
        @Part("content") content: RequestBody,
        @Part file: MultipartBody.Part
    ): BaseResponse<Unit>
}
