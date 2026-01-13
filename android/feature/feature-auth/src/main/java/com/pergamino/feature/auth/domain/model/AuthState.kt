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

    data object Unauthenticated : AuthState

    data class VerificationPending(
        val email: Email,
        val expiresAt: Instant
    ) : AuthState {
        fun isExpired(): Boolean = Instant.now().isAfter(expiresAt)
    }

    data class Authenticated(
        val user: User,
        val accessToken: String
    ) : AuthState
}
