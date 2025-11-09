package com.wealthwise.android.ui.theme

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Shapes
import androidx.compose.ui.unit.dp

/**
 * Material Design 3 shape scale.
 * 
 * Defines corner radius for various component categories.
 */
val Shapes = Shapes(
    // Extra small - Chips, badges, tooltips
    extraSmall = RoundedCornerShape(4.dp),
    
    // Small - Cards, buttons (filled, outlined, text)
    small = RoundedCornerShape(8.dp),
    
    // Medium - Dialogs, bottom sheets, large cards
    medium = RoundedCornerShape(12.dp),
    
    // Large - Navigation drawers, large modals
    large = RoundedCornerShape(16.dp),
    
    // Extra large - Full-screen modals
    extraLarge = RoundedCornerShape(24.dp)
)
