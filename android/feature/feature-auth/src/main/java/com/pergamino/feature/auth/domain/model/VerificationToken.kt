package com.pergamino.feature.auth.domain.model

import com.pergamino.core.common.Result

@JvmInline
value class VerificationToken private constructor(val value: String) {

    companion object {
        fun create(value: String): Result<VerificationToken, TokenValidationError> {
            val trimmed = value.trim()

            return when {
                trimmed.isBlank() -> Result.failure(TokenValidationError.Empty)
                trimmed.length < 10 -> Result.failure(TokenValidationError.TooShort)
                else -> Result.success(VerificationToken(trimmed))
            }
        }
    }
}

sealed interface TokenValidationError {
    data object Empty : TokenValidationError
    data object TooShort : TokenValidationError
}
