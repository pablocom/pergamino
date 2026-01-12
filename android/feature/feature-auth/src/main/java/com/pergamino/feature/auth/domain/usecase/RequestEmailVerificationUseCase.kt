package com.pergamino.feature.auth.domain.usecase

import com.pergamino.core.common.Result
import com.pergamino.feature.auth.domain.model.AuthError
import com.pergamino.feature.auth.domain.model.AuthState
import com.pergamino.feature.auth.domain.model.Email
import com.pergamino.feature.auth.domain.repository.AuthRepository
import javax.inject.Inject

/**
 * Use case for requesting email verification.
 *
 * This use case validates the email input and initiates the verification process.
 * Following Single Responsibility Principle, it handles only the email verification request.
 */
class RequestEmailVerificationUseCase @Inject constructor(
    private val authRepository: AuthRepository
) {
    /**
     * Validates the email and requests verification to be sent.
     *
     * @param emailString The raw email string from user input
     * @return [Result.Success] with pending state if successful, [Result.Failure] with error otherwise
     */
    suspend operator fun invoke(emailString: String): Result<AuthState.VerificationPending, AuthError> {
        return Email.create(emailString)
            .mapError { validationError -> AuthError.InvalidEmail(validationError) }
            .flatMap { email -> authRepository.requestEmailVerification(email) }
    }
}
