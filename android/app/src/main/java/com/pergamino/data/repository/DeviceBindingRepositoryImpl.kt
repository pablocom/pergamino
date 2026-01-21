package com.pergamino.data.repository

import com.pergamino.data.local.SecureDeviceStorage
import com.pergamino.data.network.DeviceBindingService
import com.pergamino.data.network.model.request.DeviceBindingRequest
import com.pergamino.domain.model.DeviceId
import com.pergamino.domain.model.JwtToken
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class DeviceBindingRepositoryImpl @Inject constructor(
    private val apiService: DeviceBindingService,
    private val secureStorage: SecureDeviceStorage
) : DeviceBindingRepository {

    override suspend fun verifyBinding(token: JwtToken): Result<DeviceBindingResult> = runCatching {
        val request = DeviceBindingRequest(token = token.value)
        val response = apiService.verifyBinding(request)

        val deviceId = DeviceId.fromString(response.deviceId).getOrThrow()
        val jwtToken = JwtToken.fromString(response.jwtToken).getOrThrow()

        secureStorage.storeDeviceCredentials(
            deviceId = deviceId,
            email = response.email,
            jwtToken = jwtToken
        ).getOrThrow()

        DeviceBindingResult(
            deviceId = deviceId,
            email = response.email
        )
    }

    override suspend fun getDeviceCredentials(): Result<DeviceCredentials> = runCatching {
        val deviceId = secureStorage.getDeviceId().getOrThrow()
        val email = secureStorage.getEmail().getOrThrow()

        DeviceCredentials(
            deviceId = deviceId,
            email = email
        )
    }

    override suspend fun hasCredentials(): Boolean {
        return secureStorage.hasCredentials()
    }

    override suspend fun clearCredentials(): Result<Unit> = runCatching {
        secureStorage.clearCredentials().getOrThrow()
    }
}
