package com.pergamino.data.repository

import com.pergamino.data.local.SecureDeviceStorage
import com.pergamino.data.network.DeviceBindingService
import com.pergamino.data.network.model.request.DeviceBindingRequest
import com.pergamino.data.network.model.response.DeviceBindingResponse
import com.pergamino.domain.model.DeviceId
import com.pergamino.domain.model.JwtToken
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.mockito.kotlin.any
import org.mockito.kotlin.check
import org.mockito.kotlin.eq
import org.mockito.kotlin.mock
import org.mockito.kotlin.never
import org.mockito.kotlin.verify
import org.mockito.kotlin.whenever

class DeviceBindingRepositoryImplTest {

    private lateinit var apiService: DeviceBindingService
    private lateinit var secureStorage: SecureDeviceStorage
    private lateinit var repository: DeviceBindingRepositoryImpl

    private val validVerificationToken = JwtToken.fromString("valid.jwt.token").getOrThrow()
    private val validAuthToken = JwtToken.fromString("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U").getOrThrow()
    private val validDeviceId = DeviceId.random()
    private val validEmail = "test@example.com"

    @Before
    fun setup() {
        apiService = mock()
        secureStorage = mock()
        repository = DeviceBindingRepositoryImpl(apiService, secureStorage)
    }

    @Test
    fun `verifyBinding sends correct request to API`() = runTest {
        whenever(apiService.verifyBinding(any(), any())).thenReturn(
            DeviceBindingResponse(validDeviceId.toString(), validEmail, validAuthToken.value)
        )
        whenever(secureStorage.storeDeviceCredentials(any(), any(), any())).thenReturn(Result.success(Unit))

        repository.verifyBinding(validVerificationToken)

        val expectedRequest = DeviceBindingRequest(token = validVerificationToken.value)
        verify(apiService).verifyBinding(eq(expectedRequest), any())
    }

    @Test
    fun `verifyBinding stores credentials on success`() = runTest {
        whenever(apiService.verifyBinding(any(), any())).thenReturn(
            DeviceBindingResponse(validDeviceId.toString(), validEmail, validAuthToken.value)
        )
        whenever(secureStorage.storeDeviceCredentials(any(), any(), any())).thenReturn(Result.success(Unit))

        repository.verifyBinding(validVerificationToken)

        verify(secureStorage).storeDeviceCredentials(
            any(),
            check { assertEquals(validEmail, it) },
            any()
        )
    }

    @Test
    fun `verifyBinding returns DeviceBindingResult on success`() = runTest {
        whenever(apiService.verifyBinding(any(), any())).thenReturn(
            DeviceBindingResponse(validDeviceId.toString(), validEmail, validAuthToken.value)
        )
        whenever(secureStorage.storeDeviceCredentials(any(), any(), any())).thenReturn(Result.success(Unit))

        val result = repository.verifyBinding(validVerificationToken)

        assertTrue(result.isSuccess)
        val bindingResult = result.getOrThrow()
        assertEquals(validEmail, bindingResult.email)
        assertEquals(validDeviceId, bindingResult.deviceId)
    }

    @Test
    fun `verifyBinding returns failure when API call fails`() = runTest {
        val apiException = RuntimeException("API error")
        whenever(apiService.verifyBinding(any(), any())).thenThrow(apiException)

        val result = repository.verifyBinding(validVerificationToken)

        assertTrue(result.isFailure)
        verify(secureStorage, never()).storeDeviceCredentials(any(), any(), any())
    }

    @Test
    fun `verifyBinding returns failure when storage fails`() = runTest {
        val storageException = Exception("Storage error")
        whenever(apiService.verifyBinding(any(), any())).thenReturn(
            DeviceBindingResponse(validDeviceId.toString(), validEmail, validAuthToken.value)
        )
        whenever(secureStorage.storeDeviceCredentials(any(), any(), any())).thenReturn(Result.failure(storageException))

        val result = repository.verifyBinding(validVerificationToken)

        assertTrue(result.isFailure)
    }

    @Test
    fun `verifyBinding handles invalid deviceId from backend`() = runTest {
        val invalidDeviceId = "invalid-uuid-format"
        whenever(apiService.verifyBinding(any(), any())).thenReturn(
            DeviceBindingResponse(invalidDeviceId, validEmail, validAuthToken.value)
        )

        val result = repository.verifyBinding(validVerificationToken)

        assertTrue(result.isFailure)
    }

    @Test
    fun `verifyBinding handles invalid JWT token from backend`() = runTest {
        whenever(apiService.verifyBinding(any(), any())).thenReturn(
            DeviceBindingResponse(validDeviceId.toString(), validEmail, "invalid-jwt")
        )

        val result = repository.verifyBinding(validVerificationToken)

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
    fun `clearCredentials clears storage`() = runTest {
        whenever(secureStorage.clearCredentials()).thenReturn(Result.success(Unit))

        val result = repository.clearCredentials()

        assertTrue(result.isSuccess)
        verify(secureStorage).clearCredentials()
    }

    @Test
    fun `clearCredentials returns failure when storage clear fails`() = runTest {
        val storageException = Exception("Storage clear failed")
        whenever(secureStorage.clearCredentials()).thenReturn(Result.failure(storageException))

        val result = repository.clearCredentials()

        assertTrue(result.isFailure)
    }
}
