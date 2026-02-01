/**
 ResearchQuestion model representing an investment thesis/hypothesis for an asset.
 
 A research question captures the user's core investment reasoning, including
 the thesis statement, key drivers, invalidation rules, and scenarios (bull/base/bear).
 All log entries and evidence are now attached directly to the research question.
 */

import Foundation
import SwiftData

// MARK: - Scenarios Transformer

/**
 Value transformer for encoding/decoding SimpleScenario arrays to Data.
 */
final class ScenariosTransformer: ValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        NSData.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let scenarios = value as? [SimpleScenario] else { return nil }
        return try? JSONEncoder().encode(scenarios)
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        return try? JSONDecoder().decode([SimpleScenario].self, from: data)
    }
    
    static func register() {
        ValueTransformer.setValueTransformer(
            ScenariosTransformer(),
            forName: NSValueTransformerName("ScenariosTransformer")
        )
    }
}

// MARK: - Simple Scenario Structure

/**
 Lightweight scenario representation stored as JSON array.
 Each scenario is just a type (bull/base/bear) and a title describing the outcome.
 */
struct SimpleScenario: Codable, Identifiable, Equatable {
    var id: UUID
    var type: String  // ScenarioType rawValue
    var title: String
    
    init(type: ScenarioType = .base, title: String = "") {
        self.id = UUID()
        self.type = type.rawValue
        self.title = title
    }
    
    /// Scenario type as enum
    var scenarioType: ScenarioType {
        get { ScenarioType(rawValue: type) ?? .base }
        set { type = newValue.rawValue }
    }
}

// MARK: - Research Question Status

/**
 Represents the lifecycle status of a research question.
 */
enum ResearchQuestionStatus: String, Codable, CaseIterable, Identifiable {
    case active = "Active"
    case onHold = "On Hold"
    case invalidated = "Invalidated"
    case archived = "Archived"
    
    var id: String { rawValue }
    
    /// Display label for the status
    var displayName: String { rawValue }
    
    /// Icon name for visual representation
    var iconName: String {
        switch self {
        case .active: return "checkmark.circle.fill"
        case .onHold: return "pause.circle.fill"
        case .invalidated: return "xmark.circle.fill"
        case .archived: return "archivebox.fill"
        }
    }
    
    /// Color identifier for UI theming
    var colorName: String {
        switch self {
        case .active: return "green"
        case .onHold: return "orange"
        case .invalidated: return "red"
        case .archived: return "gray"
        }
    }
}

// MARK: - Research Question Model

@Model
final class ResearchQuestion {
    // MARK: - Properties
    
    /// Unique identifier for the research question
    @Attribute(.unique) var questionId: UUID
    
    /// The research question text
    var questionText: String
    
    /// Context or background explaining why this question matters
    var context: String?
    
    /// The core thesis statement - what must be true for this investment to work
    var thesisStatement: String?
    
    /// Current confidence level (1-5)
    var confidenceCurrent: Int?
    
    /// Raw status value for persistence
    var statusRaw: String
    
    /// Version number for tracking updates
    var versionNumber: Int
    
    /// Timestamp when the question was created
    var createdAt: Date
    
    /// Timestamp when the question was last updated
    var updatedAt: Date
    
    /// Alias for updatedAt for compatibility
    var lastUpdatedAt: Date
    
    /// Timestamp when the status last changed
    var statusChangedAt: Date
    
    /// Conclusion text when the question is resolved
    var conclusion: String?
    
    /// Timestamp of last review
    var lastReviewedAt: Date?
    
    /// JSON-encoded scenarios array
    @Attribute(.transformable(by: ScenariosTransformer.self))
    private var scenariosData: Data?
    
