package com.wealthwise.android.navigation

import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument

/**
 * Main navigation setup for the app.
 * 
 * Includes NavHost with all destinations and bottom navigation bar.
 */
@Composable
fun WealthWiseNavigation(
    startDestination: String = Screen.Dashboard.route
) {
    val navController = rememberNavController()
    val bottomNavItems = getBottomNavItems()
    
    Scaffold(
        bottomBar = {
            WealthWiseBottomBar(
                navController = navController,
                items = bottomNavItems
            )
        }
    ) { paddingValues ->
        NavHost(
            navController = navController,
            startDestination = startDestination,
            modifier = Modifier.padding(paddingValues)
        ) {
            // Authentication screens
            composable(Screen.Login.route) {
                com.wealthwise.android.features.auth.LoginScreen(navController)
            }
            
            composable(Screen.SignUp.route) {
                com.wealthwise.android.features.auth.SignUpScreen(navController)
            }
            
            composable(Screen.ForgotPassword.route) {
                com.wealthwise.android.features.auth.ForgotPasswordScreen(navController)
            }
            
            // Main app screens
            composable(Screen.Dashboard.route) {
                com.wealthwise.android.features.dashboard.DashboardScreen(navController)
            }
            
            composable(Screen.Accounts.route) {
                // AccountsScreen(navController)
                Text("Accounts Screen - To be implemented")
            }
            
            composable(
                route = Screen.AccountDetail.route,
                arguments = listOf(navArgument("accountId") { type = NavType.StringType })
            ) { backStackEntry ->
                val accountId = backStackEntry.arguments?.getString("accountId")
                // AccountDetailScreen(navController, accountId)
                Text("Account Detail Screen - To be implemented")
            }
            
            composable(Screen.Transactions.route) {
                // TransactionsScreen(navController)
                Text("Transactions Screen - To be implemented")
            }
            
            composable(
                route = Screen.TransactionDetail.route,
                arguments = listOf(navArgument("transactionId") { type = NavType.StringType })
            ) { backStackEntry ->
                val transactionId = backStackEntry.arguments?.getString("transactionId")
                // TransactionDetailScreen(navController, transactionId)
                Text("Transaction Detail Screen - To be implemented")
            }
            
            composable(Screen.Budgets.route) {
                // BudgetsScreen(navController)
                Text("Budgets Screen - To be implemented")
            }
            
            composable(
                route = Screen.BudgetDetail.route,
                arguments = listOf(navArgument("budgetId") { type = NavType.StringType })
            ) { backStackEntry ->
                val budgetId = backStackEntry.arguments?.getString("budgetId")
                // BudgetDetailScreen(navController, budgetId)
                Text("Budget Detail Screen - To be implemented")
            }
            
            composable(Screen.Goals.route) {
                // GoalsScreen(navController)
                Text("Goals Screen - To be implemented")
            }
            
            composable(
                route = Screen.GoalDetail.route,
                arguments = listOf(navArgument("goalId") { type = NavType.StringType })
            ) { backStackEntry ->
                val goalId = backStackEntry.arguments?.getString("goalId")
                // GoalDetailScreen(navController, goalId)
                Text("Goal Detail Screen - To be implemented")
            }
            
            composable(Screen.Settings.route) {
                // SettingsScreen(navController)
                Text("Settings Screen - To be implemented")
            }
            
            composable(Screen.Profile.route) {
                // ProfileScreen(navController)
                Text("Profile Screen - To be implemented")
            }
        }
    }
}

/**
 * Bottom navigation bar with Material Design 3 components.
 */
@Composable
fun WealthWiseBottomBar(
    navController: NavHostController,
    items: List<BottomNavItem>
) {
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination
    
    // Only show bottom bar on main screens
    val shouldShowBottomBar = currentDestination?.route in items.map { it.route }
    
    if (shouldShowBottomBar) {
        NavigationBar {
            items.forEach { item ->
                val selected = currentDestination?.hierarchy?.any { it.route == item.route } == true
                
                NavigationBarItem(
                    icon = {
                        Icon(
                            imageVector = item.icon,
                            contentDescription = item.title
                        )
                    },
                    label = { Text(item.title) },
                    selected = selected,
                    onClick = {
                        if (!selected) {
                            navController.navigate(item.route) {
                                // Pop up to the start destination to avoid large back stack
                                popUpTo(navController.graph.findStartDestination().id) {
                                    saveState = true
                                }
                                // Avoid multiple copies of the same destination
                                launchSingleTop = true
                                // Restore state when reselecting a previously selected item
                                restoreState = true
                            }
                        }
                    }
                )
            }
        }
    }
}
