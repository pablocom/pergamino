package com.pergamino.feature.auth.domain.model

import java.time.Instant

/**
 * Domain entity representing an authenticated user.
 *
 * This entity contains the essential user information after successful authentication.
 * Following DDD principles, this entity is use case agnostic and should rarely change.
 */
data class User(
    val id: String,
    val email: Email,
    val createdAt: Instant
)
