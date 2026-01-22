package com.pergamino.data.network

import com.pergamino.data.network.model.request.DeviceBindingRequest
import com.pergamino.data.network.model.request.VerificationRequest
import com.pergamino.data.network.model.response.DeviceBindingResponse
import retrofit2.http.Body
import retrofit2.http.POST
import retrofit2.http.Tag

interface DeviceBindingService {

    @POST("/api/verification-emails")
    suspend fun requestVerificationEmail(
        @Body request: VerificationRequest,
        @Tag skipAuth: String = AuthInterceptor.TAG_SKIP_AUTH
    )

    @POST("/api/verify-binding")
    suspend fun verifyBinding(
        @Body request: DeviceBindingRequest,
        @Tag skipAuth: String = AuthInterceptor.TAG_SKIP_AUTH
    ): DeviceBindingResponse
}
