package com.pergamino.feature.auth.domain.usecase

import com.pergamino.core.common.Result
import com.pergamino.feature.auth.domain.model.AuthError
import com.pergamino.feature.auth.domain.repository.AuthRepository
import javax.inject.Inject

/**
 * Use case for logging out the current user.
 *
 * This use case clears all authentication data and returns the user
 * to the unauthenticated state.
 */
class LogoutUseCase @Inject constructor(
    private val authRepository: AuthRepository
) {
    /**
     * Logs out the current user.
     *
     * @return [Result.Success] if logout was successful, [Result.Failure] with error otherwise
     */
    suspend operator fun invoke(): Result<Unit, AuthError> {
        return authRepository.logout()
    }
}
