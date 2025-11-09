package com.wealthwise.android.data.local.converters

import androidx.room.TypeConverter
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

/**
 * Room TypeConverter for List<String>
 * 
 * Converts List<String> to/from JSON string for database storage
 * Used for budget categories and other string collections
 */
class StringListConverter {
    
    private val json = Json { 
        ignoreUnknownKeys = true
        encodeDefaults = true
    }
    
    @TypeConverter
    fun fromStringList(value: List<String>?): String? {
        return value?.let { json.encodeToString(it) }
    }
    
    @TypeConverter
    fun toStringList(value: String?): List<String>? {
        return value?.let {
            try {
                json.decodeFromString<List<String>>(it)
            } catch (e: Exception) {
                emptyList()
            }
        }
    }
}
