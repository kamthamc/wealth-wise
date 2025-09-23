# Cross-Platform Localization Architecture for WealthWise

## Overview

This document outlines the unified localization architecture that allows sharing localized strings and cultural adaptations across iOS (Swift), Android (Kotlin), and Windows (.NET) platforms while maintaining platform-specific optimizations.

## Architecture Principles

### 1. Single Source of Truth
- **Centralized JSON files** containing all localized strings
- **Cultural adaptations** defined once, applied everywhere
- **Version synchronization** across all platforms
- **Automated consistency validation**

### 2. Platform-Specific Adapters
- **iOS**: JSON → .strings/.stringsdict conversion
- **Android**: JSON → strings.xml/plurals.xml conversion  
- **Windows**: JSON → .resx/.resw conversion
- **Build-time generation** for optimal runtime performance

### 3. Modern Localization Patterns
- **Lazy loading** with caching for performance
- **Fallback mechanisms** with graceful degradation
- **RTL language support** with proper text direction
- **Cultural number formatting** (Lakh/Crore vs Million/Billion)
- **LLM integration** for automated translation workflows

## File Structure

```
localization/
├── shared/
│   ├── strings/
│   │   ├── en-IN.json          # English (India) - Primary
│   │   ├── hi-IN.json          # Hindi (India)
│   │   ├── ta-IN.json          # Tamil (India)
│   │   ├── bn-IN.json          # Bengali (India)
│   │   ├── en-US.json          # English (US)
│   │   ├── de-DE.json          # German (Germany)
│   │   ├── fr-FR.json          # French (France)
│   │   ├── ja-JP.json          # Japanese (Japan)
│   │   ├── ar-SA.json          # Arabic (Saudi Arabia)
│   │   └── ...
│   ├── metadata/
│   │   ├── locales.json        # Supported locales configuration
│   │   ├── cultural-formats.json # Number/date/currency formats
│   │   └── plurals.json        # Plural rules per language
│   └── schema/
│       ├── string-keys.schema.json # JSON schema for validation
│       └── cultural.schema.json    # Cultural adaptations schema
├── platforms/
│   ├── ios/
│   │   ├── LocalizationAdapter.swift
│   │   ├── CulturalFormatter.swift
│   │   └── generated/           # Auto-generated .strings files
│   ├── android/
│   │   ├── LocalizationAdapter.kt
│   │   ├── CulturalFormatter.kt
│   │   └── generated/           # Auto-generated strings.xml files
│   └── windows/
│       ├── LocalizationAdapter.cs
│       ├── CulturalFormatter.cs
│       └── generated/           # Auto-generated .resx files
└── tools/
    ├── sync-localization.js     # Build-time synchronization
    ├── validate-strings.js      # Consistency validation
    └── generate-platforms.js   # Platform-specific generation
```

## Shared JSON Schema

### String Keys Structure
```json
{
  "$schema": "./schema/string-keys.schema.json",
  "locale": "en-IN",
  "version": "1.0.0",
  "lastUpdated": "2025-09-21T19:40:00Z",
  "categories": {
    "assetTypes": {
      "stocks": "Stocks",
      "mutualFunds": "Mutual Funds",
      "realEstate": "Real Estate",
      "fixedDeposits": "Fixed Deposits",
      "goldBonds": "Gold Bonds",
      "ppf": "Public Provident Fund",
      "epf": "Employee Provident Fund",
      "nsc": "National Savings Certificate"
    },
    "currencies": {
      "inr": "Indian Rupee",
      "usd": "US Dollar",
      "eur": "Euro",
      "gbp": "British Pound",
      "jpy": "Japanese Yen"
    },
    "countries": {
      "india": "India",
      "unitedStates": "United States",
      "unitedKingdom": "United Kingdom",
      "germany": "Germany",
      "france": "France"
    },
    "general": {
      "appName": "WealthWise",
      "loading": "Loading...",
      "error": "Error",
      "cancel": "Cancel",
      "save": "Save",
      "delete": "Delete",
      "settings": "Settings"
    },
    "financial": {
      "portfolio": "Portfolio",
      "assets": "Assets",
      "liabilities": "Liabilities",
      "netWorth": "Net Worth",
      "totalValue": "Total Value",
      "unrealizedGain": "Unrealized Gain",
      "realizedGain": "Realized Gain"
    },
    "numberFormats": {
      "lakh": "Lakh",
      "crore": "Crore",
      "million": "Million",
      "billion": "Billion",
      "thousand": "Thousand"
    },
    "plurals": {
      "itemCount": {
        "one": "%d item",
        "other": "%d items"
      },
      "transactionCount": {
        "one": "%d transaction",
        "other": "%d transactions"
      }
    }
  }
}
```

