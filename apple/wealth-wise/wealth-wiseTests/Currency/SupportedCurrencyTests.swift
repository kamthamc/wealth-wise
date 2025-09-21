import XCTest
@testable import WealthWise

final class SupportedCurrencyTests: XCTestCase {
    
    // MARK: - Currency Properties Tests
    
    func testCurrencySymbols() {
        XCTAssertEqual(SupportedCurrency.usd.symbol, "$")
        XCTAssertEqual(SupportedCurrency.eur.symbol, "€")
        XCTAssertEqual(SupportedCurrency.gbp.symbol, "£")
        XCTAssertEqual(SupportedCurrency.inr.symbol, "₹")
        XCTAssertEqual(SupportedCurrency.jpy.symbol, "¥")
        XCTAssertEqual(SupportedCurrency.cny.symbol, "¥")
        XCTAssertEqual(SupportedCurrency.krw.symbol, "₩")
        XCTAssertEqual(SupportedCurrency.aud.symbol, "A$")
        XCTAssertEqual(SupportedCurrency.cad.symbol, "C$")
        XCTAssertEqual(SupportedCurrency.chf.symbol, "CHF")
    }
    
    func testCurrencyDisplayNames() {
        XCTAssertEqual(SupportedCurrency.usd.displayName, "US Dollar")
        XCTAssertEqual(SupportedCurrency.eur.displayName, "Euro")
        XCTAssertEqual(SupportedCurrency.gbp.displayName, "British Pound")
        XCTAssertEqual(SupportedCurrency.inr.displayName, "Indian Rupee")
        XCTAssertEqual(SupportedCurrency.jpy.displayName, "Japanese Yen")
        XCTAssertEqual(SupportedCurrency.cny.displayName, "Chinese Yuan")
        XCTAssertEqual(SupportedCurrency.krw.displayName, "South Korean Won")
        XCTAssertEqual(SupportedCurrency.aud.displayName, "Australian Dollar")
        XCTAssertEqual(SupportedCurrency.cad.displayName, "Canadian Dollar")
        XCTAssertEqual(SupportedCurrency.chf.displayName, "Swiss Franc")
    }
    
    func testCurrencyFlags() {
        XCTAssertEqual(SupportedCurrency.usd.flag, "🇺🇸")
        XCTAssertEqual(SupportedCurrency.eur.flag, "🇪🇺")
        XCTAssertEqual(SupportedCurrency.gbp.flag, "🇬🇧")
        XCTAssertEqual(SupportedCurrency.inr.flag, "🇮🇳")
        XCTAssertEqual(SupportedCurrency.jpy.flag, "🇯🇵")
        XCTAssertEqual(SupportedCurrency.cny.flag, "🇨🇳")
        XCTAssertEqual(SupportedCurrency.krw.flag, "🇰🇷")
        XCTAssertEqual(SupportedCurrency.aud.flag, "🇦🇺")
        XCTAssertEqual(SupportedCurrency.cad.flag, "🇨🇦")
        XCTAssertEqual(SupportedCurrency.chf.flag, "🇨🇭")
    }
    
    func testDecimalPlaces() {
        XCTAssertEqual(SupportedCurrency.usd.decimalPlaces, 2)
        XCTAssertEqual(SupportedCurrency.eur.decimalPlaces, 2)
        XCTAssertEqual(SupportedCurrency.jpy.decimalPlaces, 0) // No decimal places for JPY
        XCTAssertEqual(SupportedCurrency.krw.decimalPlaces, 0) // No decimal places for KRW
        XCTAssertEqual(SupportedCurrency.inr.decimalPlaces, 2)
        XCTAssertEqual(SupportedCurrency.bhd.decimalPlaces, 3) // Bahraini Dinar has 3 decimal places
        XCTAssertEqual(SupportedCurrency.kwd.decimalPlaces, 3) // Kuwaiti Dinar has 3 decimal places
    }
    
    func testIndianNumberingSystem() {
        XCTAssertTrue(SupportedCurrency.inr.usesIndianNumberingSystem)
        XCTAssertTrue(SupportedCurrency.npr.usesIndianNumberingSystem)
        XCTAssertTrue(SupportedCurrency.lkr.usesIndianNumberingSystem)
        XCTAssertTrue(SupportedCurrency.pkr.usesIndianNumberingSystem)
        XCTAssertTrue(SupportedCurrency.bdt.usesIndianNumberingSystem)
        
        XCTAssertFalse(SupportedCurrency.usd.usesIndianNumberingSystem)
        XCTAssertFalse(SupportedCurrency.eur.usesIndianNumberingSystem)
        XCTAssertFalse(SupportedCurrency.gbp.usesIndianNumberingSystem)
        XCTAssertFalse(SupportedCurrency.jpy.usesIndianNumberingSystem)
    }
    
