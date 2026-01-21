package com.pergamino.data.local

import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class AesEncryptionHelperTest {

    private lateinit var encryptionHelper: AesEncryptionHelper

    @Before
    fun setup() {
        encryptionHelper = AesEncryptionHelper()
    }

    @Test
    fun encrypt_returnsEncryptedStringWithIV() {
        val plaintext = "test data"

        val result = encryptionHelper.encrypt(plaintext)

        assertTrue(result.isSuccess)
        val encrypted = result.getOrThrow()
        assertTrue(encrypted.contains("|"))
        val parts = encrypted.split("|")
        assertEquals(2, parts.size)
    }

    @Test
    fun decrypt_returnsOriginalPlaintext() {
        val plaintext = "test data"
        val encrypted = encryptionHelper.encrypt(plaintext).getOrThrow()

        val result = encryptionHelper.decrypt(encrypted)

        assertTrue(result.isSuccess)
        assertEquals(plaintext, result.getOrThrow())
    }

    @Test
    fun encrypt_sameDataTwiceProducesDifferentCiphertext() {
        val plaintext = "test data"

        val encrypted1 = encryptionHelper.encrypt(plaintext).getOrThrow()
        val encrypted2 = encryptionHelper.encrypt(plaintext).getOrThrow()

        assertNotEquals(encrypted1, encrypted2)
    }

    @Test
    fun decrypt_withWrongEncryptedDataFails() {
        val invalidEncrypted = "invalid|encrypted|data"

        val result = encryptionHelper.decrypt(invalidEncrypted)

        assertTrue(result.isFailure)
    }

    @Test
    fun encrypt_emptyStringSucceeds() {
        val plaintext = ""

        val result = encryptionHelper.encrypt(plaintext)

        assertTrue(result.isSuccess)
        val decrypted = encryptionHelper.decrypt(result.getOrThrow()).getOrThrow()
        assertEquals(plaintext, decrypted)
    }

    @Test
    fun encrypt_andDecryptUnicodeCharacters() {
        val plaintext = "Hello 世界 🌍"

        val encrypted = encryptionHelper.encrypt(plaintext).getOrThrow()
        val decrypted = encryptionHelper.decrypt(encrypted).getOrThrow()

        assertEquals(plaintext, decrypted)
    }
}