### Cultural Formats Configuration
```json
{
  "$schema": "./schema/cultural.schema.json",
  "version": "1.0.0",
  "formats": {
    "en-IN": {
      "numberSystem": "indian",
      "currencySymbol": "₹",
      "decimalSeparator": ".",
      "groupingSeparator": ",",
      "groupingPattern": "##,##,###",
      "dateFormat": "dd/MM/yyyy",
      "timeFormat": "HH:mm",
      "isRTL": false,
      "culturalUnits": ["lakh", "crore"]
    },
    "hi-IN": {
      "numberSystem": "indian",
      "currencySymbol": "₹",
      "decimalSeparator": ".",
      "groupingSeparator": ",",
      "groupingPattern": "##,##,###",
      "dateFormat": "dd/MM/yyyy",
      "timeFormat": "HH:mm",
      "isRTL": false,
      "culturalUnits": ["लाख", "करोड़"]
    },
    "ar-SA": {
      "numberSystem": "international",
      "currencySymbol": "ر.س",
      "decimalSeparator": ".",
      "groupingSeparator": ",",
      "groupingPattern": "###,###,###",
      "dateFormat": "dd/MM/yyyy",
      "timeFormat": "HH:mm",
      "isRTL": true,
      "culturalUnits": ["million", "billion"]
    }
  }
}
```

## Platform-Specific Adapters

### iOS Swift Adapter
```swift
import Foundation
import Combine

/// Cross-platform localization adapter for iOS
/// Integrates with the existing LocalizationManager while supporting shared JSON resources
@available(iOS 16.0, macOS 13.0, *)
public class CrossPlatformLocalizationAdapter: ObservableObject {
    
    // MARK: - Properties
    @Published public private(set) var currentLocale: Locale = .current
    @Published public private(set) var culturalFormats: CulturalFormats?
    
    private var sharedStrings: [String: [String: Any]] = [:]
    private var culturalConfig: [String: CulturalFormats] = [:]
    
    // MARK: - Initialization
    public init() {
        loadSharedResources()
        setupCulturalFormats()
    }
    
    // MARK: - Public Interface
    
    /// Get localized string from shared JSON resources
    public func localizedString(category: String, key: String, locale: String? = nil) -> String {
        let targetLocale = locale ?? currentLocale.identifier
        
        if let categoryStrings = sharedStrings[targetLocale]?[category] as? [String: String],
           let localizedString = categoryStrings[key] {
            return localizedString
        }
        
        // Fallback to English (India)
        if targetLocale != "en-IN",
           let fallbackStrings = sharedStrings["en-IN"]?[category] as? [String: String],
           let fallbackString = fallbackStrings[key] {
            return fallbackString
        }
        
        // Last resort: return key with formatting
        return key.replacingOccurrences(of: "_", with: " ").capitalized
    }
    
    /// Format number with cultural preferences
    public func formatNumber(_ value: Decimal, style: NumberFormattingStyle = .default) -> String {
        guard let formats = culturalFormats else {
            return String(describing: value)
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = currentLocale
        
        let doubleValue = (value as NSDecimalNumber).doubleValue
        
        if formats.numberSystem == "indian" {
            return formatIndianNumberSystem(doubleValue)
        } else {
            return formatInternationalNumberSystem(doubleValue)
        }
    }
    
    /// Check if current locale is RTL
    public func isRTL() -> Bool {
        return culturalFormats?.isRTL ?? false
    }
    
    // MARK: - Private Methods
    
    private func loadSharedResources() {
        // Load from shared JSON files in the app bundle
        guard let resourcesPath = Bundle.main.path(forResource: "SharedLocalizations", ofType: "bundle"),
              let resourcesBundle = Bundle(path: resourcesPath) else {
            print("⚠️ Shared localization resources not found")
            return
        }
        
        for locale in getSupportedLocales() {
            if let path = resourcesBundle.path(forResource: locale, ofType: "json"),
               let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let categories = json["categories"] as? [String: Any] {
                sharedStrings[locale] = categories
            }
        }
    }
    
    private func setupCulturalFormats() {
        guard let path = Bundle.main.path(forResource: "cultural-formats", ofType: "json"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let formats = json["formats"] as? [String: [String: Any]] else {
            return
        }
        
        for (locale, formatData) in formats {
            if let cultural = CulturalFormats(from: formatData) {
                culturalConfig[locale] = cultural
            }
        }
        
        culturalFormats = culturalConfig[currentLocale.identifier] ?? culturalConfig["en-IN"]
    }
    
    private func formatIndianNumberSystem(_ value: Double) -> String {
        if value >= 10_000_000 {
            return String(format: "%.2f %@", value / 10_000_000, localizedString(category: "numberFormats", key: "crore"))
        } else if value >= 100_000 {
            return String(format: "%.2f %@", value / 100_000, localizedString(category: "numberFormats", key: "lakh"))
        } else if value >= 1_000 {
            return String(format: "%.2f %@", value / 1_000, localizedString(category: "numberFormats", key: "thousand"))
        }
        return String(format: "%.2f", value)
    }
    
    private func formatInternationalNumberSystem(_ value: Double) -> String {
        if value >= 1_000_000_000 {
            return String(format: "%.2f %@", value / 1_000_000_000, localizedString(category: "numberFormats", key: "billion"))
        } else if value >= 1_000_000 {
            return String(format: "%.2f %@", value / 1_000_000, localizedString(category: "numberFormats", key: "million"))
        } else if value >= 1_000 {
            return String(format: "%.2f %@", value / 1_000, localizedString(category: "numberFormats", key: "thousand"))
        }
        return String(format: "%.2f", value)
    }
    
    private func getSupportedLocales() -> [String] {
        return [
            "en-IN", "hi-IN", "ta-IN", "bn-IN", "te-IN", "mr-IN", "gu-IN", 
            "kn-IN", "ml-IN", "pa-IN", "en-US", "en-GB", "en-CA", "en-AU", 
            "de-DE", "fr-FR", "ja-JP", "zh-CN", "ar-SA", "es-ES", "pt-BR", 
            "ru-RU", "ko-KR"
        ]
    }
}

// MARK: - Supporting Types

public struct CulturalFormats {
    let numberSystem: String
    let currencySymbol: String
    let decimalSeparator: String
    let groupingSeparator: String
    let groupingPattern: String
    let dateFormat: String
    let timeFormat: String
    let isRTL: Bool
    let culturalUnits: [String]
    
    init?(from data: [String: Any]) {
        guard let numberSystem = data["numberSystem"] as? String,
              let currencySymbol = data["currencySymbol"] as? String,
              let decimalSeparator = data["decimalSeparator"] as? String,
              let groupingSeparator = data["groupingSeparator"] as? String,
              let groupingPattern = data["groupingPattern"] as? String,
              let dateFormat = data["dateFormat"] as? String,
              let timeFormat = data["timeFormat"] as? String,
              let isRTL = data["isRTL"] as? Bool,
              let culturalUnits = data["culturalUnits"] as? [String] else {
            return nil
        }
        
        self.numberSystem = numberSystem
        self.currencySymbol = currencySymbol
        self.decimalSeparator = decimalSeparator
        self.groupingSeparator = groupingSeparator
        self.groupingPattern = groupingPattern
        self.dateFormat = dateFormat
        self.timeFormat = timeFormat
        self.isRTL = isRTL
        self.culturalUnits = culturalUnits
    }
}

public enum NumberFormattingStyle {
    case `default`
    case currency
    case percentage
    case compact
}

// MARK: - SwiftUI Integration

extension Text {
    /// Initialize Text with cross-platform localized string
    public init(crossPlatform category: String, key: String) {
        let adapter = CrossPlatformLocalizationAdapter()
        self = Text(adapter.localizedString(category: category, key: key))
    }
}
```

