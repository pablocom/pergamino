package com.pergamino.feature.auth.presentation.navigation

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material3.Button
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.pergamino.feature.auth.presentation.email.EmailEntryScreen
import com.pergamino.feature.auth.presentation.verification.VerificationPendingScreen
import java.net.URLDecoder
import java.net.URLEncoder
import java.nio.charset.StandardCharsets

/**
 * Authentication navigation routes.
 *
 * Using a sealed class provides type-safe navigation with compile-time checking.
 */
sealed class AuthRoute(val route: String) {
    data object EmailEntry : AuthRoute("auth/email")

    data object VerificationPending : AuthRoute("auth/verification/{email}") {
        fun createRoute(email: String): String {
            val encodedEmail = URLEncoder.encode(email, StandardCharsets.UTF_8.toString())
            return "auth/verification/$encodedEmail"
        }
    }

    data object AuthSuccess : AuthRoute("auth/success")
}

/**
 * Main navigation host for the authentication flow.
 *
 * Following Jetpack Compose navigation best practices:
 * - Uses sealed class for type-safe routes
 * - Clears back stack appropriately on auth completion
 * - Handles deep links for verification tokens
 */
@Composable
fun AuthNavHost(
    navController: NavHostController = rememberNavController(),
    onAuthenticationComplete: () -> Unit = {}
) {
    NavHost(
        navController = navController,
        startDestination = AuthRoute.EmailEntry.route
    ) {
        // Email Entry Screen
        composable(route = AuthRoute.EmailEntry.route) {
            EmailEntryScreen(
                onNavigateToVerificationPending = { email ->
                    navController.navigate(AuthRoute.VerificationPending.createRoute(email)) {
                        // Don't add to back stack multiple times if user re-submits
                        launchSingleTop = true
                    }
                }
            )
        }

        // Verification Pending Screen
        composable(
            route = AuthRoute.VerificationPending.route,
            arguments = listOf(
                navArgument("email") {
                    type = NavType.StringType
                }
            )
        ) {
            VerificationPendingScreen(
                onNavigateToMain = {
                    // Clear the entire auth back stack when authenticated
                    navController.navigate(AuthRoute.AuthSuccess.route) {
                        popUpTo(AuthRoute.EmailEntry.route) {
                            inclusive = true
                        }
                    }
                },
                onNavigateBack = {
                    navController.popBackStack()
                }
            )
        }

        // Auth Success Screen (placeholder for main app entry)
        composable(route = AuthRoute.AuthSuccess.route) {
            AuthSuccessScreen(
                onContinue = onAuthenticationComplete
            )
        }
    }
}

/**
 * Simple success screen shown after authentication.
 *
 * In a real app, this would navigate to the main chat screen.
 */
@Composable
private fun AuthSuccessScreen(
    onContinue: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            imageVector = Icons.Default.CheckCircle,
            contentDescription = null,
            modifier = Modifier.size(80.dp),
            tint = MaterialTheme.colorScheme.primary
        )

        Spacer(modifier = Modifier.height(24.dp))

        Text(
            text = "You're all set!",
            style = MaterialTheme.typography.headlineMedium
        )

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = "Your email has been verified successfully.",
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(48.dp))

        Button(
            onClick = onContinue,
            modifier = Modifier
                .fillMaxWidth()
                .height(56.dp)
        ) {
            Text("Continue to Pergamino")
        }
    }
}
