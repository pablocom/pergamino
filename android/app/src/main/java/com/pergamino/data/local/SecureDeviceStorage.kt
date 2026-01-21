package com.pergamino.data.local

import com.pergamino.domain.model.DeviceId
import com.pergamino.domain.model.PublicKey

interface SecureDeviceStorage {
    fun storeDeviceCredentials(deviceId: DeviceId, email: String, publicKey: PublicKey): Result<Unit>
    fun getDeviceId(): Result<DeviceId>
    fun getEmail(): Result<String>
    fun getPublicKey(): Result<PublicKey>
    fun hasCredentials(): Boolean
    fun clearCredentials(): Result<Unit>
}
