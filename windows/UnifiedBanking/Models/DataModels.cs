// .NET Core 10 Entity Framework Models for Windows
// C# models using Entity Framework Core with SQL Server/SQLite

using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace UnifiedBanking.Models
{
    // MARK: - Account Model
    
    [Table("Accounts")]
    [Index(nameof(AccountNumber), IsUnique = true)]
    [Index(nameof(InstitutionName))]
    public class Account
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();
        
        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(50)]
        public string AccountType { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(100)]
        public string InstitutionName { get; set; } = string.Empty;
        
        [MaxLength(50)]
        public string? AccountNumber { get; set; }
        
        [Column(TypeName = "decimal(18,2)")]
        public decimal CurrentBalance { get; set; }
        
        [Required]
        [MaxLength(3)]
        public string Currency { get; set; } = "INR";
        
        public bool IsActive { get; set; } = true;
        
        public DateTime? LastSynced { get; set; }
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
        
        // Navigation properties
        public virtual ICollection<Transaction> Transactions { get; set; } = new List<Transaction>();
    }
    
    // MARK: - Transaction Model
    
    [Table("Transactions")]
    [Index(nameof(AccountId))]
    [Index(nameof(TransactionDate))]
    [Index(nameof(Category))]
    [Index(nameof(ReferenceNumber))]
    public class Transaction
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();
        
        [Required]
        public Guid AccountId { get; set; }
        
        [Column(TypeName = "decimal(18,2)")]
        public decimal Amount { get; set; }
        
        [Required]
        [MaxLength(3)]
        public string Currency { get; set; } = "INR";
        
        [Required]
        [MaxLength(50)]
        public string TransactionType { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(50)]
        public string Category { get; set; } = string.Empty;
        
        [MaxLength(50)]
        public string? Subcategory { get; set; }
        
        [Required]
        [MaxLength(500)]
        public string Description { get; set; } = string.Empty;
        
        [MaxLength(100)]
        public string? MerchantName { get; set; }
        
        [MaxLength(200)]
        public string? Location { get; set; }
        
        public DateTime TransactionDate { get; set; }
        
        public DateTime? ProcessedDate { get; set; }
        
        [MaxLength(100)]
        public string? ReferenceNumber { get; set; }
        
        public Guid? LinkedTransactionId { get; set; }
        
        [MaxLength(1000)]
        public string? Tags { get; set; } // Comma-separated
        
        [MaxLength(1000)]
        public string? Notes { get; set; }
        
        [MaxLength(500)]
        public string? ReceiptPath { get; set; }
        
        public bool IsRecurring { get; set; } = false;
        
        public Guid? RecurringGroupId { get; set; }
        
        [Column(TypeName = "decimal(5,2)")]
        public decimal CategoryConfidence { get; set; } = 0;
        
        public bool IsManuallyVerified { get; set; } = false;
        
        [Required]
        [MaxLength(20)]
        public string SyncStatus { get; set; } = "pending";
        
        [MaxLength(20)]
        public string? ImportSource { get; set; }
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
        
        // Navigation properties
        [ForeignKey(nameof(AccountId))]
        public virtual Account Account { get; set; } = null!;
    }
    
    // MARK: - Budget Model
    
    [Table("Budgets")]
    [Index(nameof(Name))]
    [Index(nameof(StartDate), nameof(EndDate))]
    [Index(nameof(IsActive))]
    public class Budget
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();
        
        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(50)]
        public string BudgetType { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(20)]
        public string Period { get; set; } = string.Empty;
        
        public DateTime StartDate { get; set; }
        
        public DateTime? EndDate { get; set; }
        
        [Column(TypeName = "decimal(18,2)")]
        public decimal TotalBudget { get; set; }
        
        [Column(TypeName = "decimal(18,2)")]
        public decimal SpentAmount { get; set; } = 0;
        
        [Column(TypeName = "decimal(18,2)")]
        public decimal RemainingAmount { get; set; }
        
        [Required]
        [MaxLength(3)]
        public string Currency { get; set; } = "INR";
        
        [Required]
        [MaxLength(1000)]
        public string IncludedCategories { get; set; } = string.Empty; // Comma-separated
        
        [MaxLength(1000)]
        public string? ExcludedCategories { get; set; } // Comma-separated
        
        [MaxLength(1000)]
        public string? IncludedAccounts { get; set; } // Comma-separated GUIDs
        
        [Required]
        [MaxLength(100)]
        public string AlertThresholds { get; set; } = string.Empty; // Comma-separated percentages
        
        public bool IsAlertEnabled { get; set; } = true;
        
        public bool AllowRollover { get; set; } = false;
        
        [Column(TypeName = "decimal(18,2)")]
        public decimal RolloverAmount { get; set; } = 0;
        
        public bool IsActive { get; set; } = true;
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    }
    
    // MARK: - Asset Model
    
    [Table("Assets")]
    [Index(nameof(AssetType))]
    [Index(nameof(PurchaseDate))]
    [Index(nameof(ValuationDate))]
    public class Asset
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();
        
        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(50)]
        public string AssetType { get; set; } = string.Empty;
        
        [MaxLength(1000)]
        public string? Description { get; set; }
        
        [Column(TypeName = "decimal(18,2)")]
        public decimal PurchaseValue { get; set; }
        
        [Column(TypeName = "decimal(18,2)")]
        public decimal CurrentValue { get; set; }
        
        public DateTime ValuationDate { get; set; }
        
        [Required]
        [MaxLength(3)]
        public string Currency { get; set; } = "INR";
        
        public DateTime PurchaseDate { get; set; }
        
        [MaxLength(200)]
        public string? PurchaseLocation { get; set; }
        
        [MaxLength(100)]
        public string? Vendor { get; set; }
        
        [Column(TypeName = "decimal(18,4)")]
        public decimal Quantity { get; set; }
        
        [Required]
        [MaxLength(20)]
        public string Unit { get; set; } = string.Empty;
        
        [MaxLength(2000)]
        public string? Photos { get; set; } // Comma-separated file paths
        
        public bool IsInsured { get; set; } = false;
        
        [MaxLength(100)]
        public string? InsuranceProvider { get; set; }
        
        [Column(TypeName = "decimal(18,2)")]
        public decimal InsuranceValue { get; set; } = 0;
        
        public DateTime? InsuranceExpiryDate { get; set; }
        
        public DateTime? WarrantyExpiryDate { get; set; }
        
        [Column(TypeName = "decimal(5,2)")]
        public decimal DepreciationRate { get; set; } = 0; // Annual percentage
        
        [Column(TypeName = "decimal(5,2)")]
        public decimal EstimatedLifespan { get; set; } = 0; // Years
        
        [MaxLength(500)]
        public string? Tags { get; set; } // Comma-separated
        
        [MaxLength(1000)]
        public string? Notes { get; set; }
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
        
        // Navigation properties
        public virtual ICollection<AssetDocument> Documents { get; set; } = new List<AssetDocument>();
    }
    
    // MARK: - Asset Document Model
    
    [Table("AssetDocuments")]
    public class AssetDocument
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();
        
        [Required]
        public Guid AssetId { get; set; }
        
        [Required]
        [MaxLength(50)]
        public string Type { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(200)]
        public string FileName { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(500)]
        public string FilePath { get; set; } = string.Empty;
        
        public DateTime UploadDate { get; set; } = DateTime.UtcNow;
        
        [MaxLength(500)]
        public string? Description { get; set; }
        
        // Navigation properties
        [ForeignKey(nameof(AssetId))]
        public virtual Asset Asset { get; set; } = null!;
    }
    
    // MARK: - Loan Model
    
    [Table("Loans")]
    [Index(nameof(LoanType))]
    [Index(nameof(Status))]
    [Index(nameof(NextEmiDate))]
    public class Loan
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();
        
        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(50)]
        public string LoanType { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(100)]
        public string LenderName { get; set; } = string.Empty;
        
        [Column(TypeName = "decimal(18,2)")]
        public decimal PrincipalAmount { get; set; }
        
        [Column(TypeName = "decimal(18,2)")]
        public decimal CurrentOutstanding { get; set; }
        
        [Column(TypeName = "decimal(5,2)")]
        public decimal InterestRate { get; set; } // Annual percentage
        
        public int Tenure { get; set; } // Months
        
        [Column(TypeName = "decimal(18,2)")]
        public decimal EmiAmount { get; set; }
        
        public DateTime StartDate { get; set; }
        
        public DateTime EndDate { get; set; }
        
        public DateTime? NextEmiDate { get; set; }
        
        [Column(TypeName = "decimal(18,2)")]
        public decimal TotalPaidAmount { get; set; } = 0;
        
        [Column(TypeName = "decimal(18,2)")]
        public decimal PrincipalPaid { get; set; } = 0;
        
        [Column(TypeName = "decimal(18,2)")]
        public decimal InterestPaid { get; set; } = 0;
        
        [Column(TypeName = "decimal(18,2)")]
        public decimal PenaltyPaid { get; set; } = 0;
        
        [Required]
        [MaxLength(20)]
        public string Status { get; set; } = "active";
        
        public Guid? AccountId { get; set; }
        
        [MaxLength(50)]
        public string? LoanAccountNumber { get; set; }
        
        [MaxLength(1000)]
        public string? Notes { get; set; }
        
        public bool AllowPrepayment { get; set; } = true;
        
        [Column(TypeName = "decimal(5,2)")]
        public decimal PrepaymentPenalty { get; set; } = 0; // Percentage
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    }
    
    // MARK: - Investment Model
    
    [Table("Investments")]
    [Index(nameof(InvestmentType))]
    [Index(nameof(Symbol))]
    [Index(nameof(FirstInvestmentDate))]
    public class Investment
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();
        
        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(50)]
        public string InvestmentType { get; set; } = string.Empty;
        
        [MaxLength(20)]
        public string? Symbol { get; set; }
        
        [Column(TypeName = "decimal(18,2)")]
        public decimal TotalInvested { get; set; }
        
        [Column(TypeName = "decimal(18,2)")]
        public decimal CurrentValue { get; set; }
        
        [Column(TypeName = "decimal(18,4)")]
        public decimal Quantity { get; set; }
        
        [Column(TypeName = "decimal(18,4)")]
        public decimal AveragePrice { get; set; }
        
        [Column(TypeName = "decimal(18,4)")]
        public decimal CurrentPrice { get; set; }
        
        [Column(TypeName = "decimal(18,2)")]
        public decimal TotalReturn { get; set; }
        
        [Column(TypeName = "decimal(5,2)")]
        public decimal TotalReturnPercentage { get; set; }
        
        [Column(TypeName = "decimal(18,2)")]
        public decimal DayReturn { get; set; } = 0;
        
        [Column(TypeName = "decimal(5,2)")]
        public decimal DayReturnPercentage { get; set; } = 0;
        
        public DateTime FirstInvestmentDate { get; set; }
        
        public DateTime? LastInvestmentDate { get; set; }
        
        public DateTime? MaturityDate { get; set; }
        
        public Guid? AccountId { get; set; }
        
        [MaxLength(100)]
        public string? BrokerName { get; set; }
        
        [MaxLength(50)]
        public string? IsinCode { get; set; }
        
        [MaxLength(10)]
        public string? RiskLevel { get; set; }
        
        [MaxLength(50)]
        public string? Category { get; set; }
        
        [MaxLength(50)]
        public string? Subcategory { get; set; }
        
        [MaxLength(20)]
        public string? TaxCategory { get; set; }
        
        public int LockInPeriod { get; set; } = 0; // Months
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    }
    
    // MARK: - User Profile Model
    
    [Table("UserProfile")]
    public class UserProfile
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();
        
        [Required]
        [MaxLength(100)]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(50)]
        public string FirstName { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(50)]
        public string LastName { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(3)]
        public string Currency { get; set; } = "INR";
        
        [Required]
        [MaxLength(50)]
        public string Timezone { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(10)]
        public string Locale { get; set; } = "en-IN";
        
        public DateTime FinancialYearStart { get; set; } = new DateTime(DateTime.Now.Year, 4, 1); // April 1st
        
        [Required]
        [MaxLength(20)]
        public string SubscriptionTier { get; set; } = "free";
        
        public DateTime? SubscriptionExpiryDate { get; set; }
        
        public bool BiometricEnabled { get; set; } = false;
        
        public bool CloudSyncEnabled { get; set; } = true;
        
        public bool AnalyticsEnabled { get; set; } = true;
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    }
    
    // MARK: - Report Template Model
    
    [Table("ReportTemplates")]
    [Index(nameof(Category))]
    public class ReportTemplate
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();
        
        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = string.Empty;
        
        [MaxLength(500)]
        public string? Description { get; set; }
        
        [Required]
        [MaxLength(50)]
        public string Category { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(50)]
        public string DateRangeType { get; set; } = string.Empty;
        
        public DateTime? StartDate { get; set; }
        
        public DateTime? EndDate { get; set; }
        
        [MaxLength(2000)]
        public string? IncludedAccounts { get; set; } // JSON array
        
        [MaxLength(2000)]
        public string? IncludedCategories { get; set; } // JSON array
        
        [Required]
        [MaxLength(20)]
        public string GroupBy { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(20)]
        public string ChartType { get; set; } = string.Empty;
        
        public bool ShowComparison { get; set; } = false;
        
        [MaxLength(50)]
        public string? ComparisonPeriod { get; set; }
        
        public bool IsCustom { get; set; } = false;
        
        public bool IsDefault { get; set; } = false;
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    }
    
    // MARK: - Sync Metadata Model
    
    [Table("SyncMetadata")]
    [Index(nameof(EntityType), nameof(EntityId), IsUnique = true)]
    [Index(nameof(LastModified))]
    public class SyncMetadata
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();
        
        [Required]
        public Guid EntityId { get; set; }
        
        [Required]
        [MaxLength(50)]
        public string EntityType { get; set; } = string.Empty;
        
        public DateTime LastModified { get; set; }
        
        public int Version { get; set; } = 1;
        
        [Required]
        [MaxLength(100)]
        public string Checksum { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(100)]
        public string DeviceId { get; set; } = string.Empty;
    }
}

