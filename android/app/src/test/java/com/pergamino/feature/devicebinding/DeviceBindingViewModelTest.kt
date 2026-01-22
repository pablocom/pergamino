package com.pergamino.feature.devicebinding

import app.cash.turbine.test
import com.pergamino.data.repository.DeviceBindingRepository
import com.pergamino.data.repository.DeviceBindingResult
import com.pergamino.domain.model.DeviceId
import com.pergamino.domain.model.JwtToken
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.mockito.kotlin.any
import org.mockito.kotlin.mock
import org.mockito.kotlin.never
import org.mockito.kotlin.verify
import org.mockito.kotlin.whenever
import retrofit2.HttpException
import retrofit2.Response
import java.io.IOException

@OptIn(ExperimentalCoroutinesApi::class)
class DeviceBindingViewModelTest {

    private val testDispatcher = StandardTestDispatcher()
    private lateinit var repository: DeviceBindingRepository
    private lateinit var viewModel: DeviceBindingViewModel

    @Before
    fun setup() {
        Dispatchers.setMain(testDispatcher)
        repository = mock()
        viewModel = DeviceBindingViewModel(repository)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `initial state is Idle`() = runTest {
        viewModel.uiState.test {
            assertEquals(DeviceBindingUiState.Idle, awaitItem())
        }
    }

    @Test
    fun `resetState returns to Idle`() = runTest {
        val email = "test@example.com"
        val deviceId = DeviceId.random()
        val result = DeviceBindingResult(deviceId, email)
        whenever(repository.verifyBinding(any())).thenReturn(Result.success(result))

        viewModel.uiState.test {
            assertEquals(DeviceBindingUiState.Idle, awaitItem())

            viewModel.verifyBindingToken("valid.jwt.token")
            assertEquals(DeviceBindingUiState.Verifying, awaitItem())
            skipItems(1)

            viewModel.resetState()
            assertEquals(DeviceBindingUiState.Idle, awaitItem())
        }
    }

    @Test
    fun `verifyBindingToken with invalid format sets Error state`() = runTest {
        val invalidToken = "invalid-token-format"

        viewModel.uiState.test {
            assertEquals(DeviceBindingUiState.Idle, awaitItem())

            viewModel.verifyBindingToken(invalidToken)
            assertEquals(DeviceBindingUiState.Verifying, awaitItem())

            val errorState = awaitItem() as DeviceBindingUiState.Error
            assertEquals("Invalid verification link", errorState.message)
        }
    }

    @Test
    fun `verifyBindingToken with empty token sets Error state`() = runTest {
        viewModel.uiState.test {
            assertEquals(DeviceBindingUiState.Idle, awaitItem())

            viewModel.verifyBindingToken("")
            assertEquals(DeviceBindingUiState.Verifying, awaitItem())

            val errorState = awaitItem() as DeviceBindingUiState.Error
            assertEquals("Invalid verification link", errorState.message)
        }
    }

    @Test
    fun `verifyBindingToken with malformed JWT sets Error state`() = runTest {
        val malformedJwt = "only.two.parts.are.wrong"

        viewModel.uiState.test {
            assertEquals(DeviceBindingUiState.Idle, awaitItem())

            viewModel.verifyBindingToken(malformedJwt)
            assertEquals(DeviceBindingUiState.Verifying, awaitItem())

            val errorState = awaitItem() as DeviceBindingUiState.Error
            assertEquals("Invalid verification link", errorState.message)
        }
    }

    @Test
    fun `verifyBindingToken with valid token transitions Idle to Verifying to Success`() = runTest {
        val validToken = "valid.jwt.token"
        val email = "test@example.com"
        val deviceId = DeviceId.random()
        val result = DeviceBindingResult(deviceId, email)

        whenever(repository.verifyBinding(any())).thenReturn(Result.success(result))

        viewModel.uiState.test {
            assertEquals(DeviceBindingUiState.Idle, awaitItem())

            viewModel.verifyBindingToken(validToken)
            assertEquals(DeviceBindingUiState.Verifying, awaitItem())

            val successState = awaitItem() as DeviceBindingUiState.Success
            assertEquals(email, successState.email)
        }
    }

    @Test
    fun `verifyBindingToken success state contains email from repository`() = runTest {
        val validToken = "valid.jwt.token"
        val expectedEmail = "user@example.com"
        val deviceId = DeviceId.random()
        val result = DeviceBindingResult(deviceId, expectedEmail)

        whenever(repository.verifyBinding(any())).thenReturn(Result.success(result))

        viewModel.uiState.test {
            skipItems(1)

            viewModel.verifyBindingToken(validToken)
            skipItems(1)

            val successState = awaitItem() as DeviceBindingUiState.Success
            assertEquals(expectedEmail, successState.email)
        }
    }

    @Test
    fun `verifyBindingToken with HttpException 401 shows expired token message`() = runTest {
        val validToken = "valid.jwt.token"
        val httpException = HttpException(Response.error<Any>(401, okhttp3.ResponseBody.create(null, "")))

        whenever(repository.verifyBinding(any())).thenReturn(Result.failure(httpException))

        viewModel.uiState.test {
            skipItems(1)

            viewModel.verifyBindingToken(validToken)
            skipItems(1)

            val errorState = awaitItem() as DeviceBindingUiState.Error
            assertEquals("Link expired. Please request a new verification email.", errorState.message)
        }
    }

    @Test
    fun `verifyBindingToken with HttpException 500 shows server error message`() = runTest {
        val validToken = "valid.jwt.token"
        val httpException = HttpException(Response.error<Any>(500, okhttp3.ResponseBody.create(null, "")))

        whenever(repository.verifyBinding(any())).thenReturn(Result.failure(httpException))

        viewModel.uiState.test {
            skipItems(1)

            viewModel.verifyBindingToken(validToken)
            skipItems(1)

            val errorState = awaitItem() as DeviceBindingUiState.Error
            assertEquals("Server error. Please try again later.", errorState.message)
        }
    }

    @Test
    fun `verifyBindingToken with IOException shows connection error message`() = runTest {
        val validToken = "valid.jwt.token"
        val ioException = IOException("Network error")

        whenever(repository.verifyBinding(any())).thenReturn(Result.failure(ioException))

        viewModel.uiState.test {
            skipItems(1)

            viewModel.verifyBindingToken(validToken)
            skipItems(1)

            val errorState = awaitItem() as DeviceBindingUiState.Error
            assertEquals("Connection failed. Please check your internet and try again.", errorState.message)
        }
    }

    @Test
    fun `verifyBindingToken with IllegalStateException shows device security error message`() = runTest {
        val validToken = "valid.jwt.token"
        val illegalStateException = IllegalStateException("Key generation failed")

        whenever(repository.verifyBinding(any())).thenReturn(Result.failure(illegalStateException))

        viewModel.uiState.test {
            skipItems(1)

            viewModel.verifyBindingToken(validToken)
            skipItems(1)

            val errorState = awaitItem() as DeviceBindingUiState.Error
            assertEquals("Device security error. Please restart the app.", errorState.message)
        }
    }

    @Test
    fun `verifyBindingToken with generic exception shows unexpected error message`() = runTest {
        val validToken = "valid.jwt.token"
        val genericException = RuntimeException("Unknown error")

        whenever(repository.verifyBinding(any())).thenReturn(Result.failure(genericException))

        viewModel.uiState.test {
            skipItems(1)

            viewModel.verifyBindingToken(validToken)
            skipItems(1)

            val errorState = awaitItem() as DeviceBindingUiState.Error
            assertEquals("An unexpected error occurred. Please try again.", errorState.message)
        }
    }

    @Test
    fun `verifyBindingToken calls repository with correct token`() = runTest {
        val tokenString = "valid.jwt.token"
        val email = "test@example.com"
        val deviceId = DeviceId.random()
        val result = DeviceBindingResult(deviceId, email)

        whenever(repository.verifyBinding(any())).thenReturn(Result.success(result))

        viewModel.verifyBindingToken(tokenString)
        testDispatcher.scheduler.advanceUntilIdle()

        val expectedToken = JwtToken.fromString(tokenString).getOrThrow()
        verify(repository).verifyBinding(expectedToken)
    }

    @Test
    fun `verifyBindingToken does not call repository with invalid token`() = runTest {
        val invalidToken = "invalid-format"

        viewModel.verifyBindingToken(invalidToken)
        testDispatcher.scheduler.advanceUntilIdle()

        verify(repository, never()).verifyBinding(any())
    }

    @Test
    fun `uiState does not emit duplicate states unnecessarily`() = runTest {
        val validToken = "valid.jwt.token"
        val email = "test@example.com"
        val deviceId = DeviceId.random()
        val result = DeviceBindingResult(deviceId, email)

        whenever(repository.verifyBinding(any())).thenReturn(Result.success(result))

        viewModel.uiState.test {
            assertEquals(DeviceBindingUiState.Idle, awaitItem())

            viewModel.verifyBindingToken(validToken)
            assertEquals(DeviceBindingUiState.Verifying, awaitItem())

            val successState = awaitItem() as DeviceBindingUiState.Success
            assertEquals(email, successState.email)

            expectNoEvents()
        }
    }

    @Test
    fun `verifyBindingToken with HttpException 400 shows generic verification failed message`() = runTest {
        val validToken = "valid.jwt.token"
        val httpException = HttpException(Response.error<Any>(400, okhttp3.ResponseBody.create(null, "")))

        whenever(repository.verifyBinding(any())).thenReturn(Result.failure(httpException))

        viewModel.uiState.test {
            skipItems(1)

            viewModel.verifyBindingToken(validToken)
            skipItems(1)

            val errorState = awaitItem() as DeviceBindingUiState.Error
            assertEquals("Verification failed. Please try again.", errorState.message)
        }
    }
}
