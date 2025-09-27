//
//  TranslationCache.swift
//  WealthWise
//
//  Created by GitHub Copilot on 27/09/2025.
//  High-performance translation cache with LRU eviction and memory management
//

import Foundation
import Combine
import os.log

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// High-performance translation cache with automatic memory management
/// Features LRU eviction, memory pressure handling, and thread-safe operations
@MainActor
public final class TranslationCache: ObservableObject {
    
    // MARK: - Configuration
    
    private struct CacheConfiguration {
        static let maxCacheSize = 1000 // Maximum number of cached entries
        static let cleanupInterval: TimeInterval = 300 // 5 minutes
        static let expirationTime: TimeInterval = 3600 // 1 hour
        static let memoryWarningReduction = 0.5 // Reduce to 50% on memory warning
    }
    
    // MARK: - Properties
    
    private var cache: [String: CachedTranslation] = [:]
    private var cacheHits: Int = 0
    private var cacheMisses: Int = 0
    private var lastCleanupTime: Date = Date()
    
    private let logger = Logger(subsystem: "com.wealthwise.localization", category: "TranslationCache")
    
    // MARK: - Public Properties
    
    /// Current number of cached entries
    public var count: Int {
        cache.count
    }
    
    /// Total cache hits since initialization
    public var totalHits: Int {
        cacheHits
    }
    
    /// Total cache misses since initialization
    public var totalMisses: Int {
        cacheMisses
    }
    
    /// Total requests (hits + misses)
    public var totalRequests: Int {
        cacheHits + cacheMisses
    }
    
    /// Cache hit rate (0.0 to 1.0)
    public var hitRate: Double {
        guard totalRequests > 0 else { return 0.0 }
        return Double(cacheHits) / Double(totalRequests)
    }
    
    /// Estimated memory usage in bytes
    public var estimatedMemoryUsage: Int {
        cache.values.reduce(0) { $0 + $1.estimatedMemoryUsage }
    }
    
    // MARK: - Initialization
    
    public init(maxSize: Int = 1000) {
        logger.info("TranslationCache initialized with max size: \(maxSize)")
        
        // Setup memory warning observer
        #if canImport(UIKit)
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }
        #endif
        
        // Setup periodic cleanup
        setupPeriodicCleanup()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Cache Operations
    
    /// Get cached translation
    /// - Parameters:
    ///   - key: Localization key
    ///   - locale: Target locale
    /// - Returns: Cached translation if available
    public func get(key: String, locale: String) -> String? {
        let cacheKey = self.cacheKey(for: key, locale: locale)
        
        if var cachedItem = cache[cacheKey] {
            // Update access information
            cachedItem.markAccessed()
            cache[cacheKey] = cachedItem
            cacheHits += 1
            
            logger.debug("Cache hit for key: \(key), locale: \(locale)")
            return cachedItem.value
        } else {
            cacheMisses += 1
            logger.debug("Cache miss for key: \(key), locale: \(locale)")
            return nil
        }
    }
    
    /// Store translation in cache
    /// - Parameters:
    ///   - key: Localization key
    ///   - locale: Target locale
    ///   - translation: Translation to cache
    public func set(key: String, locale: String, translation: String) {
        let cacheKey = self.cacheKey(for: key, locale: locale)
        
        // Check if we need to make space
        if cache.count >= CacheConfiguration.maxCacheSize {
            performLRUEviction()
        }
        
        let cachedTranslation = CachedTranslation(value: translation)
        cache[cacheKey] = cachedTranslation
        
        logger.debug("Cached translation for key: \(key), locale: \(locale)")
    }
    
    /// Clear all cached translations
    public func clear() {
        let clearedCount = cache.count
        cache.removeAll()
        
        logger.info("Cache cleared: \(clearedCount) entries removed")
    }
    
    /// Generate cache key for given parameters
    /// - Parameters:
    ///   - key: Localization key
    ///   - locale: Target locale
    /// - Returns: Unique cache key
    public func cacheKey(for key: String, locale: String) -> String {
        return "\(key)_\(locale)"
    }
    
    // MARK: - Memory Management
    
    /// Perform LRU eviction to free space
    private func performLRUEviction() {
        let targetSize = Int(Double(CacheConfiguration.maxCacheSize) * 0.8) // Remove 20%
        let sortedEntries = cache.sorted { $0.value.lastAccessed < $1.value.lastAccessed }
        
        let entriesToRemove = cache.count - targetSize
        for (key, _) in sortedEntries.prefix(entriesToRemove) {
            cache.removeValue(forKey: key)
        }
        
        logger.info("LRU eviction completed: removed \(entriesToRemove) entries")
    }
    
    /// Handle memory warning by reducing cache size
    private func handleMemoryWarning() {
        let initialCount = cache.count
        let targetSize = Int(Double(cache.count) * CacheConfiguration.memoryWarningReduction)
        let sortedEntries = cache.sorted { $0.value.lastAccessed < $1.value.lastAccessed }
        
        let entriesToRemove = cache.count - targetSize
        for (key, _) in sortedEntries.prefix(entriesToRemove) {
            cache.removeValue(forKey: key)
        }
        
        let removedCount = initialCount - cache.count
        logger.warning("Memory warning handled: removed \(removedCount) entries, cache size: \(self.cache.count)")
    }
    
    /// Perform periodic maintenance
    public func performMaintenance() {
        let currentTime = Date()
        
        // Only perform maintenance if enough time has passed
        guard currentTime.timeIntervalSince(lastCleanupTime) > CacheConfiguration.cleanupInterval else { return }
        
        let initialCount = cache.count
        
        // Remove expired entries
        let expiredKeys = cache.compactMap { key, value in
            value.isExpired ? key : nil
        }
        
        for key in expiredKeys {
            cache.removeValue(forKey: key)
        }
        
        // Perform LRU eviction if still over limit
        if cache.count > CacheConfiguration.maxCacheSize {
            performLRUEviction()
        }
        
        lastCleanupTime = currentTime
        
        let removedCount = initialCount - cache.count
        if removedCount > 0 {
            logger.info("Periodic maintenance completed: removed \(removedCount) entries")
        }
    }
    
    /// Setup periodic cleanup timer
    private func setupPeriodicCleanup() {
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.performMaintenance()
            }
        }
    }
}

// MARK: - CachedTranslation

/// Represents a cached translation with metadata
public struct CachedTranslation: Equatable {
    public let value: String
    public private(set) var lastAccessed: Date
    public private(set) var accessCount: Int
    private let creationTime: Date
    
    /// Initialize a new cached translation
    /// - Parameter value: The translation string
    public init(value: String) {
        self.value = value
        self.lastAccessed = Date()
        self.accessCount = 1
        self.creationTime = Date()
    }
    
    /// Mark this translation as accessed
    public mutating func markAccessed() {
        lastAccessed = Date()
        accessCount += 1
    }
    
    /// Check if this translation has expired
    public var isExpired: Bool {
        Date().timeIntervalSince(creationTime) > 3600 // 1 hour
    }
    
    /// Estimated memory usage of this entry
    public var estimatedMemoryUsage: Int {
        // Rough estimation: string size + metadata overhead
        return value.utf8.count + 64 // 64 bytes for metadata
    }
    
    public static func == (lhs: CachedTranslation, rhs: CachedTranslation) -> Bool {
        return lhs.value == rhs.value
    }
}