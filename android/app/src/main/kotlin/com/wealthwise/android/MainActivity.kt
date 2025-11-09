package com.wealthwise.android

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.navigation.compose.rememberNavController
import com.wealthwise.android.ui.navigation.WealthWiseNavHost
import com.wealthwise.android.ui.theme.WealthWiseTheme
import dagger.hilt.android.AndroidEntryPoint

/**
 * Main Activity for WealthWise Android application
 * 
 * Implements:
 * - Edge-to-edge display
 * - Material Design 3 theming
 * - Navigation setup with Jetpack Compose Navigation
 * - Hilt dependency injection
 */
@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Enable edge-to-edge display
        enableEdgeToEdge()
        
        setContent {
            WealthWiseTheme {
                WealthWiseApp()
            }
        }
    }
}

@Composable
fun WealthWiseApp() {
    val navController = rememberNavController()
    
    Surface(
        modifier = Modifier.fillMaxSize()
    ) {
        Scaffold(
            modifier = Modifier.fillMaxSize()
        ) { paddingValues ->
            WealthWiseNavHost(
                navController = navController,
                modifier = Modifier.padding(paddingValues)
            )
        }
    }
}
