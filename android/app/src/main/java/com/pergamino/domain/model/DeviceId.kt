package com.pergamino.domain.model

import java.util.UUID

@JvmInline
value class DeviceId(val value: UUID) {

    override fun toString(): String = value.toString()

    companion object {
        fun fromString(value: String): Result<DeviceId> = runCatching {
            DeviceId(UUID.fromString(value))
        }

        fun random(): DeviceId = DeviceId(UUID.randomUUID())
    }
}
