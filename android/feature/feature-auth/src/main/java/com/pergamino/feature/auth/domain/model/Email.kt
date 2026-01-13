package com.pergamino.feature.auth.domain.model

import com.pergamino.core.common.Result

@JvmInline
value class Email private constructor(val value: String) {
    companion object {
        private val EMAIL_REGEX = Regex(
            "^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        )

        fun create(value: String): Result<Email, EmailValidationError> {
            val trimmed = value.trim()

            return when {
                trimmed.isBlank() -> Result.failure(EmailValidationError.Empty)
                !EMAIL_REGEX.matches(trimmed) -> Result.failure(EmailValidationError.InvalidFormat)
                else -> Result.success(Email(trimmed.lowercase()))
            }
        }
    }
}

sealed interface EmailValidationError {
    data object Empty : EmailValidationError

    data object InvalidFormat : EmailValidationError
}
