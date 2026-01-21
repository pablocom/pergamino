package com.pergamino

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.pergamino.feature.devicebinding.DeviceBindingScreen
import com.pergamino.feature.emailverification.EmailVerificationScreen
import com.pergamino.ui.theme.PergaminoTheme
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        setContent {
            PergaminoTheme {
                val navController = rememberNavController()
                var deeplinkToken by remember { mutableStateOf<String?>(null) }

                LaunchedEffect(Unit) {
                    handleDeeplink(intent)?.let { token ->
                        deeplinkToken = token
                    }
                }

                LaunchedEffect(deeplinkToken) {
                    deeplinkToken?.let { token ->
                        navController.navigate("device_binding/$token") {
                            popUpTo("email_verification") { inclusive = false }
                        }
                        deeplinkToken = null
                    }
                }

                Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
                    NavHost(
                        navController = navController,
                        startDestination = "email_verification",
                        modifier = Modifier.padding(innerPadding)
                    ) {
                        composable("email_verification") {
                            EmailVerificationScreen()
                        }

                        composable(
                            route = "device_binding/{token}",
                            arguments = listOf(
                                navArgument("token") { type = NavType.StringType }
                            )
                        ) { backStackEntry ->
                            val token = backStackEntry.arguments?.getString("token") ?: ""
                            DeviceBindingScreen(
                                token = token,
                                onNavigateToHome = {
                                    navController.navigate("email_verification") {
                                        popUpTo("email_verification") { inclusive = true }
                                    }
                                }
                            )
                        }
                    }
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleDeeplink(intent)?.let { token ->
            setContent {
                PergaminoTheme {
                    val navController = rememberNavController()

                    LaunchedEffect(token) {
                        navController.navigate("device_binding/$token") {
                            popUpTo("email_verification") { inclusive = false }
                        }
                    }

                    Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
                        NavHost(
                            navController = navController,
                            startDestination = "email_verification",
                            modifier = Modifier.padding(innerPadding)
                        ) {
                            composable("email_verification") {
                                EmailVerificationScreen()
                            }

                            composable(
                                route = "device_binding/{token}",
                                arguments = listOf(
                                    navArgument("token") { type = NavType.StringType }
                                )
                            ) { backStackEntry ->
                                val tokenArg = backStackEntry.arguments?.getString("token") ?: ""
                                DeviceBindingScreen(
                                    token = tokenArg,
                                    onNavigateToHome = {
                                        navController.navigate("email_verification") {
                                            popUpTo("email_verification") { inclusive = true }
                                        }
                                    }
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    private fun handleDeeplink(intent: Intent): String? {
        val data: Uri? = intent.data
        if (data?.scheme == "pergamino" && data.host == "bind") {
            return data.getQueryParameter("token")
        }
        return null
    }
}