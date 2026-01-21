package com.pergamino.domain.model

@JvmInline
value class JwtToken(val value: String) {
    init {
        require(isValid(value)) { "Invalid JWT token format. Expected 3 parts separated by dots." }
    }

    companion object {
        private val JWT_PATTERN = Regex("^[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+$")

        fun isValid(value: String): Boolean {
            if (value.isBlank()) return false
            val parts = value.split('.')
            return parts.size == 3 && JWT_PATTERN.matches(value)
        }

        fun fromString(value: String): Result<JwtToken> = runCatching {
            JwtToken(value)
        }
    }
}
