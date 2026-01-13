package com.pergamino.feature.auth.data.datasource

import kotlinx.coroutines.flow.Flow
import java.time.Instant

interface AuthLocalDataSource {

    val authStateData: Flow<PersistedAuthState?>

    suspend fun saveVerificationPending(email: String, expiresAt: Instant)
    suspend fun saveAuthenticated(userId: String, email: String, accessToken: String, createdAt: Instant)
    suspend fun clear()
    suspend fun getPendingEmail(): String?
}

sealed interface PersistedAuthState {
    data class VerificationPending(
        val email: String,
        val expiresAt: Instant
    ) : PersistedAuthState

    data class Authenticated(
        val userId: String,
        val email: String,
        val accessToken: String,
        val createdAt: Instant
    ) : PersistedAuthState
}