### Android Kotlin Adapter
```kotlin
// CrossPlatformLocalizationAdapter.kt
package com.wealthwise.localization

import android.content.Context
import android.content.res.Configuration
import kotlinx.serialization.json.*
import java.util.*

/**
 * Cross-platform localization adapter for Android
 * Integrates with Android's localization system while supporting shared JSON resources
 */
class CrossPlatformLocalizationAdapter(private val context: Context) {
    
    private val sharedStrings = mutableMapOf<String, Map<String, Any>>()
    private val culturalConfig = mutableMapMap<String, CulturalFormats>()
    private var currentLocale: Locale = Locale.getDefault()
    private var culturalFormats: CulturalFormats? = null
    
    init {
        loadSharedResources()
        setupCulturalFormats()
    }
    
    /**
     * Get localized string from shared JSON resources
     */
    fun localizedString(category: String, key: String, locale: String? = null): String {
        val targetLocale = locale ?: currentLocale.toLanguageTag()
        
        sharedStrings[targetLocale]?.let { localeData ->
            (localeData[category] as? Map<String, String>)?.get(key)?.let { localizedString ->
                return localizedString
            }
        }
        
        // Fallback to English (India)
        if (targetLocale != "en-IN") {
            sharedStrings["en-IN"]?.let { fallbackData ->
                (fallbackData[category] as? Map<String, String>)?.get(key)?.let { fallbackString ->
                    return fallbackString
                }
            }
        }
        
        // Last resort: return formatted key
        return key.replace("_", " ").replaceFirstChar { 
            if (it.isLowerCase()) it.titlecase(Locale.getDefault()) else it.toString() 
        }
    }
    
    /**
     * Format number with cultural preferences
     */
    fun formatNumber(value: Double, style: NumberFormattingStyle = NumberFormattingStyle.DEFAULT): String {
        val formats = culturalFormats ?: return value.toString()
        
        return when (formats.numberSystem) {
            "indian" -> formatIndianNumberSystem(value)
            else -> formatInternationalNumberSystem(value)
        }
    }
    
    /**
     * Check if current locale is RTL
     */
    fun isRTL(): Boolean {
        return culturalFormats?.isRTL ?: false
    }
    
    private fun loadSharedResources() {
        try {
            getSupportedLocales().forEach { locale ->
                val inputStream = context.assets.open("shared_localization/$locale.json")
                val json = Json.parseToJsonElement(inputStream.bufferedReader().readText()).jsonObject
                val categories = json["categories"]?.jsonObject
                
                categories?.let {
                    val categoryMap = mutableMapOf<String, Any>()
                    it.forEach { (key, value) ->
                        when (value) {
                            is JsonObject -> {
                                val stringMap = mutableMapOf<String, String>()
                                value.forEach { (subKey, subValue) ->
                                    if (subValue is JsonPrimitive && subValue.isString) {
                                        stringMap[subKey] = subValue.content
                                    }
                                }
                                categoryMap[key] = stringMap
                            }
                        }
                    }
                    sharedStrings[locale] = categoryMap
                }
            }
        } catch (e: Exception) {
            println("⚠️ Failed to load shared localization resources: ${e.message}")
        }
    }
    
    private fun setupCulturalFormats() {
        try {
            val inputStream = context.assets.open("shared_localization/cultural-formats.json")
            val json = Json.parseToJsonElement(inputStream.bufferedReader().readText()).jsonObject
            val formats = json["formats"]?.jsonObject
            
            formats?.forEach { (locale, formatData) ->
                if (formatData is JsonObject) {
                    CulturalFormats.fromJson(formatData)?.let { cultural ->
                        culturalConfig[locale] = cultural
                    }
                }
            }
            
            culturalFormats = culturalConfig[currentLocale.toLanguageTag()] 
                ?: culturalConfig["en-IN"]
                
        } catch (e: Exception) {
            println("⚠️ Failed to load cultural formats: ${e.message}")
        }
    }
    
    private fun formatIndianNumberSystem(value: Double): String {
        return when {
            value >= 10_000_000 -> "%.2f %s".format(value / 10_000_000, localizedString("numberFormats", "crore"))
            value >= 100_000 -> "%.2f %s".format(value / 100_000, localizedString("numberFormats", "lakh"))
            value >= 1_000 -> "%.2f %s".format(value / 1_000, localizedString("numberFormats", "thousand"))
            else -> "%.2f".format(value)
        }
    }
    
    private fun formatInternationalNumberSystem(value: Double): String {
        return when {
            value >= 1_000_000_000 -> "%.2f %s".format(value / 1_000_000_000, localizedString("numberFormats", "billion"))
            value >= 1_000_000 -> "%.2f %s".format(value / 1_000_000, localizedString("numberFormats", "million"))
            value >= 1_000 -> "%.2f %s".format(value / 1_000, localizedString("numberFormats", "thousand"))
            else -> "%.2f".format(value)
        }
    }
    
    private fun getSupportedLocales(): List<String> {
        return listOf(
            "en-IN", "hi-IN", "ta-IN", "bn-IN", "te-IN", "mr-IN", "gu-IN", 
            "kn-IN", "ml-IN", "pa-IN", "en-US", "en-GB", "en-CA", "en-AU", 
            "de-DE", "fr-FR", "ja-JP", "zh-CN", "ar-SA", "es-ES", "pt-BR", 
            "ru-RU", "ko-KR"
        )
    }
}

// Supporting Types
data class CulturalFormats(
    val numberSystem: String,
    val currencySymbol: String,
    val decimalSeparator: String,
    val groupingSeparator: String,
    val groupingPattern: String,
    val dateFormat: String,
    val timeFormat: String,
    val isRTL: Boolean,
    val culturalUnits: List<String>
) {
    companion object {
        fun fromJson(json: JsonObject): CulturalFormats? {
            return try {
                CulturalFormats(
                    numberSystem = json["numberSystem"]?.jsonPrimitive?.content ?: return null,
                    currencySymbol = json["currencySymbol"]?.jsonPrimitive?.content ?: return null,
                    decimalSeparator = json["decimalSeparator"]?.jsonPrimitive?.content ?: return null,
                    groupingSeparator = json["groupingSeparator"]?.jsonPrimitive?.content ?: return null,
                    groupingPattern = json["groupingPattern"]?.jsonPrimitive?.content ?: return null,
                    dateFormat = json["dateFormat"]?.jsonPrimitive?.content ?: return null,
                    timeFormat = json["timeFormat"]?.jsonPrimitive?.content ?: return null,
                    isRTL = json["isRTL"]?.jsonPrimitive?.boolean ?: return null,
                    culturalUnits = json["culturalUnits"]?.jsonArray?.map { 
                        it.jsonPrimitive.content 
                    } ?: return null
                )
            } catch (e: Exception) {
                null
            }
        }
    }
}

enum class NumberFormattingStyle {
    DEFAULT, CURRENCY, PERCENTAGE, COMPACT
}
```

