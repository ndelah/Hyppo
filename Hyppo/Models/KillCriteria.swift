/**
 KillCriteria model representing a specific condition that would invalidate the investment thesis.
 
 Users define these upfront to ensure falsifiability of their research.
 */

import Foundation
import SwiftData

@Model
final class KillCriteria {
    // MARK: - Properties
    
    /// Unique identifier for the kill criteria
    @Attribute(.unique) var criteriaId: UUID
    
    /// The condition that would trigger an exit (e.g., "Gross margin drops below 60%")
    var condition: String
    
    /// Specific threshold value if applicable (e.g., "60%")
    var threshold: String?
    
    /// Expected data source to monitor (e.g., "10-Q filings")
    var dataSource: String?
    
    /// Timestamp when the criteria was triggered, if ever
    var triggeredAt: Date?
    
    /// User notes about the criteria or its triggering
    var notes: String?
    
    // MARK: - Relationships
    
    /// Parent research question
    var researchQuestion: ResearchQuestion?
    
    // MARK: - Initialization
    
    init(
        condition: String,
        threshold: String? = nil,
        dataSource: String? = nil,
        notes: String? = nil
    ) {
        self.criteriaId = UUID()
        self.condition = condition.trimmingCharacters(in: .whitespacesAndNewlines)
        self.threshold = threshold?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.dataSource = dataSource?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.notes = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - Metadata
    
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - Computed Properties
    
    /// Returns true if the criteria has been triggered
    var isTriggered: Bool {
        triggeredAt != nil
    }
}

