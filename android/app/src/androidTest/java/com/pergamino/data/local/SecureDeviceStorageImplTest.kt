package com.pergamino.data.local

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.pergamino.domain.model.DeviceId
import com.pergamino.domain.model.PublicKey
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
    private lateinit var encryptionHelper: AesEncryptionHelper

    @Before
    fun setup() {
        context = ApplicationProvider.getApplicationContext()
        encryptionHelper = AesEncryptionHelper()
        storage = SecureDeviceStorageImpl(context, encryptionHelper)
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
        val publicKey = PublicKey.fromByteArray(ByteArray(65) { it.toByte() })

        val result = storage.storeDeviceCredentials(deviceId, email, publicKey)

        assertTrue(result.isSuccess)
    }

    @Test
    fun getDeviceId_returnsStoredDeviceId() {
        val deviceId = DeviceId.random()
        val email = "test@example.com"
        val publicKey = PublicKey.fromByteArray(ByteArray(65) { it.toByte() })
        storage.storeDeviceCredentials(deviceId, email, publicKey)

        val result = storage.getDeviceId()

        assertTrue(result.isSuccess)
        assertEquals(deviceId, result.getOrThrow())
    }

    @Test
    fun getEmail_returnsStoredEmail() {
        val deviceId = DeviceId.random()
        val email = "test@example.com"
        val publicKey = PublicKey.fromByteArray(ByteArray(65) { it.toByte() })
        storage.storeDeviceCredentials(deviceId, email, publicKey)

        val result = storage.getEmail()

        assertTrue(result.isSuccess)
        assertEquals(email, result.getOrThrow())
    }

    @Test
    fun getPublicKey_returnsStoredPublicKey() {
        val deviceId = DeviceId.random()
        val email = "test@example.com"
        val publicKey = PublicKey.fromByteArray(ByteArray(65) { it.toByte() })
        storage.storeDeviceCredentials(deviceId, email, publicKey)

        val result = storage.getPublicKey()

        assertTrue(result.isSuccess)
        assertEquals(publicKey.value, result.getOrThrow().value)
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
        val publicKey = PublicKey.fromByteArray(ByteArray(65) { it.toByte() })
        storage.storeDeviceCredentials(deviceId, email, publicKey)

        val hasCredentials = storage.hasCredentials()

        assertTrue(hasCredentials)
    }

    @Test
    fun clearCredentials_removesAllData() {
        val deviceId = DeviceId.random()
        val email = "test@example.com"
        val publicKey = PublicKey.fromByteArray(ByteArray(65) { it.toByte() })
        storage.storeDeviceCredentials(deviceId, email, publicKey)

        storage.clearCredentials()

        assertFalse(storage.hasCredentials())
        assertTrue(storage.getDeviceId().isFailure)
        assertTrue(storage.getEmail().isFailure)
        assertTrue(storage.getPublicKey().isFailure)
    }

    @Test
    fun credentials_persistAcrossStorageInstanceRecreation() {
        val deviceId = DeviceId.random()
        val email = "test@example.com"
        val publicKey = PublicKey.fromByteArray(ByteArray(65) { it.toByte() })
        storage.storeDeviceCredentials(deviceId, email, publicKey)

        val newStorage = SecureDeviceStorageImpl(context, encryptionHelper)

        assertTrue(newStorage.hasCredentials())
        assertEquals(deviceId, newStorage.getDeviceId().getOrThrow())
        assertEquals(email, newStorage.getEmail().getOrThrow())
        assertEquals(publicKey.value, newStorage.getPublicKey().getOrThrow().value)
    }
}
