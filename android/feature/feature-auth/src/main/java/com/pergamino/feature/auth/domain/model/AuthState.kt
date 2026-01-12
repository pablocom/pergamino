package com.pergamino.feature.auth.domain.model

import java.time.Instant

/**
 * Represents the authentication state of the user.
 *
 * This sealed interface models the finite state machine for authentication:
 * - [Unauthenticated] -> User has not started authentication
 * - [VerificationPending] -> User has requested verification, awaiting email link click
 * - [Authenticated] -> User has completed verification and is authenticated
 *
 * State transitions:
 * Unauthenticated -> VerificationPending (on email submission)
 * VerificationPending -> Authenticated (on token verification)
 * VerificationPending -> Unauthenticated (on timeout/cancel)
 * Authenticated -> Unauthenticated (on logout)
 */
sealed interface AuthState {

    /**
     * Initial state - user has not authenticated.
     */
    data object Unauthenticated : AuthState

    /**
     * User has submitted their email and is waiting for verification.
     *
     * @property email The email address awaiting verification
     * @property expiresAt When the verification link expires
     */
    data class VerificationPending(
        val email: Email,
        val expiresAt: Instant
    ) : AuthState {
        /**
         * Checks if the verification has expired.
         */
        fun isExpired(): Boolean = Instant.now().isAfter(expiresAt)
    }

    /**
     * User is fully authenticated and can use the app.
     *
     * @property user The authenticated user's information
     * @property accessToken The access token for API calls
     */
    data class Authenticated(
        val user: User,
        val accessToken: String
    ) : AuthState
}
