import Foundation

/// Actor for thread-safe API rate limiting and quota management
public actor RateLimiter {
    
    // MARK: - Rate Limit Configuration
    
    private struct RateLimitConfig {
        let requestsPerMinute: Int
        let requestsPerHour: Int
        let requestsPerDay: Int
    }
    
    // MARK: - Request Counter
    
    private struct RequestCounter {
        var minute: (count: Int, timestamp: Date)
        var hour: (count: Int, timestamp: Date)
        var day: (count: Int, timestamp: Date)
    }
    
    // MARK: - Properties
    
    private var requestCounts: [String: RequestCounter] = [:]
    private let providerConfigs: [String: RateLimitConfig]
    
    // MARK: - Initialization
    
    public init(providerConfigs: [String: RateLimitConfig]? = nil) {
        self.providerConfigs = providerConfigs ?? Self.defaultConfigs()
    }
    
    // MARK: - Public Methods
    
    /// Check if a request can be made for a provider
    public func canMakeRequest(for providerId: String) -> Bool {
        guard let config = providerConfigs[providerId] else {
            return true // No limit configured, allow request
        }
        
        let now = Date()
        
        // Get or create counter
        var counter = requestCounts[providerId] ?? RequestCounter(
            minute: (0, now),
            hour: (0, now),
            day: (0, now)
        )
        
        // Reset counters if time windows have passed
        if now.timeIntervalSince(counter.minute.timestamp) >= 60 {
            counter.minute = (0, now)
        }
        
        if now.timeIntervalSince(counter.hour.timestamp) >= 3600 {
            counter.hour = (0, now)
        }
        
        if now.timeIntervalSince(counter.day.timestamp) >= 86400 {
            counter.day = (0, now)
        }
        
        // Check limits
        if counter.minute.count >= config.requestsPerMinute {
            return false
        }
        
        if counter.hour.count >= config.requestsPerHour {
            return false
        }
        
        if counter.day.count >= config.requestsPerDay {
            return false
        }
        
        return true
    }
    
    /// Record a request for a provider
    public func recordRequest(for providerId: String) {
        let now = Date()
        
        // Get or create counter
        var counter = requestCounts[providerId] ?? RequestCounter(
            minute: (0, now),
            hour: (0, now),
            day: (0, now)
        )
        
        // Reset counters if time windows have passed
        if now.timeIntervalSince(counter.minute.timestamp) >= 60 {
            counter.minute = (0, now)
        }
        
        if now.timeIntervalSince(counter.hour.timestamp) >= 3600 {
            counter.hour = (0, now)
        }
        
        if now.timeIntervalSince(counter.day.timestamp) >= 86400 {
            counter.day = (0, now)
        }
        
        // Increment counters
        counter.minute.count += 1
        counter.hour.count += 1
        counter.day.count += 1
        
        // Save updated counter
        requestCounts[providerId] = counter
    }
    
    /// Get current usage statistics for a provider
    public func getUsageStats(for providerId: String) -> UsageStatistics? {
        guard let config = providerConfigs[providerId],
              let counter = requestCounts[providerId] else {
            return nil
        }
        
        let now = Date()
        
        // Calculate remaining requests
        let remainingMinute = max(0, config.requestsPerMinute - counter.minute.count)
        let remainingHour = max(0, config.requestsPerHour - counter.hour.count)
        let remainingDay = max(0, config.requestsPerDay - counter.day.count)
        
        // Calculate reset times
        let minuteReset = counter.minute.timestamp.addingTimeInterval(60)
        let hourReset = counter.hour.timestamp.addingTimeInterval(3600)
        let dayReset = counter.day.timestamp.addingTimeInterval(86400)
        
        return UsageStatistics(
            providerId: providerId,
            requestsThisMinute: counter.minute.count,
            requestsThisHour: counter.hour.count,
            requestsThisDay: counter.day.count,
            remainingMinute: remainingMinute,
            remainingHour: remainingHour,
            remainingDay: remainingDay,
            minuteResetTime: minuteReset,
            hourResetTime: hourReset,
            dayResetTime: dayReset,
            timestamp: now
        )
    }
    
    /// Get usage statistics for all providers
    public func getAllUsageStats() -> [String: UsageStatistics] {
        var stats: [String: UsageStatistics] = [:]
        
        for providerId in providerConfigs.keys {
            if let providerStats = getUsageStats(for: providerId) {
                stats[providerId] = providerStats
            }
        }
        
        return stats
    }
    
    /// Reset counters for a specific provider
    public func resetCounters(for providerId: String) {
        requestCounts.removeValue(forKey: providerId)
    }
    
    /// Reset all counters
    public func resetAllCounters() {
        requestCounts.removeAll()
    }
    
    /// Calculate recommended wait time before next request
    public func recommendedWaitTime(for providerId: String) -> TimeInterval? {
        guard let config = providerConfigs[providerId],
              let counter = requestCounts[providerId] else {
            return nil
        }
        
        let now = Date()
        
        // Check which limit is hit
        if counter.minute.count >= config.requestsPerMinute {
            let timeUntilReset = 60 - now.timeIntervalSince(counter.minute.timestamp)
            return max(0, timeUntilReset)
        }
        
        if counter.hour.count >= config.requestsPerHour {
            let timeUntilReset = 3600 - now.timeIntervalSince(counter.hour.timestamp)
            return max(0, timeUntilReset)
        }
        
        if counter.day.count >= config.requestsPerDay {
            let timeUntilReset = 86400 - now.timeIntervalSince(counter.day.timestamp)
            return max(0, timeUntilReset)
        }
        
        return nil
    }
    
    // MARK: - Private Methods
    
    private static func defaultConfigs() -> [String: RateLimitConfig] {
        return [
            "ExchangeRate.host": RateLimitConfig(
                requestsPerMinute: 60,
                requestsPerHour: 1000,
                requestsPerDay: 10000
            ),
            "Fixer.io": RateLimitConfig(
                requestsPerMinute: 10,
                requestsPerHour: 100,
                requestsPerDay: 1000
            ),
            "Mock Provider": RateLimitConfig(
                requestsPerMinute: 100,
                requestsPerHour: 10000,
                requestsPerDay: 100000
            )
        ]
    }
}

// MARK: - Singleton Access

extension RateLimiter {
    public static let shared = RateLimiter()
}

// MARK: - Supporting Types

/// Usage statistics for a provider
public struct UsageStatistics: Sendable {
    public let providerId: String
    public let requestsThisMinute: Int
    public let requestsThisHour: Int
    public let requestsThisDay: Int
    public let remainingMinute: Int
    public let remainingHour: Int
    public let remainingDay: Int
    public let minuteResetTime: Date
    public let hourResetTime: Date
    public let dayResetTime: Date
    public let timestamp: Date
    
    public var utilizationPercentage: Double {
        // Calculate based on most restrictive limit
        let minuteUtilization = Double(requestsThisMinute) / Double(requestsThisMinute + remainingMinute)
        let hourUtilization = Double(requestsThisHour) / Double(requestsThisHour + remainingHour)
        let dayUtilization = Double(requestsThisDay) / Double(requestsThisDay + remainingDay)
        
        return max(minuteUtilization, hourUtilization, dayUtilization) * 100
    }
    
    public var isNearLimit: Bool {
        return utilizationPercentage > 80
    }
}
