package com.wealthwise.android

import android.app.Application
import dagger.hilt.android.HiltAndroidApp

/**
 * Main Application class for WealthWise Android
 * 
 * Responsibilities:
 * - Initialize Hilt dependency injection
 * - Configure Firebase
 * - Set up global error handling
 * - Initialize security components
 */
@HiltAndroidApp
class WealthWiseApplication : Application() {
    
    override fun onCreate() {
        super.onCreate()
        
        // Firebase is auto-initialized via google-services.json
        // Additional configuration can be added here if needed
    }
}
