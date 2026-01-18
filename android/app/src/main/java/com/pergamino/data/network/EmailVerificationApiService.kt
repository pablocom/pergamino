package com.pergamino.data.network

import com.pergamino.data.network.model.VerificationRequest
import com.pergamino.data.network.model.VerificationResponse
import retrofit2.http.Body
import retrofit2.http.POST

interface EmailVerificationApiService {

    @POST("/api/device-binding-link")
    suspend fun requestVerificationEmail(
        @Body request: VerificationRequest
    )
}
