package com.pergamino.domain.model

import android.util.Base64
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class PublicKeyTest {

    private val validKeyBytes = ByteArray(65) { it.toByte() }
    private val validBase64Key = Base64.encodeToString(validKeyBytes, Base64.NO_WRAP)

    @Test
    fun `fromByteArray with valid key creates PublicKey`() {
        val publicKey = PublicKey.fromByteArray(validKeyBytes)

        assertEquals(validBase64Key, publicKey.value)
    }

    @Test
    fun `fromString with valid base64 succeeds`() {
        val result = PublicKey.fromString(validBase64Key)

        assertTrue(result.isSuccess)
        assertEquals(validBase64Key, result.getOrThrow().value)
    }

    @Test
    fun `fromString with invalid base64 fails`() {
        val invalidBase64 = "not-valid-base64!!!"

        val result = PublicKey.fromString(invalidBase64)

        assertTrue(result.isFailure)
    }

    @Test
    fun `fromString with too small key fails`() {
        val tooSmallKey = ByteArray(20) { it.toByte() }
        val tooSmallBase64 = Base64.encodeToString(tooSmallKey, Base64.NO_WRAP)

        val result = PublicKey.fromString(tooSmallBase64)

        assertTrue(result.isFailure)
    }

    @Test
    fun `fromString with too large key fails`() {
        val tooLargeKey = ByteArray(300) { it.toByte() }
        val tooLargeBase64 = Base64.encodeToString(tooLargeKey, Base64.NO_WRAP)

        val result = PublicKey.fromString(tooLargeBase64)

        assertTrue(result.isFailure)
    }

    @Test
    fun `toByteArray returns decoded bytes`() {
        val publicKey = PublicKey.fromByteArray(validKeyBytes)

        val decodedBytes = publicKey.toByteArray()

        assertTrue(validKeyBytes.contentEquals(decodedBytes))
    }

    @Test
    fun `value returns base64 string`() {
        val publicKey = PublicKey.fromByteArray(validKeyBytes)

        assertEquals(validBase64Key, publicKey.value)
    }

    @Test
    fun `isValid returns false for blank string`() {
        assertFalse(PublicKey.isValid(""))
        assertFalse(PublicKey.isValid("   "))
    }

    @Test
    fun `isValid returns true for valid key`() {
        assertTrue(PublicKey.isValid(validBase64Key))
    }
}
