//
//  TranslationCacheTests.swift
//  WealthWiseTests
//
//  Created by GitHub Copilot on 27/09/2025.
//  Comprehensive tests for TranslationCache performance and memory management
//

import XCTest
@testable import WealthWise

final class TranslationCacheTests: XCTestCase {
    
    var cache: TranslationCache!
    
    override func setUp() {
        super.setUp()
        cache = TranslationCache()
    }
    
    override func tearDown() {
        cache = nil
        super.tearDown()
    }
    
    // MARK: - Basic Functionality Tests
    
    func testCacheInitialization() {
        XCTAssertEqual(cache.count, 0)
        XCTAssertEqual(cache.totalHits, 0)
        XCTAssertEqual(cache.totalMisses, 0)
        XCTAssertEqual(cache.hitRate, 0.0)
    }
    
    func testBasicCaching() {
        let key = "test.key"
        let locale = "en-US"
        let translation = "Test Value"
        
        // Should be miss initially
        XCTAssertNil(cache.get(key: key, locale: locale))
        XCTAssertEqual(cache.totalMisses, 1)
        
        // Store value
        cache.set(key: key, locale: locale, translation: translation)
        XCTAssertEqual(cache.count, 1)
        
        // Should be hit now
        let retrieved = cache.get(key: key, locale: locale)
        XCTAssertEqual(retrieved, translation)
        XCTAssertEqual(cache.totalHits, 1)
    }
    
    func testCacheKeyGeneration() {
        let key1 = cache.cacheKey(for: "test.key", locale: "en-US")
        let key2 = cache.cacheKey(for: "test.key", locale: "hi-IN")
        let key3 = cache.cacheKey(for: "other.key", locale: "en-US")
        
        XCTAssertNotEqual(key1, key2) // Different locales
        XCTAssertNotEqual(key1, key3) // Different keys
        XCTAssertNotEqual(key2, key3) // Different everything
        
        // Same parameters should generate same key
        let key1Duplicate = cache.cacheKey(for: "test.key", locale: "en-US")
        XCTAssertEqual(key1, key1Duplicate)
    }
    
    // MARK: - LRU Eviction Tests
    
    func testLRUEviction() {
        let cache = TranslationCache(maxSize: 3) // Small cache for testing
        
        // Fill cache to capacity
        cache.set(key: "key1", locale: "en", translation: "value1")
        cache.set(key: "key2", locale: "en", translation: "value2")
        cache.set(key: "key3", locale: "en", translation: "value3")
        XCTAssertEqual(cache.count, 3)
        
        // Access key1 to make it most recently used
        _ = cache.get(key: "key1", locale: "en")
        
        // Add another item, should evict key2 (least recently used)
        cache.set(key: "key4", locale: "en", translation: "value4")
        XCTAssertEqual(cache.count, 3)
        
        // key2 should be evicted, others should remain
        XCTAssertNotNil(cache.get(key: "key1", locale: "en"))
        XCTAssertNil(cache.get(key: "key2", locale: "en"))
        XCTAssertNotNil(cache.get(key: "key3", locale: "en"))
        XCTAssertNotNil(cache.get(key: "key4", locale: "en"))
    }
    
