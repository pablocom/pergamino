package com.pergamino.data.network.model.response

import kotlinx.serialization.Serializable

@Serializable
data class DeviceBindingResponse(
    val deviceId: String,
    val email: String
)
