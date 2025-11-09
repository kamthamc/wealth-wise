package com.wealthwise.android.features.budgets

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.wealthwise.android.data.model.Budget
import com.wealthwise.android.data.model.BudgetPeriod
import java.math.BigDecimal
import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BudgetsScreen(
    navController: NavController,
    viewModel: BudgetsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val budgets by viewModel.budgets.collectAsState()
    val selectedPeriod by viewModel.selectedPeriod.collectAsState()
    val showActive by viewModel.showActive.collectAsState()
    
    var showAddDialog by remember { mutableStateOf(false) }
    var showEditDialog by remember { mutableStateOf<Budget?>(null) }
    var showDeleteDialog by remember { mutableStateOf<Budget?>(null) }
    
    val snackbarHostState = remember { SnackbarHostState() }
    
    // Handle error messages
    LaunchedEffect(uiState) {
        if (uiState is BudgetsUiState.Error) {
            snackbarHostState.showSnackbar(
                message = (uiState as BudgetsUiState.Error).message,
                duration = SnackbarDuration.Short
            )
            viewModel.clearError()
        }
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Budgets") },
                actions = {
                    IconButton(onClick = { viewModel.toggleShowActive() }) {
                        Icon(
                            imageVector = if (showActive) Icons.Filled.Visibility else Icons.Filled.VisibilityOff,
                            contentDescription = if (showActive) "Show all" else "Show active only"
                        )
                    }
                    IconButton(onClick = { navController.navigate("settings") }) {
                        Icon(
                            imageVector = Icons.Filled.Settings,
                            contentDescription = "Settings"
                        )
                    }
                }
            )
        },
        floatingActionButton = {
            FloatingActionButton(
                onClick = { showAddDialog = true }
            ) {
                Icon(Icons.Filled.Add, contentDescription = "Add budget")
            }
        },
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Period filter chips
            PeriodFilterChips(
                selectedPeriod = selectedPeriod,
                onPeriodSelected = { viewModel.filterByPeriod(it) },
                modifier = Modifier.padding(16.dp)
            )
            
            // Budgets list
            when (val state = uiState) {
                is BudgetsUiState.Loading -> {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator()
                    }
                }
                
                is BudgetsUiState.Empty -> {
                    EmptyBudgetsState(
                        modifier = Modifier.fillMaxSize(),
                        onAddBudget = { showAddDialog = true }
                    )
                }
                
                is BudgetsUiState.Success, is BudgetsUiState.Error -> {
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(budgets, key = { it.id }) { budget ->
                            BudgetCard(
                                budget = budget,
                                onEdit = { showEditDialog = budget },
                                onDelete = { showDeleteDialog = budget },
                                onClick = {
                                    navController.navigate("budget/${budget.id}")
                                }
                            )
                        }
                    }
                }
            }
        }
    }
    
    // Add Budget Dialog
    if (showAddDialog) {
        AddBudgetDialog(
            onDismiss = { showAddDialog = false },
            onConfirm = { name, amount, period, categories ->
                viewModel.createBudget(name, amount, period, categories)
                showAddDialog = false
            }
        )
    }
    
    // Edit Budget Dialog
    showEditDialog?.let { budget ->
        EditBudgetDialog(
            budget = budget,
            onDismiss = { showEditDialog = null },
            onConfirm = { name, amount, period, categories ->
                viewModel.updateBudget(budget.id, name, amount, period, categories)
                showEditDialog = null
            }
        )
    }
    
    // Delete Confirmation Dialog
    showDeleteDialog?.let { budget ->
        AlertDialog(
            onDismissRequest = { showDeleteDialog = null },
            title = { Text("Delete Budget") },
            text = { Text("Are you sure you want to delete '${budget.name}'? This action cannot be undone.") },
            confirmButton = {
                Button(
                    onClick = {
                        viewModel.deleteBudget(budget.id)
                        showDeleteDialog = null
                    },
                    colors = ButtonDefaults.buttonColors(
                        containerColor = MaterialTheme.colorScheme.error
                    )
                ) {
                    Text("Delete")
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteDialog = null }) {
                    Text("Cancel")
                }
            }
        )
    }
}

