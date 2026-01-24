/**
 Tag model for categorizing assets, scenarios, log entries, and evidence.
 
 Tags provide a flexible way to organize and filter content
 across the application using user-defined labels.
 */

import Foundation
import SwiftData

@Model
final class Tag {
    // MARK: - Properties
    
    /// Unique identifier for the tag
    @Attribute(.unique) var tagId: UUID
    
    /// Display name of the tag
    var name: String
    
    /// Normalized name for search and deduplication (lowercase, trimmed)
    var nameNormalized: String
    
    /// Optional color identifier for visual distinction
    var colorName: String?
    
    /// Timestamp when the tag was created
    var createdAt: Date
    
    // MARK: - Relationships
    
    /// Assets associated with this tag
    @Relationship(inverse: \Asset.tags) var assets: [Asset]?
    
    /// Scenarios associated with this tag
    @Relationship(inverse: \Scenario.tags) var scenarios: [Scenario]?
    
    /// Log entries associated with this tag
    @Relationship(inverse: \LogEntry.tags) var logEntries: [LogEntry]?
    
    /// Evidence items associated with this tag
    @Relationship(inverse: \Evidence.tags) var evidenceItems: [Evidence]?
    
    // MARK: - Initialization
    
    /**
     Creates a new tag with the specified name.
     
     - Parameters:
       - name: The display name for the tag
       - colorName: Optional color identifier for visual styling
     */
    init(name: String, colorName: String? = nil) {
        self.tagId = UUID()
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.nameNormalized = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        self.colorName = colorName
        self.createdAt = Date()
    }
    
    // MARK: - Methods
    
    /**
     Updates the tag name and re-normalizes.
     
     - Parameter newName: The new display name
     */
    func updateName(_ newName: String) {
        self.name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.nameNormalized = newName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

// MARK: - Validation

extension Tag {
    /// Validates that the tag has a non-empty name
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Returns validation errors if any
    var validationErrors: [String] {
        var errors: [String] = []
        
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Tag name is required")
        }
        
        return errors
    }
}

