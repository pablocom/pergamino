package com.pergamino.data.local

import com.pergamino.domain.model.DeviceId
import com.pergamino.domain.model.JwtToken

interface SecureDeviceStorage {
    fun storeDeviceCredentials(deviceId: DeviceId, email: String, jwtToken: JwtToken): Result<Unit>
    fun getDeviceId(): Result<DeviceId>
    fun getEmail(): Result<String>
    fun getJwtToken(): Result<JwtToken>
    fun hasCredentials(): Boolean
    fun clearCredentials(): Result<Unit>
}