### Windows .NET Adapter
```csharp
// CrossPlatformLocalizationAdapter.cs
using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Text.Json;
using System.ComponentModel;
using System.Runtime.CompilerServices;

namespace WealthWise.Localization
{
    /// <summary>
    /// Cross-platform localization adapter for Windows
    /// Integrates with .NET's localization system while supporting shared JSON resources
    /// </summary>
    public class CrossPlatformLocalizationAdapter : INotifyPropertyChanged
    {
        private readonly Dictionary<string, Dictionary<string, object>> _sharedStrings = new();
        private readonly Dictionary<string, CulturalFormats> _culturalConfig = new();
        private CultureInfo _currentCulture = CultureInfo.CurrentCulture;
        private CulturalFormats _culturalFormats;

        public event PropertyChangedEventHandler PropertyChanged;

        public CultureInfo CurrentCulture
        {
            get => _currentCulture;
            set
            {
                _currentCulture = value;
                OnPropertyChanged();
                SetupCulturalFormats();
            }
        }

        public CulturalFormats CulturalFormats
        {
            get => _culturalFormats;
            private set
            {
                _culturalFormats = value;
                OnPropertyChanged();
            }
        }

        public CrossPlatformLocalizationAdapter()
        {
            LoadSharedResources();
            SetupCulturalFormats();
        }

        /// <summary>
        /// Get localized string from shared JSON resources
        /// </summary>
        public string LocalizedString(string category, string key, string locale = null)
        {
            var targetLocale = locale ?? _currentCulture.Name;

            if (_sharedStrings.TryGetValue(targetLocale, out var localeData) &&
                localeData.TryGetValue(category, out var categoryData) &&
                categoryData is Dictionary<string, object> categoryStrings &&
                categoryStrings.TryGetValue(key, out var localizedString))
            {
                return localizedString.ToString();
            }

            // Fallback to English (India)
            if (targetLocale != "en-IN" &&
                _sharedStrings.TryGetValue("en-IN", out var fallbackData) &&
                fallbackData.TryGetValue(category, out var fallbackCategory) &&
                fallbackCategory is Dictionary<string, object> fallbackStrings &&
                fallbackStrings.TryGetValue(key, out var fallbackString))
            {
                return fallbackString.ToString();
            }

            // Last resort: return formatted key
            return key.Replace("_", " ").Replace(".", " ");
        }

        /// <summary>
        /// Format number with cultural preferences
        /// </summary>
        public string FormatNumber(decimal value, NumberFormattingStyle style = NumberFormattingStyle.Default)
        {
            if (_culturalFormats == null)
                return value.ToString();

            var doubleValue = (double)value;

            return _culturalFormats.NumberSystem switch
            {
                "indian" => FormatIndianNumberSystem(doubleValue),
                _ => FormatInternationalNumberSystem(doubleValue)
            };
        }

        /// <summary>
        /// Check if current locale is RTL
        /// </summary>
        public bool IsRTL()
        {
            return _culturalFormats?.IsRTL ?? false;
        }

        private void LoadSharedResources()
        {
            try
            {
                var baseDirectory = AppDomain.CurrentDomain.BaseDirectory;
                var localizationPath = Path.Combine(baseDirectory, "SharedLocalization");

                if (!Directory.Exists(localizationPath))
                {
                    Console.WriteLine("⚠️ Shared localization directory not found");
                    return;
                }

                foreach (var locale in GetSupportedLocales())
                {
                    var filePath = Path.Combine(localizationPath, $"{locale}.json");
                    if (File.Exists(filePath))
                    {
                        var json = File.ReadAllText(filePath);
                        var document = JsonDocument.Parse(json);
                        
                        if (document.RootElement.TryGetProperty("categories", out var categories))
                        {
                            var categoryDict = new Dictionary<string, object>();
                            
                            foreach (var category in categories.EnumerateObject())
                            {
                                var stringDict = new Dictionary<string, object>();
                                foreach (var item in category.Value.EnumerateObject())
                                {
                                    stringDict[item.Name] = item.Value.GetString();
                                }
                                categoryDict[category.Name] = stringDict;
                            }
                            
                            _sharedStrings[locale] = categoryDict;
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"⚠️ Failed to load shared localization resources: {ex.Message}");
            }
        }

        private void SetupCulturalFormats()
        {
            try
            {
                var baseDirectory = AppDomain.CurrentDomain.BaseDirectory;
                var formatPath = Path.Combine(baseDirectory, "SharedLocalization", "cultural-formats.json");

                if (File.Exists(formatPath))
                {
                    var json = File.ReadAllText(formatPath);
                    var document = JsonDocument.Parse(json);
                    
                    if (document.RootElement.TryGetProperty("formats", out var formats))
                    {
                        foreach (var format in formats.EnumerateObject())
                        {
                            var cultural = CulturalFormats.FromJson(format.Value);
                            if (cultural != null)
                            {
                                _culturalConfig[format.Name] = cultural;
                            }
                        }
                    }
                }

                CulturalFormats = _culturalConfig.TryGetValue(_currentCulture.Name, out var current) 
                    ? current 
                    : _culturalConfig.GetValueOrDefault("en-IN");
                    
            }
            catch (Exception ex)
            {
                Console.WriteLine($"⚠️ Failed to load cultural formats: {ex.Message}");
            }
        }

        private string FormatIndianNumberSystem(double value)
        {
            return value switch
            {
                >= 10_000_000 => $"{value / 10_000_000:F2} {LocalizedString("numberFormats", "crore")}",
                >= 100_000 => $"{value / 100_000:F2} {LocalizedString("numberFormats", "lakh")}",
                >= 1_000 => $"{value / 1_000:F2} {LocalizedString("numberFormats", "thousand")}",
                _ => $"{value:F2}"
            };
        }

        private string FormatInternationalNumberSystem(double value)
        {
            return value switch
            {
                >= 1_000_000_000 => $"{value / 1_000_000_000:F2} {LocalizedString("numberFormats", "billion")}",
                >= 1_000_000 => $"{value / 1_000_000:F2} {LocalizedString("numberFormats", "million")}",
                >= 1_000 => $"{value / 1_000:F2} {LocalizedString("numberFormats", "thousand")}",
                _ => $"{value:F2}"
            };
        }

        private static List<string> GetSupportedLocales()
        {
            return new List<string>
            {
                "en-IN", "hi-IN", "ta-IN", "bn-IN", "te-IN", "mr-IN", "gu-IN", 
                "kn-IN", "ml-IN", "pa-IN", "en-US", "en-GB", "en-CA", "en-AU", 
                "de-DE", "fr-FR", "ja-JP", "zh-CN", "ar-SA", "es-ES", "pt-BR", 
                "ru-RU", "ko-KR"
            };
        }

        protected virtual void OnPropertyChanged([CallerMemberName] string propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }

    // Supporting Types
    public class CulturalFormats
    {
        public string NumberSystem { get; set; }
        public string CurrencySymbol { get; set; }
        public string DecimalSeparator { get; set; }
        public string GroupingSeparator { get; set; }
        public string GroupingPattern { get; set; }
        public string DateFormat { get; set; }
        public string TimeFormat { get; set; }
        public bool IsRTL { get; set; }
        public List<string> CulturalUnits { get; set; }

        public static CulturalFormats FromJson(JsonElement json)
        {
            try
            {
                return new CulturalFormats
                {
                    NumberSystem = json.GetProperty("numberSystem").GetString(),
                    CurrencySymbol = json.GetProperty("currencySymbol").GetString(),
                    DecimalSeparator = json.GetProperty("decimalSeparator").GetString(),
                    GroupingSeparator = json.GetProperty("groupingSeparator").GetString(),
                    GroupingPattern = json.GetProperty("groupingPattern").GetString(),
                    DateFormat = json.GetProperty("dateFormat").GetString(),
                    TimeFormat = json.GetProperty("timeFormat").GetString(),
                    IsRTL = json.GetProperty("isRTL").GetBoolean(),
                    CulturalUnits = json.GetProperty("culturalUnits")
                        .EnumerateArray()
                        .Select(x => x.GetString())
                        .ToList()
                };
            }
            catch
            {
                return null;
            }
        }
    }

    public enum NumberFormattingStyle
    {
        Default,
        Currency,
        Percentage,
        Compact
    }
}
```

