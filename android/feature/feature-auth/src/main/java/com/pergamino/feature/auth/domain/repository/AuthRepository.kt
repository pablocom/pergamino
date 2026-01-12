package com.pergamino.feature.auth.domain.repository

import com.pergamino.core.common.Result
import com.pergamino.feature.auth.domain.model.AuthError
import com.pergamino.feature.auth.domain.model.AuthState
import com.pergamino.feature.auth.domain.model.Email
import com.pergamino.feature.auth.domain.model.VerificationToken
import kotlinx.coroutines.flow.Flow

/**
 * Repository interface for authentication operations.
 *
 * This interface defines the contract between the domain layer and the data layer.
 * Implementations are responsible for coordinating data sources (remote API, local storage)
 * to fulfill authentication requirements.
 *
 * Following Clean Architecture principles, this interface:
 * - Is defined in the domain layer
 * - Uses domain types only (no DTOs or framework-specific types)
 * - Exposes a reactive stream for auth state observation
 */
interface AuthRepository {

    /**
     * Observable stream of the current authentication state.
     *
     * This is the single source of truth for auth state across the application.
     * UI components should observe this flow to react to auth state changes.
     */
    val authState: Flow<AuthState>

    /**
     * Requests email verification to be sent to the provided email address.
     *
     * On success, a verification link will be sent to the user's email,
     * and the auth state will transition to [AuthState.VerificationPending].
     *
     * @param email The validated email address to send verification to
     * @return [Result.Success] with the pending state, or [Result.Failure] with error
     */
    suspend fun requestEmailVerification(email: Email): Result<AuthState.VerificationPending, AuthError>

    /**
     * Verifies the token received from the email verification link.
     *
     * On success, the user becomes authenticated and the auth state
     * transitions to [AuthState.Authenticated].
     *
     * @param token The verification token from the email link
     * @return [Result.Success] with authenticated state, or [Result.Failure] with error
     */
    suspend fun verifyToken(token: VerificationToken): Result<AuthState.Authenticated, AuthError>

    /**
     * Resends the verification email for the current pending verification.
     *
     * Can only be called when auth state is [AuthState.VerificationPending].
     *
     * @return [Result.Success] on successful resend, or [Result.Failure] with error
     */
    suspend fun resendVerificationEmail(): Result<Unit, AuthError>

    /**
     * Logs out the current user.
     *
     * Clears all stored credentials and transitions auth state to [AuthState.Unauthenticated].
     *
     * @return [Result.Success] on successful logout, or [Result.Failure] with error
     */
    suspend fun logout(): Result<Unit, AuthError>
}
