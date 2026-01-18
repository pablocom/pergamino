package com.pergamino.data.network.model

import kotlinx.serialization.Serializable

@Serializable
data class VerificationRequest(
    val email: String
)
