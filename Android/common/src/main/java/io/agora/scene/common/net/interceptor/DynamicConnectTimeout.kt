package io.agora.scene.common.net.interceptor;

import okhttp3.Interceptor
import okhttp3.Response
import java.util.concurrent.TimeUnit

class DynamicConnectTimeout(private val longTimeoutUrls: List<String>) : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response {
        val request = chain.request()
        val requestUrl = request.url.toString()

        // Check if the request URL matches any URL in the array
        val needLongTimeout = longTimeoutUrls.any { requestUrl.contains(it) }

        if (needLongTimeout) {
            return chain.withConnectTimeout(60 * 3, TimeUnit.SECONDS)
                .withReadTimeout(60 * 3, TimeUnit.SECONDS)
                .withWriteTimeout(60 * 3, TimeUnit.SECONDS)
                .proceed(request)
        }
        return chain.proceed(request)
    }
}
