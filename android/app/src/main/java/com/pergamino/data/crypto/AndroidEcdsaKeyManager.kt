package com.pergamino.data.crypto

import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import com.pergamino.domain.model.PublicKey
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.Signature
import java.security.spec.ECGenParameterSpec
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AndroidEcdsaKeyManager @Inject constructor() : EcdsaKeyManager {

    companion object {
        private const val ANDROID_KEYSTORE = "AndroidKeyStore"
        private const val KEY_ALIAS = "pergamino_device_key"
        private const val EC_CURVE = "secp256r1"
        private const val SIGNATURE_ALGORITHM = "SHA256withECDSA"
    }

    private val keyStore: KeyStore by lazy {
        KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
    }

    override fun generateKeyPair(): Result<PublicKey> = runCatching {
        if (hasKeyPair()) {
            deleteKeyPair().getOrThrow()
        }

        val keyPairGenerator = KeyPairGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_EC,
            ANDROID_KEYSTORE
        )

        val parameterSpec = KeyGenParameterSpec.Builder(
            KEY_ALIAS,
            KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY
        )
            .setAlgorithmParameterSpec(ECGenParameterSpec(EC_CURVE))
            .setDigests(
                KeyProperties.DIGEST_SHA256,
                KeyProperties.DIGEST_SHA512
            )
            .setUserAuthenticationRequired(false)
            .build()

        keyPairGenerator.initialize(parameterSpec)
        val keyPair = keyPairGenerator.generateKeyPair()

        PublicKey.fromByteArray(keyPair.public.encoded)
    }

    override fun getPublicKey(): Result<PublicKey> = runCatching {
        if (!hasKeyPair()) {
            throw IllegalStateException("Key pair does not exist. Generate one first.")
        }

        val entry = keyStore.getEntry(KEY_ALIAS, null) as? KeyStore.PrivateKeyEntry
            ?: throw IllegalStateException("Failed to retrieve key pair from KeyStore")

        val publicKeyBytes = entry.certificate.publicKey.encoded
        PublicKey.fromByteArray(publicKeyBytes)
    }

    override fun hasKeyPair(): Boolean {
        return try {
            keyStore.containsAlias(KEY_ALIAS)
        } catch (e: Exception) {
            false
        }
    }

    override fun deleteKeyPair(): Result<Unit> = runCatching {
        if (hasKeyPair()) {
            keyStore.deleteEntry(KEY_ALIAS)
        }
    }

    override fun signData(data: ByteArray): Result<ByteArray> = runCatching {
        if (!hasKeyPair()) {
            throw IllegalStateException("Key pair does not exist. Generate one first.")
        }

        val entry = keyStore.getEntry(KEY_ALIAS, null) as? KeyStore.PrivateKeyEntry
            ?: throw IllegalStateException("Failed to retrieve private key from KeyStore")

        val signature = Signature.getInstance(SIGNATURE_ALGORITHM)
        signature.initSign(entry.privateKey)
        signature.update(data)
        signature.sign()
    }
}
