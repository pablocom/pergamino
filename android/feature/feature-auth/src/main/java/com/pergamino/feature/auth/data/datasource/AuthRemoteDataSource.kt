package com.pergamino.feature.auth.data.datasource

import com.pergamino.core.common.Result
import com.pergamino.feature.auth.domain.model.AuthError
import java.time.Instant

interface AuthRemoteDataSource {
    suspend fun requestVerification(email: String): Result<VerificationResponse, AuthError>
    suspend fun verifyToken(token: String): Result<TokenVerificationResponse, AuthError>
}

data class VerificationResponse(
    val success: Boolean,
    val expiresAt: Instant
)

data class TokenVerificationResponse(
    val userId: String,
    val email: String,
    val accessToken: String,
    val createdAt: Instant
)
