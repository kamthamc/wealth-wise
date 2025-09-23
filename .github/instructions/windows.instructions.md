---
applyTo: "**/*.cs"
---
# Windows Development Instructions (.NET/C#)

## Overview
Platform-specific instructions for Windows development within cross-platform projects using .NET, C#, WPF/WinUI, and modern Windows frameworks.

## Development Principles

### C# & Modern Patterns
- Use async/await for asynchronous operations
- Implement proper exception handling with custom exceptions
- Apply modern .NET architecture (MVVM, Repository pattern)
- Use WPF or WinUI 3 for modern UI development
- Leverage INotifyPropertyChanged and ObservableCollection for data binding

### Security First (Windows Platforms)
- Encrypt sensitive data using Windows Data Protection API (DPAPI)
- Use Windows Credential Manager for secure storage
- Implement Windows Hello for biometric authentication
- Apply code signing for distribution security
- Use HTTPS and certificate pinning for network security

### Platform-Native Design
- Follow Windows design guidelines (Fluent Design)
- Use proper Windows navigation patterns
- Implement accessibility with Narrator support
- Support multiple screen resolutions and DPI scaling

## Architecture Guidelines

### Data Models (Entity Framework/.NET)
```csharp
// Financial data models with encryption attributes
[Table("Transactions")]
public class Transaction
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();
    
    [Required]
    [Column(TypeName = "decimal(18,2)")]
    public decimal Amount { get; set; }
    
    [Required]
    [MaxLength(500)]
    [Encrypted] // Custom attribute for encryption
    public string Description { get; set; } = string.Empty;
    
    public Guid CategoryId { get; set; }
    public Guid AccountId { get; set; }
    public DateTime Date { get; set; }
    
    // Navigation properties
    public virtual Category Category { get; set; } = null!;
    public virtual Account Account { get; set; } = null!;
}
```

### Service Layer (async/await-based)
```csharp
// Repository pattern with async operations
public interface ITransactionRepository
{
    Task<Result<Transaction>> CreateTransactionAsync(Transaction transaction);
    Task<IEnumerable<Transaction>> GetTransactionsAsync(Guid accountId);
}

public class TransactionRepository : ITransactionRepository
{
    private readonly ApplicationDbContext _context;
    private readonly IEncryptionService _encryptionService;
    
    public TransactionRepository(ApplicationDbContext context, IEncryptionService encryptionService)
    {
        _context = context;
        _encryptionService = encryptionService;
    }
    
    public async Task<Result<Transaction>> CreateTransactionAsync(Transaction transaction)
    {
        try
        {
            // Encrypt sensitive data before saving
            transaction.Description = await _encryptionService.EncryptAsync(transaction.Description);
            
            _context.Transactions.Add(transaction);
            await _context.SaveChangesAsync();
            
            return Result<Transaction>.Success(transaction);
        }
        catch (Exception ex)
        {
            return Result<Transaction>.Failure(ex.Message);
        }
    }
}
```

### UI Components (WPF/WinUI)
```csharp
// Modern WPF/WinUI with MVVM
public partial class TransactionListView : UserControl
{
    public TransactionListView()
    {
        InitializeComponent();
        DataContext = App.ServiceProvider.GetRequiredService<TransactionListViewModel>();
    }
}

public class TransactionListViewModel : ViewModelBase
{
    private readonly ITransactionRepository _repository;
    private ObservableCollection<TransactionViewModel> _transactions;
    
    public TransactionListViewModel(ITransactionRepository repository)
    {
        _repository = repository;
        _transactions = new ObservableCollection<TransactionViewModel>();
        LoadTransactionsCommand = new AsyncRelayCommand(LoadTransactionsAsync);
    }
    
    public ObservableCollection<TransactionViewModel> Transactions
    {
        get => _transactions;
        set => SetProperty(ref _transactions, value);
    }
    
    public IAsyncRelayCommand LoadTransactionsCommand { get; }
    
    private async Task LoadTransactionsAsync()
    {
        var transactions = await _repository.GetTransactionsAsync(CurrentAccountId);
        Transactions.Clear();
        foreach (var transaction in transactions)
        {
            Transactions.Add(new TransactionViewModel(transaction));
        }
    }
}
```

## MCP Tools for Windows Development

### GitHub Integration
- `mcp_github_list_issues` - List open issues for project planning
- `mcp_github_get_issue` - Get detailed issue information
- `mcp_github_create_issue` - Create new issues from feature requests
- `mcp_github_update_issue` - Update issue status and progress
- `mcp_github_add_issue_comment` - Add progress comments
- `activate_github_pull_request_management` - Manage PRs

