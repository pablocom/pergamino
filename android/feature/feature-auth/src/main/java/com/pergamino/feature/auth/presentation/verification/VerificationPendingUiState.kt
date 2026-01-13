package com.pergamino.feature.auth.presentation.verification

import com.pergamino.feature.auth.domain.model.AuthError

data class VerificationPendingUiState(
    val email: String = "",
    val isResending: Boolean = false,
    val resendCooldownSeconds: Int = 0,
    val error: AuthError? = null
) {
    val canResend: Boolean
        get() = !isResending && resendCooldownSeconds == 0
}

sealed interface VerificationPendingEvent {
    data object NavigateToMain : VerificationPendingEvent

    data object NavigateBack : VerificationPendingEvent

    data object ShowResendSuccess : VerificationPendingEvent

    data class ShowError(val error: AuthError) : VerificationPendingEvent
}
