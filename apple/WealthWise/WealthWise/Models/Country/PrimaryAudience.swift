import Foundation

/// Primary target audience segments for WealthWise
/// Determines market-specific features, regulations, and cultural adaptations
public enum PrimaryAudience: String, CaseIterable, Codable, Hashable {
    // Primary Markets
    case indian = "indian"
    case american = "american"
    case british = "british"
    case canadian = "canadian"
    case australian = "australian"
    case singaporean = "singaporean"
    
    // European Markets
    case german = "german"
    case french = "french"
    case dutch = "dutch"
    case swiss = "swiss"
    case irish = "irish"
    case luxembourgish = "luxembourgish"
    
    // Asia-Pacific
    case japanese = "japanese"
    case hongKongese = "hongKongese"
    case newZealander = "newZealander"
    case malaysian = "malaysian"
    case thai = "thai"
    case filipino = "filipino"
    
    // Middle East
    case emirati = "emirati"
    case qatari = "qatari"
    case saudi = "saudi"
    
    // Americas
    case brazilian = "brazilian"
    case mexican = "mexican"
    
    /// Display name for the audience
    public var displayName: String {
        switch self {
        case .indian: return "Indian"
        case .american: return "American"
        case .british: return "British"
        case .canadian: return "Canadian"
        case .australian: return "Australian"
        case .singaporean: return "Singaporean"
        case .german: return "German"
        case .french: return "French"
        case .dutch: return "Dutch"
        case .swiss: return "Swiss"
        case .irish: return "Irish"
        case .luxembourgish: return "Luxembourgish"
        case .japanese: return "Japanese"
        case .hongKongese: return "Hong Kong"
        case .newZealander: return "New Zealand"
        case .malaysian: return "Malaysian"
        case .thai: return "Thai"
        case .filipino: return "Filipino"
        case .emirati: return "Emirati"
        case .qatari: return "Qatari"
        case .saudi: return "Saudi"
        case .brazilian: return "Brazilian"
        case .mexican: return "Mexican"
        }
    }
    
    /// Associated country codes for this audience
    public var associatedCountryCodes: [String] {
        switch self {
        case .indian: return ["IND"]
        case .american: return ["USA"]
        case .british: return ["GBR"]
        case .canadian: return ["CAN"]
        case .australian: return ["AUS"]
        case .singaporean: return ["SGP"]
        case .german: return ["DEU"]
        case .french: return ["FRA"]
        case .dutch: return ["NLD"]
        case .swiss: return ["CHE"]
        case .irish: return ["IRL"]
        case .luxembourgish: return ["LUX"]
        case .japanese: return ["JPN"]
        case .hongKongese: return ["HKG"]
        case .newZealander: return ["NZL"]
        case .malaysian: return ["MYS"]
        case .thai: return ["THA"]
        case .filipino: return ["PHL"]
        case .emirati: return ["ARE"]
        case .qatari: return ["QAT"]
        case .saudi: return ["SAU"]
        case .brazilian: return ["BRA"]
        case .mexican: return ["MEX"]
        }
    }
    
    /// Primary country code for this audience
    public var primaryCountryCode: String {
        return associatedCountryCodes.first!
    }
    
    /// Preferred number formatting style
    public var numberFormatStyle: NumberFormatStyle {
        switch self {
        case .indian: return .indian  // Lakh/Crore system
        case .american, .canadian, .australian, .newZealander, .singaporean:
            return .western  // Million/Billion system
        case .british: return .british  // Mixed usage
        case .german, .french, .dutch, .swiss, .irish, .luxembourgish:
            return .european  // European formatting
        case .japanese: return .japanese  // Japanese formatting
        case .hongKongese, .malaysian, .thai, .filipino, .emirati, .qatari, .saudi:
            return .western  // Western style adopted
        case .brazilian: return .brazilian  // Brazilian formatting
        case .mexican: return .mexican  // Mexican formatting
        }
    }
    
    /// Preferred date format style
    public var dateFormatStyle: AudienceDateFormatStyle {
        switch self {
        case .indian: return .ddMMYYYY  // DD/MM/YYYY
        case .american: return .mmDDYYYY  // MM/DD/YYYY
        case .british, .australian, .newZealander, .singaporean, .irish:
            return .ddMMYYYY  // DD/MM/YYYY
        case .canadian: return .mixed  // Both formats common
        case .german, .french, .dutch, .swiss, .luxembourgish:
            return .ddMMYYYY  // DD.MM.YYYY or DD/MM/YYYY
        case .japanese: return .yyyyMMDD  // YYYY/MM/DD
        case .hongKongese, .malaysian, .thai, .filipino:
            return .ddMMYYYY  // DD/MM/YYYY
        case .emirati, .qatari, .saudi: return .ddMMYYYY  // DD/MM/YYYY
        case .brazilian, .mexican: return .ddMMYYYY  // DD/MM/YYYY
        }
    }
    
