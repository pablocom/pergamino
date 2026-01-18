package com.pergamino.data.repository

import com.pergamino.domain.model.Email

interface EmailVerificationRepository {
    suspend fun requestVerificationEmail(email: Email): Result<Unit>
}
