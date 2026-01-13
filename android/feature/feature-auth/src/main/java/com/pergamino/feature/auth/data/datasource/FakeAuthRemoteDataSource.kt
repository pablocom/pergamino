package com.pergamino.feature.auth.data.datasource

import android.util.Log
import com.pergamino.core.common.Result
import com.pergamino.feature.auth.domain.model.AuthError
import kotlinx.coroutines.delay
import java.time.Instant
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class FakeAuthRemoteDataSource @Inject constructor() : AuthRemoteDataSource {

    private val pendingVerifications = mutableMapOf<String, String>()

    override suspend fun requestVerification(email: String): Result<VerificationResponse, AuthError> {
        delay(NETWORK_DELAY_MS)

        val token = UUID.randomUUID().toString()
        pendingVerifications[email] = token

        val deepLink = "pergamino://verify?token=$token"
        Log.d(TAG, "=".repeat(60))
        Log.d(TAG, "Verification email sent to: $email")
        Log.d(TAG, "Deep link for testing: $deepLink")
        Log.d(TAG, "Test with: adb shell am start -a android.intent.action.VIEW -d \"$deepLink\"")
        Log.d(TAG, "=".repeat(60))

        return Result.success(
            VerificationResponse(
                success = true,
                expiresAt = Instant.now().plusSeconds(VERIFICATION_EXPIRY_SECONDS)
            )
        )
    }

    override suspend fun verifyToken(token: String): Result<TokenVerificationResponse, AuthError> {
        delay(NETWORK_DELAY_MS / 2)

        val email = pendingVerifications.entries.find { it.value == token }?.key

        if (email == null) {
            Log.w(TAG, "Token verification failed: Token not found or expired")
            return Result.failure(AuthError.TokenNotFound)
        }

        pendingVerifications.remove(email)

        Log.d(TAG, "Token verified successfully for: $email")

        return Result.success(
            TokenVerificationResponse(
                userId = UUID.randomUUID().toString(),
                email = email,
                accessToken = "fake_access_token_${System.currentTimeMillis()}",
                createdAt = Instant.now()
            )
        )
    }

    companion object {
        private const val TAG = "FakeAuthRemoteDataSource"
        private const val NETWORK_DELAY_MS = 1000L
        private const val VERIFICATION_EXPIRY_SECONDS = 300L // 5 minutes
    }
}
