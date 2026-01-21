package com.pergamino.data.local

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.google.crypto.tink.Aead
import com.google.crypto.tink.KeysetHandle
import com.google.crypto.tink.aead.AeadConfig
import com.google.crypto.tink.aead.AeadKeyTemplates
import com.google.crypto.tink.integration.android.AndroidKeysetManager
import com.pergamino.domain.model.DeviceId
import com.pergamino.domain.model.JwtToken
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.runBlocking
import javax.inject.Inject
import javax.inject.Singleton

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "device_credentials")

@Singleton
class SecureDeviceStorageImpl @Inject constructor(
    @ApplicationContext private val context: Context
) : SecureDeviceStorage {

    companion object {
        private const val KEYSET_NAME = "device_credentials_keyset"
        private const val MASTER_KEY_URI = "android-keystore://device_credentials_master_key"
        private val KEY_DEVICE_ID = stringPreferencesKey("device_id")
        private val KEY_EMAIL = stringPreferencesKey("email")
        private val KEY_JWT_TOKEN = stringPreferencesKey("jwt_token")
    }

    private val aead: Aead by lazy {
        AeadConfig.register()

        val keysetHandle = AndroidKeysetManager.Builder()
            .withSharedPref(context, KEYSET_NAME, "device_credentials_prefs")
            .withKeyTemplate(AeadKeyTemplates.AES256_GCM)
            .withMasterKeyUri(MASTER_KEY_URI)
            .build()
            .keysetHandle

        keysetHandle.getPrimitive(Aead::class.java)
    }

    private fun encrypt(plaintext: String): String {
        val ciphertext = aead.encrypt(plaintext.toByteArray(Charsets.UTF_8), null)
        return android.util.Base64.encodeToString(ciphertext, android.util.Base64.NO_WRAP)
    }

    private fun decrypt(ciphertext: String): String {
        val encryptedBytes = android.util.Base64.decode(ciphertext, android.util.Base64.NO_WRAP)
        val plaintext = aead.decrypt(encryptedBytes, null)
        return String(plaintext, Charsets.UTF_8)
    }

    override fun storeDeviceCredentials(
        deviceId: DeviceId,
        email: String,
        jwtToken: JwtToken
    ): Result<Unit> = runCatching {
        runBlocking {
            context.dataStore.edit { preferences ->
                preferences[KEY_DEVICE_ID] = encrypt(deviceId.toString())
                preferences[KEY_EMAIL] = encrypt(email)
                preferences[KEY_JWT_TOKEN] = encrypt(jwtToken.value)
            }
        }
    }

    override fun getDeviceId(): Result<DeviceId> = runCatching {
        runBlocking {
            val encrypted = context.dataStore.data.map { preferences ->
                preferences[KEY_DEVICE_ID]
            }.first() ?: throw IllegalStateException("Device ID not found")

            val decrypted = decrypt(encrypted)
            DeviceId.fromString(decrypted).getOrThrow()
        }
    }

    override fun getEmail(): Result<String> = runCatching {
        runBlocking {
            val encrypted = context.dataStore.data.map { preferences ->
                preferences[KEY_EMAIL]
            }.first() ?: throw IllegalStateException("Email not found")

            decrypt(encrypted)
        }
    }

    override fun getJwtToken(): Result<JwtToken> = runCatching {
        runBlocking {
            val encrypted = context.dataStore.data.map { preferences ->
                preferences[KEY_JWT_TOKEN]
            }.first() ?: throw IllegalStateException("JWT token not found")

            val decrypted = decrypt(encrypted)
            JwtToken.fromString(decrypted).getOrThrow()
        }
    }

    override fun hasCredentials(): Boolean = runBlocking {
        val preferences = context.dataStore.data.first()
        preferences.contains(KEY_DEVICE_ID) &&
                preferences.contains(KEY_EMAIL) &&
                preferences.contains(KEY_JWT_TOKEN)
    }

    override fun clearCredentials(): Result<Unit> = runCatching {
        runBlocking {
            context.dataStore.edit { preferences ->
                preferences.remove(KEY_DEVICE_ID)
                preferences.remove(KEY_EMAIL)
                preferences.remove(KEY_JWT_TOKEN)
            }
        }
    }
}
