package com.pergamino.feature.auth.domain.model

sealed interface AuthError {

    data class InvalidEmail(val validationError: EmailValidationError) : AuthError
    data class InvalidToken(val validationError: TokenValidationError) : AuthError
    data object TokenExpired : AuthError
    data object TokenNotFound : AuthError
    data class NetworkError(val message: String? = null) : AuthError
    data class ServerError(val message: String? = null) : AuthError
    data object RateLimitExceeded : AuthError
}
