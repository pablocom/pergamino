package com.pergamino.feature.emailverification

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.pergamino.data.repository.EmailVerificationRepository
import com.pergamino.domain.model.Email
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
        val email = Email.create(_email.value.trim()).getOrElse {
            _emailError.value = "Please enter a valid email address"
            return
        }

        viewModelScope.launch {
            _uiState.value = EmailVerificationUiState.Loading
            
            val result = repository.requestVerificationEmail(email)
            
            _uiState.value = result.fold(
                onSuccess = { EmailVerificationUiState.Success },
                onFailure = { e -> 
                    EmailVerificationUiState.Error(
                        e.message ?: "Failed to send verification email"
                    ) 
                }
            )
        }
    }

    fun resetState() {
        _uiState.value = EmailVerificationUiState.Idle
    }
}
