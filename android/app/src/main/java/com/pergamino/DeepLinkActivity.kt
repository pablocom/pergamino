package com.pergamino

import android.content.Intent
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.lifecycle.lifecycleScope
import com.pergamino.feature.auth.domain.usecase.VerifyEmailTokenUseCase
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * Activity that handles deep links for email verification.
 *
 * This activity handles the following deep link schemes:
 * - pergamino://verify?token=XXX (development/testing)
 * - https://pergamino.app/verify?token=XXX (production)
 *
 * When a verification link is clicked:
 * 1. Extract the token from the URI
 * 2. Verify the token using the use case
 * 3. On success: Navigate to MainActivity (auth state will handle routing)
 * 4. On failure: Navigate to MainActivity with error (auth state will show pending screen)
 */
@AndroidEntryPoint
class DeepLinkActivity : ComponentActivity() {

    @Inject
    lateinit var verifyEmailTokenUseCase: VerifyEmailTokenUseCase

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleDeepLink(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleDeepLink(intent)
    }

    private fun handleDeepLink(intent: Intent?) {
        val uri = intent?.data

        if (uri == null) {
            Log.w(TAG, "DeepLinkActivity launched without URI")
            navigateToMain()
            return
        }

        Log.d(TAG, "Handling deep link: $uri")

        when {
            // Handle verification links: pergamino://verify?token=XXX or https://pergamino.app/verify?token=XXX
            uri.host == "verify" || uri.path == "/verify" -> {
                val token = uri.getQueryParameter("token")
                if (token != null) {
                    handleVerificationToken(token)
                } else {
                    Log.w(TAG, "Verification link missing token parameter")
                    navigateToMain()
                }
            }
            else -> {
                Log.w(TAG, "Unknown deep link: $uri")
                navigateToMain()
            }
        }
    }

    private fun handleVerificationToken(token: String) {
        Log.d(TAG, "Verifying token...")

        lifecycleScope.launch {
            verifyEmailTokenUseCase(token)
                .onSuccess { authenticatedState ->
                    Log.d(TAG, "Token verified successfully for user: ${authenticatedState.user.email.value}")
                    navigateToMain()
                }
                .onFailure { error ->
                    Log.e(TAG, "Token verification failed: $error")
                    // Navigate to main anyway - the auth state flow will determine what screen to show
                    navigateToMain()
                }
        }
    }

    private fun navigateToMain() {
        val intent = Intent(this, MainActivity::class.java).apply {
            // Clear the task stack and start fresh
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        startActivity(intent)
        finish()
    }

    companion object {
        private const val TAG = "DeepLinkActivity"
    }
}
