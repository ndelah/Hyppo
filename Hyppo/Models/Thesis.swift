/**
 Thesis model representing an investment hypothesis for an asset.
 
 A thesis captures the user's reasoning about why an investment
 might succeed or fail. Users can create multiple theses per asset
 to represent different scenarios (bull/base/bear cases).
 */

import Foundation
import SwiftData

@Model
final class Thesis {
    // MARK: - Properties
    
    /// Unique identifier for the thesis
    @Attribute(.unique) var thesisId: UUID
    
    /// Type/scenario of the thesis (base, bull, bear, custom)
    var thesisTypeRaw: String
    
    /// Title of the thesis
    var title: String
    
    /// The core thesis statement - what must be true for this to work
    var thesisStatement: String
    
    /// Key drivers that support the thesis (stored as JSON array)
    var keyDriversData: Data?
    
    /// Rules that would invalidate the thesis (stored as JSON array)
    var invalidationRulesData: Data?
    
    /// Optional catalysts that could trigger the thesis (stored as JSON array)
    var catalystsData: Data?
    
    /// Optional key risks to the thesis (stored as JSON array)
    var keyRisksData: Data?
    
    /// Current confidence level (1-5, optional)
    var confidenceCurrent: Int?
    
    /// Current status of the thesis
    var statusRaw: String
    
    /// Version number for tracking revisions
    var versionNumber: Int
    
    /// Timestamp when the thesis was created
    var createdAt: Date
    
    /// Timestamp when the thesis was last updated
    var updatedAt: Date
    
    /// Timestamp when the thesis content was last meaningfully updated
    var lastUpdatedAt: Date
    
    /// Optional timestamp of the last review
    var lastReviewedAt: Date?
    
    /// Timestamp when the status was last changed
    var statusChangedAt: Date
    
    // MARK: - Relationships
    
    /// Parent asset this thesis belongs to
    var asset: Asset?
    
    /// Log entries for this thesis (ordered chronologically)
    @Relationship(deleteRule: .cascade) var logEntries: [LogEntry]?
    
    /// Tags associated with this thesis
    var tags: [Tag]?
    
    /// Review reminder for this thesis
    @Relationship(deleteRule: .cascade) var reviewReminder: ReviewReminder?
    
    // MARK: - Initialization
    
    /**
     Creates a new thesis with the required fields.
     
     - Parameters:
       - thesisType: The type/scenario of the thesis
       - title: Short title for the thesis
       - thesisStatement: The core hypothesis statement
       - keyDrivers: List of key drivers supporting the thesis
       - invalidationRules: List of conditions that would invalidate the thesis
       - catalysts: Optional list of potential catalysts
       - keyRisks: Optional list of key risks
       - confidence: Optional confidence level (1-5)
     */
    init(
        thesisType: ThesisType,
        title: String,
        thesisStatement: String,
        keyDrivers: [String],
        invalidationRules: [String],
        catalysts: [String]? = nil,
        keyRisks: [String]? = nil,
        confidence: Int? = nil
    ) {
        self.thesisId = UUID()
        self.thesisTypeRaw = thesisType.rawValue
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.thesisStatement = thesisStatement.trimmingCharacters(in: .whitespacesAndNewlines)
        self.keyDriversData = try? JSONEncoder().encode(keyDrivers)
        self.invalidationRulesData = try? JSONEncoder().encode(invalidationRules)
        self.catalystsData = catalysts.flatMap { try? JSONEncoder().encode($0) }
        self.keyRisksData = keyRisks.flatMap { try? JSONEncoder().encode($0) }
        self.confidenceCurrent = confidence
        self.statusRaw = ThesisStatus.active.rawValue
        self.versionNumber = 1
        self.createdAt = Date()
        self.updatedAt = Date()
        self.lastUpdatedAt = Date()
        self.statusChangedAt = Date()
    }
    
    // MARK: - Computed Properties
    
    /// Thesis type as enum
    var thesisType: ThesisType {
        get { ThesisType(rawValue: thesisTypeRaw) ?? .custom }
        set { thesisTypeRaw = newValue.rawValue }
    }
    
