package com.pergamino.feature.emailverification

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.pergamino.ui.theme.PergaminoTheme

@Composable
fun EmailVerificationScreen(
    modifier: Modifier = Modifier,
    viewModel: EmailVerificationViewModel = viewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val email by viewModel.email.collectAsStateWithLifecycle()
    val emailError by viewModel.emailError.collectAsStateWithLifecycle()

    EmailVerificationContent(
        email = email,
        emailError = emailError,
        uiState = uiState,
        onEmailChange = viewModel::onEmailChange,
        onRequestVerification = viewModel::requestVerificationEmail,
        onResetState = viewModel::resetState,
        modifier = modifier
    )
}

@Composable
private fun EmailVerificationContent(
    email: String,
    emailError: String?,
    uiState: EmailVerificationUiState,
    onEmailChange: (String) -> Unit,
    onRequestVerification: () -> Unit,
    onResetState: () -> Unit,
    modifier: Modifier = Modifier
) {
    val keyboardController = LocalSoftwareKeyboardController.current

    Surface(
        modifier = modifier.fillMaxSize(),
        color = MaterialTheme.colorScheme.background
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Text(
                text = "Verify your email",
                style = MaterialTheme.typography.headlineMedium,
                color = MaterialTheme.colorScheme.onBackground
            )

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = "Enter your email address and we'll send you a verification link",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(32.dp))

            when (uiState) {
                is EmailVerificationUiState.Success -> {
                    SuccessContent(
                        email = email,
                        onTryAgain = onResetState
                    )
                }
                else -> {
                    EmailInputContent(
                        email = email,
                        emailError = emailError,
                        isLoading = uiState is EmailVerificationUiState.Loading,
                        errorMessage = (uiState as? EmailVerificationUiState.Error)?.message,
                        onEmailChange = onEmailChange,
                        onRequestVerification = {
                            keyboardController?.hide()
                            onRequestVerification()
                        }
                    )
                }
            }
        }
    }
}

@Composable
private fun EmailInputContent(
    email: String,
    emailError: String?,
    isLoading: Boolean,
    errorMessage: String?,
    onEmailChange: (String) -> Unit,
    onRequestVerification: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        OutlinedTextField(
            value = email,
            onValueChange = onEmailChange,
            label = { Text("Email address") },
            placeholder = { Text("you@example.com") },
            singleLine = true,
            isError = emailError != null || errorMessage != null,
            supportingText = {
                when {
                    emailError != null -> Text(emailError)
                    errorMessage != null -> Text(errorMessage)
                }
            },
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Email,
                imeAction = ImeAction.Done
            ),
            keyboardActions = KeyboardActions(
                onDone = { onRequestVerification() }
            ),
            enabled = !isLoading,
            modifier = Modifier.fillMaxWidth()
        )

        Spacer(modifier = Modifier.height(24.dp))

        Button(
            onClick = onRequestVerification,
            enabled = !isLoading && email.isNotBlank(),
            modifier = Modifier.fillMaxWidth()
        ) {
            if (isLoading) {
                CircularProgressIndicator(
                    modifier = Modifier.size(20.dp),
                    strokeWidth = 2.dp,
                    color = MaterialTheme.colorScheme.onPrimary
                )
            } else {
                Text("Send verification email")
            }
        }
    }
}

@Composable
private fun SuccessContent(
    email: String,
    onTryAgain: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = "Check your inbox!",
            style = MaterialTheme.typography.titleLarge,
            color = MaterialTheme.colorScheme.primary
        )

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = "We've sent a verification link to $email",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(24.dp))

        Button(
            onClick = onTryAgain,
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("Use a different email")
        }
    }
}

@Preview(showBackground = true)
@Composable
private fun EmailVerificationContentIdlePreview() {
    PergaminoTheme {
        EmailVerificationContent(
            email = "",
            emailError = null,
            uiState = EmailVerificationUiState.Idle,
            onEmailChange = {},
            onRequestVerification = {},
            onResetState = {}
        )
    }
}

@Preview(showBackground = true)
@Composable
private fun EmailVerificationContentLoadingPreview() {
    PergaminoTheme {
        EmailVerificationContent(
            email = "test@example.com",
            emailError = null,
            uiState = EmailVerificationUiState.Loading,
            onEmailChange = {},
            onRequestVerification = {},
            onResetState = {}
        )
    }
}

@Preview(showBackground = true)
@Composable
private fun EmailVerificationContentSuccessPreview() {
    PergaminoTheme {
        EmailVerificationContent(
            email = "test@example.com",
            emailError = null,
            uiState = EmailVerificationUiState.Success,
            onEmailChange = {},
            onRequestVerification = {},
            onResetState = {}
        )
    }
}

@Preview(showBackground = true)
@Composable
private fun EmailVerificationContentErrorPreview() {
    PergaminoTheme {
        EmailVerificationContent(
            email = "invalid",
            emailError = "Please enter a valid email address",
            uiState = EmailVerificationUiState.Idle,
            onEmailChange = {},
            onRequestVerification = {},
            onResetState = {}
        )
    }
}