    func testAccessibilityLabels() {
        XCTAssertEqual(SupportedCurrency.usd.accessibilityLabel, "US Dollar")
        XCTAssertEqual(SupportedCurrency.eur.accessibilityLabel, "Euro")
        XCTAssertEqual(SupportedCurrency.gbp.accessibilityLabel, "British Pound Sterling")
        XCTAssertEqual(SupportedCurrency.inr.accessibilityLabel, "Indian Rupee")
        XCTAssertEqual(SupportedCurrency.jpy.accessibilityLabel, "Japanese Yen")
    }
    
    // MARK: - Regional Grouping Tests
    
    func testNorthAmericanCurrencies() {
        let northAmericanCurrencies = [
            SupportedCurrency.usd,
            SupportedCurrency.cad,
            SupportedCurrency.mxn
        ]
        
        for currency in northAmericanCurrencies {
            XCTAssertTrue(SupportedCurrency.northAmericanCurrencies.contains(currency))
        }
    }
    
    func testEuropeanCurrencies() {
        let europeanCurrencies = [
            SupportedCurrency.eur,
            SupportedCurrency.gbp,
            SupportedCurrency.chf,
            SupportedCurrency.nok,
            SupportedCurrency.sek,
            SupportedCurrency.dkk
        ]
        
        for currency in europeanCurrencies {
            XCTAssertTrue(SupportedCurrency.europeanCurrencies.contains(currency))
        }
    }
    
    func testAsianCurrencies() {
        let asianCurrencies = [
            SupportedCurrency.jpy,
            SupportedCurrency.cny,
            SupportedCurrency.krw,
            SupportedCurrency.inr,
            SupportedCurrency.sgd,
            SupportedCurrency.hkd,
            SupportedCurrency.thb,
            SupportedCurrency.myr,
            SupportedCurrency.idr,
            SupportedCurrency.php,
            SupportedCurrency.vnd,
            SupportedCurrency.npr,
            SupportedCurrency.lkr,
            SupportedCurrency.pkr,
            SupportedCurrency.bdt
        ]
        
        for currency in asianCurrencies {
            XCTAssertTrue(SupportedCurrency.asianCurrencies.contains(currency))
        }
    }
    
    func testOceanianCurrencies() {
        let oceanianCurrencies = [
            SupportedCurrency.aud,
            SupportedCurrency.nzd
        ]
        
        for currency in oceanianCurrencies {
            XCTAssertTrue(SupportedCurrency.oceanianCurrencies.contains(currency))
        }
    }
    
    func testMiddleEasternCurrencies() {
        let middleEasternCurrencies = [
            SupportedCurrency.aed,
            SupportedCurrency.sar,
            SupportedCurrency.kwd,
            SupportedCurrency.bhd,
            SupportedCurrency.qar,
            SupportedCurrency.omr
        ]
        
        for currency in middleEasternCurrencies {
            XCTAssertTrue(SupportedCurrency.middleEasternCurrencies.contains(currency))
        }
    }
    
    func testAfricanCurrencies() {
        let africanCurrencies = [
            SupportedCurrency.zar
        ]
        
        for currency in africanCurrencies {
            XCTAssertTrue(SupportedCurrency.africanCurrencies.contains(currency))
        }
    }
    
    func testSouthAmericanCurrencies() {
        let southAmericanCurrencies = [
            SupportedCurrency.brl
        ]
        
        for currency in southAmericanCurrencies {
            XCTAssertTrue(SupportedCurrency.southAmericanCurrencies.contains(currency))
        }
    }
    
    // MARK: - Locale Tests
    