// MARK: - Database Context

namespace UnifiedBanking.Data
{
    public class UnifiedBankingContext : DbContext
    {
        public UnifiedBankingContext(DbContextOptions<UnifiedBankingContext> options) : base(options)
        {
        }
        
        // DbSets
        public DbSet<Account> Accounts { get; set; }
        public DbSet<Transaction> Transactions { get; set; }
        public DbSet<Budget> Budgets { get; set; }
        public DbSet<Asset> Assets { get; set; }
        public DbSet<AssetDocument> AssetDocuments { get; set; }
        public DbSet<Loan> Loans { get; set; }
        public DbSet<Investment> Investments { get; set; }
        public DbSet<UserProfile> UserProfiles { get; set; }
        public DbSet<ReportTemplate> ReportTemplates { get; set; }
        public DbSet<SyncMetadata> SyncMetadata { get; set; }
        
        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);
            
            // Configure relationships
            modelBuilder.Entity<Transaction>()
                .HasOne(t => t.Account)
                .WithMany(a => a.Transactions)
                .HasForeignKey(t => t.AccountId)
                .OnDelete(DeleteBehavior.Cascade);
            
            modelBuilder.Entity<AssetDocument>()
                .HasOne(ad => ad.Asset)
                .WithMany(a => a.Documents)
                .HasForeignKey(ad => ad.AssetId)
                .OnDelete(DeleteBehavior.Cascade);
            
