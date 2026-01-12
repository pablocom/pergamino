package com.pergamino.feature.auth.domain.model

/**
 * Domain-specific errors for the authentication feature.
 *
 * These errors represent all possible failure scenarios in the authentication flow,
 * providing meaningful error information for the UI layer to display to users.
 */
sealed interface AuthError {

    /**
     * The email address provided is invalid.
     */
    data class InvalidEmail(val validationError: EmailValidationError) : AuthError

    /**
     * The verification token is invalid or malformed.
     */
    data class InvalidToken(val validationError: TokenValidationError) : AuthError

    /**
     * The verification token has expired.
     */
    data object TokenExpired : AuthError

    /**
     * The verification token was not found or has already been used.
     */
    data object TokenNotFound : AuthError

    /**
     * A network error occurred while communicating with the server.
     */
    data class NetworkError(val message: String? = null) : AuthError

    /**
     * An unknown server error occurred.
     */
    data class ServerError(val message: String? = null) : AuthError

    /**
     * Rate limit exceeded - too many verification requests.
     */
    data object RateLimitExceeded : AuthError
}
