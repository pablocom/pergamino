package com.pergamino.feature.auth.data.datasource

import com.pergamino.core.common.Result
import com.pergamino.feature.auth.domain.model.AuthError
import java.time.Instant

/**
 * Data source interface for remote authentication operations.
 *
 * This interface abstracts the network layer, allowing for easy testing
 * and swapping of implementations (real API vs fake/mock).
 */
interface AuthRemoteDataSource {

    /**
     * Requests a verification email to be sent.
     *
     * @param email The email address to send verification to
     * @return [Result.Success] with response containing expiry time, or [Result.Failure] with error
     */
    suspend fun requestVerification(email: String): Result<VerificationResponse, AuthError>

    /**
     * Verifies the token from the email link.
     *
     * @param token The verification token to validate
     * @return [Result.Success] with authenticated user info, or [Result.Failure] with error
     */
    suspend fun verifyToken(token: String): Result<TokenVerificationResponse, AuthError>
}

/**
 * Response from verification request.
 */
data class VerificationResponse(
    val success: Boolean,
    val expiresAt: Instant
)

/**
 * Response from token verification.
 */
data class TokenVerificationResponse(
    val userId: String,
    val email: String,
    val accessToken: String,
    val createdAt: Instant
)
