package com.pergamino.feature.auth.domain.repository

import com.pergamino.core.common.Result
import com.pergamino.feature.auth.domain.model.AuthError
import com.pergamino.feature.auth.domain.model.AuthState
import com.pergamino.feature.auth.domain.model.Email
import com.pergamino.feature.auth.domain.model.VerificationToken
import kotlinx.coroutines.flow.Flow

interface AuthRepository {

    val authState: Flow<AuthState>

    suspend fun requestEmailVerification(email: Email): Result<AuthState.VerificationPending, AuthError>
    suspend fun verifyToken(token: VerificationToken): Result<AuthState.Authenticated, AuthError>
    suspend fun resendVerificationEmail(): Result<Unit, AuthError>
    suspend fun logout(): Result<Unit, AuthError>
}
