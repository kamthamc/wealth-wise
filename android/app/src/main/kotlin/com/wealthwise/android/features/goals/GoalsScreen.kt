package com.wealthwise.android.features.goals

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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.wealthwise.android.data.model.Goal
import com.wealthwise.android.data.model.GoalPriority
import com.wealthwise.android.data.model.GoalType
import java.math.BigDecimal
import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GoalsScreen(
    navController: NavController,
    viewModel: GoalsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val goals by viewModel.goals.collectAsState()
    val selectedType by viewModel.selectedType.collectAsState()
    val selectedPriority by viewModel.selectedPriority.collectAsState()
    val showCompleted by viewModel.showCompleted.collectAsState()
    
    var showAddDialog by remember { mutableStateOf(false) }
    var showEditDialog by remember { mutableStateOf<Goal?>(null) }
    var showContributionDialog by remember { mutableStateOf<Goal?>(null) }
    var showDeleteDialog by remember { mutableStateOf<Goal?>(null) }
    var showFilters by remember { mutableStateOf(false) }
    
    val snackbarHostState = remember { SnackbarHostState() }
    
    // Handle error messages
    LaunchedEffect(uiState) {
        if (uiState is GoalsUiState.Error) {
            snackbarHostState.showSnackbar(
                message = (uiState as GoalsUiState.Error).message,
                duration = SnackbarDuration.Short
            )
            viewModel.clearError()
        }
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Goals") },
                actions = {
                    IconButton(onClick = { showFilters = !showFilters }) {
                        Icon(
                            imageVector = Icons.Filled.FilterList,
                            contentDescription = "Filter"
                        )
                    }
                    IconButton(onClick = { viewModel.toggleShowCompleted() }) {
                        Icon(
                            imageVector = if (showCompleted) Icons.Filled.Visibility else Icons.Filled.VisibilityOff,
                            contentDescription = if (showCompleted) "Hide completed" else "Show completed"
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
                Icon(Icons.Filled.Add, contentDescription = "Add goal")
            }
        },
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Filter chips
            if (showFilters) {
                FilterChips(
                    selectedType = selectedType,
                    selectedPriority = selectedPriority,
                    onTypeSelected = { viewModel.filterByType(it) },
                    onPrioritySelected = { viewModel.filterByPriority(it) },
                    onClearFilters = { viewModel.clearFilters() },
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                )
            }
            
            // Goals list
            when (val state = uiState) {
                is GoalsUiState.Loading -> {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator()
                    }
                }
                
                is GoalsUiState.Empty -> {
                    EmptyGoalsState(
                        modifier = Modifier.fillMaxSize(),
                        onAddGoal = { showAddDialog = true }
                    )
                }
                
                is GoalsUiState.Success, is GoalsUiState.Error -> {
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(goals, key = { it.id }) { goal ->
                            GoalCard(
                                goal = goal,
                                onAddContribution = { showContributionDialog = goal },
                                onEdit = { showEditDialog = goal },
                                onDelete = { showDeleteDialog = goal },
                                onClick = {
                                    navController.navigate("goal/${goal.id}")
                                }
                            )
                        }
                    }
                }
            }
        }
    }
    
    // Add Goal Dialog
    if (showAddDialog) {
        AddGoalDialog(
            onDismiss = { showAddDialog = false },
            onConfirm = { name, targetAmount, targetDate, type, priority, initialAmount ->
                viewModel.createGoal(name, targetAmount, targetDate, type, priority, initialAmount)
                showAddDialog = false
            }
        )
    }
    
    // Edit Goal Dialog
    showEditDialog?.let { goal ->
        EditGoalDialog(
            goal = goal,
            onDismiss = { showEditDialog = null },
            onConfirm = { name, targetAmount, targetDate, type, priority ->
                viewModel.updateGoal(goal.id, name, targetAmount, targetDate, type, priority)
                showEditDialog = null
            }
        )
    }
    
    // Add Contribution Dialog
    showContributionDialog?.let { goal ->
        AddContributionDialog(
            goal = goal,
            onDismiss = { showContributionDialog = null },
            onConfirm = { amount ->
                viewModel.addContribution(goal.id, amount)
                showContributionDialog = null
            }
        )
    }
    
    // Delete Confirmation Dialog
    showDeleteDialog?.let { goal ->
        AlertDialog(
            onDismissRequest = { showDeleteDialog = null },
            title = { Text("Delete Goal") },
            text = { Text("Are you sure you want to delete '${goal.name}'? This action cannot be undone.") },
            confirmButton = {
                Button(
                    onClick = {
                        viewModel.deleteGoal(goal.id)
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

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun FilterChips(
    selectedType: GoalType?,
    selectedPriority: GoalPriority?,
    onTypeSelected: (GoalType?) -> Unit,
    onPrioritySelected: (GoalPriority?) -> Unit,
    onClearFilters: () -> Unit,
    modifier: Modifier = Modifier
) {
    var showTypeMenu by remember { mutableStateOf(false) }
    var showPriorityMenu by remember { mutableStateOf(false) }
    
    LazyRow(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
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
                        imageVector = Icons.Filled.Category,
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
                GoalType.values().forEach { type ->
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
        
        // Priority filter
        item {
            FilterChip(
                selected = selectedPriority != null,
                onClick = { showPriorityMenu = true },
                label = { 
                    Text(selectedPriority?.name ?: "All Priorities") 
                },
                leadingIcon = {
                    Icon(
                        imageVector = Icons.Filled.Flag,
                        contentDescription = null,
                        modifier = Modifier.size(18.dp)
                    )
                }
            )
            
            DropdownMenu(
                expanded = showPriorityMenu,
                onDismissRequest = { showPriorityMenu = false }
            ) {
                DropdownMenuItem(
                    text = { Text("All Priorities") },
                    onClick = {
                        onPrioritySelected(null)
                        showPriorityMenu = false
                    }
                )
                GoalPriority.values().forEach { priority ->
                    DropdownMenuItem(
                        text = { Text(priority.name) },
                        onClick = {
                            onPrioritySelected(priority)
                            showPriorityMenu = false
                        }
                    )
                }
            }
        }
        
        // Clear filters button
        if (selectedType != null || selectedPriority != null) {
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
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun GoalCard(
    goal: Goal,
    onAddContribution: () -> Unit,
    onEdit: () -> Unit,
    onDelete: () -> Unit,
    onClick: () -> Unit
) {
    var showMenu by remember { mutableStateOf(false) }
    val progress = goal.getProgress()
    val daysRemaining = getDaysRemaining(goal.targetDate)
    val isBehindSchedule = goal.isBehindSchedule()
    val requiredMonthly = goal.getRequiredMonthlyContribution()
    
    val priorityColor = when (goal.priority) {
        GoalPriority.HIGH -> MaterialTheme.colorScheme.error
        GoalPriority.MEDIUM -> Color(0xFFFFA726)
        GoalPriority.LOW -> MaterialTheme.colorScheme.primary
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
                        text = goal.name,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Medium
                    )
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = goal.type.name,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Text(
                            text = "•",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Surface(
                            color = priorityColor.copy(alpha = 0.2f),
                            shape = MaterialTheme.shapes.small
                        ) {
                            Text(
                                text = goal.priority.name,
                                style = MaterialTheme.typography.labelSmall,
                                color = priorityColor,
                                modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                            )
                        }
                    }
                }
                
                // Behind schedule warning
                if (isBehindSchedule) {
                    Icon(
                        imageVector = Icons.Filled.Warning,
                        contentDescription = "Behind schedule",
                        tint = Color(0xFFFFA726),
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
                            text = { Text("Add Contribution") },
                            onClick = {
                                onAddContribution()
                                showMenu = false
                            },
                            leadingIcon = {
                                Icon(Icons.Filled.Add, contentDescription = null)
                            }
                        )
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
            
            // Progress circle
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Current vs target
                Column {
                    Text(
                        text = formatCurrency(goal.currentAmount),
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        text = "of ${formatCurrency(goal.targetAmount)}",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                
                // Circular progress
                Box(
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator(
                        progress = (progress / 100f).coerceIn(0f, 1f),
                        modifier = Modifier.size(80.dp),
                        strokeWidth = 8.dp,
                        color = if (goal.isCompleted()) 
                            MaterialTheme.colorScheme.primary 
                        else if (isBehindSchedule) 
                            Color(0xFFFFA726) 
                        else 
                            MaterialTheme.colorScheme.primary
                    )
                    Text(
                        text = "${String.format("%.0f", progress)}%",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
            // Target date and days remaining
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Column {
                    Text(
                        text = "Target Date",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = formatDate(goal.targetDate),
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Medium
                    )
                }
                if (daysRemaining >= 0 && !goal.isCompleted()) {
                    Column(horizontalAlignment = Alignment.End) {
                        Text(
                            text = "Days Remaining",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Text(
                            text = "$daysRemaining days",
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = FontWeight.Medium,
                            color = if (isBehindSchedule) Color(0xFFFFA726) else MaterialTheme.colorScheme.onSurface
                        )
                    }
                }
            }
            
            // Required monthly contribution
            if (!goal.isCompleted() && requiredMonthly > BigDecimal.ZERO) {
                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(8.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Required monthly:",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = formatCurrency(requiredMonthly),
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Medium,
                        color = if (isBehindSchedule) 
                            Color(0xFFFFA726) 
                        else 
                            MaterialTheme.colorScheme.primary
                    )
                }
            }
            
            // Completed badge
            if (goal.isCompleted()) {
                Spacer(modifier = Modifier.height(8.dp))
                Surface(
                    color = MaterialTheme.colorScheme.primaryContainer,
                    shape = MaterialTheme.shapes.small,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Row(
                        modifier = Modifier.padding(8.dp),
                        horizontalArrangement = Arrangement.Center,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Filled.CheckCircle,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.size(18.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "Goal Completed!",
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = FontWeight.Medium,
                            color = MaterialTheme.colorScheme.primary
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun EmptyGoalsState(
    modifier: Modifier = Modifier,
    onAddGoal: () -> Unit
) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            imageVector = Icons.Filled.EmojiEvents,
            contentDescription = null,
            modifier = Modifier.size(80.dp),
            tint = MaterialTheme.colorScheme.primary
        )
        Spacer(modifier = Modifier.height(16.dp))
        Text(
            text = "No goals yet",
            style = MaterialTheme.typography.titleLarge
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = "Set a goal to start saving",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(modifier = Modifier.height(24.dp))
        Button(onClick = onAddGoal) {
            Icon(Icons.Filled.Add, contentDescription = null)
            Spacer(modifier = Modifier.width(8.dp))
            Text("Set Goal")
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun AddGoalDialog(
    onDismiss: () -> Unit,
    onConfirm: (name: String, targetAmount: BigDecimal, targetDate: Date, type: GoalType, priority: GoalPriority, initialAmount: BigDecimal) -> Unit
) {
    var name by remember { mutableStateOf("") }
    var targetAmount by remember { mutableStateOf("") }
    var type by remember { mutableStateOf(GoalType.SAVINGS) }
    var priority by remember { mutableStateOf(GoalPriority.MEDIUM) }
    var initialAmount by remember { mutableStateOf("0") }
    var typeExpanded by remember { mutableStateOf(false) }
    var priorityExpanded by remember { mutableStateOf(false) }
    
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Set Goal") },
        text = {
            Column(
                modifier = Modifier.fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    label = { Text("Goal Name") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )
                
                OutlinedTextField(
                    value = targetAmount,
                    onValueChange = { targetAmount = it },
                    label = { Text("Target Amount") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                    prefix = { Text("₹") }
                )
                
                ExposedDropdownMenuBox(
                    expanded = typeExpanded,
                    onExpandedChange = { typeExpanded = it }
                ) {
                    OutlinedTextField(
                        value = type.name,
                        onValueChange = {},
                        readOnly = true,
                        label = { Text("Type") },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = typeExpanded) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .menuAnchor()
                    )
                    
                    ExposedDropdownMenu(
                        expanded = typeExpanded,
                        onDismissRequest = { typeExpanded = false }
                    ) {
                        GoalType.values().forEach { goalType ->
                            DropdownMenuItem(
                                text = { Text(goalType.name) },
                                onClick = {
                                    type = goalType
                                    typeExpanded = false
                                }
                            )
                        }
                    }
                }
                
                ExposedDropdownMenuBox(
                    expanded = priorityExpanded,
                    onExpandedChange = { priorityExpanded = it }
                ) {
                    OutlinedTextField(
                        value = priority.name,
                        onValueChange = {},
                        readOnly = true,
                        label = { Text("Priority") },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = priorityExpanded) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .menuAnchor()
                    )
                    
                    ExposedDropdownMenu(
                        expanded = priorityExpanded,
                        onDismissRequest = { priorityExpanded = false }
                    ) {
                        GoalPriority.values().forEach { goalPriority ->
                            DropdownMenuItem(
                                text = { Text(goalPriority.name) },
                                onClick = {
                                    priority = goalPriority
                                    priorityExpanded = false
                                }
                            )
                        }
                    }
                }
                
                OutlinedTextField(
                    value = initialAmount,
                    onValueChange = { initialAmount = it },
                    label = { Text("Initial Amount (Optional)") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                    prefix = { Text("₹") }
                )
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    val target = targetAmount.toBigDecimalOrNull() ?: BigDecimal.ZERO
                    val initial = initialAmount.toBigDecimalOrNull() ?: BigDecimal.ZERO
                    val date = Calendar.getInstance().apply {
                        add(Calendar.MONTH, 12) // Default: 1 year from now
                    }.time
                    onConfirm(name, target, date, type, priority, initial)
                },
                enabled = name.isNotBlank() && targetAmount.isNotBlank()
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
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun EditGoalDialog(
    goal: Goal,
    onDismiss: () -> Unit,
    onConfirm: (name: String, targetAmount: BigDecimal, targetDate: Date, type: GoalType, priority: GoalPriority) -> Unit
) {
    var name by remember { mutableStateOf(goal.name) }
    var targetAmount by remember { mutableStateOf(goal.targetAmount.toString()) }
    var type by remember { mutableStateOf(goal.type) }
    var priority by remember { mutableStateOf(goal.priority) }
    var typeExpanded by remember { mutableStateOf(false) }
    var priorityExpanded by remember { mutableStateOf(false) }
    
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Edit Goal") },
        text = {
            Column(
                modifier = Modifier.fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    label = { Text("Goal Name") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )
                
                OutlinedTextField(
                    value = targetAmount,
                    onValueChange = { targetAmount = it },
                    label = { Text("Target Amount") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                    prefix = { Text("₹") }
                )
                
                ExposedDropdownMenuBox(
                    expanded = typeExpanded,
                    onExpandedChange = { typeExpanded = it }
                ) {
                    OutlinedTextField(
                        value = type.name,
                        onValueChange = {},
                        readOnly = true,
                        label = { Text("Type") },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = typeExpanded) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .menuAnchor()
                    )
                    
                    ExposedDropdownMenu(
                        expanded = typeExpanded,
                        onDismissRequest = { typeExpanded = false }
                    ) {
                        GoalType.values().forEach { goalType ->
                            DropdownMenuItem(
                                text = { Text(goalType.name) },
                                onClick = {
                                    type = goalType
                                    typeExpanded = false
                                }
                            )
                        }
                    }
                }
                
                ExposedDropdownMenuBox(
                    expanded = priorityExpanded,
                    onExpandedChange = { priorityExpanded = it }
                ) {
                    OutlinedTextField(
                        value = priority.name,
                        onValueChange = {},
                        readOnly = true,
                        label = { Text("Priority") },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = priorityExpanded) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .menuAnchor()
                    )
                    
                    ExposedDropdownMenu(
                        expanded = priorityExpanded,
                        onDismissRequest = { priorityExpanded = false }
                    ) {
                        GoalPriority.values().forEach { goalPriority ->
                            DropdownMenuItem(
                                text = { Text(goalPriority.name) },
                                onClick = {
                                    priority = goalPriority
                                    priorityExpanded = false
                                }
                            )
                        }
                    }
                }
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    val target = targetAmount.toBigDecimalOrNull() ?: BigDecimal.ZERO
                    onConfirm(name, target, goal.targetDate, type, priority)
                },
                enabled = name.isNotBlank() && targetAmount.isNotBlank()
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

@Composable
private fun AddContributionDialog(
    goal: Goal,
    onDismiss: () -> Unit,
    onConfirm: (amount: BigDecimal) -> Unit
) {
    var amount by remember { mutableStateOf("") }
    
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Add Contribution") },
        text = {
            Column {
                Text(
                    text = "Contributing to: ${goal.name}",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.height(16.dp))
                OutlinedTextField(
                    value = amount,
                    onValueChange = { amount = it },
                    label = { Text("Amount") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                    prefix = { Text("₹") }
                )
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    val contribution = amount.toBigDecimalOrNull() ?: BigDecimal.ZERO
                    onConfirm(contribution)
                },
                enabled = amount.isNotBlank()
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

private fun getDaysRemaining(targetDate: Date): Long {
    val today = Calendar.getInstance().timeInMillis
    val target = targetDate.time
    return (target - today) / (1000 * 60 * 60 * 24)
}

private fun formatCurrency(amount: BigDecimal): String {
    val formatter = NumberFormat.getCurrencyInstance(Locale("en", "IN"))
    formatter.currency = Currency.getInstance("INR")
    return formatter.format(amount)
}

private fun formatDate(date: Date): String {
    val formatter = SimpleDateFormat("MMM dd, yyyy", Locale.getDefault())
    return formatter.format(date)
}
