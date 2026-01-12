package com.pergamino.feature.auth.presentation.verification

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.pergamino.feature.auth.domain.model.AuthState
import com.pergamino.feature.auth.domain.usecase.ObserveAuthStateUseCase
import com.pergamino.feature.auth.domain.usecase.ResendVerificationEmailUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Job
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * ViewModel for the Verification Pending screen.
 *
 * Handles:
 * - Observing auth state changes (for when verification completes)
 * - Resend functionality with cooldown timer
 * - Navigation events
 */
@HiltViewModel
class VerificationPendingViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val observeAuthStateUseCase: ObserveAuthStateUseCase,
    private val resendVerificationEmailUseCase: ResendVerificationEmailUseCase
) : ViewModel() {

    private val email: String = savedStateHandle.get<String>("email") ?: ""

    private val _uiState = MutableStateFlow(VerificationPendingUiState(email = email))
    val uiState: StateFlow<VerificationPendingUiState> = _uiState.asStateFlow()

    private val _events = Channel<VerificationPendingEvent>(Channel.BUFFERED)
    val events = _events.receiveAsFlow()

    private var cooldownJob: Job? = null

    init {
        observeAuthState()
    }

    /**
     * Observes auth state changes to detect when verification is complete.
     */
    private fun observeAuthState() {
        viewModelScope.launch {
            observeAuthStateUseCase().collect { authState ->
                when (authState) {
                    is AuthState.Authenticated -> {
                        _events.send(VerificationPendingEvent.NavigateToMain)
                    }
                    is AuthState.Unauthenticated -> {
                        // User logged out or verification expired
                        _events.send(VerificationPendingEvent.NavigateBack)
                    }
                    is AuthState.VerificationPending -> {
                        // Update email if it changed (e.g., after resend)
                        _uiState.update { it.copy(email = authState.email.value) }
                    }
                }
            }
        }
    }

    /**
     * Called when the user taps the resend button.
     */
    fun onResendClicked() {
        if (!_uiState.value.canResend) return

        viewModelScope.launch {
            _uiState.update { it.copy(isResending = true, error = null) }

            resendVerificationEmailUseCase()
                .onSuccess {
                    _events.send(VerificationPendingEvent.ShowResendSuccess)
                    startCooldownTimer()
                }
                .onFailure { error ->
                    _uiState.update { it.copy(error = error) }
                    _events.send(VerificationPendingEvent.ShowError(error))
                }

            _uiState.update { it.copy(isResending = false) }
        }
    }

    /**
     * Called when the user taps the change email button.
     */
    fun onChangeEmailClicked() {
        viewModelScope.launch {
            _events.send(VerificationPendingEvent.NavigateBack)
        }
    }

    /**
     * Starts the cooldown timer after a resend.
     */
    private fun startCooldownTimer() {
        cooldownJob?.cancel()
        cooldownJob = viewModelScope.launch {
            _uiState.update { it.copy(resendCooldownSeconds = RESEND_COOLDOWN_SECONDS) }

            repeat(RESEND_COOLDOWN_SECONDS) {
                delay(1000)
                _uiState.update { state ->
                    state.copy(resendCooldownSeconds = state.resendCooldownSeconds - 1)
                }
            }
        }
    }

    /**
     * Called when the user dismisses an error.
     */
    fun onErrorDismissed() {
        _uiState.update { it.copy(error = null) }
    }

    companion object {
        private const val RESEND_COOLDOWN_SECONDS = 60
    }
}
