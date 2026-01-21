package com.pergamino.data.local

import android.content.Context
import android.content.SharedPreferences
import com.pergamino.domain.model.DeviceId
import com.pergamino.domain.model.PublicKey
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class SecureDeviceStorageImpl @Inject constructor(
    @ApplicationContext private val context: Context,
    private val encryptionHelper: AesEncryptionHelper
) : SecureDeviceStorage {

    companion object {
        private const val PREFS_NAME = "device_credentials"
        private const val KEY_DEVICE_ID = "device_id"
        private const val KEY_EMAIL = "email"
        private const val KEY_PUBLIC_KEY = "public_key"
    }

    private val sharedPreferences: SharedPreferences by lazy {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    override fun storeDeviceCredentials(
        deviceId: DeviceId,
        email: String,
        publicKey: PublicKey
    ): Result<Unit> = runCatching {
        val encryptedDeviceId = encryptionHelper.encrypt(deviceId.toString()).getOrThrow()
        val encryptedEmail = encryptionHelper.encrypt(email).getOrThrow()
        val encryptedPublicKey = encryptionHelper.encrypt(publicKey.value).getOrThrow()

        sharedPreferences.edit().apply {
            putString(KEY_DEVICE_ID, encryptedDeviceId)
            putString(KEY_EMAIL, encryptedEmail)
            putString(KEY_PUBLIC_KEY, encryptedPublicKey)
            apply()
        }
    }

    override fun getDeviceId(): Result<DeviceId> = runCatching {
        val encrypted = sharedPreferences.getString(KEY_DEVICE_ID, null)
            ?: throw IllegalStateException("Device ID not found")

        val decrypted = encryptionHelper.decrypt(encrypted).getOrThrow()
        DeviceId.fromString(decrypted).getOrThrow()
    }

    override fun getEmail(): Result<String> = runCatching {
        val encrypted = sharedPreferences.getString(KEY_EMAIL, null)
            ?: throw IllegalStateException("Email not found")

        encryptionHelper.decrypt(encrypted).getOrThrow()
    }

    override fun getPublicKey(): Result<PublicKey> = runCatching {
        val encrypted = sharedPreferences.getString(KEY_PUBLIC_KEY, null)
            ?: throw IllegalStateException("Public key not found")

        val decrypted = encryptionHelper.decrypt(encrypted).getOrThrow()
        PublicKey.fromString(decrypted).getOrThrow()
    }

    override fun hasCredentials(): Boolean {
        return sharedPreferences.contains(KEY_DEVICE_ID) &&
                sharedPreferences.contains(KEY_EMAIL) &&
                sharedPreferences.contains(KEY_PUBLIC_KEY)
    }

    override fun clearCredentials(): Result<Unit> = runCatching {
        sharedPreferences.edit().apply {
            remove(KEY_DEVICE_ID)
            remove(KEY_EMAIL)
            remove(KEY_PUBLIC_KEY)
            apply()
        }
    }
}
