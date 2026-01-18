package com.pergamino.feature.emailverification

import app.cash.turbine.test
import com.pergamino.data.repository.EmailVerificationRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.mockito.kotlin.any
import org.mockito.kotlin.mock
import org.mockito.kotlin.whenever

@OptIn(ExperimentalCoroutinesApi::class)
class EmailVerificationViewModelTest {

    private val testDispatcher = StandardTestDispatcher()
    private lateinit var repository: EmailVerificationRepository
    private lateinit var viewModel: EmailVerificationViewModel

    @Before
    fun setup() {
        Dispatchers.setMain(testDispatcher)
        repository = mock()
        viewModel = EmailVerificationViewModel(repository)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `initial state is Idle`() = runTest {
        viewModel.uiState.test {
            assertEquals(EmailVerificationUiState.Idle, awaitItem())
        }
    }

    @Test
    fun `initial email is empty`() = runTest {
        viewModel.email.test {
            assertEquals("", awaitItem())
        }
    }

    @Test
    fun `onEmailChange updates email value`() = runTest {
        viewModel.email.test {
            assertEquals("", awaitItem())
            viewModel.onEmailChange("test@example.com")
            assertEquals("test@example.com", awaitItem())
        }
    }

    @Test
    fun `onEmailChange clears email error`() = runTest {
        viewModel.requestVerificationEmail()
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.emailError.test {
            assertEquals("Please enter a valid email address", awaitItem())
            viewModel.onEmailChange("t")
            assertNull(awaitItem())
        }
    }

    @Test
    fun `requestVerificationEmail with empty email sets error`() = runTest {
        viewModel.requestVerificationEmail()
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.emailError.test {
            assertEquals("Please enter a valid email address", awaitItem())
        }
    }

    @Test
    fun `requestVerificationEmail with invalid email sets error`() = runTest {
        viewModel.onEmailChange("invalid-email")
        viewModel.requestVerificationEmail()
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.emailError.test {
            assertEquals("Please enter a valid email address", awaitItem())
        }
    }

    @Test
    fun `requestVerificationEmail with valid email transitions through Loading to Success`() = runTest {
        whenever(repository.requestVerificationEmail(any())).thenReturn(Result.success(Unit))
        viewModel.onEmailChange("test@example.com")

        viewModel.uiState.test {
            assertEquals(EmailVerificationUiState.Idle, awaitItem())

            viewModel.requestVerificationEmail()

            assertEquals(EmailVerificationUiState.Loading, awaitItem())

            testDispatcher.scheduler.advanceUntilIdle()

            assertEquals(EmailVerificationUiState.Success, awaitItem())
        }
    }

    @Test
    fun `resetState returns to Idle`() = runTest {
        whenever(repository.requestVerificationEmail(any())).thenReturn(Result.success(Unit))
        viewModel.onEmailChange("test@example.com")
        viewModel.requestVerificationEmail()
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.uiState.test {
            assertEquals(EmailVerificationUiState.Success, awaitItem())

            viewModel.resetState()

            assertEquals(EmailVerificationUiState.Idle, awaitItem())
        }
    }

    @Test
    fun `onEmailChange on Idle state does not emit new state`() = runTest {
        viewModel.uiState.test {
            assertEquals(EmailVerificationUiState.Idle, awaitItem())

            viewModel.onEmailChange("test@example.com")

            expectNoEvents()
        }
    }

    @Test
    fun `email is trimmed before validation`() = runTest {
        whenever(repository.requestVerificationEmail(any())).thenReturn(Result.success(Unit))
        viewModel.onEmailChange("  test@example.com  ")

        viewModel.uiState.test {
            assertEquals(EmailVerificationUiState.Idle, awaitItem())

            viewModel.requestVerificationEmail()
            assertEquals(EmailVerificationUiState.Loading, awaitItem())

            testDispatcher.scheduler.advanceUntilIdle()
            assertEquals(EmailVerificationUiState.Success, awaitItem())
        }
    }

    @Test
    fun `requestVerificationEmail transitions to Error on repository failure`() = runTest {
        whenever(repository.requestVerificationEmail(any()))
            .thenReturn(Result.failure(Exception("Network error")))
        viewModel.onEmailChange("test@example.com")

        viewModel.uiState.test {
            assertEquals(EmailVerificationUiState.Idle, awaitItem())

            viewModel.requestVerificationEmail()

            assertEquals(EmailVerificationUiState.Loading, awaitItem())

            testDispatcher.scheduler.advanceUntilIdle()

            val errorState = awaitItem()
            assertTrue(errorState is EmailVerificationUiState.Error)
            assertEquals("Network error", (errorState as EmailVerificationUiState.Error).message)
        }
    }
}
