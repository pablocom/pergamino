package com.pergamino.domain.model

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class JwtTokenTest {

    @Test
    fun `fromString with valid JWT succeeds`() {
        val validJwt = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"

        val result = JwtToken.fromString(validJwt)

        assertTrue(result.isSuccess)
        assertEquals(validJwt, result.getOrThrow().value)
    }

    @Test
    fun `fromString with 2 parts fails`() {
        val invalidJwt = "part1.part2"

        val result = JwtToken.fromString(invalidJwt)

        assertTrue(result.isFailure)
    }

    @Test
    fun `fromString with 4 parts fails`() {
        val invalidJwt = "part1.part2.part3.part4"

        val result = JwtToken.fromString(invalidJwt)

        assertTrue(result.isFailure)
    }

    @Test
    fun `fromString with empty string fails`() {
        val result = JwtToken.fromString("")

        assertTrue(result.isFailure)
    }

    @Test
    fun `fromString with invalid characters fails`() {
        val invalidJwt = "part1@invalid.part2.part3"

        val result = JwtToken.fromString(invalidJwt)

        assertTrue(result.isFailure)
    }

    @Test
    fun `valid JWT patterns accepted`() {
        val validTokens = listOf(
            "abc.def.ghi",
            "a-b_c.d-e_f.g-h_i",
            "ABC123.DEF456.GHI789",
            "a1-_b2.c3-_d4.e5-_f6"
        )

        validTokens.forEach { token ->
            val result = JwtToken.fromString(token)
            assertTrue("Token $token should be valid", result.isSuccess)
        }
    }

    @Test
    fun `isValid returns false for blank string`() {
        assertFalse(JwtToken.isValid(""))
        assertFalse(JwtToken.isValid("   "))
    }

    @Test
    fun `isValid returns true for valid JWT`() {
        val validJwt = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"

        assertTrue(JwtToken.isValid(validJwt))
    }
}