    func testLRUOrderMaintenance() {
        let cache = TranslationCache(maxSize: 3)
        
        // Add items
        cache.set(key: "a", locale: "en", translation: "A")
        cache.set(key: "b", locale: "en", translation: "B")
        cache.set(key: "c", locale: "en", translation: "C")
        
        // Access in specific order to establish LRU order
        _ = cache.get(key: "a", locale: "en") // a becomes most recent
        _ = cache.get(key: "b", locale: "en") // b becomes most recent
        // c remains least recent
        
        // Add new item, should evict c
        cache.set(key: "d", locale: "en", translation: "D")
        
        XCTAssertNotNil(cache.get(key: "a", locale: "en"))
        XCTAssertNotNil(cache.get(key: "b", locale: "en"))
        XCTAssertNil(cache.get(key: "c", locale: "en")) // Evicted
        XCTAssertNotNil(cache.get(key: "d", locale: "en"))
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryWarningHandling() {
        // Fill cache with data
        for i in 0..<100 {
            cache.set(key: "key\(i)", locale: "en", translation: "value\(i)")
        }
        XCTAssertEqual(cache.count, 100)
        
        // Simulate memory warning
        NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        
        // Allow notification to be processed
        let expectation = XCTestExpectation(description: "Memory warning processed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Cache should be significantly reduced or cleared
        XCTAssertLessThan(cache.count, 100)
    }
    
    func testClearCache() {
        // Add some items
        cache.set(key: "key1", locale: "en", translation: "value1")
        cache.set(key: "key2", locale: "hi", translation: "value2")
        XCTAssertEqual(cache.count, 2)
        
        // Clear cache
        cache.clear()
        
        XCTAssertEqual(cache.count, 0)
        XCTAssertNil(cache.get(key: "key1", locale: "en"))
        XCTAssertNil(cache.get(key: "key2", locale: "hi"))
    }
    
    func testClearCachePreservesStatistics() {
        // Generate some statistics
        cache.set(key: "key1", locale: "en", translation: "value1")
        _ = cache.get(key: "key1", locale: "en") // Hit
        _ = cache.get(key: "missing", locale: "en") // Miss
        
        let hits = cache.totalHits
        let misses = cache.totalMisses
        
        // Clear cache
        cache.clear()
        
        // Statistics should be preserved
        XCTAssertEqual(cache.totalHits, hits)
        XCTAssertEqual(cache.totalMisses, misses)
        XCTAssertEqual(cache.count, 0)
    }
    
    // MARK: - Statistics Tests
    
    func testHitRateCalculation() {
        XCTAssertEqual(cache.hitRate, 0.0) // No requests yet
        
        cache.set(key: "key1", locale: "en", translation: "value1")
        
        // One miss (initial get)
        _ = cache.get(key: "missing", locale: "en")
        XCTAssertEqual(cache.hitRate, 0.0) // 0 hits, 1 miss
        
        // One hit
        _ = cache.get(key: "key1", locale: "en")
        XCTAssertEqual(cache.hitRate, 0.5) // 1 hit, 1 miss
        
        // Another hit
        _ = cache.get(key: "key1", locale: "en")
        XCTAssertEqual(cache.hitRate, 2.0/3.0, accuracy: 0.001) // 2 hits, 1 miss
    }
    
    func testStatisticsAccuracy() {
        var expectedHits = 0
        var expectedMisses = 0
        
        // Test multiple operations
        for i in 0..<10 {
            let key = "key\(i)"
            
            // First access should be a miss
            let firstResult = cache.get(key: key, locale: "en")
            XCTAssertNil(firstResult)
            expectedMisses += 1
            
            // Set the value
            cache.set(key: key, locale: "en", translation: "value\(i)")
            
            // Second access should be a hit
            let secondResult = cache.get(key: key, locale: "en")
            XCTAssertNotNil(secondResult)
            expectedHits += 1
        }
        
        XCTAssertEqual(cache.totalHits, expectedHits)
        XCTAssertEqual(cache.totalMisses, expectedMisses)
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentAccess() {
        let expectation = XCTestExpectation(description: "Concurrent operations completed")
        expectation.expectedFulfillmentCount = 3
        
        let queue = DispatchQueue.global(qos: .userInitiated)
        
        // Thread 1: Writing
        queue.async {
            for i in 0..<100 {
                self.cache.set(key: "key\(i)", locale: "en", translation: "value\(i)")
            }
            expectation.fulfill()
        }
        
        // Thread 2: Reading existing keys
        queue.async {
            for i in 0..<50 {
                self.cache.set(key: "setup\(i)", locale: "en", translation: "setup\(i)")
            }
            for i in 0..<50 {
                _ = self.cache.get(key: "setup\(i)", locale: "en")
            }
            expectation.fulfill()
        }
        
        // Thread 3: Mixed operations
        queue.async {
            for i in 0..<30 {
                self.cache.set(key: "mixed\(i)", locale: "hi", translation: "मिश्रित\(i)")
                _ = self.cache.get(key: "mixed\(i)", locale: "hi")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
        
        // Cache should be in a consistent state
        XCTAssertGreaterThan(cache.count, 0)
        XCTAssertEqual(cache.totalHits + cache.totalMisses, cache.totalRequests)
    }
    
    func testConcurrentEviction() {
        let smallCache = TranslationCache(maxSize: 10)
        let expectation = XCTestExpectation(description: "Concurrent eviction completed")
        expectation.expectedFulfillmentCount = 5
        
        let queue = DispatchQueue.global(qos: .userInitiated)
        
        // Multiple threads adding items to trigger eviction
        for threadId in 0..<5 {
            queue.async {
                for i in 0..<20 {
                    let key = "thread\(threadId)_key\(i)"
                    smallCache.set(key: key, locale: "en", translation: "value\(i)")
                }
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Cache should respect size limit
        XCTAssertLessThanOrEqual(smallCache.count, 10)
    }
    
    // MARK: - Performance Tests
    
    func testCachePerformance() {
        // Pre-populate cache
        for i in 0..<1000 {
            cache.set(key: "perf_key\(i)", locale: "en", translation: "performance_value\(i)")
        }
        
        measure {
            for i in 0..<1000 {
                _ = cache.get(key: "perf_key\(i)", locale: "en")
            }
        }
    }
    
    func testLargeDatasetPerformance() {
        let largeCache = TranslationCache(maxSize: 10000)
        
        measure {
            // Add items
            for i in 0..<5000 {
                largeCache.set(key: "large_key\(i)", locale: "en", translation: "large_value_\(i)_with_more_content")
            }
            
            // Random access
            for _ in 0..<1000 {
                let randomIndex = Int.random(in: 0..<5000)
                _ = largeCache.get(key: "large_key\(randomIndex)", locale: "en")
            }
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testEmptyStrings() {
        cache.set(key: "", locale: "en", translation: "")
        let result = cache.get(key: "", locale: "en")
        XCTAssertEqual(result, "")
    }
    
    func testSpecialCharacters() {
        let specialKey = "special.key_with-chars@#$%"
        let specialLocale = "zh-Hans-CN"
        let specialTranslation = "特殊字符测试 🎉"
        
        cache.set(key: specialKey, locale: specialLocale, translation: specialTranslation)
        let result = cache.get(key: specialKey, locale: specialLocale)
        XCTAssertEqual(result, specialTranslation)
    }
    
    func testLongStrings() {
        let longKey = String(repeating: "long_key_", count: 100)
        let longTranslation = String(repeating: "This is a very long translation string that might cause issues if not handled properly. ", count: 50)
        
        cache.set(key: longKey, locale: "en", translation: longTranslation)
        let result = cache.get(key: longKey, locale: "en")
        XCTAssertEqual(result, longTranslation)
    }
    
    func testZeroMaxSize() {
        let zeroSizeCache = TranslationCache(maxSize: 0)
        
        zeroSizeCache.set(key: "test", locale: "en", translation: "value")
        XCTAssertEqual(zeroSizeCache.count, 0) // Should not store anything
        XCTAssertNil(zeroSizeCache.get(key: "test", locale: "en"))
    }
    
    func testNegativeMaxSize() {
        let negativeCache = TranslationCache(maxSize: -1)
        
        negativeCache.set(key: "test", locale: "en", translation: "value")
        XCTAssertEqual(negativeCache.count, 0) // Should not store anything
    }
    
    // MARK: - Locale Handling Tests
    
    func testLocaleSpecificCaching() {
        let key = "greeting"
        
        cache.set(key: key, locale: "en-US", translation: "Hello")
        cache.set(key: key, locale: "hi-IN", translation: "नमस्ते")
        cache.set(key: key, locale: "es-ES", translation: "Hola")
        
        XCTAssertEqual(cache.get(key: key, locale: "en-US"), "Hello")
        XCTAssertEqual(cache.get(key: key, locale: "hi-IN"), "नमस्ते")
        XCTAssertEqual(cache.get(key: key, locale: "es-ES"), "Hola")
        
        // Different locale should be a miss
        XCTAssertNil(cache.get(key: key, locale: "fr-FR"))
    }
    
    func testCasesensitivity() {
        cache.set(key: "Test.Key", locale: "en-US", translation: "Value1")
        cache.set(key: "test.key", locale: "en-US", translation: "Value2")
        cache.set(key: "TEST.KEY", locale: "en-US", translation: "Value3")
        
        // All should be treated as separate entries
        XCTAssertEqual(cache.get(key: "Test.Key", locale: "en-US"), "Value1")
        XCTAssertEqual(cache.get(key: "test.key", locale: "en-US"), "Value2")
        XCTAssertEqual(cache.get(key: "TEST.KEY", locale: "en-US"), "Value3")
        XCTAssertEqual(cache.count, 3)
    }
    
    // MARK: - Memory Usage Tests
    
    func testMemoryUsageTracking() {
        let initialMemoryUsage = cache.estimatedMemoryUsage
        
        // Add substantial data
        for i in 0..<100 {
            let longValue = String(repeating: "data", count: 100)
            cache.set(key: "memory_test_\(i)", locale: "en", translation: longValue)
        }
        
        let finalMemoryUsage = cache.estimatedMemoryUsage
        XCTAssertGreaterThan(finalMemoryUsage, initialMemoryUsage)
    }
    
    func testClearReducesMemoryUsage() {
        // Add data
        for i in 0..<50 {
            cache.set(key: "clear_test_\(i)", locale: "en", translation: String(repeating: "x", count: 1000))
        }
        
        let beforeClearMemory = cache.estimatedMemoryUsage
        cache.clear()
        let afterClearMemory = cache.estimatedMemoryUsage
        
        XCTAssertLessThan(afterClearMemory, beforeClearMemory)
    }
}

// MARK: - CachedTranslation Tests

final class CachedTranslationTests: XCTestCase {
    
    func testCachedTranslationCreation() {
        let translation = CachedTranslation(value: "Test Value")
        
        XCTAssertEqual(translation.value, "Test Value")
        XCTAssertEqual(translation.accessCount, 1) // Initial creation counts as access
        XCTAssertLessThanOrEqual(abs(translation.lastAccessed.timeIntervalSinceNow), 1.0) // Should be recent
    }
    
    func testAccessTracking() {
        var translation = CachedTranslation(value: "Test")
        let initialAccess = translation.lastAccessed
        let initialCount = translation.accessCount
        
        // Simulate access
        Thread.sleep(forTimeInterval: 0.01) // Small delay
        translation.markAccessed()
        
        XCTAssertGreaterThan(translation.lastAccessed, initialAccess)
        XCTAssertEqual(translation.accessCount, initialCount + 1)
    }
    
    func testMemoryEstimation() {
        let shortTranslation = CachedTranslation(value: "Hi")
        let longTranslation = CachedTranslation(value: String(repeating: "Long text ", count: 100))
        
        XCTAssertGreaterThan(longTranslation.estimatedMemoryUsage, shortTranslation.estimatedMemoryUsage)
    }
    
    func testEquality() {
        let translation1 = CachedTranslation(value: "Test")
        let translation2 = CachedTranslation(value: "Test")
        let translation3 = CachedTranslation(value: "Different")
        
        XCTAssertEqual(translation1, translation2)
        XCTAssertNotEqual(translation1, translation3)
    }
}