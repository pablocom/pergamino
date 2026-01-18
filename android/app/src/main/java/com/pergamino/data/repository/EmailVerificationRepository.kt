package com.pergamino.data.repository

interface EmailVerificationRepository {
    suspend fun requestVerificationEmail(email: String): Result<Unit>
}
