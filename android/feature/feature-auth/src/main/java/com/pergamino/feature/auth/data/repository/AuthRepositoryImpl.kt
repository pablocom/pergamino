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

@Singleton
class AuthRepositoryImpl @Inject constructor(
    private val remoteDataSource: AuthRemoteDataSource,
    private val localDataSource: AuthLocalDataSource,
    @param:IoDispatcher private val ioDispatcher: CoroutineDispatcher
) : AuthRepository {

    override val authState: Flow<AuthState> = localDataSource.authStateData
        .map { persisted -> persisted.toDomain() }
        .flowOn(ioDispatcher)

    override suspend fun requestEmailVerification(
        email: Email
    ): Result<AuthState.VerificationPending, AuthError> = withContext(ioDispatcher) {
        remoteDataSource.requestVerification(email.value)
            .map { response ->
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
                Email.create(response.email)
                    .mapError { AuthError.ServerError("Invalid email in response") }
                    .map { email ->
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

    private fun PersistedAuthState?.toDomain(): AuthState {
        return when (this) {
            null -> AuthState.Unauthenticated

            is PersistedAuthState.VerificationPending -> {
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
