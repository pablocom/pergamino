package com.pergamino.feature.auth.presentation.email

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.pergamino.feature.auth.domain.model.AuthError
import com.pergamino.feature.auth.domain.model.EmailValidationError

/**
 * Stateful Email Entry screen that connects to the ViewModel.
 *
 * This composable:
 * - Collects state from the ViewModel
 * - Handles one-time events (navigation, snackbars)
 * - Delegates rendering to the stateless [EmailEntryContent]
 */
@Composable
fun EmailEntryScreen(
    viewModel: EmailEntryViewModel = hiltViewModel(),
    onNavigateToVerificationPending: (String) -> Unit
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val snackbarHostState = remember { SnackbarHostState() }

    // Handle one-time events
    LaunchedEffect(Unit) {
        viewModel.events.collect { event ->
            when (event) {
                is EmailEntryEvent.NavigateToVerificationPending -> {
                    onNavigateToVerificationPending(event.email)
                }
                is EmailEntryEvent.ShowError -> {
                    snackbarHostState.showSnackbar(
                        message = event.error.toUserMessage()
                    )
                }
            }
        }
    }

    EmailEntryContent(
        uiState = uiState,
        snackbarHostState = snackbarHostState,
        onEmailChanged = viewModel::onEmailChanged,
        onContinueClicked = viewModel::onContinueClicked
    )
}

/**
 * Stateless Email Entry content.
 *
 * This composable receives all state as parameters and emits events via callbacks.
 * This makes it easy to test and preview.
 */
@Composable
fun EmailEntryContent(
    uiState: EmailEntryUiState,
    snackbarHostState: SnackbarHostState,
    onEmailChanged: (String) -> Unit,
    onContinueClicked: () -> Unit,
    modifier: Modifier = Modifier
) {
    val keyboardController = LocalSoftwareKeyboardController.current

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) },
        modifier = modifier
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(horizontal = 24.dp)
                .imePadding(),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.height(80.dp))

            // Title
            Text(
                text = "Enter your email",
                style = MaterialTheme.typography.headlineMedium,
                color = MaterialTheme.colorScheme.onBackground
            )

            Spacer(modifier = Modifier.height(12.dp))

            // Subtitle
            Text(
                text = "We'll send you a verification link to confirm your email address",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(48.dp))

            // Email input field
            OutlinedTextField(
                value = uiState.email,
                onValueChange = onEmailChanged,
                label = { Text("Email address") },
                placeholder = { Text("you@example.com") },
                isError = uiState.emailValidationError != null,
                supportingText = {
                    uiState.emailValidationError?.let { error ->
                        Text(
                            text = error.toUserMessage(),
                            color = MaterialTheme.colorScheme.error
                        )
                    }
                },
                singleLine = true,
                enabled = !uiState.isLoading,
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Email,
                    imeAction = ImeAction.Done
                ),
                keyboardActions = KeyboardActions(
                    onDone = {
                        keyboardController?.hide()
                        if (uiState.canSubmit) {
                            onContinueClicked()
                        }
                    }
                ),
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag("email_input")
            )

            Spacer(modifier = Modifier.weight(1f))

            // Continue button
            Button(
                onClick = {
                    keyboardController?.hide()
                    onContinueClicked()
                },
                enabled = uiState.canSubmit,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp)
                    .testTag("continue_button")
            ) {
                if (uiState.isLoading) {
                    CircularProgressIndicator(
                        modifier = Modifier
                            .size(24.dp)
                            .testTag("loading_indicator"),
                        color = MaterialTheme.colorScheme.onPrimary,
                        strokeWidth = 2.dp
                    )
                } else {
                    Text(
                        text = "Continue",
                        style = MaterialTheme.typography.labelLarge
                    )
                }
            }

            Spacer(modifier = Modifier.height(32.dp))
        }
    }
}

/**
 * Converts [EmailValidationError] to a user-friendly message.
 */
private fun EmailValidationError.toUserMessage(): String = when (this) {
    EmailValidationError.Empty -> "Please enter your email address"
    EmailValidationError.InvalidFormat -> "Please enter a valid email address"
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