### Code Analysis
- `semantic_search` - Find related C# code patterns
- `grep_search` - Search for specific .NET/WPF patterns
- `list_code_usages` - Understand C# class/interface dependencies
- `get_errors` - Check C# compilation errors

## VSCode Tasks for Windows Development

Use these tasks from `.vscode/tasks.json`:

### Build Tasks
- **`dotnet-build-debug`** - Build debug configuration
- **`dotnet-build-release`** - Build release configuration
- **`dotnet-clean`** - Clean build artifacts

### Testing Tasks
- **`dotnet-test-unit`** - Run unit tests
- **`dotnet-test-integration`** - Run integration tests
- **`dotnet-test-coverage`** - Run tests with coverage

### Code Quality
- **`dotnet-format`** - Format C# code
- **`dotnet-analyze`** - Run static code analysis
- **`windows-security-scan`** - Run security analysis

### Development Workflow
- **`visual-studio-open`** - Open project in Visual Studio
- **`dotnet-restore`** - Restore NuGet packages
- **`windows-package`** - Create Windows package

## Windows-Specific Implementation Guidelines

### Security Implementation (Windows)
```csharp
// DPAPI encryption for sensitive data
public class WindowsEncryptionService : IEncryptionService
{
    public async Task<string> EncryptAsync(string plainText)
    {
        return await Task.Run(() =>
        {
            byte[] plainBytes = Encoding.UTF8.GetBytes(plainText);
            byte[] encryptedBytes = ProtectedData.Protect(
                plainBytes, 
                null, 
                DataProtectionScope.CurrentUser
            );
            return Convert.ToBase64String(encryptedBytes);
        });
    }
    
    public async Task<string> DecryptAsync(string encryptedText)
    {
        return await Task.Run(() =>
        {
            byte[] encryptedBytes = Convert.FromBase64String(encryptedText);
            byte[] decryptedBytes = ProtectedData.Unprotect(
                encryptedBytes, 
                null, 
                DataProtectionScope.CurrentUser
            );
            return Encoding.UTF8.GetString(decryptedBytes);
        });
    }
}
```

### Performance Guidelines (Windows)
- Use async/await for non-blocking operations
- Implement proper memory management with using statements
- Use background threads for heavy operations
- Monitor performance with Visual Studio diagnostic tools

### Testing Requirements (Windows)
```csharp
[TestClass]
public class TransactionRepositoryTests
{
    private ApplicationDbContext _context;
    private ITransactionRepository _repository;
    
    [TestInitialize]
    public void Setup()
    {
        var options = new DbContextOptionsBuilder<ApplicationDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;
            
        _context = new ApplicationDbContext(options);
        _repository = new TransactionRepository(_context, new FakeEncryptionService());
    }
    
    [TestMethod]
    public async Task CreateTransaction_Success()
    {
        // Arrange
        var transaction = CreateTestTransaction();
        
        // Act
        var result = await _repository.CreateTransactionAsync(transaction);
        
        // Assert
        Assert.IsTrue(result.IsSuccess);
        Assert.IsNotNull(result.Data);
    }
    
    [TestCleanup]
    public void Cleanup()
    {
        _context.Dispose();
    }
}
```

## Code Generation Preferences (C#)

### Naming Conventions
- Use descriptive names following C# conventions (PascalCase for public, camelCase for private)
- Interface names should start with 'I' (e.g., `ITransactionProcessor`)
- Use meaningful abbreviations sparingly

### Error Handling (C#)
```csharp
// Use custom exceptions for comprehensive error handling
public class TransactionException : Exception
{
    public TransactionErrorType ErrorType { get; }
    
    public TransactionException(TransactionErrorType errorType, string message) 
        : base(message)
    {
        ErrorType = errorType;
    }
    
    public TransactionException(TransactionErrorType errorType, string message, Exception innerException) 
        : base(message, innerException)
    {
        ErrorType = errorType;
    }
}

public enum TransactionErrorType
{
    InvalidAmount,
    InsufficientFunds,
    NetworkError
}

// Result pattern for better error handling
public class Result<T>
{
    public bool IsSuccess { get; private set; }
    public T Data { get; private set; }
    public string ErrorMessage { get; private set; }
    
    private Result(bool isSuccess, T data, string errorMessage)
    {
        IsSuccess = isSuccess;
        Data = data;
        ErrorMessage = errorMessage;
    }
    
    public static Result<T> Success(T data) => new(true, data, string.Empty);
    public static Result<T> Failure(string errorMessage) => new(false, default, errorMessage);
}
```

### Documentation Standards
- Add XML documentation comments for public APIs
- Explain complex business logic
- Include usage examples for non-trivial methods
- Document security considerations

This instruction set ensures consistent, secure, and high-quality Windows platform development while leveraging modern .NET features and MCP GitHub integration tools.