package com.pergamino.data.network.model.request

import kotlinx.serialization.Serializable

@Serializable
data class DeviceBindingRequest(
    val token: String
)
