package com.pergamino.data.network

import com.pergamino.data.network.model.request.DeviceBindingRequest
import com.pergamino.data.network.model.request.VerificationRequest
import com.pergamino.data.network.model.response.DeviceBindingResponse
import retrofit2.http.Body
import retrofit2.http.POST

interface DeviceBindingService {

    @POST("/api/device-binding-link")
    suspend fun requestVerificationEmail(
        @Body request: VerificationRequest
    )

    @POST("/api/verify-binding")
    suspend fun verifyBinding(
        @Body request: DeviceBindingRequest
    ): DeviceBindingResponse
}
