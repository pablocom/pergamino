package com.pergamino.domain.model

import android.util.Base64

@JvmInline
value class PublicKey(val value: String) {
    init {
        require(isValid(value)) { "Invalid public key format. Expected base64-encoded key." }
    }

    fun toByteArray(): ByteArray = Base64.decode(value, Base64.NO_WRAP)

    companion object {
        private const val MIN_KEY_SIZE = 33
        private const val MAX_KEY_SIZE = 200

        fun isValid(value: String): Boolean {
            if (value.isBlank()) return false

            return try {
                val decoded = Base64.decode(value, Base64.NO_WRAP)
                decoded.size in MIN_KEY_SIZE..MAX_KEY_SIZE
            } catch (e: IllegalArgumentException) {
                false
            }
        }

        fun fromByteArray(bytes: ByteArray): PublicKey {
            val base64 = Base64.encodeToString(bytes, Base64.NO_WRAP)
            return PublicKey(base64)
        }

        fun fromString(value: String): Result<PublicKey> = runCatching {
            PublicKey(value)
        }
    }
}
