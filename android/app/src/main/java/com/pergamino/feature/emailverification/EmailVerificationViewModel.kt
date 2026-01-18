package com.pergamino.feature.emailverification

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.pergamino.data.repository.EmailVerificationRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class EmailVerificationViewModel @Inject constructor(
    private val repository: EmailVerificationRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow<EmailVerificationUiState>(EmailVerificationUiState.Idle)
    val uiState: StateFlow<EmailVerificationUiState> = _uiState.asStateFlow()

    private val _email = MutableStateFlow("")
    val email: StateFlow<String> = _email.asStateFlow()

    private val _emailError = MutableStateFlow<String?>(null)
    val emailError: StateFlow<String?> = _emailError.asStateFlow()

    fun onEmailChange(newEmail: String) {
        _email.value = newEmail
        _emailError.value = null
        if (_uiState.value is EmailVerificationUiState.Error) {
            _uiState.value = EmailVerificationUiState.Idle
        }
    }

    fun requestVerificationEmail() {
        val currentEmail = _email.value.trim()

        if (!isValidEmail(currentEmail)) {
            _emailError.value = "Please enter a valid email address"
            return
        }

        viewModelScope.launch {
            _uiState.value = EmailVerificationUiState.Loading
            repository.requestVerificationEmail(currentEmail)
                .onSuccess {
                    _uiState.value = EmailVerificationUiState.Success
                }
                .onFailure { e ->
                    _uiState.value = EmailVerificationUiState.Error(
                        e.message ?: "Failed to send verification email"
                    )
                }
        }
    }

    fun resetState() {
        _uiState.value = EmailVerificationUiState.Idle
    }

    private fun isValidEmail(email: String): Boolean {
        if (email.isBlank()) return false
        val emailRegex = "^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return email.matches(emailRegex.toRegex())
    }
}
