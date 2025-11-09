package com.wealthwise.android.data.local

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import androidx.sqlite.db.SupportSQLiteDatabase
import com.wealthwise.android.data.local.converters.DateConverter
import com.wealthwise.android.data.local.converters.DecimalConverter
import com.wealthwise.android.data.local.converters.StringListConverter
import com.wealthwise.android.data.local.dao.AccountDao
import com.wealthwise.android.data.local.dao.BudgetDao
import com.wealthwise.android.data.local.dao.GoalDao
import com.wealthwise.android.data.local.dao.TransactionDao
import com.wealthwise.android.data.model.Account
import com.wealthwise.android.data.model.Budget
import com.wealthwise.android.data.model.Goal
import com.wealthwise.android.data.model.Transaction
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/**
 * Room Database for WealthWise
 * 
 * Features:
 * - Offline-first architecture with local persistence
 * - Encrypted storage for sensitive financial data
 * - Foreign key constraints for data integrity
 * - Automatic migrations for schema updates
 * - Type converters for complex types (BigDecimal, LocalDateTime)
 * 
 * Entities:
 * - Account: User financial accounts
 * - Transaction: Financial transactions
 * - Budget: Spending budgets
 * - Goal: Savings and financial goals
 * 
 * Security:
 * - Database encryption using SQLCipher (to be added)
 * - Secure key storage with Android Keystore
 */
@Database(
    entities = [
        Account::class,
        Transaction::class,
        Budget::class,
        Goal::class
    ],
    version = 1,
    exportSchema = true
)
@TypeConverters(
    DateConverter::class,
    DecimalConverter::class,
    StringListConverter::class
)
abstract class WealthWiseDatabase : RoomDatabase() {
    
    // DAOs
    abstract fun accountDao(): AccountDao
    abstract fun transactionDao(): TransactionDao
    abstract fun budgetDao(): BudgetDao
    abstract fun goalDao(): GoalDao
    
    companion object {
        private const val DATABASE_NAME = "wealthwise_database"
        
        @Volatile
        private var INSTANCE: WealthWiseDatabase? = null
        
        /**
         * Get database instance (singleton)
         * 
         * TODO: Add encryption using SQLCipher:
         * 1. Add net.zetetic:android-database-sqlcipher dependency
         * 2. Generate encryption key using Android Keystore
         * 3. Build encrypted database:
         *    Room.databaseBuilder(context, WealthWiseDatabase::class.java, DATABASE_NAME)
         *        .openHelperFactory(SupportFactory(SQLiteDatabase.getBytes(key)))
         *        .build()
         */
        fun getInstance(context: Context): WealthWiseDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    WealthWiseDatabase::class.java,
                    DATABASE_NAME
                )
                    .addCallback(DatabaseCallback())
                    .fallbackToDestructiveMigration() // Remove in production, add proper migrations
                    .build()
                
                INSTANCE = instance
                instance
            }
        }
        
        /**
         * Clear database instance (for testing)
         */
        fun clearInstance() {
            INSTANCE = null
        }
    }
    
    /**
     * Database callback for initialization
     */
    private class DatabaseCallback : Callback() {
        override fun onCreate(db: SupportSQLiteDatabase) {
            super.onCreate(db)
            
            // Create indexes for better query performance
            db.execSQL("CREATE INDEX IF NOT EXISTS idx_transactions_account_date ON transactions(accountId, date DESC)")
            db.execSQL("CREATE INDEX IF NOT EXISTS idx_transactions_category_date ON transactions(category, date DESC)")
            db.execSQL("CREATE INDEX IF NOT EXISTS idx_budgets_user_active ON budgets(userId, startDate, endDate)")
            db.execSQL("CREATE INDEX IF NOT EXISTS idx_goals_user_target ON goals(userId, targetDate)")
            
            // Initialize with sample data in debug mode (optional)
            INSTANCE?.let { database ->
                CoroutineScope(Dispatchers.IO).launch {
                    // Add sample data here if needed for development
                }
            }
        }
        
        override fun onOpen(db: SupportSQLiteDatabase) {
            super.onOpen(db)
            
            // Enable foreign key constraints
            db.execSQL("PRAGMA foreign_keys=ON")
            
            // Optimize database performance
            db.execSQL("PRAGMA journal_mode=WAL") // Write-Ahead Logging for better concurrency
            db.execSQL("PRAGMA synchronous=NORMAL") // Reasonable balance between safety and performance
        }
    }
}
