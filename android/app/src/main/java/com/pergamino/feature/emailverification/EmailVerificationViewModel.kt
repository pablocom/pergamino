package com.pergamino.feature.emailverification

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class EmailVerificationViewModel : ViewModel() {

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
            try {
                sendVerificationEmail(currentEmail)
                _uiState.value = EmailVerificationUiState.Success
            } catch (e: Exception) {
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

    private suspend fun sendVerificationEmail(email: String) {
        delay(1500)
    }
}
