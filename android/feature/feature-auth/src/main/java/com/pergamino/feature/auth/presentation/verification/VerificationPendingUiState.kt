package com.pergamino.feature.auth.presentation.verification

import com.pergamino.feature.auth.domain.model.AuthError

/**
 * Immutable UI state for the Verification Pending screen.
 */
data class VerificationPendingUiState(
    val email: String = "",
    val isResending: Boolean = false,
    val resendCooldownSeconds: Int = 0,
    val error: AuthError? = null
) {
    /**
     * Whether the resend button should be enabled.
     */
    val canResend: Boolean
        get() = !isResending && resendCooldownSeconds == 0
}

/**
 * One-time events for the Verification Pending screen.
 */
sealed interface VerificationPendingEvent {
    /**
     * Navigate to the authenticated/main screen.
     */
    data object NavigateToMain : VerificationPendingEvent

    /**
     * Navigate back to email entry (e.g., user wants to change email).
     */
    data object NavigateBack : VerificationPendingEvent

    /**
     * Show success message for resend.
     */
    data object ShowResendSuccess : VerificationPendingEvent

    /**
     * Show error message.
     */
    data class ShowError(val error: AuthError) : VerificationPendingEvent
}
