package com.pergamino.feature.auth.presentation.email

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.pergamino.feature.auth.domain.model.Email
import com.pergamino.feature.auth.domain.model.EmailValidationError
import com.pergamino.feature.auth.domain.usecase.RequestEmailVerificationUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * ViewModel for the Email Entry screen.
 *
 * Following MVVM pattern with Clean Architecture:
 * - Holds and manages UI state
 * - Handles user interactions
 * - Delegates business logic to use cases
 * - Emits one-time events for navigation/side effects
 */
@HiltViewModel
class EmailEntryViewModel @Inject constructor(
    private val requestEmailVerificationUseCase: RequestEmailVerificationUseCase
) : ViewModel() {

    private val _uiState = MutableStateFlow(EmailEntryUiState())
    val uiState: StateFlow<EmailEntryUiState> = _uiState.asStateFlow()

    private val _events = Channel<EmailEntryEvent>(Channel.BUFFERED)
    val events = _events.receiveAsFlow()

    /**
     * Called when the user changes the email input.
     *
     * Validates the email in real-time and updates the UI state.
     */
    fun onEmailChanged(email: String) {
        // Validate the email as the user types
        val validationError = if (email.isBlank()) {
            null // Don't show error for empty field while typing
        } else {
            when (val result = Email.create(email)) {
                is com.pergamino.core.common.Result.Success -> null
                is com.pergamino.core.common.Result.Failure -> result.error
            }
        }

        _uiState.update { state ->
            state.copy(
                email = email,
                emailValidationError = validationError,
                error = null // Clear any previous submission errors
            )
        }
    }

    /**
     * Called when the user taps the continue button.
     *
     * Initiates the email verification request.
     */
    fun onContinueClicked() {
        val currentEmail = _uiState.value.email

        // Final validation before submission
        val validationResult = Email.create(currentEmail)
        if (validationResult is com.pergamino.core.common.Result.Failure) {
            _uiState.update { state ->
                state.copy(emailValidationError = validationResult.error)
            }
            return
        }

        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            requestEmailVerificationUseCase(currentEmail)
                .onSuccess { pendingState ->
                    _events.send(
                        EmailEntryEvent.NavigateToVerificationPending(pendingState.email.value)
                    )
                }
                .onFailure { error ->
                    _uiState.update { state ->
                        state.copy(error = error)
                    }
                    _events.send(EmailEntryEvent.ShowError(error))
                }

            _uiState.update { it.copy(isLoading = false) }
        }
    }

    /**
     * Called when the user dismisses an error.
     */
    fun onErrorDismissed() {
        _uiState.update { it.copy(error = null) }
    }
}
