package com.wealthwise.android.data.remote.firebase

import com.google.firebase.functions.FirebaseFunctions
import com.google.firebase.functions.HttpsCallableResult
import kotlinx.coroutines.tasks.await
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Service for calling Firebase Cloud Functions.
 * 
 * Provides methods for:
 * - CSV import processing
 * - Tax calculation
 * - Analytics generation
 * - Data validation
 */
@Singleton
class CloudFunctionsService @Inject constructor(
    private val functions: FirebaseFunctions
) {
    
    companion object {
        private const val FUNCTION_IMPORT_CSV = "importTransactionsFromCSV"
        private const val FUNCTION_CALCULATE_TAX = "calculateTaxSummary"
        private const val FUNCTION_GENERATE_ANALYTICS = "generateAnalytics"
        private const val FUNCTION_VALIDATE_ACCOUNT = "validateAccountData"
    }
    
    /**
     * Import transactions from CSV data.
     * 
     * @param csvData CSV file content as string
     * @param accountId Target account ID
     * @param bankType Bank identifier for column mapping
     * @return Result containing import statistics or error
     */
    suspend fun importTransactionsFromCSV(
        csvData: String,
        accountId: String,
        bankType: String
    ): Result<ImportResult> {
        return try {
            val data = mapOf(
                "csvData" to csvData,
                "accountId" to accountId,
                "bankType" to bankType
            )
            
            val result = functions
                .getHttpsCallable(FUNCTION_IMPORT_CSV)
                .call(data)
                .await()
            
            val importResult = parseImportResult(result)
            Result.success(importResult)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Calculate tax summary for a given financial year.
     * 
     * @param userId User ID
     * @param financialYear Financial year (e.g., "2024-25")
     * @return Result containing tax calculation or error
     */
    suspend fun calculateTaxSummary(
        userId: String,
        financialYear: String
    ): Result<TaxSummary> {
        return try {
            val data = mapOf(
                "userId" to userId,
                "financialYear" to financialYear
            )
            
            val result = functions
                .getHttpsCallable(FUNCTION_CALCULATE_TAX)
                .call(data)
                .await()
            
            val taxSummary = parseTaxSummary(result)
            Result.success(taxSummary)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Generate analytics data for dashboard.
     * 
     * @param userId User ID
     * @param period Analytics period (MONTH, QUARTER, YEAR)
     * @return Result containing analytics data or error
     */
    suspend fun generateAnalytics(
        userId: String,
        period: AnalyticsPeriod
    ): Result<AnalyticsData> {
        return try {
            val data = mapOf(
                "userId" to userId,
                "period" to period.name
            )
            
            val result = functions
                .getHttpsCallable(FUNCTION_GENERATE_ANALYTICS)
                .call(data)
                .await()
            
            val analytics = parseAnalyticsData(result)
            Result.success(analytics)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Validate account data for consistency.
     * 
     * @param accountId Account ID to validate
     * @return Result containing validation report or error
     */
    suspend fun validateAccountData(accountId: String): Result<ValidationReport> {
        return try {
            val data = mapOf("accountId" to accountId)
            
            val result = functions
                .getHttpsCallable(FUNCTION_VALIDATE_ACCOUNT)
                .call(data)
                .await()
            
            val report = parseValidationReport(result)
            Result.success(report)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    // ============================================
    // Data Classes
    // ============================================
    
    @Serializable
    data class ImportResult(
        val success: Boolean,
        val importedCount: Int,
        val skippedCount: Int,
        val errorCount: Int,
        val errors: List<String> = emptyList()
    )
    
    @Serializable
    data class TaxSummary(
        val totalIncome: Double,
        val totalDeductions: Double,
        val taxableIncome: Double,
        val estimatedTax: Double,
        val breakdownByCategory: Map<String, Double>
    )
    
    @Serializable
    data class AnalyticsData(
        val totalIncome: Double,
        val totalExpenses: Double,
        val netSavings: Double,
        val categoryBreakdown: Map<String, Double>,
        val monthlyTrend: List<MonthlyData>,
        val topExpenseCategories: List<CategoryTotal>
    )
    
    @Serializable
    data class MonthlyData(
        val month: String,
        val income: Double,
        val expenses: Double,
        val savings: Double
    )
    
    @Serializable
    data class CategoryTotal(
        val category: String,
        val amount: Double,
        val percentage: Double
    )
    
    @Serializable
    data class ValidationReport(
        val isValid: Boolean,
        val issues: List<ValidationIssue>,
        val warnings: List<String>
    )
    
    @Serializable
    data class ValidationIssue(
        val severity: String,
        val field: String,
        val message: String
    )
    
    enum class AnalyticsPeriod {
        MONTH,
        QUARTER,
        YEAR,
        ALL_TIME
    }
    
    // ============================================
    // Parsing Methods
    // ============================================
    
    private fun parseImportResult(result: HttpsCallableResult): ImportResult {
        val data = result.data as? Map<*, *> ?: throw Exception("Invalid result format")
        
        return ImportResult(
            success = data["success"] as? Boolean ?: false,
            importedCount = (data["importedCount"] as? Number)?.toInt() ?: 0,
            skippedCount = (data["skippedCount"] as? Number)?.toInt() ?: 0,
            errorCount = (data["errorCount"] as? Number)?.toInt() ?: 0,
            errors = (data["errors"] as? List<*>)?.mapNotNull { it as? String } ?: emptyList()
        )
    }
    
    private fun parseTaxSummary(result: HttpsCallableResult): TaxSummary {
        val data = result.data as? Map<*, *> ?: throw Exception("Invalid result format")
        
        return TaxSummary(
            totalIncome = (data["totalIncome"] as? Number)?.toDouble() ?: 0.0,
            totalDeductions = (data["totalDeductions"] as? Number)?.toDouble() ?: 0.0,
            taxableIncome = (data["taxableIncome"] as? Number)?.toDouble() ?: 0.0,
            estimatedTax = (data["estimatedTax"] as? Number)?.toDouble() ?: 0.0,
            breakdownByCategory = (data["breakdownByCategory"] as? Map<*, *>)
                ?.mapKeys { it.key as String }
                ?.mapValues { (it.value as? Number)?.toDouble() ?: 0.0 }
                ?: emptyMap()
        )
    }
    
    private fun parseAnalyticsData(result: HttpsCallableResult): AnalyticsData {
        val data = result.data as? Map<*, *> ?: throw Exception("Invalid result format")
        
        return AnalyticsData(
            totalIncome = (data["totalIncome"] as? Number)?.toDouble() ?: 0.0,
            totalExpenses = (data["totalExpenses"] as? Number)?.toDouble() ?: 0.0,
            netSavings = (data["netSavings"] as? Number)?.toDouble() ?: 0.0,
            categoryBreakdown = (data["categoryBreakdown"] as? Map<*, *>)
                ?.mapKeys { it.key as String }
                ?.mapValues { (it.value as? Number)?.toDouble() ?: 0.0 }
                ?: emptyMap(),
            monthlyTrend = (data["monthlyTrend"] as? List<*>)?.mapNotNull { item ->
                (item as? Map<*, *>)?.let {
                    MonthlyData(
                        month = it["month"] as? String ?: "",
                        income = (it["income"] as? Number)?.toDouble() ?: 0.0,
                        expenses = (it["expenses"] as? Number)?.toDouble() ?: 0.0,
                        savings = (it["savings"] as? Number)?.toDouble() ?: 0.0
                    )
                }
            } ?: emptyList(),
            topExpenseCategories = (data["topExpenseCategories"] as? List<*>)?.mapNotNull { item ->
                (item as? Map<*, *>)?.let {
                    CategoryTotal(
                        category = it["category"] as? String ?: "",
                        amount = (it["amount"] as? Number)?.toDouble() ?: 0.0,
                        percentage = (it["percentage"] as? Number)?.toDouble() ?: 0.0
                    )
                }
            } ?: emptyList()
        )
    }
    
    private fun parseValidationReport(result: HttpsCallableResult): ValidationReport {
        val data = result.data as? Map<*, *> ?: throw Exception("Invalid result format")
        
        return ValidationReport(
            isValid = data["isValid"] as? Boolean ?: false,
            issues = (data["issues"] as? List<*>)?.mapNotNull { item ->
                (item as? Map<*, *>)?.let {
                    ValidationIssue(
                        severity = it["severity"] as? String ?: "",
                        field = it["field"] as? String ?: "",
                        message = it["message"] as? String ?: ""
                    )
                }
            } ?: emptyList(),
            warnings = (data["warnings"] as? List<*>)?.mapNotNull { it as? String } ?: emptyList()
        )
    }
}
