package io.agora.scene.common.net.interceptor

import io.agora.scene.common.net.ApiManager
import okhttp3.Interceptor
import okhttp3.Response

class AuthorizationInterceptor : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response {
        val request = chain.request()
        val response = chain.proceed(request)

        // Check for 401 response
        if (response.code == 401) {
            ApiManager.notifyUnauthorized()
        }

        return response
    }
}