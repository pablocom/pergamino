package com.pergamino.data.repository

import com.pergamino.data.crypto.EcdsaKeyManager
import com.pergamino.data.local.SecureDeviceStorage
import com.pergamino.data.network.DeviceBindingService
import com.pergamino.data.network.model.request.DeviceBindingRequest
import com.pergamino.data.network.model.response.DeviceBindingResponse
import com.pergamino.domain.model.DeviceId
import com.pergamino.domain.model.JwtToken
import com.pergamino.domain.model.PublicKey
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.mockito.kotlin.any
import org.mockito.kotlin.mock
import org.mockito.kotlin.never
import org.mockito.kotlin.verify
import org.mockito.kotlin.whenever

class DeviceBindingRepositoryImplTest {

    private lateinit var apiService: DeviceBindingService
    private lateinit var keyManager: EcdsaKeyManager
    private lateinit var secureStorage: SecureDeviceStorage
    private lateinit var repository: DeviceBindingRepositoryImpl

    private val validToken = JwtToken.fromString("valid.jwt.token").getOrThrow()
    private val validPublicKey = PublicKey.fromByteArray(ByteArray(65) { it.toByte() })
    private val validDeviceId = DeviceId.random()
    private val validEmail = "test@example.com"

    @Before
    fun setup() {
        apiService = mock()
        keyManager = mock()
        secureStorage = mock()
        repository = DeviceBindingRepositoryImpl(apiService, keyManager, secureStorage)
    }

    @Test
    fun `verifyBinding generates new key pair`() = runTest {
        whenever(keyManager.generateKeyPair()).thenReturn(Result.success(validPublicKey))
        whenever(apiService.verifyBinding(any())).thenReturn(
            DeviceBindingResponse(validDeviceId.toString(), validEmail)
        )
        whenever(secureStorage.storeDeviceCredentials(any(), any(), any())).thenReturn(Result.success(Unit))

        repository.verifyBinding(validToken)

        verify(keyManager).generateKeyPair()
    }

    @Test
    fun `verifyBinding sends correct request to API`() = runTest {
        whenever(keyManager.generateKeyPair()).thenReturn(Result.success(validPublicKey))
        whenever(apiService.verifyBinding(any())).thenReturn(
            DeviceBindingResponse(validDeviceId.toString(), validEmail)
        )
        whenever(secureStorage.storeDeviceCredentials(any(), any(), any())).thenReturn(Result.success(Unit))

        repository.verifyBinding(validToken)

        val expectedRequest = DeviceBindingRequest(
            token = validToken.value,
            publicKey = validPublicKey.value
        )
        verify(apiService).verifyBinding(expectedRequest)
    }

    @Test
    fun `verifyBinding stores credentials on success`() = runTest {
        whenever(keyManager.generateKeyPair()).thenReturn(Result.success(validPublicKey))
        whenever(apiService.verifyBinding(any())).thenReturn(
            DeviceBindingResponse(validDeviceId.toString(), validEmail)
        )
        whenever(secureStorage.storeDeviceCredentials(any(), any(), any())).thenReturn(Result.success(Unit))

        repository.verifyBinding(validToken)

        verify(secureStorage).storeDeviceCredentials(
            deviceId = any(),
            email = validEmail,
            publicKey = validPublicKey
        )
    }

    @Test
    fun `verifyBinding returns DeviceBindingResult on success`() = runTest {
        whenever(keyManager.generateKeyPair()).thenReturn(Result.success(validPublicKey))
        whenever(apiService.verifyBinding(any())).thenReturn(
            DeviceBindingResponse(validDeviceId.toString(), validEmail)
        )
        whenever(secureStorage.storeDeviceCredentials(any(), any(), any())).thenReturn(Result.success(Unit))

        val result = repository.verifyBinding(validToken)

        assertTrue(result.isSuccess)
        val bindingResult = result.getOrThrow()
        assertEquals(validEmail, bindingResult.email)
        assertEquals(validDeviceId, bindingResult.deviceId)
    }

