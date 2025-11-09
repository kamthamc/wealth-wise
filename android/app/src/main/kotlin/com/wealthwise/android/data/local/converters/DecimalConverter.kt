package com.wealthwise.android.data.local.converters

import androidx.room.TypeConverter
import java.math.BigDecimal

/**
 * Room TypeConverter for BigDecimal
 * 
 * Converts BigDecimal to/from String for database storage
 * Preserves precision for financial calculations
 */
class DecimalConverter {
    
    @TypeConverter
    fun fromBigDecimal(value: BigDecimal?): String? {
        return value?.toPlainString()
    }
    
    @TypeConverter
    fun toBigDecimal(value: String?): BigDecimal? {
        return value?.let {
            try {
                BigDecimal(it)
            } catch (e: NumberFormatException) {
                null
            }
        }
    }
}
