package com.pergamino.domain.model

@JvmInline
value class Email private constructor(val value: String) {
    
    companion object {
        private const val EMAIL_REGEX = "^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"

        fun create(value: String): Result<Email> {
            return if (isValidEmail(value)) {
                Result.success(Email(value))
            } else {
                Result.failure(IllegalArgumentException("Invalid email format"))
            }
        }

        private fun isValidEmail(email: String): Boolean {
            if (email.isBlank()) return false
            return email.matches(EMAIL_REGEX.toRegex())
        }
    }
}

