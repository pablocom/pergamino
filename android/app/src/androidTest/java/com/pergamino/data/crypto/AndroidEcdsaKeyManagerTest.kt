package com.pergamino.data.crypto

import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class AndroidEcdsaKeyManagerTest {

    private lateinit var keyManager: AndroidEcdsaKeyManager

    @Before
    fun setup() {
        keyManager = AndroidEcdsaKeyManager()
        keyManager.deleteKeyPair()
    }

    @After
    fun tearDown() {
        keyManager.deleteKeyPair()
    }

    @Test
    fun generateKeyPair_createsValidPublicKey() {
        val result = keyManager.generateKeyPair()

        assertTrue(result.isSuccess)
        val publicKey = result.getOrThrow()
        assertTrue(publicKey.value.isNotBlank())
        assertTrue(publicKey.toByteArray().size >= 33)
    }

    @Test
    fun generateKeyPair_deletesExistingKeyBeforeCreatingNewOne() {
        val firstResult = keyManager.generateKeyPair()
        assertTrue(firstResult.isSuccess)
        val firstPublicKey = firstResult.getOrThrow()

        val secondResult = keyManager.generateKeyPair()
        assertTrue(secondResult.isSuccess)
        val secondPublicKey = secondResult.getOrThrow()

        assertNotEquals(firstPublicKey.value, secondPublicKey.value)
    }

    @Test
    fun getPublicKey_returnsSameKeyAfterGeneration() {
        val generatedKey = keyManager.generateKeyPair().getOrThrow()

        val retrievedKey = keyManager.getPublicKey().getOrThrow()

        assertEquals(generatedKey.value, retrievedKey.value)
    }

    @Test
    fun getPublicKey_failsWhenNoKeyExists() {
        val result = keyManager.getPublicKey()

        assertTrue(result.isFailure)
    }

    @Test
    fun hasKeyPair_returnsFalseInitially() {
        val hasKey = keyManager.hasKeyPair()

        assertFalse(hasKey)
    }

    @Test
    fun hasKeyPair_returnsTrueAfterGeneration() {
        keyManager.generateKeyPair()

        val hasKey = keyManager.hasKeyPair()

        assertTrue(hasKey)
    }

    @Test
    fun deleteKeyPair_removesKey() {
        keyManager.generateKeyPair()
        assertTrue(keyManager.hasKeyPair())

        keyManager.deleteKeyPair()

        assertFalse(keyManager.hasKeyPair())
    }

    @Test
    fun signData_withValidKeyReturnsSignature() {
        keyManager.generateKeyPair()
        val dataToSign = "test data".toByteArray()

        val result = keyManager.signData(dataToSign)

        assertTrue(result.isSuccess)
        val signature = result.getOrThrow()
        assertTrue(signature.isNotEmpty())
        assertTrue(signature.size >= 64)
    }
}
