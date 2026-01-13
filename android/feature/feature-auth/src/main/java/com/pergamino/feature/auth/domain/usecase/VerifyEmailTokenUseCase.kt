package com.pergamino.feature.auth.domain.usecase

import com.pergamino.core.common.Result
import com.pergamino.feature.auth.domain.model.AuthError
import com.pergamino.feature.auth.domain.model.AuthState
import com.pergamino.feature.auth.domain.model.VerificationToken
import com.pergamino.feature.auth.domain.model.TokenValidationError
import com.pergamino.feature.auth.domain.repository.AuthRepository
import javax.inject.Inject

class VerifyEmailTokenUseCase @Inject constructor(
    private val authRepository: AuthRepository
) {
    suspend operator fun invoke(tokenString: String): Result<AuthState.Authenticated, AuthError> {
        return VerificationToken.create(tokenString)
            .mapError(::toAuthError)
            .flatMap { token -> authRepository.verifyToken(token) }
    }

    private fun toAuthError(validationError: TokenValidationError): AuthError {
        return AuthError.InvalidToken(validationError)
    }
}
