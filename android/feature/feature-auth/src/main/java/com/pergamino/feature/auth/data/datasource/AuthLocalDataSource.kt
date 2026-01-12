package com.pergamino.feature.auth.data.datasource

import kotlinx.coroutines.flow.Flow
import java.time.Instant

/**
 * Data source interface for local authentication storage.
 *
 * This interface abstracts local persistence, handling storage of
 * authentication state, tokens, and user information.
 */
interface AuthLocalDataSource {

    /**
     * Observable stream of the persisted authentication state.
     */
    val authStateData: Flow<PersistedAuthState?>

    /**
     * Saves the verification pending state.
     *
     * @param email The email awaiting verification
     * @param expiresAt When the verification expires
     */
    suspend fun saveVerificationPending(email: String, expiresAt: Instant)

    /**
     * Saves the authenticated user state.
     *
     * @param userId The user's unique identifier
     * @param email The user's email address
     * @param accessToken The access token for API calls
     * @param createdAt When the user was created
     */
    suspend fun saveAuthenticated(
        userId: String,
        email: String,
        accessToken: String,
        createdAt: Instant
    )

    /**
     * Clears all stored authentication data.
     */
    suspend fun clear()

    /**
     * Gets the pending verification email if any.
     */
    suspend fun getPendingEmail(): String?
}

/**
 * Persisted authentication state from local storage.
 */
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
