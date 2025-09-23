# Android Development Instructions (Kotlin/Java)

## Overview
Platform-specific instructions for Android development within cross-platform projects using Kotlin, Jetpack Compose, and modern Android frameworks.

## Development Principles

### Kotlin & Modern Patterns
- Use Kotlin coroutines for async operations
- Implement proper exception handling with sealed classes
- Apply modern Android architecture (MVVM, Repository pattern)
- Use Jetpack Compose for modern UI development
- Leverage StateFlow and SharedFlow for reactive programming

### Security First (Android Platforms)
- Encrypt sensitive data using Android Keystore
- Use EncryptedSharedPreferences for secure storage
- Implement biometric authentication with BiometricPrompt
- Apply ProGuard/R8 for code obfuscation
- Use network security config for secure connections

### Platform-Native Design
- Follow Material Design guidelines
- Use proper Android navigation patterns
- Implement accessibility with TalkBack support
- Support multiple screen densities and orientations

## Architecture Guidelines

### Data Models (Room/Kotlin)
```kotlin
// Financial data models with encryption
@Entity(tableName = "transactions")
data class Transaction(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    @ColumnInfo(name = "amount") val amount: BigDecimal,
    @ColumnInfo(name = "description") val description: String,
    @ColumnInfo(name = "category_id") val categoryId: String,
    @ColumnInfo(name = "account_id") val accountId: String,
    @ColumnInfo(name = "date") val date: LocalDateTime
)
```

### Service Layer (Coroutines-based)
```kotlin
// Repository pattern with coroutines
interface TransactionRepository {
    suspend fun createTransaction(transaction: Transaction): Result<Transaction>
    suspend fun getTransactions(accountId: String): Flow<List<Transaction>>
}

class TransactionRepositoryImpl @Inject constructor(
    private val dao: TransactionDao,
    private val encryptionService: EncryptionService
) : TransactionRepository {
    
    override suspend fun createTransaction(transaction: Transaction): Result<Transaction> = 
        withContext(Dispatchers.IO) {
            try {
                val encryptedTransaction = encryptionService.encrypt(transaction)
                dao.insert(encryptedTransaction)
                Result.success(transaction)
            } catch (e: Exception) {
                Result.failure(e)
            }
        }
}
```

### UI Components (Jetpack Compose)
```kotlin
// Modern Compose UI
@Composable
fun TransactionListScreen(
    viewModel: TransactionViewModel = hiltViewModel()
) {
    val transactions by viewModel.transactions.collectAsState()
    val uiState by viewModel.uiState.collectAsState()
    
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(16.dp)
    ) {
        items(transactions) { transaction ->
            TransactionItem(
                transaction = transaction,
                onClick = { viewModel.onTransactionClick(transaction.id) }
            )
        }
    }
}
```

## MCP Tools for Android Development

### GitHub Integration
- `mcp_github_list_issues` - List open issues for project planning
- `mcp_github_get_issue` - Get detailed issue information
- `mcp_github_create_issue` - Create new issues from feature requests
- `mcp_github_update_issue` - Update issue status and progress
- `mcp_github_add_issue_comment` - Add progress comments
- `activate_github_pull_request_management` - Manage PRs

### Code Analysis
- `semantic_search` - Find related Kotlin code patterns
- `grep_search` - Search for specific Kotlin/Compose patterns
- `list_code_usages` - Understand Kotlin class/interface dependencies
- `get_errors` - Check Kotlin compilation errors

## VSCode Tasks for Android Development

Use these tasks from `.vscode/tasks.json`:

### Build Tasks
- **`android-build-debug`** - Build debug APK
- **`android-build-release`** - Build release APK
- **`android-clean`** - Clean build artifacts

### Testing Tasks
- **`android-test-unit`** - Run unit tests
- **`android-test-instrumented`** - Run instrumented tests
- **`android-test-coverage`** - Run tests with coverage

### Code Quality
- **`kotlin-lint`** - Run ktlint analysis
- **`kotlin-format`** - Auto-format Kotlin code
- **`android-security-scan`** - Run security analysis

### Development Workflow
- **`android-studio-open`** - Open project in Android Studio
- **`gradle-sync`** - Sync Gradle dependencies
- **`android-install-debug`** - Install debug APK

## Android-Specific Implementation Guidelines

### Security Implementation (Android)
```kotlin
// AES encryption using Android Keystore
class EncryptionService @Inject constructor(
    private val context: Context
) {
    private val keyAlias = "FinancialDataKey"
    
    suspend fun encrypt(data: String): String = withContext(Dispatchers.IO) {
        val keyGenerator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        val keyGenParameterSpec = KeyGenParameterSpec.Builder(
            keyAlias,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
        )
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .build()
            
        keyGenerator.init(keyGenParameterSpec)
        val secretKey = keyGenerator.generateKey()
        
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, secretKey)
        
        val encryptedData = cipher.doFinal(data.toByteArray())
        Base64.encodeToString(encryptedData, Base64.DEFAULT)
    }
}
```

### Performance Guidelines (Android)
- Use ViewBinding or Compose for efficient UI
- Implement proper lifecycle management
- Use background threads for heavy operations
- Monitor memory usage with Android Studio profiler

### Testing Requirements (Android)
```kotlin
@RunWith(AndroidJUnit4::class)
class TransactionRepositoryTest {
    
    @get:Rule
    val instantExecutorRule = InstantTaskExecutorRule()
    
    private lateinit var database: TestDatabase
    private lateinit var repository: TransactionRepository
    
    @Before
    fun setup() {
        database = Room.inMemoryDatabaseBuilder(
            ApplicationProvider.getApplicationContext(),
            TestDatabase::class.java
        ).allowMainThreadQueries().build()
        
        repository = TransactionRepositoryImpl(
            dao = database.transactionDao(),
            encryptionService = FakeEncryptionService()
        )
    }
    
    @Test
    fun createTransaction_success() = runTest {
        val transaction = createTestTransaction()
        val result = repository.createTransaction(transaction)
        
        assertThat(result.isSuccess).isTrue()
    }
}
```

## Code Generation Preferences (Kotlin)

### Naming Conventions
- Use descriptive names following Kotlin conventions (camelCase)
- Interface names should describe capability (e.g., `TransactionProcessor`)
- Use meaningful abbreviations sparingly

### Error Handling (Kotlin)
```kotlin
// Use sealed classes for comprehensive error handling
sealed class TransactionError : Exception() {
    object InvalidAmount : TransactionError()
    object InsufficientFunds : TransactionError()
    data class NetworkError(val cause: Throwable) : TransactionError()
}

suspend fun processTransaction(transaction: Transaction): Result<Transaction> {
    return try {
        // Implementation
        Result.success(processedTransaction)
    } catch (e: TransactionError) {
        Result.failure(e)
    }
}
```

### Documentation Standards
- Add KDoc comments for public APIs
- Explain complex business logic
- Include usage examples for non-trivial functions
- Document security considerations

This instruction set ensures consistent, secure, and high-quality Android platform development while leveraging modern Kotlin features and MCP GitHub integration tools.