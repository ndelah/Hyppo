/**
 LogEntry model representing a timestamped journal entry for a thesis.
 
 Log entries form the chronological record of observations, updates,
 and evidence that track the evolution of an investment thesis over time.
 */

import Foundation
import SwiftData

@Model
final class LogEntry {
    // MARK: - Properties
    
    /// Unique identifier for the log entry
    @Attribute(.unique) var logEntryId: UUID
    
    /// Title of the log entry
    var title: String
    
    /// Body content of the log entry
    var body: String
    
    /// Type of the log entry
    var entryTypeRaw: String
    
    /// Confidence level at time of entry (1-5, optional)
    var confidence: Int?
    
    /// Whether this entry was system-generated (e.g., auto revision log)
    var isSystemGenerated: Bool
    
    /// Whether this entry is pinned for quick access
    var isPinned: Bool
    
    /// Timestamp when the event occurred (user-editable)
    var occurredAt: Date
    
    /// Timestamp when the entry was created
    var createdAt: Date
    
    /// Timestamp when the entry was last updated
    var updatedAt: Date
    
    // MARK: - Relationships
    
    /// Parent thesis this log entry belongs to
    var thesis: Thesis?
    
    /// Evidence items attached to this log entry
    @Relationship(deleteRule: .cascade) var evidenceItems: [Evidence]?
    
    /// Tags associated with this log entry
    var tags: [Tag]?
    
    // MARK: - Initialization
    
    /**
     Creates a new log entry with the required fields.
     
     - Parameters:
       - title: Title of the log entry
       - body: Body content of the log entry
       - entryType: Type of the log entry
       - confidence: Optional confidence level (1-5)
       - occurredAt: When the event occurred (defaults to now)
       - isSystemGenerated: Whether system-generated (defaults to false)
     */
    init(
        title: String,
        body: String,
        entryType: LogEntryType = .observation,
        confidence: Int? = nil,
        occurredAt: Date = Date(),
        isSystemGenerated: Bool = false
    ) {
        self.logEntryId = UUID()
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.body = body.trimmingCharacters(in: .whitespacesAndNewlines)
        self.entryTypeRaw = entryType.rawValue
        self.confidence = confidence
        self.isSystemGenerated = isSystemGenerated
        self.isPinned = false
        self.occurredAt = occurredAt
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - Computed Properties
    
    /// Entry type as enum
    var entryType: LogEntryType {
        get { LogEntryType(rawValue: entryTypeRaw) ?? .observation }
        set { entryTypeRaw = newValue.rawValue }
    }
    
    /// Confidence level as enum
    var confidenceLevel: ConfidenceLevel? {
        get {
            guard let value = confidence else { return nil }
            return ConfidenceLevel(rawValue: value)
        }
        set {
            confidence = newValue?.rawValue
        }
    }
    
    /// Returns the count of evidence items
    var evidenceCount: Int {
        evidenceItems?.count ?? 0
    }
    
    /// Returns evidence items sorted by captured date
    var sortedEvidence: [Evidence] {
        evidenceItems?.sorted { $0.capturedAt > $1.capturedAt } ?? []
    }
    
    /// Display subtitle with type and date
    var displaySubtitle: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "\(entryType.displayName) • \(formatter.string(from: occurredAt))"
    }
    
    /// Short preview of the body content
    var bodyPreview: String {
        let maxLength = 150
        if body.count <= maxLength {
            return body
        }
        return String(body.prefix(maxLength)) + "..."
    }
    
    // MARK: - Methods
    
    /**
     Updates the log entry content.
     
     - Parameters:
       - title: New title
       - body: New body content
       - entryType: New entry type
       - confidence: New confidence level
       - occurredAt: New occurred date
     */
    func update(
        title: String,
        body: String,
        entryType: LogEntryType,
        confidence: Int?,
        occurredAt: Date
    ) {
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.body = body.trimmingCharacters(in: .whitespacesAndNewlines)
        self.entryType = entryType
        self.confidence = confidence
        self.occurredAt = occurredAt
        self.updatedAt = Date()
    }
    
    /**
     Toggles the pinned state of the log entry.
     */
    func togglePinned() {
        self.isPinned.toggle()
        self.updatedAt = Date()
    }
}

// MARK: - Validation

extension LogEntry {
    /// Validates that the log entry has all required fields populated
    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Returns validation errors if any
    var validationErrors: [String] {
        var errors: [String] = []
        
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Title is required")
        }
        
        if body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Body content is required")
        }
        
        if let confidence = confidence, (confidence < 1 || confidence > 5) {
            errors.append("Confidence must be between 1 and 5")
        }
        
        return errors
    }
}

// MARK: - Factory Methods

extension LogEntry {
    /**
     Creates a system-generated update log entry for thesis revisions.
     
     - Parameters:
       - diffSummary: Summary of what changed
       - confidenceBefore: Previous confidence level
       - confidenceAfter: New confidence level
     - Returns: A new system-generated log entry
     */
    static func createRevisionLog(
        diffSummary: String,
        confidenceBefore: Int?,
        confidenceAfter: Int?
    ) -> LogEntry {
        var body = diffSummary
        
        if let before = confidenceBefore, let after = confidenceAfter, before != after {
            body += "\n\nConfidence changed from \(before)/5 to \(after)/5"
        }
        
        return LogEntry(
            title: "Thesis Updated",
            body: body,
            entryType: .update,
            confidence: confidenceAfter,
            isSystemGenerated: true
        )
    }
    
    /**
     Creates a system-generated review log entry.
     
     - Parameters:
       - outcome: The review outcome
       - summary: Summary of the review
       - confidence: Confidence level after review
     - Returns: A new system-generated log entry
     */
    static func createReviewLog(
        outcome: ReviewOutcome,
        summary: String,
        confidence: Int?
    ) -> LogEntry {
        return LogEntry(
            title: "Review: \(outcome.displayName)",
            body: summary,
            entryType: .review,
            confidence: confidence,
            isSystemGenerated: true
        )
    }
}
