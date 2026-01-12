package com.pergamino.feature.auth.domain.model

import com.pergamino.core.common.Result

/**
 * Value object representing a verification token received from the email verification link.
 *
 * This token is used to complete the authentication process after the user clicks
 * the verification link sent to their email.
 */
@JvmInline
value class VerificationToken private constructor(val value: String) {

    companion object {
        /**
         * Creates a [VerificationToken] instance if the provided string is valid.
         *
         * @param value The raw token string
         * @return [Result.Success] containing the token if valid, [Result.Failure] otherwise
         */
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

/**
 * Represents the possible validation errors when creating a [VerificationToken].
 */
sealed interface TokenValidationError {
    data object Empty : TokenValidationError
    data object TooShort : TokenValidationError
}
