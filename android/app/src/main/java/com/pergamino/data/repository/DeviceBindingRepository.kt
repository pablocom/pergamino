package com.pergamino.data.repository

import com.pergamino.domain.model.DeviceId
import com.pergamino.domain.model.JwtToken

interface DeviceBindingRepository {
    suspend fun verifyBinding(token: JwtToken): Result<DeviceBindingResult>
    suspend fun getDeviceCredentials(): Result<DeviceCredentials>
    suspend fun hasCredentials(): Boolean
    suspend fun clearCredentials(): Result<Unit>
}

data class DeviceBindingResult(
    val deviceId: DeviceId,
    val email: String
)

data class DeviceCredentials(
    val deviceId: DeviceId,
    val email: String
)