    func testPreferredCurrencyForLocale() {
        XCTAssertEqual(SupportedCurrency.preferredCurrency(for: Locale(identifier: "en_US")), .usd)
        XCTAssertEqual(SupportedCurrency.preferredCurrency(for: Locale(identifier: "en_IN")), .inr)
        XCTAssertEqual(SupportedCurrency.preferredCurrency(for: Locale(identifier: "en_GB")), .gbp)
        XCTAssertEqual(SupportedCurrency.preferredCurrency(for: Locale(identifier: "ja_JP")), .jpy)
        XCTAssertEqual(SupportedCurrency.preferredCurrency(for: Locale(identifier: "zh_CN")), .cny)
        XCTAssertEqual(SupportedCurrency.preferredCurrency(for: Locale(identifier: "ko_KR")), .krw)
        XCTAssertEqual(SupportedCurrency.preferredCurrency(for: Locale(identifier: "en_AU")), .aud)
        XCTAssertEqual(SupportedCurrency.preferredCurrency(for: Locale(identifier: "en_CA")), .cad)
        XCTAssertEqual(SupportedCurrency.preferredCurrency(for: Locale(identifier: "de_DE")), .eur)
        XCTAssertEqual(SupportedCurrency.preferredCurrency(for: Locale(identifier: "fr_FR")), .eur)
        
        // Test fallback
        XCTAssertEqual(SupportedCurrency.preferredCurrency(for: Locale(identifier: "xx_XX")), .usd)
    }
    
    // MARK: - CaseIterable Tests
    
    func testAllCases() {
        let allCases = SupportedCurrency.allCases
        
        // Verify we have all expected currencies
        XCTAssertTrue(allCases.contains(.usd))
        XCTAssertTrue(allCases.contains(.eur))
        XCTAssertTrue(allCases.contains(.gbp))
        XCTAssertTrue(allCases.contains(.inr))
        XCTAssertTrue(allCases.contains(.jpy))
        XCTAssertTrue(allCases.contains(.cny))
        XCTAssertTrue(allCases.contains(.krw))
        XCTAssertTrue(allCases.contains(.aud))
        XCTAssertTrue(allCases.contains(.cad))
        XCTAssertTrue(allCases.contains(.chf))
        
        // Verify count matches expected number of currencies
        XCTAssertGreaterThanOrEqual(allCases.count, 30)
    }
    
    // MARK: - Codable Tests
    
    func testCodable() throws {
        let currency = SupportedCurrency.inr
        
        // Test encoding
        let encoder = JSONEncoder()
        let data = try encoder.encode(currency)
        
        // Test decoding
        let decoder = JSONDecoder()
        let decodedCurrency = try decoder.decode(SupportedCurrency.self, from: data)
        
        XCTAssertEqual(currency, decodedCurrency)
    }
    
    func testCodableArray() throws {
        let currencies: [SupportedCurrency] = [.usd, .eur, .inr, .jpy]
        
        // Test encoding
        let encoder = JSONEncoder()
        let data = try encoder.encode(currencies)
        
        // Test decoding
        let decoder = JSONDecoder()
        let decodedCurrencies = try decoder.decode([SupportedCurrency].self, from: data)
        
        XCTAssertEqual(currencies, decodedCurrencies)
    }
    
    // MARK: - Edge Cases
    
    func testAllCurrenciesHaveValidProperties() {
        for currency in SupportedCurrency.allCases {
            // All currencies should have non-empty symbols
            XCTAssertFalse(currency.symbol.isEmpty, "Currency \(currency) has empty symbol")
            
            // All currencies should have non-empty display names
            XCTAssertFalse(currency.displayName.isEmpty, "Currency \(currency) has empty display name")
            
            // All currencies should have non-empty flags
            XCTAssertFalse(currency.flag.isEmpty, "Currency \(currency) has empty flag")
            
            // All currencies should have non-empty accessibility labels
            XCTAssertFalse(currency.accessibilityLabel.isEmpty, "Currency \(currency) has empty accessibility label")
            
            // Decimal places should be reasonable (0-4)
            XCTAssertTrue(currency.decimalPlaces >= 0 && currency.decimalPlaces <= 4, 
                         "Currency \(currency) has invalid decimal places: \(currency.decimalPlaces)")
        }
    }
    
    func testRegionalGroupingCompleteness() {
        let allRegionalCurrencies = Set(
            SupportedCurrency.northAmericanCurrencies +
            SupportedCurrency.europeanCurrencies +
            SupportedCurrency.asianCurrencies +
            SupportedCurrency.oceanianCurrencies +
            SupportedCurrency.middleEasternCurrencies +
            SupportedCurrency.africanCurrencies +
            SupportedCurrency.southAmericanCurrencies
        )
        
        let allCurrencies = Set(SupportedCurrency.allCases)
        
        // All currencies should be in at least one regional group
        XCTAssertEqual(allRegionalCurrencies, allCurrencies, 
                      "Some currencies are not assigned to regional groups")
    }
}