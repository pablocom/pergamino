package com.pergamino.feature.auth.presentation.email

import com.pergamino.feature.auth.domain.model.AuthError
import com.pergamino.feature.auth.domain.model.EmailValidationError

data class EmailEntryUiState(
    val email: String = "",
    val emailValidationError: EmailValidationError? = null,
    val isLoading: Boolean = false,
    val error: AuthError? = null
) {
    val isEmailValid: Boolean
        get() = email.isNotBlank() && emailValidationError == null

    val canSubmit: Boolean
        get() = isEmailValid && !isLoading
}

sealed interface EmailEntryEvent {
    data class NavigateToVerificationPending(val email: String) : EmailEntryEvent

    data class ShowError(val error: AuthError) : EmailEntryEvent
}
