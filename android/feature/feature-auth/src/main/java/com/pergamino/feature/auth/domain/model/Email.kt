package com.pergamino.feature.auth.domain.model

import com.pergamino.core.common.Result

/**
 * Value object representing a validated email address.
 *
 * This class ensures that email addresses are always valid by making the constructor private
 * and only allowing creation through the [create] factory method which performs validation.
 *
 * Following Domain-Driven Design principles, this value object is:
 * - Immutable
 * - Self-validating
 * - Use case agnostic (can be used across different use cases)
 */
@JvmInline
value class Email private constructor(val value: String) {

    companion object {
        private val EMAIL_REGEX = Regex(
            "^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        )

        /**
         * Creates an [Email] instance if the provided string is a valid email address.
         *
         * @param value The raw email string to validate
         * @return [Result.Success] containing the Email if valid, [Result.Failure] with validation error otherwise
         */
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

/**
 * Represents the possible validation errors when creating an [Email].
 */
sealed interface EmailValidationError {
    /**
     * The email string was empty or contained only whitespace.
     */
    data object Empty : EmailValidationError

    /**
     * The email string did not match the expected email format.
     */
    data object InvalidFormat : EmailValidationError
}
