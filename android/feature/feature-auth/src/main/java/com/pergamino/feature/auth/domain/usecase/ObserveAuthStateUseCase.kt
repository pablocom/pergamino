package com.pergamino.feature.auth.domain.usecase

import com.pergamino.feature.auth.domain.model.AuthState
import com.pergamino.feature.auth.domain.repository.AuthRepository
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject

/**
 * Use case for observing the current authentication state.
 *
 * This use case provides a reactive stream of auth state changes.
 * UI components can use this to reactively update based on auth state.
 */
class ObserveAuthStateUseCase @Inject constructor(
    private val authRepository: AuthRepository
) {
    /**
     * Returns a flow of authentication state changes.
     *
     * @return [Flow] emitting [AuthState] whenever it changes
     */
    operator fun invoke(): Flow<AuthState> = authRepository.authState
}