    /// Scenarios for this research question
    var scenarios: [SimpleScenario] {
        get {
            guard let data = scenariosData else { return [] }
            return (try? JSONDecoder().decode([SimpleScenario].self, from: data)) ?? []
        }
        set {
            scenariosData = try? JSONEncoder().encode(newValue)
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
    
    // MARK: - Relationships
    
    /// Parent asset this research question belongs to
    var asset: Asset?
    
    /// Drivers (assumptions) supporting the thesis
    @Relationship(deleteRule: .cascade, inverse: \Driver.researchQuestion)
    var drivers: [Driver]?
    
    /// Log entries for this research question (ordered chronologically)
    @Relationship(deleteRule: .cascade) var logEntries: [LogEntry]?
    
    /// Tags associated with this research question
    var tags: [Tag]?
    
    /// Review reminder for this research question
    @Relationship(deleteRule: .cascade) var reviewReminder: ReviewReminder?
    
    // MARK: - Initialization
    
    /**
     Creates a new research question with the required fields.
     
     - Parameters:
       - questionText: The research question
       - context: Optional background context
       - thesisStatement: Optional core thesis statement
       - keyDrivers: List of key drivers supporting the thesis
       - invalidationRules: List of conditions that would invalidate the thesis
       - catalysts: Optional list of potential catalysts
       - keyRisks: Optional list of key risks
       - scenarios: Optional list of simple scenarios (bull/base/bear outcomes)
       - confidence: Optional confidence level (1-5)
     */
    init(
        questionText: String,
        context: String? = nil,
        thesisStatement: String? = nil,
        confidence: Int? = nil
    ) {
        self.questionId = UUID()
        self.questionText = questionText.trimmingCharacters(in: .whitespacesAndNewlines)
        self.context = context?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.thesisStatement = thesisStatement?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.confidenceCurrent = confidence
        self.statusRaw = ResearchQuestionStatus.active.rawValue
        self.versionNumber = 1
        self.createdAt = Date()
        self.updatedAt = Date()
        self.lastUpdatedAt = Date()
        self.statusChangedAt = Date()
    }
    
    // MARK: - Computed Properties
    
    /// Status as enum
    var status: ResearchQuestionStatus {
        get { ResearchQuestionStatus(rawValue: statusRaw) ?? .active }
        set {
            statusRaw = newValue.rawValue
            statusChangedAt = Date()
            updatedAt = Date()
        }
    }
    
    /// Top-level drivers (those without a parent)
    var topLevelDrivers: [Driver] {
        drivers?.filter { $0.parentDriver == nil }.sorted { $0.position < $1.position } ?? []
    }
    
    /// Returns true if the question has at least 2 drivers
    var hasMinimumDrivers: Bool {
        (drivers?.count ?? 0) >= 2
    }
    
    /// Returns the count of log entries for this research question
    var logEntriesCount: Int {
        logEntries?.count ?? 0
    }
    
    /// Returns log entries sorted by occurred date (most recent first)
    var sortedLogEntries: [LogEntry] {
        logEntries?.sorted { $0.occurredAt > $1.occurredAt } ?? []
    }
    
    /// Returns the count of scenarios
    var scenariosCount: Int {
        scenarios.count
    }
    
    /// Display subtitle combining status and info
    var displaySubtitle: String {
        var parts: [String] = [status.displayName]
        if !scenarios.isEmpty {
            let scenarioText = scenariosCount == 1 ? "scenario" : "scenarios"
            parts.append("\(scenariosCount) \(scenarioText)")
        }
        if let confidence = confidence {
            parts.append(confidence.shortLabel)
        }
        return parts.joined(separator: " • ")
    }
    
    // MARK: - Methods
    
    /**
     Updates the research question content and increments the version number.
     
     - Parameters:
       - questionText: New question text
       - context: New context
       - thesisStatement: New thesis statement
       - keyDrivers: Updated key drivers
       - invalidationRules: Updated invalidation rules
       - catalysts: Updated catalysts
       - keyRisks: Updated key risks
       - scenarios: Updated scenarios
       - confidence: Updated confidence level
     */
    func update(
        questionText: String,
        context: String?,
        thesisStatement: String?,
        confidence: Int?
    ) {
        self.questionText = questionText.trimmingCharacters(in: .whitespacesAndNewlines)
        self.context = context?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.thesisStatement = thesisStatement?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.confidenceCurrent = confidence
        self.versionNumber += 1
        self.updatedAt = Date()
        self.lastUpdatedAt = Date()
    }
    
    /**
     Updates the research question status and returns the previous status for logging.
     
     - Parameter newStatus: The new status to set
     - Returns: The previous status before the change, or nil if unchanged
     */
    @discardableResult
    func updateStatus(_ newStatus: ResearchQuestionStatus) -> ResearchQuestionStatus? {
        let oldStatus = self.status
        guard oldStatus != newStatus else { return nil }
        
        self.status = newStatus
        return oldStatus
    }
    
    /**
     Marks the research question as answered with a conclusion.
     
     - Parameter conclusion: The answer or conclusion text
     */
    func markAnswered(conclusion: String) {
        self.conclusion = conclusion.trimmingCharacters(in: .whitespacesAndNewlines)
        self.status = .archived
        self.updatedAt = Date()
    }
    
    /**
     Records that a review was completed.
     */
    func markReviewed() {
        self.lastReviewedAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - Scenario Helpers
    
    /**
     Adds a new scenario to the list.
     
     - Parameters:
       - type: The scenario type (bull/base/bear)
       - title: The scenario title/description
     */
    func addScenario(type: ScenarioType, title: String) {
        var current = scenarios
        current.append(SimpleScenario(type: type, title: title))
        scenarios = current
        updatedAt = Date()
    }
    
    /**
     Removes a scenario by ID.
     
     - Parameter id: The scenario ID to remove
     */
    func removeScenario(id: UUID) {
        var current = scenarios
        current.removeAll { $0.id == id }
        scenarios = current
        updatedAt = Date()
    }
    
    /**
     Updates an existing scenario.
     
     - Parameters:
       - id: The scenario ID to update
       - type: The new scenario type
       - title: The new scenario title
     */
    func updateScenario(id: UUID, type: ScenarioType, title: String) {
        var current = scenarios
        if let index = current.firstIndex(where: { $0.id == id }) {
            current[index].scenarioType = type
            current[index].title = title
            scenarios = current
            updatedAt = Date()
        }
    }
}

// MARK: - Validation

extension ResearchQuestion {
    /// Validates that the research question has all required fields populated
    var isValid: Bool {
        !questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Returns validation errors if any
    var validationErrors: [String] {
        var errors: [String] = []
        
        if questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Question text is required")
        }
        
        if let confidence = confidenceCurrent, (confidence < 1 || confidence > 5) {
            errors.append("Confidence must be between 1 and 5")
        }
        
        return errors
    }
}
