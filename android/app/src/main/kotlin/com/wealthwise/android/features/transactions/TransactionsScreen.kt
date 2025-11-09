package com.wealthwise.android.features.transactions

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
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
import com.wealthwise.android.data.model.Account
import com.wealthwise.android.data.model.AccountType
import com.wealthwise.android.data.model.Transaction
import com.wealthwise.android.data.model.TransactionType
import java.math.BigDecimal
import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TransactionsScreen(
    navController: NavController,
    viewModel: TransactionsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val transactions by viewModel.transactions.collectAsState()
    val accounts by viewModel.accounts.collectAsState()
    val selectedAccount by viewModel.selectedAccount.collectAsState()
    val selectedType by viewModel.selectedType.collectAsState()
    val selectedCategory by viewModel.selectedCategory.collectAsState()
    val searchQuery by viewModel.searchQuery.collectAsState()
    
    var showAddDialog by remember { mutableStateOf(false) }
    var showEditDialog by remember { mutableStateOf<Transaction?>(null) }
    var showDeleteDialog by remember { mutableStateOf<Transaction?>(null) }
    var showFilters by remember { mutableStateOf(false) }
    
    val snackbarHostState = remember { SnackbarHostState() }
    
    // Handle error messages
    LaunchedEffect(uiState) {
        if (uiState is TransactionsUiState.Error) {
            snackbarHostState.showSnackbar(
                message = (uiState as TransactionsUiState.Error).message,
                duration = SnackbarDuration.Short
            )
            viewModel.clearError()
        }
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Transactions") },
                actions = {
                    IconButton(onClick = { showFilters = !showFilters }) {
                        Icon(
                            imageVector = Icons.Filled.FilterList,
                            contentDescription = "Filter"
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
                Icon(Icons.Filled.Add, contentDescription = "Add transaction")
            }
        },
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Search bar
            SearchBar(
                query = searchQuery,
                onQueryChange = { viewModel.updateSearchQuery(it) },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp)
            )
            
            // Filter chips
            if (showFilters) {
                FilterChips(
                    selectedAccount = selectedAccount,
                    selectedType = selectedType,
                    selectedCategory = selectedCategory,
                    accounts = accounts,
                    onAccountSelected = { viewModel.filterByAccount(it) },
                    onTypeSelected = { viewModel.filterByType(it) },
                    onCategorySelected = { viewModel.filterByCategory(it) },
                    onClearFilters = { viewModel.clearFilters() },
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                )
            }
            
            // Transactions list
            when (val state = uiState) {
                is TransactionsUiState.Loading -> {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator()
                    }
                }
                
                is TransactionsUiState.Empty -> {
                    EmptyTransactionsState(
                        modifier = Modifier.fillMaxSize(),
                        onAddTransaction = { showAddDialog = true }
                    )
                }
                
                is TransactionsUiState.Success, is TransactionsUiState.Error -> {
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(transactions, key = { it.id }) { transaction ->
                            val account = accounts.find { it.id == transaction.accountId }
                            TransactionCard(
                                transaction = transaction,
                                account = account,
                                onEdit = { showEditDialog = transaction },
                                onDelete = { showDeleteDialog = transaction },
                                onClick = {
                                    navController.navigate("transaction/${transaction.id}")
                                }
                            )
                        }
                    }
                }
            }
        }
    }
    
    // Add Transaction Dialog
    if (showAddDialog) {
        AddTransactionDialog(
            accounts = accounts,
            onDismiss = { showAddDialog = false },
            onConfirm = { accountId, amount, type, category, description, date ->
                viewModel.createTransaction(accountId, amount, type, category, description, date)
                showAddDialog = false
            }
        )
    }
    
    // Edit Transaction Dialog
    showEditDialog?.let { transaction ->
        EditTransactionDialog(
            transaction = transaction,
            accounts = accounts,
            onDismiss = { showEditDialog = null },
            onConfirm = { accountId, amount, type, category, description ->
                viewModel.updateTransaction(
                    transaction.id,
                    accountId,
                    amount,
                    type,
                    category,
                    description
                )
                showEditDialog = null
            }
        )
    }
    
    // Delete Confirmation Dialog
    showDeleteDialog?.let { transaction ->
        AlertDialog(
            onDismissRequest = { showDeleteDialog = null },
            title = { Text("Delete Transaction") },
            text = { Text("Are you sure you want to delete this transaction? This action cannot be undone.") },
            confirmButton = {
                Button(
                    onClick = {
                        viewModel.deleteTransaction(transaction.id)
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
private fun SearchBar(
    query: String,
    onQueryChange: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    OutlinedTextField(
        value = query,
        onValueChange = onQueryChange,
        modifier = modifier,
        placeholder = { Text("Search transactions...") },
        leadingIcon = {
            Icon(Icons.Filled.Search, contentDescription = null)
        },
        trailingIcon = {
            if (query.isNotEmpty()) {
                IconButton(onClick = { onQueryChange("") }) {
                    Icon(Icons.Filled.Clear, contentDescription = "Clear")
                }
            }
        },
        singleLine = true
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun FilterChips(
    selectedAccount: Account?,
    selectedType: TransactionType?,
    selectedCategory: String?,
    accounts: List<Account>,
    onAccountSelected: (Account?) -> Unit,
    onTypeSelected: (TransactionType?) -> Unit,
    onCategorySelected: (String?) -> Unit,
    onClearFilters: () -> Unit,
    modifier: Modifier = Modifier
) {
    var showAccountMenu by remember { mutableStateOf(false) }
    var showTypeMenu by remember { mutableStateOf(false) }
    var showCategoryMenu by remember { mutableStateOf(false) }
    
    LazyRow(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        // Account filter
        item {
            FilterChip(
                selected = selectedAccount != null,
                onClick = { showAccountMenu = true },
                label = { 
                    Text(selectedAccount?.name ?: "All Accounts") 
                },
                leadingIcon = {
                    Icon(
                        imageVector = Icons.Filled.AccountBalance,
                        contentDescription = null,
                        modifier = Modifier.size(18.dp)
                    )
                }
            )
            
            DropdownMenu(
                expanded = showAccountMenu,
                onDismissRequest = { showAccountMenu = false }
            ) {
                DropdownMenuItem(
                    text = { Text("All Accounts") },
                    onClick = {
                        onAccountSelected(null)
                        showAccountMenu = false
                    }
                )
                accounts.forEach { account ->
                    DropdownMenuItem(
                        text = { Text(account.name) },
                        onClick = {
                            onAccountSelected(account)
                            showAccountMenu = false
                        }
                    )
                }
            }
        }
        
        // Type filter
        item {
            FilterChip(
                selected = selectedType != null,
                onClick = { showTypeMenu = true },
                label = { 
                    Text(selectedType?.name ?: "All Types") 
                },
                leadingIcon = {
                    Icon(
                        imageVector = if (selectedType == TransactionType.CREDIT) 
                            Icons.Filled.TrendingUp else Icons.Filled.SwapVert,
                        contentDescription = null,
                        modifier = Modifier.size(18.dp)
                    )
                }
            )
            
            DropdownMenu(
                expanded = showTypeMenu,
                onDismissRequest = { showTypeMenu = false }
            ) {
                DropdownMenuItem(
                    text = { Text("All Types") },
                    onClick = {
                        onTypeSelected(null)
                        showTypeMenu = false
                    }
                )
                TransactionType.values().forEach { type ->
                    DropdownMenuItem(
                        text = { Text(type.name) },
                        onClick = {
                            onTypeSelected(type)
                            showTypeMenu = false
                        }
                    )
                }
            }
        }
        
        // Category filter
        item {
            FilterChip(
                selected = selectedCategory != null,
                onClick = { showCategoryMenu = true },
                label = { 
                    Text(selectedCategory ?: "All Categories") 
                },
                leadingIcon = {
                    Icon(
                        imageVector = Icons.Filled.Category,
                        contentDescription = null,
                        modifier = Modifier.size(18.dp)
                    )
                }
            )
            
            DropdownMenu(
                expanded = showCategoryMenu,
                onDismissRequest = { showCategoryMenu = false }
            ) {
                DropdownMenuItem(
                    text = { Text("All Categories") },
                    onClick = {
                        onCategorySelected(null)
                        showCategoryMenu = false
                    }
                )
                getCommonCategories().forEach { category ->
                    DropdownMenuItem(
                        text = { Text(category) },
                        onClick = {
                            onCategorySelected(category)
                            showCategoryMenu = false
                        }
                    )
                }
            }
        }
        
        // Clear filters button
        if (selectedAccount != null || selectedType != null || selectedCategory != null) {
            item {
                FilterChip(
                    selected = false,
                    onClick = onClearFilters,
                    label = { Text("Clear") },
                    leadingIcon = {
                        Icon(
                            imageVector = Icons.Filled.Clear,
                            contentDescription = null,
                            modifier = Modifier.size(18.dp)
                        )
                    }
                )
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun TransactionCard(
    transaction: Transaction,
    account: Account?,
    onEdit: () -> Unit,
    onDelete: () -> Unit,
    onClick: () -> Unit
) {
    var showMenu by remember { mutableStateOf(false) }
    
    Card(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Transaction type icon
            Icon(
                imageVector = if (transaction.type == TransactionType.CREDIT)
                    Icons.Filled.TrendingUp
                else
                    Icons.Filled.TrendingDown,
                contentDescription = null,
                modifier = Modifier.size(40.dp),
                tint = if (transaction.type == TransactionType.CREDIT)
                    MaterialTheme.colorScheme.primary
                else
                    MaterialTheme.colorScheme.error
            )
            
            Spacer(modifier = Modifier.width(16.dp))
            
            // Transaction info
            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = transaction.category,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Medium
                )
                if (transaction.description.isNotBlank()) {
                    Text(
                        text = transaction.description,
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    account?.let {
                        Text(
                            text = it.name,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    Text(
                        text = "•",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = formatDate(transaction.date),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
            
            // Amount
            Column(
                horizontalAlignment = Alignment.End
            ) {
                Text(
                    text = formatCurrency(transaction.getSignedAmount()),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = if (transaction.type == TransactionType.CREDIT)
                        MaterialTheme.colorScheme.primary
                    else
                        MaterialTheme.colorScheme.error
                )
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
    }
}

@Composable
private fun EmptyTransactionsState(
    modifier: Modifier = Modifier,
    onAddTransaction: () -> Unit
) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            imageVector = Icons.Filled.Receipt,
            contentDescription = null,
            modifier = Modifier.size(80.dp),
            tint = MaterialTheme.colorScheme.primary
        )
        Spacer(modifier = Modifier.height(16.dp))
        Text(
            text = "No transactions yet",
            style = MaterialTheme.typography.titleLarge
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = "Add your first transaction to start tracking",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(modifier = Modifier.height(24.dp))
        Button(onClick = onAddTransaction) {
            Icon(Icons.Filled.Add, contentDescription = null)
            Spacer(modifier = Modifier.width(8.dp))
            Text("Add Transaction")
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun AddTransactionDialog(
    accounts: List<Account>,
    onDismiss: () -> Unit,
    onConfirm: (accountId: String, amount: BigDecimal, type: TransactionType, category: String, description: String, date: Date) -> Unit
) {
    var selectedAccount by remember { mutableStateOf<Account?>(accounts.firstOrNull()) }
    var amount by remember { mutableStateOf("") }
    var type by remember { mutableStateOf(TransactionType.DEBIT) }
    var category by remember { mutableStateOf("") }
    var description by remember { mutableStateOf("") }
    var accountExpanded by remember { mutableStateOf(false) }
    var categoryExpanded by remember { mutableStateOf(false) }
    
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Add Transaction") },
        text = {
            Column(
                modifier = Modifier.fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                // Account dropdown
                ExposedDropdownMenuBox(
                    expanded = accountExpanded,
                    onExpandedChange = { accountExpanded = it }
                ) {
                    OutlinedTextField(
                        value = selectedAccount?.name ?: "Select account",
                        onValueChange = {},
                        readOnly = true,
                        label = { Text("Account") },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = accountExpanded) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .menuAnchor()
                    )
                    
                    ExposedDropdownMenu(
                        expanded = accountExpanded,
                        onDismissRequest = { accountExpanded = false }
                    ) {
                        accounts.forEach { account ->
                            DropdownMenuItem(
                                text = { Text(account.name) },
                                onClick = {
                                    selectedAccount = account
                                    accountExpanded = false
                                }
                            )
                        }
                    }
                }
                
                // Amount
                OutlinedTextField(
                    value = amount,
                    onValueChange = { amount = it },
                    label = { Text("Amount") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                    prefix = { Text("₹") }
                )
                
                // Type radio buttons
                Column {
                    Text("Type", style = MaterialTheme.typography.bodySmall)
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        TransactionType.values().forEach { transactionType ->
                            Row(
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                RadioButton(
                                    selected = type == transactionType,
                                    onClick = { type = transactionType }
                                )
                                Text(transactionType.name)
                            }
                        }
                    }
                }
                
                // Category dropdown
                ExposedDropdownMenuBox(
                    expanded = categoryExpanded,
                    onExpandedChange = { categoryExpanded = it }
                ) {
                    OutlinedTextField(
                        value = category,
                        onValueChange = { category = it },
                        label = { Text("Category") },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = categoryExpanded) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .menuAnchor()
                    )
                    
                    ExposedDropdownMenu(
                        expanded = categoryExpanded,
                        onDismissRequest = { categoryExpanded = false }
                    ) {
                        getCommonCategories().forEach { cat ->
                            DropdownMenuItem(
                                text = { Text(cat) },
                                onClick = {
                                    category = cat
                                    categoryExpanded = false
                                }
                            )
                        }
                    }
                }
                
                // Description
                OutlinedTextField(
                    value = description,
                    onValueChange = { description = it },
                    label = { Text("Description (Optional)") },
                    modifier = Modifier.fillMaxWidth(),
                    maxLines = 3
                )
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    selectedAccount?.let { account ->
                        val transactionAmount = amount.toBigDecimalOrNull() ?: BigDecimal.ZERO
                        onConfirm(
                            account.id,
                            transactionAmount,
                            type,
                            category,
                            description,
                            Date()
                        )
                    }
                },
                enabled = selectedAccount != null && amount.isNotBlank() && category.isNotBlank()
            ) {
                Text("Add")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun EditTransactionDialog(
    transaction: Transaction,
    accounts: List<Account>,
    onDismiss: () -> Unit,
    onConfirm: (accountId: String, amount: BigDecimal, type: TransactionType, category: String, description: String) -> Unit
) {
    var selectedAccount by remember { 
        mutableStateOf(accounts.find { it.id == transaction.accountId } ?: accounts.firstOrNull()) 
    }
    var amount by remember { mutableStateOf(transaction.amount.toString()) }
    var type by remember { mutableStateOf(transaction.type) }
    var category by remember { mutableStateOf(transaction.category) }
    var description by remember { mutableStateOf(transaction.description) }
    var accountExpanded by remember { mutableStateOf(false) }
    var categoryExpanded by remember { mutableStateOf(false) }
    
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Edit Transaction") },
        text = {
            Column(
                modifier = Modifier.fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                // Account dropdown
                ExposedDropdownMenuBox(
                    expanded = accountExpanded,
                    onExpandedChange = { accountExpanded = it }
                ) {
                    OutlinedTextField(
                        value = selectedAccount?.name ?: "Select account",
                        onValueChange = {},
                        readOnly = true,
                        label = { Text("Account") },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = accountExpanded) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .menuAnchor()
                    )
                    
                    ExposedDropdownMenu(
                        expanded = accountExpanded,
                        onDismissRequest = { accountExpanded = false }
                    ) {
                        accounts.forEach { account ->
                            DropdownMenuItem(
                                text = { Text(account.name) },
                                onClick = {
                                    selectedAccount = account
                                    accountExpanded = false
                                }
                            )
                        }
                    }
                }
                
                // Amount
                OutlinedTextField(
                    value = amount,
                    onValueChange = { amount = it },
                    label = { Text("Amount") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                    prefix = { Text("₹") }
                )
                
                // Type radio buttons
                Column {
                    Text("Type", style = MaterialTheme.typography.bodySmall)
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        TransactionType.values().forEach { transactionType ->
                            Row(
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                RadioButton(
                                    selected = type == transactionType,
                                    onClick = { type = transactionType }
                                )
                                Text(transactionType.name)
                            }
                        }
                    }
                }
                
                // Category dropdown
                ExposedDropdownMenuBox(
                    expanded = categoryExpanded,
                    onExpandedChange = { categoryExpanded = it }
                ) {
                    OutlinedTextField(
                        value = category,
                        onValueChange = { category = it },
                        label = { Text("Category") },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = categoryExpanded) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .menuAnchor()
                    )
                    
                    ExposedDropdownMenu(
                        expanded = categoryExpanded,
                        onDismissRequest = { categoryExpanded = false }
                    ) {
                        getCommonCategories().forEach { cat ->
                            DropdownMenuItem(
                                text = { Text(cat) },
                                onClick = {
                                    category = cat
                                    categoryExpanded = false
                                }
                            )
                        }
                    }
                }
                
                // Description
                OutlinedTextField(
                    value = description,
                    onValueChange = { description = it },
                    label = { Text("Description (Optional)") },
                    modifier = Modifier.fillMaxWidth(),
                    maxLines = 3
                )
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    selectedAccount?.let { account ->
                        val transactionAmount = amount.toBigDecimalOrNull() ?: BigDecimal.ZERO
                        onConfirm(account.id, transactionAmount, type, category, description)
                    }
                },
                enabled = selectedAccount != null && amount.isNotBlank() && category.isNotBlank()
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
    "Salary",
    "Investment",
    "Other"
)

private fun formatCurrency(amount: BigDecimal): String {
    val formatter = NumberFormat.getCurrencyInstance(Locale("en", "IN"))
    formatter.currency = Currency.getInstance("INR")
    return formatter.format(amount)
}

private fun formatDate(date: Date): String {
    val formatter = SimpleDateFormat("MMM dd, yyyy", Locale.getDefault())
    return formatter.format(date)
}
