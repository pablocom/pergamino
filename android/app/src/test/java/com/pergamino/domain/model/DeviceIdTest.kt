package com.pergamino.domain.model

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.UUID

class DeviceIdTest {

    @Test
    fun `fromString with valid UUID succeeds`() {
        val validUuid = "123e4567-e89b-12d3-a456-426614174000"

        val result = DeviceId.fromString(validUuid)

        assertTrue(result.isSuccess)
        assertEquals(validUuid, result.getOrThrow().toString())
    }

    @Test
    fun `fromString with invalid UUID format fails`() {
        val invalidUuid = "not-a-valid-uuid"

        val result = DeviceId.fromString(invalidUuid)

        assertTrue(result.isFailure)
    }

    @Test
    fun `fromString with empty string fails`() {
        val result = DeviceId.fromString("")

        assertTrue(result.isFailure)
    }

    @Test
    fun `toString returns UUID string representation`() {
        val uuidString = "123e4567-e89b-12d3-a456-426614174000"
        val deviceId = DeviceId.fromString(uuidString).getOrThrow()

        assertEquals(uuidString, deviceId.toString())
    }

    @Test
    fun `random generates valid DeviceId`() {
        val deviceId = DeviceId.random()

        val uuidString = deviceId.toString()
        val parsedResult = UUID.fromString(uuidString)

        assertEquals(uuidString, parsedResult.toString())
    }

    @Test
    fun `two DeviceIds with same UUID are equal`() {
        val uuidString = "123e4567-e89b-12d3-a456-426614174000"
        val deviceId1 = DeviceId.fromString(uuidString).getOrThrow()
        val deviceId2 = DeviceId.fromString(uuidString).getOrThrow()

        assertEquals(deviceId1, deviceId2)
    }

    @Test
    fun `two DeviceIds with different UUIDs are not equal`() {
        val deviceId1 = DeviceId.fromString("123e4567-e89b-12d3-a456-426614174000").getOrThrow()
        val deviceId2 = DeviceId.fromString("223e4567-e89b-12d3-a456-426614174000").getOrThrow()

        assertNotEquals(deviceId1, deviceId2)
    }
}
