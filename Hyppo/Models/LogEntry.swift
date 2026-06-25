/**
 LogEntry model representing a timestamped journal entry for a research question.
 
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
    
    /// Whether this entry was system-generated (e.g., auto revision log)
    var isSystemGenerated: Bool
    
    /// Whether this entry is pinned for quick access
    var isPinned: Bool
    
    /// Sentiment of the log entry when linked to a Driver (Supporting/Contradicting/Neutral)
    var sentimentRaw: String?
    
    /// Source type when linked to a Driver (Article, Filing, etc.)
    var sourceTypeRaw: String?
    
    /// Optional URL for the source
    var sourceUrl: String?
    
    /// Timestamp when the event occurred (user-editable)
    var occurredAt: Date
    
    /// Timestamp when the entry was created
    var createdAt: Date
    
    /// Timestamp when the entry was last updated
    var updatedAt: Date
    
    // MARK: - Relationships
    
    /// Parent research question this log entry belongs to
    @Relationship(inverse: \ResearchQuestion.logEntries)
    var researchQuestion: ResearchQuestion?
    
    /// Associated driver for McKinsey framework (optional)
    var driver: Driver?
    
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
       - occurredAt: When the event occurred (defaults to now)
       - isSystemGenerated: Whether system-generated (defaults to false)
     */
    init(
        title: String,
        body: String,
        entryType: LogEntryType = .observation,
        occurredAt: Date = Date(),
        isSystemGenerated: Bool = false
    ) {
        self.logEntryId = UUID()
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.body = body.trimmingCharacters(in: .whitespacesAndNewlines)
        self.entryTypeRaw = entryType.rawValue
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
    
    /// Sentiment as enum (for McKinsey framework)
    var sentiment: EvidenceSentiment? {
        get {
            guard let raw = sentimentRaw else { return nil }
            return EvidenceSentiment(rawValue: raw)
        }
        set {
            sentimentRaw = newValue?.rawValue
        }
    }
    
    /// Source type as enum (for McKinsey framework)
    var sourceType: SourceType? {
        get {
            guard let raw = sourceTypeRaw else { return nil }
            return SourceType(rawValue: raw)
        }
        set {
            sourceTypeRaw = newValue?.rawValue
        }
    }
    
    /// Returns true if this log entry is linked to a driver
    var isLinkedToDriver: Bool {
        driver != nil
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
       - occurredAt: New occurred date
     */
    func update(
        title: String,
        body: String,
        entryType: LogEntryType,
        occurredAt: Date
    ) {
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.body = body.trimmingCharacters(in: .whitespacesAndNewlines)
        self.entryType = entryType
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
        
        return errors
    }
}

// MARK: - Factory Methods

extension LogEntry {
    /**
     Creates a system-generated review log entry.
     
     - Parameters:
       - outcome: The review outcome
       - summary: Summary of the review
     - Returns: A new system-generated log entry
     */
    static func createReviewLog(
        outcome: ReviewOutcome,
        summary: String
    ) -> LogEntry {
        return LogEntry(
            title: "Review: \(outcome.displayName)",
            body: summary,
            entryType: .review,
            isSystemGenerated: true
        )
    }
    
    /**
     Creates a system-generated log entry for research question status changes.
     
     - Parameters:
       - fromStatus: The previous status
       - toStatus: The new status
       - reason: Optional reason for the status change
     - Returns: A new system-generated log entry
     */
    static func createStatusChangeLog(
        fromStatus: ResearchQuestionStatus,
        toStatus: ResearchQuestionStatus,
        reason: String? = nil
    ) -> LogEntry {
        let title = "Status: \(fromStatus.displayName) → \(toStatus.displayName)"
        
        var body = "Research question status changed from \(fromStatus.displayName) to \(toStatus.displayName)."
        
        // Add contextual message based on new status
        switch toStatus {
        case .active:
            body += "\n\nThe research is now actively being tracked."
        case .onHold:
            body += "\n\nThe research has been put on hold for further evaluation."
        case .invalidated:
            body += "\n\nThe thesis has been marked as invalidated. One or more invalidation rules may have been triggered."
        case .archived:
            body += "\n\nThe research has been archived and is no longer actively tracked."
        }
        
        if let reason = reason, !reason.isEmpty {
            body += "\n\nReason: \(reason)"
        }
        
        return LogEntry(
            title: title,
            body: body,
            entryType: .update,
            isSystemGenerated: true
        )
    }
}