    @Test
    fun `verifyBinding returns failure when key generation fails`() = runTest {
        val keyGenException = IllegalStateException("Key generation failed")
        whenever(keyManager.generateKeyPair()).thenReturn(Result.failure(keyGenException))

        val result = repository.verifyBinding(validToken)

        assertTrue(result.isFailure)
        verify(apiService, never()).verifyBinding(any())
        verify(secureStorage, never()).storeDeviceCredentials(any(), any(), any())
    }

    @Test
    fun `verifyBinding returns failure when API call fails`() = runTest {
        val apiException = RuntimeException("API error")
        whenever(keyManager.generateKeyPair()).thenReturn(Result.success(validPublicKey))
        whenever(apiService.verifyBinding(any())).thenThrow(apiException)

        val result = repository.verifyBinding(validToken)

        assertTrue(result.isFailure)
        verify(secureStorage, never()).storeDeviceCredentials(any(), any(), any())
    }

    @Test
    fun `verifyBinding returns failure when storage fails`() = runTest {
        val storageException = Exception("Storage error")
        whenever(keyManager.generateKeyPair()).thenReturn(Result.success(validPublicKey))
        whenever(apiService.verifyBinding(any())).thenReturn(
            DeviceBindingResponse(validDeviceId.toString(), validEmail)
        )
        whenever(secureStorage.storeDeviceCredentials(any(), any(), any())).thenReturn(Result.failure(storageException))

        val result = repository.verifyBinding(validToken)

        assertTrue(result.isFailure)
    }

    @Test
    fun `verifyBinding handles invalid deviceId from backend`() = runTest {
        val invalidDeviceId = "invalid-uuid-format"
        whenever(keyManager.generateKeyPair()).thenReturn(Result.success(validPublicKey))
        whenever(apiService.verifyBinding(any())).thenReturn(
            DeviceBindingResponse(invalidDeviceId, validEmail)
        )

        val result = repository.verifyBinding(validToken)

        assertTrue(result.isFailure)
    }

    @Test
    fun `getDeviceCredentials returns stored credentials`() = runTest {
        whenever(secureStorage.getDeviceId()).thenReturn(Result.success(validDeviceId))
        whenever(secureStorage.getEmail()).thenReturn(Result.success(validEmail))

        val result = repository.getDeviceCredentials()

        assertTrue(result.isSuccess)
        val credentials = result.getOrThrow()
        assertEquals(validDeviceId, credentials.deviceId)
        assertEquals(validEmail, credentials.email)
    }

    @Test
    fun `getDeviceCredentials returns failure when storage is empty`() = runTest {
        val storageException = IllegalStateException("Device ID not found")
        whenever(secureStorage.getDeviceId()).thenReturn(Result.failure(storageException))

        val result = repository.getDeviceCredentials()

        assertTrue(result.isFailure)
    }

    @Test
    fun `hasCredentials returns true when credentials exist`() = runTest {
        whenever(secureStorage.hasCredentials()).thenReturn(true)

        val hasCredentials = repository.hasCredentials()

        assertTrue(hasCredentials)
    }

    @Test
    fun `hasCredentials returns false when credentials missing`() = runTest {
        whenever(secureStorage.hasCredentials()).thenReturn(false)

        val hasCredentials = repository.hasCredentials()

        assertFalse(hasCredentials)
    }

    @Test
    fun `clearCredentials clears storage and deletes key pair`() = runTest {
        whenever(secureStorage.clearCredentials()).thenReturn(Result.success(Unit))
        whenever(keyManager.deleteKeyPair()).thenReturn(Result.success(Unit))

        val result = repository.clearCredentials()

        assertTrue(result.isSuccess)
        verify(secureStorage).clearCredentials()
        verify(keyManager).deleteKeyPair()
    }

    @Test
    fun `clearCredentials returns failure when storage clear fails`() = runTest {
        val storageException = Exception("Storage clear failed")
        whenever(secureStorage.clearCredentials()).thenReturn(Result.failure(storageException))

        val result = repository.clearCredentials()

        assertTrue(result.isFailure)
        verify(keyManager, never()).deleteKeyPair()
    }
}