    /// Primary language codes for this audience
    public var primaryLanguages: [String] {
        switch self {
        case .indian: return ["hi", "en"]
        case .american, .british, .canadian, .australian, .newZealander, .singaporean, .irish, .filipino: return ["en"]
        case .german: return ["de"]
        case .french: return ["fr"]
        case .dutch: return ["nl"]
        case .swiss: return ["de", "fr", "it"]
        case .luxembourgish: return ["lb", "fr", "de"]
        case .japanese: return ["ja"]
        case .hongKongese: return ["zh", "en"]
        case .malaysian: return ["ms", "en"]
        case .thai: return ["th"]
        case .emirati, .qatari, .saudi: return ["ar", "en"]
        case .brazilian: return ["pt"]
        case .mexican: return ["es"]
        }
    }
    
    /// Whether this audience uses right-to-left text direction
    public var isRTL: Bool {
        switch self {
        case .emirati, .qatari, .saudi: return true
        default: return false
        }
    }
    
    /// Financial year start month
    public var financialYearStartMonth: Int {
        switch self {
        case .indian, .british: return 4  // April
        default: return 1  // January
        }
    }
    
    /// Audiences primarily targeting Indian expats
    public static var indianExpatAudiences: [PrimaryAudience] {
        return [.american, .british, .canadian, .australian, .singaporean, .emirati, .german, .dutch]
    }
    
    /// Audiences in English-speaking countries
    public static var englishSpeaking: [PrimaryAudience] {
        return [.american, .british, .canadian, .australian, .newZealander, .singaporean, .irish, .emirati, .qatari, .saudi, .filipino]
    }
    
    /// Audiences in European Union countries
    public static var europeanUnion: [PrimaryAudience] {
        return [.german, .french, .dutch, .irish, .luxembourgish]
    }
    
    /// Initialize from country code string
    public init?(from countryCode: String) {
        for audience in PrimaryAudience.allCases {
            if audience.associatedCountryCodes.contains(countryCode) {
                self = audience
                return
            }
        }
        return nil
    }
    
    /// Get audience from current device locale
    public static var current: PrimaryAudience {
        let currentLocale = Locale.current
        let regionCode: String
        if #available(macOS 13.0, iOS 16.0, *) {
            regionCode = currentLocale.region?.identifier ?? "US"
        } else {
            regionCode = currentLocale.regionCode ?? "US"
        }
        return PrimaryAudience(from: regionCode) ?? .american  // Default fallback
    }
}

// MARK: - Supporting Enums

/// Number formatting styles for different audiences
public enum NumberFormatStyle: String, CaseIterable, Codable {
    case indian = "indian"        // 1,00,000 (Lakh), 1,00,00,000 (Crore)
    case western = "western"      // 1,000,000 (Million), 1,000,000,000 (Billion)
    case british = "british"      // Mixed usage of both systems
    case european = "european"    // 1.000.000 or 1 000 000 (space/period separators)
    case japanese = "japanese"    // 1,0000 (Man), 1,0000,0000 (Oku)
    case brazilian = "brazilian"  // 1.000.000 (period separator)
    case mexican = "mexican"      // 1,000,000 (comma separator)
    
    /// Display name for the format style
    public var displayName: String {
        switch self {
        case .indian: return "Indian (Lakh/Crore)"
        case .western: return "Western (Million/Billion)"
        case .british: return "British (Mixed)"
        case .european: return "European"
        case .japanese: return "Japanese (Man/Oku)"
        case .brazilian: return "Brazilian"
        case .mexican: return "Mexican"
        }
    }
}

/// Date formatting styles for different audiences
public enum AudienceDateFormatStyle: String, CaseIterable, Codable {
    case ddMMYYYY = "ddMMYYYY"    // DD/MM/YYYY
    case mmDDYYYY = "mmDDYYYY"    // MM/DD/YYYY
    case yyyyMMDD = "yyyyMMDD"    // YYYY/MM/DD
    case mixed = "mixed"          // Context-dependent
    
    /// Display name for the format style
    public var displayName: String {
        switch self {
        case .ddMMYYYY: return "DD/MM/YYYY"
        case .mmDDYYYY: return "MM/DD/YYYY"
        case .yyyyMMDD: return "YYYY/MM/DD"
        case .mixed: return "Mixed"
        }
    }
    
    /// Example formatted date
    public var example: String {
        let date = Date()
        let formatter = DateFormatter()
        switch self {
        case .ddMMYYYY:
            formatter.dateFormat = "dd/MM/yyyy"
        case .mmDDYYYY:
            formatter.dateFormat = "MM/dd/yyyy"
        case .yyyyMMDD:
            formatter.dateFormat = "yyyy/MM/dd"
        case .mixed:
            formatter.dateFormat = "dd/MM/yyyy"  // Default to DD/MM/YYYY
        }
        return formatter.string(from: date)
    }
}

// MARK: - Comparable
extension PrimaryAudience: Comparable {
    public static func < (lhs: PrimaryAudience, rhs: PrimaryAudience) -> Bool {
        lhs.displayName < rhs.displayName
    }
}

// MARK: - CustomStringConvertible
extension PrimaryAudience: CustomStringConvertible {
    public var description: String {
        displayName
    }
}