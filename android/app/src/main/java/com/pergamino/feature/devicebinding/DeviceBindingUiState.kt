package com.pergamino.feature.devicebinding

sealed interface DeviceBindingUiState {
    data object Idle : DeviceBindingUiState
    data object Verifying : DeviceBindingUiState
    data class Success(val email: String) : DeviceBindingUiState
    data class Error(val message: String) : DeviceBindingUiState
}
