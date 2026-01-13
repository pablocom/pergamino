package com.pergamino.feature.auth.domain.model

import java.time.Instant

data class User(
    val id: String,
    val email: Email,
    val createdAt: Instant
)
