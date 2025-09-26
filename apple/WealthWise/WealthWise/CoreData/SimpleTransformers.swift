import Foundation
import CoreData

/// Simplified transformer registration without complex transformers
/// This allows the project to build while we resolve actor isolation issues
public class AssetTransformers {
    
    public static func registerTransformers() {
        // For now, we'll rely on Core Data's built-in transformations
        // Complex transformers will be added back once actor isolation is resolved
    }
}