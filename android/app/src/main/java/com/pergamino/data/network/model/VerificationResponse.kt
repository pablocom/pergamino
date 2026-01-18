package com.pergamino.data.network.model

import kotlinx.serialization.Serializable

@Serializable
data class VerificationResponse(
    val success: Boolean,
    val message: String
)
