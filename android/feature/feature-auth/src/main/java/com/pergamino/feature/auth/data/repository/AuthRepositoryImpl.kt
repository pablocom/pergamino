package com.pergamino.feature.auth.data.repository

import com.pergamino.core.common.IoDispatcher
import com.pergamino.core.common.Result
import com.pergamino.feature.auth.data.datasource.AuthLocalDataSource
import com.pergamino.feature.auth.data.datasource.AuthRemoteDataSource
import com.pergamino.feature.auth.data.datasource.PersistedAuthState
import com.pergamino.feature.auth.domain.model.AuthError
import com.pergamino.feature.auth.domain.model.AuthState
import com.pergamino.feature.auth.domain.model.Email
import com.pergamino.feature.auth.domain.model.User
import com.pergamino.feature.auth.domain.model.VerificationToken
import com.pergamino.feature.auth.domain.repository.AuthRepository
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.withContext
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Implementation of [AuthRepository] that coordinates remote and local data sources.
 *
 * This repository:
 * - Uses the remote data source for API calls
 * - Persists state changes to local storage
 * - Exposes a reactive auth state flow
 * - Executes IO operations on the IO dispatcher
 */
@Singleton
class AuthRepositoryImpl @Inject constructor(
    private val remoteDataSource: AuthRemoteDataSource,
    private val localDataSource: AuthLocalDataSource,
    @IoDispatcher private val ioDispatcher: CoroutineDispatcher
) : AuthRepository {

    override val authState: Flow<AuthState> = localDataSource.authStateData
        .map { persisted -> persisted.toDomain() }
        .flowOn(ioDispatcher)

    override suspend fun requestEmailVerification(
        email: Email
    ): Result<AuthState.VerificationPending, AuthError> = withContext(ioDispatcher) {
        remoteDataSource.requestVerification(email.value)
            .map { response ->
                // Save pending state locally
                localDataSource.saveVerificationPending(
                    email = email.value,
                    expiresAt = response.expiresAt
                )

                AuthState.VerificationPending(
                    email = email,
                    expiresAt = response.expiresAt
                )
            }
    }

    override suspend fun verifyToken(
        token: VerificationToken
    ): Result<AuthState.Authenticated, AuthError> = withContext(ioDispatcher) {
        remoteDataSource.verifyToken(token.value)
            .flatMap { response ->
                // Create the Email value object for the User
                Email.create(response.email)
                    .mapError { AuthError.ServerError("Invalid email in response") }
                    .map { email ->
                        // Save authenticated state locally
                        localDataSource.saveAuthenticated(
                            userId = response.userId,
                            email = response.email,
                            accessToken = response.accessToken,
                            createdAt = response.createdAt
                        )

                        val user = User(
                            id = response.userId,
                            email = email,
                            createdAt = response.createdAt
                        )

                        AuthState.Authenticated(
                            user = user,
                            accessToken = response.accessToken
                        )
                    }
            }
    }

    override suspend fun resendVerificationEmail(): Result<Unit, AuthError> = withContext(ioDispatcher) {
        val pendingEmail = localDataSource.getPendingEmail()
            ?: return@withContext Result.failure(AuthError.ServerError("No pending verification"))

        remoteDataSource.requestVerification(pendingEmail)
            .map { response ->
                // Update the expiry time
                localDataSource.saveVerificationPending(
                    email = pendingEmail,
                    expiresAt = response.expiresAt
                )
            }
    }

    override suspend fun logout(): Result<Unit, AuthError> = withContext(ioDispatcher) {
        localDataSource.clear()
        Result.success(Unit)
    }

    /**
     * Maps persisted auth state to domain auth state.
     */
    private fun PersistedAuthState?.toDomain(): AuthState {
        return when (this) {
            null -> AuthState.Unauthenticated

            is PersistedAuthState.VerificationPending -> {
                // Create Email value object - if it fails, return unauthenticated
                val emailResult = Email.create(email)
                when (emailResult) {
                    is Result.Success -> AuthState.VerificationPending(
                        email = emailResult.value,
                        expiresAt = expiresAt
                    )
                    is Result.Failure -> AuthState.Unauthenticated
                }
            }

            is PersistedAuthState.Authenticated -> {
                // Create Email value object - if it fails, return unauthenticated
                val emailResult = Email.create(email)
                when (emailResult) {
                    is Result.Success -> {
                        val user = User(
                            id = userId,
                            email = emailResult.value,
                            createdAt = createdAt
                        )
                        AuthState.Authenticated(
                            user = user,
                            accessToken = accessToken
                        )
                    }
                    is Result.Failure -> AuthState.Unauthenticated
                }
            }
        }
    }
}