## Build-Time Synchronization Tools

### Sync Script (Node.js)
```javascript
// tools/sync-localization.js
const fs = require('fs');
const path = require('path');

/**
 * Build-time tool to synchronize localization across platforms
 * Generates platform-specific files from shared JSON resources
 */
class LocalizationSyncer {
    constructor() {
        this.sharedPath = path.join(__dirname, '../localization/shared');
        this.platformsPath = path.join(__dirname, '../localization/platforms');
        this.supportedLocales = [
            'en-IN', 'hi-IN', 'ta-IN', 'bn-IN', 'te-IN', 'mr-IN', 'gu-IN', 
            'kn-IN', 'ml-IN', 'pa-IN', 'en-US', 'en-GB', 'en-CA', 'en-AU', 
            'de-DE', 'fr-FR', 'ja-JP', 'zh-CN', 'ar-SA', 'es-ES', 'pt-BR', 
            'ru-RU', 'ko-KR'
        ];
    }

    async syncAll() {
        console.log('🔄 Starting cross-platform localization sync...');
        
        try {
            await this.generateiOSFiles();
            await this.generateAndroidFiles();
            await this.generateWindowsFiles();
            
            console.log('✅ Cross-platform localization sync completed successfully');
        } catch (error) {
            console.error('❌ Localization sync failed:', error.message);
            process.exit(1);
        }
    }

    async generateiOSFiles() {
        console.log('📱 Generating iOS .strings files...');
        
        const iosPath = path.join(this.platformsPath, 'ios/generated');
        this.ensureDirectoryExists(iosPath);

        for (const locale of this.supportedLocales) {
            const jsonPath = path.join(this.sharedPath, 'strings', `${locale}.json`);
            
            if (fs.existsSync(jsonPath)) {
                const jsonData = JSON.parse(fs.readFileSync(jsonPath, 'utf-8'));
                const stringsContent = this.convertToiOSStrings(jsonData.categories);
                
                const localeDir = path.join(iosPath, `${locale}.lproj`);
                this.ensureDirectoryExists(localeDir);
                
                fs.writeFileSync(
                    path.join(localeDir, 'Localizable.strings'),
                    stringsContent,
                    'utf-8'
                );
            }
        }
    }

    async generateAndroidFiles() {
        console.log('🤖 Generating Android strings.xml files...');
        
        const androidPath = path.join(this.platformsPath, 'android/generated');
        this.ensureDirectoryExists(androidPath);

        for (const locale of this.supportedLocales) {
            const jsonPath = path.join(this.sharedPath, 'strings', `${locale}.json`);
            
            if (fs.existsSync(jsonPath)) {
                const jsonData = JSON.parse(fs.readFileSync(jsonPath, 'utf-8'));
                const xmlContent = this.convertToAndroidXML(jsonData.categories);
                
                const localeDir = path.join(androidPath, `values-${locale.replace('-', '-r')}`);
                this.ensureDirectoryExists(localeDir);
                
                fs.writeFileSync(
                    path.join(localeDir, 'strings.xml'),
                    xmlContent,
                    'utf-8'
                );
            }
        }
    }

    async generateWindowsFiles() {
        console.log('🪟 Generating Windows .resx files...');
        
        const windowsPath = path.join(this.platformsPath, 'windows/generated');
        this.ensureDirectoryExists(windowsPath);

        for (const locale of this.supportedLocales) {
            const jsonPath = path.join(this.sharedPath, 'strings', `${locale}.json`);
            
            if (fs.existsSync(jsonPath)) {
                const jsonData = JSON.parse(fs.readFileSync(jsonPath, 'utf-8'));
                const resxContent = this.convertToWindowsResx(jsonData.categories);
                
                const fileName = locale === 'en-IN' 
                    ? 'Strings.resx' 
                    : `Strings.${locale}.resx`;
                
                fs.writeFileSync(
                    path.join(windowsPath, fileName),
                    resxContent,
                    'utf-8'
                );
            }
        }
    }

    convertToiOSStrings(categories) {
        let content = '// Auto-generated from shared JSON resources\n';
        content += `// Generated on: ${new Date().toISOString()}\n\n`;

        for (const [categoryName, categoryData] of Object.entries(categories)) {
            content += `/* ${categoryName.charAt(0).toUpperCase() + categoryName.slice(1)} */\n`;
            
            if (typeof categoryData === 'object' && categoryData !== null) {
                for (const [key, value] of Object.entries(categoryData)) {
                    if (typeof value === 'string') {
                        const escapedValue = value.replace(/"/g, '\\"');
                        content += `"${categoryName}.${key}" = "${escapedValue}";\n`;
                    }
                }
            }
            content += '\n';
        }

        return content;
    }

    convertToAndroidXML(categories) {
        let content = '<?xml version="1.0" encoding="utf-8"?>\n';
        content += '<!-- Auto-generated from shared JSON resources -->\n';
        content += `<!-- Generated on: ${new Date().toISOString()} -->\n`;
        content += '<resources>\n';

        for (const [categoryName, categoryData] of Object.entries(categories)) {
            content += `    <!-- ${categoryName.charAt(0).toUpperCase() + categoryName.slice(1)} -->\n`;
            
            if (typeof categoryData === 'object' && categoryData !== null) {
                for (const [key, value] of Object.entries(categoryData)) {
                    if (typeof value === 'string') {
                        const escapedValue = value
                            .replace(/&/g, '&amp;')
                            .replace(/</g, '&lt;')
                            .replace(/>/g, '&gt;')
                            .replace(/"/g, '&quot;')
                            .replace(/'/g, '&apos;');
                        content += `    <string name="${categoryName}_${key}">${escapedValue}</string>\n`;
                    }
                }
            }
            content += '\n';
        }

        content += '</resources>\n';
        return content;
    }

    convertToWindowsResx(categories) {
        let content = '<?xml version="1.0" encoding="utf-8"?>\n';
        content += '<root>\n';
        content += '  <!-- Auto-generated from shared JSON resources -->\n';
        content += `  <!-- Generated on: ${new Date().toISOString()} -->\n`;
        content += '  <resheader name="resmimetype">\n';
        content += '    <value>text/microsoft-resx</value>\n';
        content += '  </resheader>\n';
        content += '  <resheader name="version">\n';
        content += '    <value>2.0</value>\n';
        content += '  </resheader>\n';

        for (const [categoryName, categoryData] of Object.entries(categories)) {
            if (typeof categoryData === 'object' && categoryData !== null) {
                for (const [key, value] of Object.entries(categoryData)) {
                    if (typeof value === 'string') {
                        const escapedValue = value
                            .replace(/&/g, '&amp;')
                            .replace(/</g, '&lt;')
                            .replace(/>/g, '&gt;');
                        content += `  <data name="${categoryName}.${key}" xml:space="preserve">\n`;
                        content += `    <value>${escapedValue}</value>\n`;
                        content += '  </data>\n';
                    }
                }
            }
        }

        content += '</root>\n';
        return content;
    }

    ensureDirectoryExists(dirPath) {
        if (!fs.existsSync(dirPath)) {
            fs.mkdirSync(dirPath, { recursive: true });
        }
    }
}

// Run sync if called directly
if (require.main === module) {
    const syncer = new LocalizationSyncer();
    syncer.syncAll();
}

module.exports = LocalizationSyncer;
```

## Usage Examples

### iOS Usage
```swift
// Using the cross-platform adapter alongside the existing LocalizationManager
class PortfolioViewController: UIViewController {
    @StateObject private var localizationAdapter = CrossPlatformLocalizationAdapter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        // Using cross-platform localization
        titleLabel.text = localizationAdapter.localizedString(category: "general", key: "appName")
        portfolioLabel.text = localizationAdapter.localizedString(category: "financial", key: "portfolio")
        
        // Format numbers with cultural preferences
        netWorthLabel.text = localizationAdapter.formatNumber(netWorthValue, style: .currency)
        
        // Check RTL layout
        if localizationAdapter.isRTL() {
            view.semanticContentAttribute = .forceRightToLeft
        }
    }
}
```

### Android Usage
```kotlin
// Using the cross-platform adapter in an Android Activity
class PortfolioActivity : AppCompatActivity() {
    private lateinit var localizationAdapter: CrossPlatformLocalizationAdapter
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        localizationAdapter = CrossPlatformLocalizationAdapter(this)
        setupUI()
    }
    
    private fun setupUI() {
        // Using cross-platform localization
        title = localizationAdapter.localizedString("general", "appName")
        portfolioLabel.text = localizationAdapter.localizedString("financial", "portfolio")
        
        // Format numbers with cultural preferences
        netWorthLabel.text = localizationAdapter.formatNumber(netWorthValue, NumberFormattingStyle.CURRENCY)
        
        // Handle RTL layout
        if (localizationAdapter.isRTL()) {
            window.decorView.layoutDirection = View.LAYOUT_DIRECTION_RTL
        }
    }
}
```

### Windows Usage
```csharp
// Using the cross-platform adapter in a WPF Window
public partial class PortfolioWindow : Window
{
    private CrossPlatformLocalizationAdapter _localizationAdapter;
    
