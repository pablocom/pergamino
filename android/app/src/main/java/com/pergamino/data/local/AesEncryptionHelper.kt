package com.pergamino.data.local

import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AesEncryptionHelper @Inject constructor() {

    companion object {
        private const val ANDROID_KEYSTORE = "AndroidKeyStore"
        private const val MASTER_KEY_ALIAS = "pergamino_master_key"
        private const val TRANSFORMATION = "AES/GCM/NoPadding"
        private const val KEY_SIZE = 256
        private const val GCM_TAG_LENGTH = 128
        private const val IV_SEPARATOR = "|"
    }

    private val keyStore: KeyStore by lazy {
        KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
    }

    init {
        createMasterKeyIfNeeded()
    }

    private fun createMasterKeyIfNeeded() {
        if (keyStore.containsAlias(MASTER_KEY_ALIAS)) return

        val keyGenerator = KeyGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_AES,
            ANDROID_KEYSTORE
        )

        val keyGenSpec = KeyGenParameterSpec.Builder(
            MASTER_KEY_ALIAS,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
        )
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(KEY_SIZE)
            .setUserAuthenticationRequired(false)
            .build()

        keyGenerator.init(keyGenSpec)
        keyGenerator.generateKey()
    }

    private fun getMasterKey(): SecretKey {
        return keyStore.getKey(MASTER_KEY_ALIAS, null) as SecretKey
    }

    fun encrypt(plaintext: String): Result<String> = runCatching {
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, getMasterKey())

        val iv = cipher.iv
        val encryptedData = cipher.doFinal(plaintext.toByteArray(Charsets.UTF_8))

        val ivBase64 = Base64.encodeToString(iv, Base64.NO_WRAP)
        val encryptedBase64 = Base64.encodeToString(encryptedData, Base64.NO_WRAP)

        "$ivBase64$IV_SEPARATOR$encryptedBase64"
    }

    fun decrypt(encryptedData: String): Result<String> = runCatching {
        val parts = encryptedData.split(IV_SEPARATOR)
        require(parts.size == 2) { "Invalid encrypted data format" }

        val iv = Base64.decode(parts[0], Base64.NO_WRAP)
        val encrypted = Base64.decode(parts[1], Base64.NO_WRAP)

        val cipher = Cipher.getInstance(TRANSFORMATION)
        val gcmSpec = GCMParameterSpec(GCM_TAG_LENGTH, iv)
        cipher.init(Cipher.DECRYPT_MODE, getMasterKey(), gcmSpec)

        val decryptedData = cipher.doFinal(encrypted)
        String(decryptedData, Charsets.UTF_8)
    }
}
