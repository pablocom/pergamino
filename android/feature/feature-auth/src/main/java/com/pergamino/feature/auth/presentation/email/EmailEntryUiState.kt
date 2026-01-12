package com.pergamino.feature.auth.presentation.email

import com.pergamino.feature.auth.domain.model.AuthError
import com.pergamino.feature.auth.domain.model.EmailValidationError

/**
 * Immutable UI state for the Email Entry screen.
 *
 * Following the unidirectional data flow pattern, this data class represents
 * the complete UI state at any given moment. The ViewModel is the single source
 * of truth for this state.
 */
data class EmailEntryUiState(
    val email: String = "",
    val emailValidationError: EmailValidationError? = null,
    val isLoading: Boolean = false,
    val error: AuthError? = null
) {
    /**
     * Whether the email passes validation.
     */
    val isEmailValid: Boolean
        get() = email.isNotBlank() && emailValidationError == null

    /**
     * Whether the continue button should be enabled.
     */
    val canSubmit: Boolean
        get() = isEmailValid && !isLoading
}

/**
 * One-time events that the UI should handle.
 *
 * These events are consumed once and should not be replayed on configuration changes.
 * Examples include navigation events and showing snackbars.
 */
sealed interface EmailEntryEvent {
    /**
     * Navigate to the verification pending screen.
     */
    data class NavigateToVerificationPending(val email: String) : EmailEntryEvent

    /**
     * Show an error message to the user.
     */
    data class ShowError(val error: AuthError) : EmailEntryEvent
}
