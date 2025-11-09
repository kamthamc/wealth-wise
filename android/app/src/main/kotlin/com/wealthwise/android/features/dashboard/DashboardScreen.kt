package com.wealthwise.android.features.dashboard

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.wealthwise.android.data.model.Transaction
import com.wealthwise.android.data.repository.BudgetRepository
import com.wealthwise.android.ui.theme.*
import java.math.BigDecimal
import java.text.NumberFormat
import java.util.*

/**
 * Dashboard screen showing financial overview.
 * 
 * Features:
 * - Total balance card
 * - Income/expense summary
 * - Net savings and savings rate
 * - Recent transactions list
 * - Budget alerts
 * - Goals progress summary
 * - Pull-to-refresh
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DashboardScreen(
    navController: NavController,
    viewModel: DashboardViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val totalBalance by viewModel.totalBalance.collectAsState()
    val recentTransactions by viewModel.recentTransactions.collectAsState()
    val budgetAlerts by viewModel.budgetAlerts.collectAsState()
    val goalsSummary by viewModel.goalsSummary.collectAsState()
    val monthlyIncome by viewModel.monthlyIncome.collectAsState()
    val monthlyExpenses by viewModel.monthlyExpenses.collectAsState()
    val netSavings by viewModel.getNetSavings().collectAsState()
    val savingsRate by viewModel.getSavingsRate().collectAsState()
    
    val snackbarHostState = remember { SnackbarHostState() }
    
    // Show error message
    LaunchedEffect(uiState) {
        if (uiState is DashboardViewModel.DashboardUiState.Error) {
            snackbarHostState.showSnackbar(
                message = (uiState as DashboardViewModel.DashboardUiState.Error).message
            )
            viewModel.clearError()
        }
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Dashboard") },
                actions = {
                    IconButton(onClick = { navController.navigate("profile") }) {
                        Icon(Icons.Filled.Person, contentDescription = "Profile")
                    }
                    IconButton(onClick = { navController.navigate("settings") }) {
                        Icon(Icons.Filled.Settings, contentDescription = "Settings")
                    }
                }
            )
        },
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { paddingValues ->
        if (uiState is DashboardViewModel.DashboardUiState.Loading) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator()
            }
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Total balance card
                item {
                    TotalBalanceCard(
                        balance = totalBalance,
                        onViewDetails = { navController.navigate("accounts") }
                    )
                }
                
                // Income/Expense/Savings summary
                item {
                    FinancialSummaryCard(
                        income = monthlyIncome,
                        expenses = monthlyExpenses,
                        savings = netSavings,
                        savingsRate = savingsRate
                    )
                }
                
                // Budget alerts (if any)
                if (budgetAlerts.isNotEmpty()) {
                    item {
                        BudgetAlertsCard(
                            alerts = budgetAlerts,
                            onViewBudgets = { navController.navigate("budgets") }
                        )
                    }
                }
                
                // Goals summary
                goalsSummary?.let { summary ->
                    item {
                        GoalsSummaryCard(
                            summary = summary,
                            onViewGoals = { navController.navigate("goals") }
                        )
                    }
                }
                
                // Recent transactions
                item {
                    Text(
                        text = "Recent Transactions",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold
                    )
                }
                
                if (recentTransactions.isEmpty()) {
                    item {
                        EmptyTransactionsCard(
                            onAddTransaction = { navController.navigate("transactions") }
                        )
                    }
                } else {
                    items(recentTransactions) { transaction ->
                        TransactionItem(
                            transaction = transaction,
                            onClick = { 
                                navController.navigate("transaction/${transaction.id}") 
                            }
                        )
                    }
                    
                    item {
                        TextButton(
                            onClick = { navController.navigate("transactions") },
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text("View All Transactions")
                            Icon(
                                Icons.Filled.ArrowForward,
                                contentDescription = null,
                                modifier = Modifier.padding(start = 4.dp)
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun TotalBalanceCard(
    balance: BigDecimal,
    onViewDetails: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.primaryContainer
        )
    ) {
        Column(
            modifier = Modifier.padding(20.dp)
        ) {
            Text(
                text = "Total Balance",
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onPrimaryContainer
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = formatCurrency(balance),
                style = MaterialTheme.typography.displaySmall,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onPrimaryContainer
            )
            Spacer(modifier = Modifier.height(12.dp))
            TextButton(
                onClick = onViewDetails,
                colors = ButtonDefaults.textButtonColors(
                    contentColor = MaterialTheme.colorScheme.primary
                )
            ) {
                Text("View Accounts")
                Icon(
                    Icons.Filled.ArrowForward,
                    contentDescription = null,
                    modifier = Modifier.padding(start = 4.dp)
                )
            }
        }
    }
}

@Composable
private fun FinancialSummaryCard(
    income: BigDecimal,
    expenses: BigDecimal,
    savings: BigDecimal,
    savingsRate: Double
) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = "This Month",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(16.dp))
            
            // Income
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        Icons.Filled.TrendingUp,
                        contentDescription = null,
                        tint = Income
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Income")
                }
                Text(
                    text = formatCurrency(income),
                    fontWeight = FontWeight.Bold,
                    color = Income
                )
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
            // Expenses
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        Icons.Filled.TrendingDown,
                        contentDescription = null,
                        tint = Expense
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Expenses")
                }
                Text(
                    text = formatCurrency(expenses),
                    fontWeight = FontWeight.Bold,
                    color = Expense
                )
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            HorizontalDivider()
            Spacer(modifier = Modifier.height(12.dp))
            
            // Net Savings
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        Icons.Filled.Savings,
                        contentDescription = null,
                        tint = Savings
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Net Savings", fontWeight = FontWeight.Bold)
                }
                Column(horizontalAlignment = Alignment.End) {
                    Text(
                        text = formatCurrency(savings),
                        fontWeight = FontWeight.Bold,
                        color = Savings
                    )
                    Text(
                        text = "${String.format("%.1f", savingsRate)}% saved",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
    }
}

@Composable
private fun BudgetAlertsCard(
    alerts: List<BudgetRepository.BudgetAlert>,
    onViewBudgets: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.errorContainer
        )
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        Icons.Filled.Warning,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.error
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "Budget Alerts",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onErrorContainer
                    )
                }
                Badge {
                    Text(alerts.size.toString())
                }
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
            alerts.take(3).forEach { alert ->
                Text(
                    text = "• ${alert.budgetName}: ${alert.message}",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onErrorContainer,
                    modifier = Modifier.padding(vertical = 4.dp)
                )
            }
            
            if (alerts.size > 3) {
                Text(
                    text = "And ${alerts.size - 3} more...",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onErrorContainer,
                    modifier = Modifier.padding(top = 4.dp)
                )
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            TextButton(
                onClick = onViewBudgets,
                colors = ButtonDefaults.textButtonColors(
                    contentColor = MaterialTheme.colorScheme.error
                )
            ) {
                Text("View Budgets")
            }
        }
    }
}

@Composable
private fun GoalsSummaryCard(
    summary: com.wealthwise.android.data.repository.GoalRepository.GoalProgressSummary,
    onViewGoals: () -> Unit
) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Financial Goals",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
                Icon(Icons.Filled.EmojiEvents, contentDescription = null)
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceAround
            ) {
                GoalStatItem(
                    label = "Active",
                    value = summary.activeGoals.toString()
                )
                GoalStatItem(
                    label = "Completed",
                    value = summary.completedGoals.toString()
                )
                GoalStatItem(
                    label = "Progress",
                    value = "${String.format("%.0f", summary.averageProgress)}%"
                )
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
            TextButton(
                onClick = onViewGoals,
                modifier = Modifier.align(Alignment.End)
            ) {
                Text("View Goals")
                Icon(
                    Icons.Filled.ArrowForward,
                    contentDescription = null,
                    modifier = Modifier.padding(start = 4.dp)
                )
            }
        }
    }
}

@Composable
private fun GoalStatItem(label: String, value: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(
            text = value,
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.primary
        )
        Text(
            text = label,
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
private fun TransactionItem(
    transaction: Transaction,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        onClick = onClick
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = transaction.category,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Medium
                )
                transaction.description?.let { desc ->
                    Text(
                        text = desc,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                Text(
                    text = transaction.date.toLocalDate().toString(),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            
            Text(
                text = formatCurrency(transaction.getSignedAmount()),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = when (transaction.type) {
                    Transaction.TransactionType.CREDIT -> Income
                    Transaction.TransactionType.DEBIT -> Expense
                }
            )
        }
    }
}

@Composable
private fun EmptyTransactionsCard(onAddTransaction: () -> Unit) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(32.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                Icons.Filled.Receipt,
                contentDescription = null,
                modifier = Modifier.size(48.dp),
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.height(16.dp))
            Text(
                text = "No transactions yet",
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.height(8.dp))
            Button(onClick = onAddTransaction) {
                Text("Add Transaction")
            }
        }
    }
}

private fun formatCurrency(amount: BigDecimal): String {
    val formatter = NumberFormat.getCurrencyInstance(Locale("en", "IN"))
    formatter.currency = Currency.getInstance("INR")
    return formatter.format(amount)
}
