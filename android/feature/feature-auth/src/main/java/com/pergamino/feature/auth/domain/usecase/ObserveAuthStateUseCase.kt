package com.pergamino.feature.auth.domain.usecase

import com.pergamino.feature.auth.domain.model.AuthState
import com.pergamino.feature.auth.domain.repository.AuthRepository
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject

class ObserveAuthStateUseCase @Inject constructor(
    private val authRepository: AuthRepository
) {
    operator fun invoke(): Flow<AuthState> = authRepository.authState
}