            // Configure value conversions for enums stored as strings
            // Add any additional configurations here
            
            // Seed default data
            SeedDefaultData(modelBuilder);
        }
        
        private void SeedDefaultData(ModelBuilder modelBuilder)
        {
            // Seed default report templates
            var defaultReportTemplates = new[]
            {
                new ReportTemplate
                {
                    Id = Guid.NewGuid(),
                    Name = "Monthly Expense Report",
                    Description = "Monthly breakdown of expenses by category",
                    Category = "expense",
                    DateRangeType = "current_month",
                    GroupBy = "category",
                    ChartType = "pie",
                    IsDefault = true,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                },
                new ReportTemplate
                {
                    Id = Guid.NewGuid(),
                    Name = "Income vs Expense",
                    Description = "Monthly comparison of income and expenses",
                    Category = "custom",
                    DateRangeType = "last_6_months",
                    GroupBy = "month",
                    ChartType = "bar",
                    ShowComparison = true,
                    IsDefault = true,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                },
                new ReportTemplate
                {
                    Id = Guid.NewGuid(),
                    Name = "Net Worth Tracking",
                    Description = "Track net worth over time",
                    Category = "net_worth",
                    DateRangeType = "last_year",
                    GroupBy = "month",
                    ChartType = "line",
                    IsDefault = true,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                }
            };
            
            modelBuilder.Entity<ReportTemplate>().HasData(defaultReportTemplates);
        }
        
        public override int SaveChanges()
        {
            UpdateTimestamps();
            return base.SaveChanges();
        }
        
        public override async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        {
            UpdateTimestamps();
            return await base.SaveChangesAsync(cancellationToken);
        }
        
        private void UpdateTimestamps()
        {
            var entries = ChangeTracker.Entries()
                .Where(e => e.State == EntityState.Added || e.State == EntityState.Modified);
            
            foreach (var entry in entries)
            {
                if (entry.Entity is Account account)
                {
                    if (entry.State == EntityState.Added)
                        account.CreatedAt = DateTime.UtcNow;
                    account.UpdatedAt = DateTime.UtcNow;
                }
                else if (entry.Entity is Transaction transaction)
                {
                    if (entry.State == EntityState.Added)
                        transaction.CreatedAt = DateTime.UtcNow;
                    transaction.UpdatedAt = DateTime.UtcNow;
                }
                // Add similar logic for other entities
            }
        }
    }
}