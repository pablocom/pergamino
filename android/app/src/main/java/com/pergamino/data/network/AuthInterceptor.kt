package com.pergamino.data.network

import com.pergamino.data.local.SecureDeviceStorage
import okhttp3.Interceptor
import okhttp3.Response
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AuthInterceptor @Inject constructor(
    private val secureStorage: SecureDeviceStorage
) : Interceptor {

    companion object {
        const val TAG_SKIP_AUTH = "skip_auth"
    }

    override fun intercept(chain: Interceptor.Chain): Response {
        val originalRequest = chain.request()

        if (originalRequest.tag(String::class.java) == TAG_SKIP_AUTH) {
            return chain.proceed(originalRequest)
        }

        val jwtToken = secureStorage.getJwtToken().getOrNull()

        return if (jwtToken != null) {
            val authenticatedRequest = originalRequest.newBuilder()
                .header("Authorization", "Bearer ${jwtToken.value}")
                .build()
            chain.proceed(authenticatedRequest)
        } else {
            chain.proceed(originalRequest)
        }
    }
}
