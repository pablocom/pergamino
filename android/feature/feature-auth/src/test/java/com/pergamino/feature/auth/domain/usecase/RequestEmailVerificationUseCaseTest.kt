package com.pergamino.feature.auth.domain.usecase

import com.google.common.truth.Truth.assertThat
import com.pergamino.core.common.Result
import com.pergamino.feature.auth.domain.model.AuthError
import com.pergamino.feature.auth.domain.model.AuthState
import com.pergamino.feature.auth.domain.model.Email
import com.pergamino.feature.auth.domain.repository.AuthRepository
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import kotlinx.coroutines.test.runTest
import org.junit.Before
import org.junit.Test
import java.time.Instant

/**
 * Unit tests for [RequestEmailVerificationUseCase].
 *
 * Demonstrates testing use cases with mocked repositories.
 */
class RequestEmailVerificationUseCaseTest {

    private lateinit var mockRepository: AuthRepository
    private lateinit var useCase: RequestEmailVerificationUseCase

    @Before
    fun setup() {
        mockRepository = mockk()
        useCase = RequestEmailVerificationUseCase(mockRepository)
    }

    @Test
    fun `invoke returns InvalidEmail error for invalid email format`() = runTest {
        // Given
        val invalidEmail = "invalid-email"

        // When
        val result = useCase(invalidEmail)

        // Then
        assertThat(result).isInstanceOf(Result.Failure::class.java)
        val error = (result as Result.Failure).error
        assertThat(error).isInstanceOf(AuthError.InvalidEmail::class.java)

        // Verify repository was never called
        coVerify(exactly = 0) { mockRepository.requestEmailVerification(any()) }
    }

    @Test
    fun `invoke returns InvalidEmail error for empty email`() = runTest {
        // Given
        val emptyEmail = ""

        // When
        val result = useCase(emptyEmail)

        // Then
        assertThat(result).isInstanceOf(Result.Failure::class.java)
        val error = (result as Result.Failure).error
        assertThat(error).isInstanceOf(AuthError.InvalidEmail::class.java)

        // Verify repository was never called
        coVerify(exactly = 0) { mockRepository.requestEmailVerification(any()) }
    }

    @Test
    fun `invoke calls repository with valid email`() = runTest {
        // Given
        val validEmail = "test@example.com"
        val email = Email.create(validEmail).getOrThrow()
        val expectedState = AuthState.VerificationPending(
            email = email,
            expiresAt = Instant.now().plusSeconds(300)
        )

        coEvery {
            mockRepository.requestEmailVerification(any())
        } returns Result.success(expectedState)

        // When
        val result = useCase(validEmail)

        // Then
        assertThat(result).isInstanceOf(Result.Success::class.java)
        assertThat((result as Result.Success).value).isEqualTo(expectedState)

        // Verify repository was called with correct email
        coVerify(exactly = 1) {
            mockRepository.requestEmailVerification(match { it.value == "test@example.com" })
        }
    }

    @Test
    fun `invoke returns error when repository fails`() = runTest {
        // Given
        val validEmail = "test@example.com"
        val networkError = AuthError.NetworkError("Connection failed")

        coEvery {
            mockRepository.requestEmailVerification(any())
        } returns Result.failure(networkError)

        // When
        val result = useCase(validEmail)

        // Then
        assertThat(result).isInstanceOf(Result.Failure::class.java)
        assertThat((result as Result.Failure).error).isEqualTo(networkError)
    }

    @Test
    fun `invoke normalizes email before calling repository`() = runTest {
        // Given
        val mixedCaseEmail = "Test@Example.COM"
        val expectedState = AuthState.VerificationPending(
            email = Email.create(mixedCaseEmail).getOrThrow(),
            expiresAt = Instant.now().plusSeconds(300)
        )

        coEvery {
            mockRepository.requestEmailVerification(any())
        } returns Result.success(expectedState)

        // When
        val result = useCase(mixedCaseEmail)

        // Then
        assertThat(result).isInstanceOf(Result.Success::class.java)

        // Verify repository was called with normalized (lowercase) email
        coVerify(exactly = 1) {
            mockRepository.requestEmailVerification(match { it.value == "test@example.com" })
        }
    }
}