    /// Status as enum
    var status: ThesisStatus {
        get { ThesisStatus(rawValue: statusRaw) ?? .active }
        set {
            statusRaw = newValue.rawValue
            statusChangedAt = Date()
        }
    }
    
    /// Key drivers as string array
    var keyDrivers: [String] {
        get {
            guard let data = keyDriversData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            keyDriversData = try? JSONEncoder().encode(newValue)
        }
    }
    
    /// Invalidation rules as string array
    var invalidationRules: [String] {
        get {
            guard let data = invalidationRulesData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            invalidationRulesData = try? JSONEncoder().encode(newValue)
        }
    }
    
    /// Catalysts as string array
    var catalysts: [String] {
        get {
            guard let data = catalystsData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            catalystsData = try? JSONEncoder().encode(newValue)
        }
    }
    
    /// Key risks as string array
    var keyRisks: [String] {
        get {
            guard let data = keyRisksData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            keyRisksData = try? JSONEncoder().encode(newValue)
        }
    }
    
    /// Confidence level as enum
    var confidence: ConfidenceLevel? {
        get {
            guard let value = confidenceCurrent else { return nil }
            return ConfidenceLevel(rawValue: value)
        }
        set {
            confidenceCurrent = newValue?.rawValue
        }
    }
    
    /// Returns the count of log entries for this thesis
    var logEntriesCount: Int {
        logEntries?.count ?? 0
    }
    
    /// Returns log entries sorted by occurred date (most recent first)
    var sortedLogEntries: [LogEntry] {
        logEntries?.sorted { $0.occurredAt > $1.occurredAt } ?? []
    }
    
    /// Display subtitle combining type and status
    var displaySubtitle: String {
        "\(thesisType.displayName) • \(status.displayName)"
    }
    
    // MARK: - Methods
    
    /**
     Updates the thesis content and increments the version number.
     
     - Parameters:
       - title: New title
       - thesisStatement: New thesis statement
       - keyDrivers: Updated key drivers
       - invalidationRules: Updated invalidation rules
       - catalysts: Updated catalysts
       - keyRisks: Updated key risks
       - confidence: Updated confidence level
     */
    func update(
        title: String,
        thesisStatement: String,
        keyDrivers: [String],
        invalidationRules: [String],
        catalysts: [String]?,
        keyRisks: [String]?,
        confidence: Int?
    ) {
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.thesisStatement = thesisStatement.trimmingCharacters(in: .whitespacesAndNewlines)
        self.keyDrivers = keyDrivers
        self.invalidationRules = invalidationRules
        self.catalysts = catalysts ?? []
        self.keyRisks = keyRisks ?? []
        self.confidenceCurrent = confidence
        self.versionNumber += 1
        self.updatedAt = Date()
        self.lastUpdatedAt = Date()
    }
    
    /**
     Updates the thesis status and returns the previous status for logging.
     
     - Parameter newStatus: The new status to set
     - Returns: The previous status before the change, or nil if unchanged
     */
    @discardableResult
    func updateStatus(_ newStatus: ThesisStatus) -> ThesisStatus? {
        let oldStatus = self.status
        guard oldStatus != newStatus else { return nil }
        
        self.status = newStatus
        self.updatedAt = Date()
        return oldStatus
    }
    
    /**
     Records that a review was completed.
     */
    func markReviewed() {
        self.lastReviewedAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Validation

extension Thesis {
    /// Validates that the thesis has all required fields populated
    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !thesisStatement.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !keyDrivers.isEmpty &&
        !invalidationRules.isEmpty
    }
    
    /// Returns validation errors if any
    var validationErrors: [String] {
        var errors: [String] = []
        
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Title is required")
        }
        
        if thesisStatement.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Thesis statement is required")
        }
        
        if keyDrivers.isEmpty {
            errors.append("At least one key driver is required")
        }
        
        if invalidationRules.isEmpty {
            errors.append("At least one invalidation rule is required")
        }
        
        if let confidence = confidenceCurrent, (confidence < 1 || confidence > 5) {
            errors.append("Confidence must be between 1 and 5")
        }
        
        return errors
    }
}
