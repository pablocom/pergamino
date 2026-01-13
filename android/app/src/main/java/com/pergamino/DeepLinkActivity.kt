package com.pergamino

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.lifecycle.lifecycleScope
import com.pergamino.core.ui.clearTaskAndStartNew
import com.pergamino.feature.auth.domain.usecase.VerifyEmailTokenUseCase
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.launch
import javax.inject.Inject

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
            navigateToMainAndLetAuthStateHandleRouting()
            return
        }

        Log.d(TAG, "Handling deep link: $uri")

        when {
            isVerificationLink(uri) -> handleVerificationLink(uri)
            else -> {
                Log.w(TAG, "Unknown deep link: $uri")
                navigateToMainAndLetAuthStateHandleRouting()
            }
        }
    }

    private fun isVerificationLink(uri: Uri): Boolean {
        return uri.host == "verify" || uri.path == "/verify"
    }

    private fun handleVerificationLink(uri: Uri) {
        val token = uri.getQueryParameter("token")
        if (token != null) {
            handleVerificationToken(token)
        } else {
            Log.w(TAG, "Verification link missing token parameter")
            navigateToMainAndLetAuthStateHandleRouting()
        }
    }

    private fun handleVerificationToken(token: String) {
        Log.d(TAG, "Verifying token...")

        lifecycleScope.launch {
            verifyEmailTokenUseCase(token)
                .onSuccess { authenticatedState ->
                    Log.d(TAG, "Token verified successfully for user: ${authenticatedState.user.email.value}")
                    navigateToMainAndLetAuthStateHandleRouting()
                }
                .onFailure { error ->
                    Log.e(TAG, "Token verification failed: $error")
                    navigateToMainAndLetAuthStateHandleRouting()
                }
        }
    }

    private fun navigateToMainAndLetAuthStateHandleRouting() {
        val intent = Intent(this, MainActivity::class.java).clearTaskAndStartNew()
        startActivity(intent)
        finish()
    }

    companion object {
        private const val TAG = "DeepLinkActivity"
    }
}
