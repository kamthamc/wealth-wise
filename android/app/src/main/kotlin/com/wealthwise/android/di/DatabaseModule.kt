package com.wealthwise.android.di

import android.content.Context
import com.wealthwise.android.data.local.WealthWiseDatabase
import com.wealthwise.android.data.local.dao.AccountDao
import com.wealthwise.android.data.local.dao.BudgetDao
import com.wealthwise.android.data.local.dao.GoalDao
import com.wealthwise.android.data.local.dao.TransactionDao
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

/**
 * Hilt module for providing database dependencies.
 */
@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {
    
    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext context: Context): WealthWiseDatabase {
        return WealthWiseDatabase.getInstance(context)
    }
    
    @Provides
    fun provideAccountDao(database: WealthWiseDatabase): AccountDao {
        return database.accountDao()
    }
    
    @Provides
    fun provideTransactionDao(database: WealthWiseDatabase): TransactionDao {
        return database.transactionDao()
    }
    
    @Provides
    fun provideBudgetDao(database: WealthWiseDatabase): BudgetDao {
        return database.budgetDao()
    }
    
    @Provides
    fun provideGoalDao(database: WealthWiseDatabase): GoalDao {
        return database.goalDao()
    }
}
