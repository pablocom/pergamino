package com.pergamino.feature.auth.data.datasource

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.longPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import java.time.Instant
import javax.inject.Inject
import javax.inject.Singleton

private val Context.authDataStore: DataStore<Preferences> by preferencesDataStore(name = "auth_preferences")

@Singleton
class AuthLocalDataSourceImpl @Inject constructor(
    @param:ApplicationContext private val context: Context
) : AuthLocalDataSource {

    override val authStateData: Flow<PersistedAuthState?> = context.authDataStore.data.map { prefs ->
        when (prefs[KEY_AUTH_STATE_TYPE]) {
            STATE_VERIFICATION_PENDING -> {
                val email = prefs[KEY_EMAIL] ?: return@map null
                val expiresAt = prefs[KEY_EXPIRES_AT] ?: return@map null
                PersistedAuthState.VerificationPending(
                    email = email,
                    expiresAt = Instant.ofEpochMilli(expiresAt)
                )
            }
            STATE_AUTHENTICATED -> {
                val userId = prefs[KEY_USER_ID] ?: return@map null
                val email = prefs[KEY_EMAIL] ?: return@map null
                val accessToken = prefs[KEY_ACCESS_TOKEN] ?: return@map null
                val createdAt = prefs[KEY_CREATED_AT] ?: return@map null
                PersistedAuthState.Authenticated(
                    userId = userId,
                    email = email,
                    accessToken = accessToken,
                    createdAt = Instant.ofEpochMilli(createdAt)
                )
            }
            else -> null
        }
    }

    override suspend fun saveVerificationPending(email: String, expiresAt: Instant) {
        context.authDataStore.edit { prefs ->
            prefs[KEY_AUTH_STATE_TYPE] = STATE_VERIFICATION_PENDING
            prefs[KEY_EMAIL] = email
            prefs[KEY_EXPIRES_AT] = expiresAt.toEpochMilli()
            prefs.remove(KEY_USER_ID)
            prefs.remove(KEY_ACCESS_TOKEN)
            prefs.remove(KEY_CREATED_AT)
        }
    }

    override suspend fun saveAuthenticated(
        userId: String,
        email: String,
        accessToken: String,
        createdAt: Instant
    ) {
        context.authDataStore.edit { prefs ->
            prefs[KEY_AUTH_STATE_TYPE] = STATE_AUTHENTICATED
            prefs[KEY_USER_ID] = userId
            prefs[KEY_EMAIL] = email
            prefs[KEY_ACCESS_TOKEN] = accessToken
            prefs[KEY_CREATED_AT] = createdAt.toEpochMilli()
            prefs.remove(KEY_EXPIRES_AT)
        }
    }

    override suspend fun clear() {
        context.authDataStore.edit { prefs ->
            prefs.clear()
        }
    }

    override suspend fun getPendingEmail(): String? {
        val prefs = context.authDataStore.data.first()
        return if (prefs[KEY_AUTH_STATE_TYPE] == STATE_VERIFICATION_PENDING) {
            prefs[KEY_EMAIL]
        } else {
            null
        }
    }

    companion object {
        private val KEY_AUTH_STATE_TYPE = stringPreferencesKey("auth_state_type")
        private val KEY_EMAIL = stringPreferencesKey("email")
        private val KEY_EXPIRES_AT = longPreferencesKey("expires_at")
        private val KEY_USER_ID = stringPreferencesKey("user_id")
        private val KEY_ACCESS_TOKEN = stringPreferencesKey("access_token")
        private val KEY_CREATED_AT = longPreferencesKey("created_at")

        private const val STATE_VERIFICATION_PENDING = "verification_pending"
        private const val STATE_AUTHENTICATED = "authenticated"
    }
}