@Composable
private fun PeriodFilterChips(
    selectedPeriod: BudgetPeriod?,
    onPeriodSelected: (BudgetPeriod?) -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        FilterChip(
            selected = selectedPeriod == null,
            onClick = { onPeriodSelected(null) },
            label = { Text("All") }
        )
        
        BudgetPeriod.values().forEach { period ->
            FilterChip(
                selected = selectedPeriod == period,
                onClick = { onPeriodSelected(period) },
                label = { Text(period.name) }
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun BudgetCard(
    budget: Budget,
    onEdit: () -> Unit,
    onDelete: () -> Unit,
    onClick: () -> Unit
) {
    var showMenu by remember { mutableStateOf(false) }
    val percentage = budget.getPercentage()
    val remaining = budget.getRemaining()
    val daysRemaining = getDaysRemaining(budget.endDate)
    
    val progressColor = when {
        budget.isExceeded() -> MaterialTheme.colorScheme.error
        budget.isApproachingLimit() -> Color(0xFFFFA726) // Warning color
        else -> MaterialTheme.colorScheme.primary
    }
    
    val alertIcon = when {
        budget.isExceeded() -> Icons.Filled.Error
        budget.isApproachingLimit() -> Icons.Filled.Warning
        else -> null
    }
    
    Card(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            // Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = budget.name,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Medium
                    )
                    Text(
                        text = budget.period.name,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                
                // Alert badge
                alertIcon?.let {
                    Icon(
                        imageVector = it,
                        contentDescription = null,
                        tint = if (budget.isExceeded()) 
                            MaterialTheme.colorScheme.error
                        else 
                            Color(0xFFFFA726),
                        modifier = Modifier.size(24.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                }
                
                // More menu
                Box {
                    IconButton(onClick = { showMenu = true }) {
                        Icon(Icons.Filled.MoreVert, contentDescription = "More options")
                    }
                    
                    DropdownMenu(
                        expanded = showMenu,
                        onDismissRequest = { showMenu = false }
                    ) {
                        DropdownMenuItem(
                            text = { Text("Edit") },
                            onClick = {
                                onEdit()
                                showMenu = false
                            },
                            leadingIcon = {
                                Icon(Icons.Filled.Edit, contentDescription = null)
                            }
                        )
                        DropdownMenuItem(
                            text = { Text("Delete") },
                            onClick = {
                                onDelete()
                                showMenu = false
                            },
                            leadingIcon = {
                                Icon(
                                    Icons.Filled.Delete,
                                    contentDescription = null,
                                    tint = MaterialTheme.colorScheme.error
                                )
                            }
                        )
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
            // Amount spent vs budget
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = formatCurrency(budget.spent),
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                    color = progressColor
                )
                Text(
                    text = "of ${formatCurrency(budget.amount)}",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            // Progress bar
            LinearProgressIndicator(
                progress = (percentage / 100f).coerceIn(0f, 1f),
                modifier = Modifier
                    .fillMaxWidth()
                    .height(8.dp),
                color = progressColor,
                trackColor = MaterialTheme.colorScheme.surfaceVariant
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            // Progress info
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = "${String.format("%.1f", percentage)}% used",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Text(
                    text = if (remaining >= BigDecimal.ZERO) {
                        "${formatCurrency(remaining)} left"
                    } else {
                        "${formatCurrency(remaining.abs())} over"
                    },
                    style = MaterialTheme.typography.bodySmall,
                    color = if (remaining >= BigDecimal.ZERO) 
                        MaterialTheme.colorScheme.onSurfaceVariant
                    else 
                        MaterialTheme.colorScheme.error
                )
            }
            
            // Days remaining
            if (daysRemaining >= 0) {
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "$daysRemaining days remaining",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            
            // Categories
            if (budget.categories.isNotEmpty()) {
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "Categories: ${budget.categories.joinToString(", ")}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
private fun EmptyBudgetsState(
    modifier: Modifier = Modifier,
    onAddBudget: () -> Unit
) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            imageVector = Icons.Filled.AccountBalanceWallet,
            contentDescription = null,
            modifier = Modifier.size(80.dp),
            tint = MaterialTheme.colorScheme.primary
        )
        Spacer(modifier = Modifier.height(16.dp))
        Text(
            text = "No budgets yet",
            style = MaterialTheme.typography.titleLarge
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = "Create a budget to track your spending",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(modifier = Modifier.height(24.dp))
        Button(onClick = onAddBudget) {
            Icon(Icons.Filled.Add, contentDescription = null)
            Spacer(modifier = Modifier.width(8.dp))
            Text("Create Budget")
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun AddBudgetDialog(
    onDismiss: () -> Unit,
    onConfirm: (name: String, amount: BigDecimal, period: BudgetPeriod, categories: List<String>) -> Unit
) {
    var name by remember { mutableStateOf("") }
    var amount by remember { mutableStateOf("") }
    var period by remember { mutableStateOf(BudgetPeriod.MONTHLY) }
    var selectedCategories by remember { mutableStateOf(setOf<String>()) }
    var periodExpanded by remember { mutableStateOf(false) }
    var showCategoryDialog by remember { mutableStateOf(false) }
    
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Create Budget") },
        text = {
            Column(
                modifier = Modifier.fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    label = { Text("Budget Name") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )
                
                OutlinedTextField(
                    value = amount,
                    onValueChange = { amount = it },
                    label = { Text("Amount") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                    prefix = { Text("₹") }
                )
                
                ExposedDropdownMenuBox(
                    expanded = periodExpanded,
                    onExpandedChange = { periodExpanded = it }
                ) {
                    OutlinedTextField(
                        value = period.name,
                        onValueChange = {},
                        readOnly = true,
                        label = { Text("Period") },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = periodExpanded) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .menuAnchor()
                    )
                    
                    ExposedDropdownMenu(
                        expanded = periodExpanded,
                        onDismissRequest = { periodExpanded = false }
                    ) {
                        BudgetPeriod.values().forEach { budgetPeriod ->
                            DropdownMenuItem(
                                text = { Text(budgetPeriod.name) },
                                onClick = {
                                    period = budgetPeriod
                                    periodExpanded = false
                                }
                            )
                        }
                    }
                }
                
                OutlinedButton(
                    onClick = { showCategoryDialog = true },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text(
                        text = if (selectedCategories.isEmpty()) 
                            "Select Categories (Optional)" 
                        else 
                            "${selectedCategories.size} categories selected"
                    )
                }
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    val budgetAmount = amount.toBigDecimalOrNull() ?: BigDecimal.ZERO
                    onConfirm(name, budgetAmount, period, selectedCategories.toList())
                },
                enabled = name.isNotBlank() && amount.isNotBlank()
            ) {
                Text("Create")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
    
    if (showCategoryDialog) {
        CategorySelectionDialog(
            selectedCategories = selectedCategories,
            onDismiss = { showCategoryDialog = false },
            onConfirm = { categories ->
                selectedCategories = categories
                showCategoryDialog = false
            }
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun EditBudgetDialog(
    budget: Budget,
    onDismiss: () -> Unit,
    onConfirm: (name: String, amount: BigDecimal, period: BudgetPeriod, categories: List<String>) -> Unit
) {
    var name by remember { mutableStateOf(budget.name) }
    var amount by remember { mutableStateOf(budget.amount.toString()) }
    var period by remember { mutableStateOf(budget.period) }
    var selectedCategories by remember { mutableStateOf(budget.categories.toSet()) }
    var periodExpanded by remember { mutableStateOf(false) }
    var showCategoryDialog by remember { mutableStateOf(false) }
    
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Edit Budget") },
        text = {
            Column(
                modifier = Modifier.fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    label = { Text("Budget Name") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )
                
                OutlinedTextField(
                    value = amount,
                    onValueChange = { amount = it },
                    label = { Text("Amount") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                    prefix = { Text("₹") }
                )
                
                ExposedDropdownMenuBox(
                    expanded = periodExpanded,
                    onExpandedChange = { periodExpanded = it }
                ) {
                    OutlinedTextField(
                        value = period.name,
                        onValueChange = {},
                        readOnly = true,
                        label = { Text("Period") },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = periodExpanded) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .menuAnchor()
                    )
                    
                    ExposedDropdownMenu(
                        expanded = periodExpanded,
                        onDismissRequest = { periodExpanded = false }
                    ) {
                        BudgetPeriod.values().forEach { budgetPeriod ->
                            DropdownMenuItem(
                                text = { Text(budgetPeriod.name) },
                                onClick = {
                                    period = budgetPeriod
                                    periodExpanded = false
                                }
                            )
                        }
                    }
                }
                
                OutlinedButton(
                    onClick = { showCategoryDialog = true },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text(
                        text = if (selectedCategories.isEmpty()) 
                            "Select Categories (Optional)" 
                        else 
                            "${selectedCategories.size} categories selected"
                    )
                }
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    val budgetAmount = amount.toBigDecimalOrNull() ?: BigDecimal.ZERO
                    onConfirm(name, budgetAmount, period, selectedCategories.toList())
                },
                enabled = name.isNotBlank() && amount.isNotBlank()
            ) {
                Text("Save")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
    
    if (showCategoryDialog) {
        CategorySelectionDialog(
            selectedCategories = selectedCategories,
            onDismiss = { showCategoryDialog = false },
            onConfirm = { categories ->
                selectedCategories = categories
                showCategoryDialog = false
            }
        )
    }
}

@Composable
private fun CategorySelectionDialog(
    selectedCategories: Set<String>,
    onDismiss: () -> Unit,
    onConfirm: (Set<String>) -> Unit
) {
    var selected by remember { mutableStateOf(selectedCategories) }
    
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Select Categories") },
        text = {
            LazyColumn {
                items(getCommonCategories()) { category ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 4.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Checkbox(
                            checked = selected.contains(category),
                            onCheckedChange = { isChecked ->
                                selected = if (isChecked) {
                                    selected + category
                                } else {
                                    selected - category
                                }
                            }
                        )
                        Text(
                            text = category,
                            modifier = Modifier.padding(start = 8.dp)
                        )
                    }
                }
            }
        },
        confirmButton = {
            Button(onClick = { onConfirm(selected) }) {
                Text("Done")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

private fun getCommonCategories() = listOf(
    "Food & Dining",
    "Shopping",
    "Transportation",
    "Bills & Utilities",
    "Entertainment",
    "Healthcare",
    "Education",
    "Travel",
    "Other"
)

private fun getDaysRemaining(endDate: Date): Long {
    val today = Calendar.getInstance().timeInMillis
    val end = endDate.time
    return (end - today) / (1000 * 60 * 60 * 24)
}

private fun formatCurrency(amount: BigDecimal): String {
    val formatter = NumberFormat.getCurrencyInstance(Locale("en", "IN"))
    formatter.currency = Currency.getInstance("INR")
    return formatter.format(amount)
}
