package com.pergamino.data.repository

import com.pergamino.data.network.DeviceBindingService
import com.pergamino.data.network.model.request.VerificationRequest
import com.pergamino.domain.model.Email
import javax.inject.Inject

class EmailVerificationRepositoryImpl @Inject constructor(
    private val apiService: DeviceBindingService
) : EmailVerificationRepository {

    override suspend fun requestVerificationEmail(email: Email): Result<Unit> {
        return try {
            apiService.requestVerificationEmail(VerificationRequest(email.value))
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
