package com.pergamino.feature.auth.presentation.verification

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Email
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.pergamino.feature.auth.domain.model.AuthError

/**
 * Stateful Verification Pending screen.
 */
@Composable
fun VerificationPendingScreen(
    viewModel: VerificationPendingViewModel = hiltViewModel(),
    onNavigateToMain: () -> Unit,
    onNavigateBack: () -> Unit
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val snackbarHostState = remember { SnackbarHostState() }

    // Handle one-time events
    LaunchedEffect(Unit) {
        viewModel.events.collect { event ->
            when (event) {
                VerificationPendingEvent.NavigateToMain -> onNavigateToMain()
                VerificationPendingEvent.NavigateBack -> onNavigateBack()
                VerificationPendingEvent.ShowResendSuccess -> {
                    snackbarHostState.showSnackbar("Verification email sent!")
                }
                is VerificationPendingEvent.ShowError -> {
                    snackbarHostState.showSnackbar(event.error.toUserMessage())
                }
            }
        }
    }

    VerificationPendingContent(
        uiState = uiState,
        snackbarHostState = snackbarHostState,
        onResendClicked = viewModel::onResendClicked,
        onChangeEmailClicked = viewModel::onChangeEmailClicked
    )
}

/**
 * Stateless Verification Pending content.
 */
@Composable
fun VerificationPendingContent(
    uiState: VerificationPendingUiState,
    snackbarHostState: SnackbarHostState,
    onResendClicked: () -> Unit,
    onChangeEmailClicked: () -> Unit,
    modifier: Modifier = Modifier
) {
    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) },
        modifier = modifier
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(horizontal = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            // Email icon
            Icon(
                imageVector = Icons.Outlined.Email,
                contentDescription = null,
                modifier = Modifier.size(80.dp),
                tint = MaterialTheme.colorScheme.primary
            )

            Spacer(modifier = Modifier.height(32.dp))

            // Title
            Text(
                text = "Check your email",
                style = MaterialTheme.typography.headlineMedium,
                color = MaterialTheme.colorScheme.onBackground
            )

            Spacer(modifier = Modifier.height(16.dp))

            // Description
            Text(
                text = "We've sent a verification link to",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(8.dp))

            // Email address
            Text(
                text = uiState.email,
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.primary,
                textAlign = TextAlign.Center,
                modifier = Modifier.testTag("email_display")
            )

            Spacer(modifier = Modifier.height(8.dp))

            // Instructions
            Text(
                text = "Click the link in the email to verify your account. If you don't see it, check your spam folder.",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(48.dp))

            // Resend button
            Button(
                onClick = onResendClicked,
                enabled = uiState.canResend,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp)
                    .testTag("resend_button")
            ) {
                if (uiState.isResending) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(24.dp),
                        color = MaterialTheme.colorScheme.onPrimary,
                        strokeWidth = 2.dp
                    )
                } else if (uiState.resendCooldownSeconds > 0) {
                    Text(
                        text = "Resend in ${uiState.resendCooldownSeconds}s",
                        style = MaterialTheme.typography.labelLarge
                    )
                } else {
                    Text(
                        text = "Resend email",
                        style = MaterialTheme.typography.labelLarge
                    )
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Change email button
            TextButton(
                onClick = onChangeEmailClicked,
                modifier = Modifier.testTag("change_email_button")
            ) {
                Text(
                    text = "Use a different email",
                    style = MaterialTheme.typography.labelLarge
                )
            }
        }
    }
}

/**
 * Converts [AuthError] to a user-friendly message.
 */
private fun AuthError.toUserMessage(): String = when (this) {
    is AuthError.InvalidEmail -> "Please enter a valid email address"
    is AuthError.InvalidToken -> "Invalid verification link"
    AuthError.TokenExpired -> "Verification link has expired"
    AuthError.TokenNotFound -> "Verification link is invalid or already used"
    is AuthError.NetworkError -> message ?: "Network error. Please check your connection."
    is AuthError.ServerError -> message ?: "Server error. Please try again later."
    AuthError.RateLimitExceeded -> "Too many requests. Please wait before trying again."
}
