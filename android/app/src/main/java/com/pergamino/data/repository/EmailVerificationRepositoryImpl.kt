package com.pergamino.data.repository

import com.pergamino.data.network.EmailVerificationApiService
import com.pergamino.data.network.model.VerificationRequest
import javax.inject.Inject

class EmailVerificationRepositoryImpl @Inject constructor(
    private val apiService: EmailVerificationApiService
) : EmailVerificationRepository {

    override suspend fun requestVerificationEmail(email: String): Result<Unit> {
        return try {
            val response = apiService.requestVerificationEmail(VerificationRequest(email))
            if (response.success) {
                Result.success(Unit)
            } else {
                Result.failure(Exception(response.message))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
