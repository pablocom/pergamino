package com.pergamino.feature.auth.domain.usecase

import com.pergamino.core.common.Result
import com.pergamino.feature.auth.domain.model.AuthError
import com.pergamino.feature.auth.domain.repository.AuthRepository
import javax.inject.Inject

/**
 * Use case for resending the verification email.
 *
 * This use case allows users to request a new verification email
 * if the original one was not received or has expired.
 */
class ResendVerificationEmailUseCase @Inject constructor(
    private val authRepository: AuthRepository
) {
    /**
     * Resends the verification email to the pending email address.
     *
     * @return [Result.Success] if email was sent, [Result.Failure] with error otherwise
     */
    suspend operator fun invoke(): Result<Unit, AuthError> {
        return authRepository.resendVerificationEmail()
    }
}
