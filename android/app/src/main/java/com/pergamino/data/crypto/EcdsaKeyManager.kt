package com.pergamino.data.crypto

import com.pergamino.domain.model.PublicKey

interface EcdsaKeyManager {
    fun generateKeyPair(): Result<PublicKey>
    fun getPublicKey(): Result<PublicKey>
    fun hasKeyPair(): Boolean
    fun deleteKeyPair(): Result<Unit>
    fun signData(data: ByteArray): Result<ByteArray>
}
