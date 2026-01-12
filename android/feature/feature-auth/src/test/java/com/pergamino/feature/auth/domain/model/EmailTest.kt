package com.pergamino.feature.auth.domain.model

import com.google.common.truth.Truth.assertThat
import com.pergamino.core.common.Result
import org.junit.Test

/**
 * Unit tests for [Email] value object.
 *
 * Tests validation logic to ensure emails are correctly validated.
 */
class EmailTest {

    @Test
    fun `create returns success for valid email`() {
        // Given
        val validEmail = "user@example.com"

        // When
        val result = Email.create(validEmail)

        // Then
        assertThat(result).isInstanceOf(Result.Success::class.java)
        assertThat((result as Result.Success).value.value).isEqualTo("user@example.com")
    }

    @Test
    fun `create returns failure for empty email`() {
        // Given
        val emptyEmail = ""

        // When
        val result = Email.create(emptyEmail)

        // Then
        assertThat(result).isInstanceOf(Result.Failure::class.java)
        assertThat((result as Result.Failure).error).isEqualTo(EmailValidationError.Empty)
    }

    @Test
    fun `create returns failure for blank email`() {
        // Given
        val blankEmail = "   "

        // When
        val result = Email.create(blankEmail)

        // Then
        assertThat(result).isInstanceOf(Result.Failure::class.java)
        assertThat((result as Result.Failure).error).isEqualTo(EmailValidationError.Empty)
    }

    @Test
    fun `create returns failure for invalid email format - missing @`() {
        // Given
        val invalidEmail = "userexample.com"

        // When
        val result = Email.create(invalidEmail)

        // Then
        assertThat(result).isInstanceOf(Result.Failure::class.java)
        assertThat((result as Result.Failure).error).isEqualTo(EmailValidationError.InvalidFormat)
    }

    @Test
    fun `create returns failure for invalid email format - missing domain`() {
        // Given
        val invalidEmail = "user@"

        // When
        val result = Email.create(invalidEmail)

        // Then
        assertThat(result).isInstanceOf(Result.Failure::class.java)
        assertThat((result as Result.Failure).error).isEqualTo(EmailValidationError.InvalidFormat)
    }

    @Test
    fun `create returns failure for invalid email format - missing local part`() {
        // Given
        val invalidEmail = "@example.com"

        // When
        val result = Email.create(invalidEmail)

        // Then
        assertThat(result).isInstanceOf(Result.Failure::class.java)
        assertThat((result as Result.Failure).error).isEqualTo(EmailValidationError.InvalidFormat)
    }

    @Test
    fun `create normalizes email to lowercase`() {
        // Given
        val mixedCaseEmail = "User@Example.COM"

        // When
        val result = Email.create(mixedCaseEmail)

        // Then
        assertThat(result).isInstanceOf(Result.Success::class.java)
        assertThat((result as Result.Success).value.value).isEqualTo("user@example.com")
    }

    @Test
    fun `create trims whitespace from email`() {
        // Given
        val emailWithWhitespace = "  user@example.com  "

        // When
        val result = Email.create(emailWithWhitespace)

        // Then
        assertThat(result).isInstanceOf(Result.Success::class.java)
        assertThat((result as Result.Success).value.value).isEqualTo("user@example.com")
    }

    @Test
    fun `create accepts email with plus sign`() {
        // Given
        val emailWithPlus = "user+tag@example.com"

        // When
        val result = Email.create(emailWithPlus)

        // Then
        assertThat(result).isInstanceOf(Result.Success::class.java)
        assertThat((result as Result.Success).value.value).isEqualTo("user+tag@example.com")
    }

    @Test
    fun `create accepts email with dots`() {
        // Given
        val emailWithDots = "first.last@example.com"

        // When
        val result = Email.create(emailWithDots)

        // Then
        assertThat(result).isInstanceOf(Result.Success::class.java)
        assertThat((result as Result.Success).value.value).isEqualTo("first.last@example.com")
    }

    @Test
    fun `create accepts email with subdomain`() {
        // Given
        val emailWithSubdomain = "user@mail.example.com"

        // When
        val result = Email.create(emailWithSubdomain)

        // Then
        assertThat(result).isInstanceOf(Result.Success::class.java)
        assertThat((result as Result.Success).value.value).isEqualTo("user@mail.example.com")
    }
}
