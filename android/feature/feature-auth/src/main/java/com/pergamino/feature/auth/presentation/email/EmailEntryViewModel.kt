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

@HiltViewModel
class EmailEntryViewModel @Inject constructor(
    private val requestEmailVerificationUseCase: RequestEmailVerificationUseCase
) : ViewModel() {

    private val _uiState = MutableStateFlow(EmailEntryUiState())
    val uiState: StateFlow<EmailEntryUiState> = _uiState.asStateFlow()

    private val _events = Channel<EmailEntryEvent>(Channel.BUFFERED)
    val events = _events.receiveAsFlow()

    fun onEmailChanged(email: String) {
        val validationError = validateEmailRealtime(email)

        _uiState.update { state ->
            state.copy(
                email = email,
                emailValidationError = validationError,
                error = null
            )
        }
    }

    fun onContinueClicked() {
        val currentEmail = _uiState.value.email

        val validationError = validateEmailForSubmission(currentEmail)
        if (validationError != null) {
            _uiState.update { state ->
                state.copy(emailValidationError = validationError)
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

    fun onErrorDismissed() {
        _uiState.update { it.copy(error = null) }
    }

    private fun validateEmailRealtime(email: String): EmailValidationError? {
        if (email.isBlank()) {
            return null
        }
        return when (val result = Email.create(email)) {
            is com.pergamino.core.common.Result.Success -> null
            is com.pergamino.core.common.Result.Failure -> result.error
        }
    }

    private fun validateEmailForSubmission(email: String): EmailValidationError? {
        return when (val result = Email.create(email)) {
            is com.pergamino.core.common.Result.Success -> null
            is com.pergamino.core.common.Result.Failure -> result.error
        }
    }
}
