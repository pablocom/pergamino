package com.pergamino.data.local

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.pergamino.domain.model.DeviceId
import com.pergamino.domain.model.JwtToken
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class SecureDeviceStorageImplTest {

    private lateinit var storage: SecureDeviceStorageImpl
    private lateinit var context: Context

    @Before
    fun setup() {
        context = ApplicationProvider.getApplicationContext()
        storage = SecureDeviceStorageImpl(context)
        storage.clearCredentials()
    }

    @After
    fun tearDown() {
        storage.clearCredentials()
    }

    @Test
    fun storeDeviceCredentials_savesAllFields() {
        val deviceId = DeviceId.random()
        val email = "test@example.com"
        val jwtToken = JwtToken.fromString("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U").getOrThrow()

        val result = storage.storeDeviceCredentials(deviceId, email, jwtToken)

        assertTrue(result.isSuccess)
    }

    @Test
    fun getDeviceId_returnsStoredDeviceId() {
        val deviceId = DeviceId.random()
        val email = "test@example.com"
        val jwtToken = JwtToken.fromString("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U").getOrThrow()
        storage.storeDeviceCredentials(deviceId, email, jwtToken)

        val result = storage.getDeviceId()

        assertTrue(result.isSuccess)
        assertEquals(deviceId, result.getOrThrow())
    }

    @Test
    fun getEmail_returnsStoredEmail() {
        val deviceId = DeviceId.random()
        val email = "test@example.com"
        val jwtToken = JwtToken.fromString("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U").getOrThrow()
        storage.storeDeviceCredentials(deviceId, email, jwtToken)

        val result = storage.getEmail()

        assertTrue(result.isSuccess)
        assertEquals(email, result.getOrThrow())
    }

    @Test
    fun getJwtToken_returnsStoredJwtToken() {
        val deviceId = DeviceId.random()
        val email = "test@example.com"
        val jwtToken = JwtToken.fromString("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U").getOrThrow()
        storage.storeDeviceCredentials(deviceId, email, jwtToken)

        val result = storage.getJwtToken()

        assertTrue(result.isSuccess)
        assertEquals(jwtToken.value, result.getOrThrow().value)
    }

    @Test
    fun hasCredentials_returnsFalseWhenEmpty() {
        val hasCredentials = storage.hasCredentials()

        assertFalse(hasCredentials)
    }

    @Test
    fun hasCredentials_returnsTrueAfterStoring() {
        val deviceId = DeviceId.random()
        val email = "test@example.com"
        val jwtToken = JwtToken.fromString("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U").getOrThrow()
        storage.storeDeviceCredentials(deviceId, email, jwtToken)

        val hasCredentials = storage.hasCredentials()

        assertTrue(hasCredentials)
    }

    @Test
    fun clearCredentials_removesAllData() {
        val deviceId = DeviceId.random()
        val email = "test@example.com"
        val jwtToken = JwtToken.fromString("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U").getOrThrow()
        storage.storeDeviceCredentials(deviceId, email, jwtToken)

        storage.clearCredentials()

        assertFalse(storage.hasCredentials())
        assertTrue(storage.getDeviceId().isFailure)
        assertTrue(storage.getEmail().isFailure)
        assertTrue(storage.getJwtToken().isFailure)
    }

    @Test
    fun credentials_persistAcrossStorageInstanceRecreation() {
        val deviceId = DeviceId.random()
        val email = "test@example.com"
        val jwtToken = JwtToken.fromString("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U").getOrThrow()
        storage.storeDeviceCredentials(deviceId, email, jwtToken)

        val newStorage = SecureDeviceStorageImpl(context)

        assertTrue(newStorage.hasCredentials())
        assertEquals(deviceId, newStorage.getDeviceId().getOrThrow())
        assertEquals(email, newStorage.getEmail().getOrThrow())
        assertEquals(jwtToken.value, newStorage.getJwtToken().getOrThrow().value)
    }
}
