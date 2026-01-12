package com.pergamino.feature.auth.presentation.email

import app.cash.turbine.test
import com.google.common.truth.Truth.assertThat
import com.pergamino.core.common.Result
import com.pergamino.feature.auth.domain.model.AuthError
import com.pergamino.feature.auth.domain.model.AuthState
import com.pergamino.feature.auth.domain.model.Email
import com.pergamino.feature.auth.domain.model.EmailValidationError
import com.pergamino.feature.auth.domain.usecase.RequestEmailVerificationUseCase
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Before
import org.junit.Test
import java.time.Instant

/**
 * Unit tests for [EmailEntryViewModel].
 *
 * Demonstrates testing ViewModels with coroutines and flow collection.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class EmailEntryViewModelTest {

    private lateinit var mockRequestEmailVerificationUseCase: RequestEmailVerificationUseCase
    private lateinit var viewModel: EmailEntryViewModel

    private val testDispatcher = StandardTestDispatcher()

    @Before
    fun setup() {
        Dispatchers.setMain(testDispatcher)
        mockRequestEmailVerificationUseCase = mockk()
        viewModel = EmailEntryViewModel(mockRequestEmailVerificationUseCase)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `initial state has empty email and no errors`() {
        // Then
        val state = viewModel.uiState.value
        assertThat(state.email).isEmpty()
        assertThat(state.emailValidationError).isNull()
        assertThat(state.isLoading).isFalse()
        assertThat(state.error).isNull()
    }

    @Test
    fun `onEmailChanged updates email in state`() {
        // When
        viewModel.onEmailChanged("test@example.com")

        // Then
        assertThat(viewModel.uiState.value.email).isEqualTo("test@example.com")
        assertThat(viewModel.uiState.value.emailValidationError).isNull()
    }

    @Test
    fun `onEmailChanged with invalid email shows validation error`() {
        // When
        viewModel.onEmailChanged("invalid-email")

        // Then
        assertThat(viewModel.uiState.value.email).isEqualTo("invalid-email")
        assertThat(viewModel.uiState.value.emailValidationError).isEqualTo(EmailValidationError.InvalidFormat)
    }

    @Test
    fun `onEmailChanged with valid email clears validation error`() {
        // Given - start with invalid email
        viewModel.onEmailChanged("invalid")
        assertThat(viewModel.uiState.value.emailValidationError).isNotNull()

        // When - change to valid email
        viewModel.onEmailChanged("test@example.com")

        // Then
        assertThat(viewModel.uiState.value.emailValidationError).isNull()
    }

    @Test
    fun `onEmailChanged clears previous submission errors`() {
        // Given - simulate a submission error
        val error = AuthError.NetworkError()
        coEvery { mockRequestEmailVerificationUseCase(any()) } returns Result.failure(error)
        viewModel.onEmailChanged("test@example.com")
        viewModel.onContinueClicked()
        advanceUntilIdle()
        assertThat(viewModel.uiState.value.error).isNotNull()

        // When - user changes email
        viewModel.onEmailChanged("new@example.com")

        // Then - error is cleared
        assertThat(viewModel.uiState.value.error).isNull()
    }

    @Test
    fun `onContinueClicked with invalid email does not call use case`() = runTest {
        // Given
        viewModel.onEmailChanged("invalid-email")

        // When
        viewModel.onContinueClicked()
        advanceUntilIdle()

        // Then
        coVerify(exactly = 0) { mockRequestEmailVerificationUseCase(any()) }
        assertThat(viewModel.uiState.value.emailValidationError).isNotNull()
    }

    @Test
    fun `onContinueClicked with valid email calls use case and emits navigation event`() = runTest {
        // Given
        val email = "test@example.com"
        val expectedState = AuthState.VerificationPending(
            email = Email.create(email).getOrThrow(),
            expiresAt = Instant.now().plusSeconds(300)
        )

        coEvery {
            mockRequestEmailVerificationUseCase(email)
        } returns Result.success(expectedState)

        viewModel.onEmailChanged(email)

        // When
        viewModel.events.test {
            viewModel.onContinueClicked()
            advanceUntilIdle()

            // Then
            val event = awaitItem()
            assertThat(event).isInstanceOf(EmailEntryEvent.NavigateToVerificationPending::class.java)
            assertThat((event as EmailEntryEvent.NavigateToVerificationPending).email).isEqualTo(email)

            coVerify(exactly = 1) { mockRequestEmailVerificationUseCase(email) }
        }
    }

    @Test
    fun `onContinueClicked shows loading state during execution`() = runTest {
        // Given
        val email = "test@example.com"
        coEvery {
            mockRequestEmailVerificationUseCase(email)
        } coAnswers {
            // Simulate slow network
            kotlinx.coroutines.delay(100)
            Result.success(
                AuthState.VerificationPending(
                    email = Email.create(email).getOrThrow(),
                    expiresAt = Instant.now().plusSeconds(300)
                )
            )
        }

        viewModel.onEmailChanged(email)

        // When
        viewModel.onContinueClicked()

        // Then - should be loading immediately
        assertThat(viewModel.uiState.value.isLoading).isTrue()

        advanceUntilIdle()

        // Then - should not be loading after completion
        assertThat(viewModel.uiState.value.isLoading).isFalse()
    }

    @Test
    fun `onContinueClicked with error updates state and emits error event`() = runTest {
        // Given
        val email = "test@example.com"
        val networkError = AuthError.NetworkError("Connection failed")

        coEvery {
            mockRequestEmailVerificationUseCase(email)
        } returns Result.failure(networkError)

        viewModel.onEmailChanged(email)

        // When
        viewModel.events.test {
            viewModel.onContinueClicked()
            advanceUntilIdle()

            // Then
            val event = awaitItem()
            assertThat(event).isInstanceOf(EmailEntryEvent.ShowError::class.java)
            assertThat((event as EmailEntryEvent.ShowError).error).isEqualTo(networkError)

            assertThat(viewModel.uiState.value.error).isEqualTo(networkError)
            assertThat(viewModel.uiState.value.isLoading).isFalse()
        }
    }

    @Test
    fun `canSubmit is true only when email is valid and not loading`() {
        // Initially false (empty email)
        assertThat(viewModel.uiState.value.canSubmit).isFalse()

        // False with invalid email
        viewModel.onEmailChanged("invalid")
        assertThat(viewModel.uiState.value.canSubmit).isFalse()

        // True with valid email
        viewModel.onEmailChanged("test@example.com")
        assertThat(viewModel.uiState.value.canSubmit).isTrue()
    }

    @Test
    fun `onErrorDismissed clears error from state`() {
        // Given - set an error
        val error = AuthError.NetworkError()
        coEvery { mockRequestEmailVerificationUseCase(any()) } returns Result.failure(error)
        viewModel.onEmailChanged("test@example.com")
        viewModel.onContinueClicked()
        advanceUntilIdle()
        assertThat(viewModel.uiState.value.error).isNotNull()

        // When
        viewModel.onErrorDismissed()

        // Then
        assertThat(viewModel.uiState.value.error).isNull()
    }
}
