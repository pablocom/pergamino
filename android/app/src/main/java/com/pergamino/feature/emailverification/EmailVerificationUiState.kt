package com.pergamino.feature.emailverification

sealed interface EmailVerificationUiState {
    data object Idle : EmailVerificationUiState
    data object Loading : EmailVerificationUiState
    data object Success : EmailVerificationUiState
    data class Error(val message: String) : EmailVerificationUiState
}
