package com.wealthwise.android.navigation

/**
 * Navigation routes for the app.
 * 
 * Uses sealed class for type-safe navigation with arguments.
 */
sealed class Screen(val route: String) {
    // Authentication
    object Login : Screen("login")
    object SignUp : Screen("signup")
    object ForgotPassword : Screen("forgot_password")
    
    // Main app screens
    object Dashboard : Screen("dashboard")
    object Accounts : Screen("accounts")
    object AccountDetail : Screen("account/{accountId}") {
        fun createRoute(accountId: String) = "account/$accountId"
    }
    
    object Transactions : Screen("transactions")
    object TransactionDetail : Screen("transaction/{transactionId}") {
        fun createRoute(transactionId: String) = "transaction/$transactionId"
    }
    
    object Budgets : Screen("budgets")
    object BudgetDetail : Screen("budget/{budgetId}") {
        fun createRoute(budgetId: String) = "budget/$budgetId"
    }
    
    object Goals : Screen("goals")
    object GoalDetail : Screen("goal/{goalId}") {
        fun createRoute(goalId: String) = "goal/$goalId"
    }
    
    object Settings : Screen("settings")
    object Profile : Screen("profile")
}

/**
 * Bottom navigation items.
 */
sealed class BottomNavItem(
    val route: String,
    val title: String,
    val icon: androidx.compose.ui.graphics.vector.ImageVector
) {
    object Dashboard : BottomNavItem(
        route = Screen.Dashboard.route,
        title = "Dashboard",
        icon = androidx.compose.material.icons.Icons.Filled.Dashboard
    )
    
    object Accounts : BottomNavItem(
        route = Screen.Accounts.route,
        title = "Accounts",
        icon = androidx.compose.material.icons.Icons.Filled.AccountBalance
    )
    
    object Transactions : BottomNavItem(
        route = Screen.Transactions.route,
        title = "Transactions",
        icon = androidx.compose.material.icons.Icons.Filled.Receipt
    )
    
    object Budgets : BottomNavItem(
        route = Screen.Budgets.route,
        title = "Budgets",
        icon = androidx.compose.material.icons.Icons.Filled.PieChart
    )
    
    object Goals : BottomNavItem(
        route = Screen.Goals.route,
        title = "Goals",
        icon = androidx.compose.material.icons.Icons.Filled.EmojiEvents
    )
}

/**
 * Get all bottom navigation items.
 */
fun getBottomNavItems() = listOf(
    BottomNavItem.Dashboard,
    BottomNavItem.Accounts,
    BottomNavItem.Transactions,
    BottomNavItem.Budgets,
    BottomNavItem.Goals
)
