import SwiftUI

public struct SemanticColors: Sendable {
    public let colorScheme: ColorScheme
    public let isHighContrast: Bool
    
    public init(colorScheme: ColorScheme, isHighContrast: Bool = false) {
        self.colorScheme = colorScheme
        self.isHighContrast = isHighContrast
    }
    
    public var primary: Color { Color.blue }
    public var background: Color { Color.white }
    public var primaryText: Color { Color.primary }
    public var secondaryText: Color { Color.secondary }
    public var tertiaryText: Color { Color.gray }
    public var positive: Color { Color.green }
    public var negative: Color { Color.red }
    public var warning: Color { Color.orange }
    public var neutral: Color { Color.gray }
}
