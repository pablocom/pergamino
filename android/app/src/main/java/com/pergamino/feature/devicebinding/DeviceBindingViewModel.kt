package com.pergamino.feature.devicebinding

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.pergamino.data.repository.DeviceBindingRepository
import com.pergamino.domain.model.JwtToken
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import retrofit2.HttpException
import java.io.IOException
import javax.inject.Inject

@HiltViewModel
class DeviceBindingViewModel @Inject constructor(
    private val repository: DeviceBindingRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow<DeviceBindingUiState>(DeviceBindingUiState.Idle)
    val uiState: StateFlow<DeviceBindingUiState> = _uiState.asStateFlow()

    fun verifyBindingToken(tokenString: String) {
        viewModelScope.launch {
            _uiState.value = DeviceBindingUiState.Verifying

            val tokenResult = JwtToken.fromString(tokenString)
            if (tokenResult.isFailure) {
                _uiState.value = DeviceBindingUiState.Error("Invalid verification link")
                return@launch
            }

            val token = tokenResult.getOrThrow()

            repository.verifyBinding(token)
                .onSuccess { result ->
                    _uiState.value = DeviceBindingUiState.Success(result.email)
                }
                .onFailure { error ->
                    val errorMessage = when (error) {
                        is HttpException -> when (error.code()) {
                            401 -> "Link expired. Please request a new verification email."
                            500 -> "Server error. Please try again later."
                            else -> "Verification failed. Please try again."
                        }
                        is IOException -> "Connection failed. Please check your internet and try again."
                        is IllegalStateException -> "Device security error. Please restart the app."
                        else -> "An unexpected error occurred. Please try again."
                    }
                    _uiState.value = DeviceBindingUiState.Error(errorMessage)
                }
        }
    }

    fun resetState() {
        _uiState.value = DeviceBindingUiState.Idle
    }
}
