package com.pergamino.feature.auth.domain.usecase

import com.pergamino.core.common.Result
import com.pergamino.feature.auth.domain.model.AuthError
import com.pergamino.feature.auth.domain.model.AuthState
import com.pergamino.feature.auth.domain.model.VerificationToken
import com.pergamino.feature.auth.domain.repository.AuthRepository
import javax.inject.Inject

/**
 * Use case for verifying the email verification token.
 *
 * This use case validates the token and completes the authentication process.
 * Called when the user clicks the verification link in their email.
 */
class VerifyEmailTokenUseCase @Inject constructor(
    private val authRepository: AuthRepository
) {
    /**
     * Validates the token and completes authentication.
     *
     * @param tokenString The raw token string from the deep link
     * @return [Result.Success] with authenticated state if successful, [Result.Failure] with error otherwise
     */
    suspend operator fun invoke(tokenString: String): Result<AuthState.Authenticated, AuthError> {
        return VerificationToken.create(tokenString)
            .mapError { validationError -> AuthError.InvalidToken(validationError) }
            .flatMap { token -> authRepository.verifyToken(token) }
    }
}