    public PortfolioWindow()
    {
        InitializeComponent();
        _localizationAdapter = new CrossPlatformLocalizationAdapter();
        SetupUI();
    }
    
    private void SetupUI()
    {
        // Using cross-platform localization
        Title = _localizationAdapter.LocalizedString("general", "appName");
        PortfolioLabel.Content = _localizationAdapter.LocalizedString("financial", "portfolio");
        
        // Format numbers with cultural preferences
        NetWorthLabel.Content = _localizationAdapter.FormatNumber(netWorthValue, NumberFormattingStyle.Currency);
        
        // Handle RTL layout
        if (_localizationAdapter.IsRTL())
        {
            FlowDirection = FlowDirection.RightToLeft;
        }
    }
}
```

## Build Integration

### iOS (Xcode Build Phases)
```bash
#!/bin/bash
# Add to Xcode Build Phases -> Run Script
echo "🔄 Syncing cross-platform localizations..."
cd "${SRCROOT}/../localization"
node tools/sync-localization.js
echo "✅ Localization sync completed"
```

### Android (Gradle)
```gradle
// Add to app/build.gradle
task syncLocalizations(type: Exec) {
    workingDir '../localization'
    commandLine 'node', 'tools/sync-localization.js'
}

preBuild.dependsOn syncLocalizations
```

### Windows (.NET)
```xml
<!-- Add to .csproj -->
<Target Name="SyncLocalizations" BeforeTargets="BeforeBuild">
    <Exec Command="node tools/sync-localization.js" 
          WorkingDirectory="../localization" />
</Target>
```

## Benefits

1. **Single Source of Truth**: All localized strings managed in shared JSON files
2. **Consistency**: Same strings and cultural adaptations across all platforms
3. **Maintainability**: Easy to add new languages and update existing ones
4. **Performance**: Platform-native files generated at build time
5. **Flexibility**: Support for complex cultural formatting and RTL languages
6. **Automation**: LLM-friendly JSON format for automated translation workflows
7. **Validation**: Build-time consistency checks and missing key detection

This architecture ensures that WealthWise can maintain consistent localization across all platforms while leveraging the best practices and performance optimizations of each platform's native localization system.