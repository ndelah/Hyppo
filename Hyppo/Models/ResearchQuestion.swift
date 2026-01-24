/**
 ResearchQuestion model representing an area of inquiry about an asset.
 
 A research question is the primary organizing concept between Asset and Scenario.
 Users formulate questions about their investments, then create scenario-based
 answers (bull/base/bear) to explore different possible outcomes.
 */

import Foundation
import SwiftData

@Model
final class ResearchQuestion {
    // MARK: - Properties
    
    /// Unique identifier for the research question
    @Attribute(.unique) var questionId: UUID
    
    /// The research question text
    var questionText: String
    
    /// Context or background explaining why this question matters
    var context: String?
    
    /// Current status of the research question
    var statusRaw: String
    
    /// Conclusion or answer summary once the question is resolved
    var conclusion: String?
    
    /// Priority level (1-5, optional)
    var priority: Int?
    
    /// Timestamp when the question was created
    var createdAt: Date
    
    /// Timestamp when the question was last updated
    var updatedAt: Date
    
    // MARK: - Relationships
    
    /// Parent asset this research question belongs to
    var asset: Asset?
    
    /// Scenarios associated with this research question
    @Relationship(deleteRule: .cascade) var scenarios: [Scenario]?
    
    // MARK: - Initialization
    
    /**
     Creates a new research question with the required fields.
     
     - Parameters:
       - questionText: The research question
       - context: Optional background context
       - priority: Optional priority level (1-5)
     */
    init(
        questionText: String,
        context: String? = nil,
        priority: Int? = nil
    ) {
        self.questionId = UUID()
        self.questionText = questionText.trimmingCharacters(in: .whitespacesAndNewlines)
        self.context = context?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.statusRaw = ResearchQuestionStatus.open.rawValue
        self.priority = priority
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - Computed Properties
    
    /// Status as enum
    var status: ResearchQuestionStatus {
        get { ResearchQuestionStatus(rawValue: statusRaw) ?? .open }
        set {
            statusRaw = newValue.rawValue
            updatedAt = Date()
        }
    }
    
    /// Returns the count of scenarios for this research question
    var scenariosCount: Int {
        scenarios?.count ?? 0
    }
    
    /// Returns only active scenarios
    var activeScenarios: [Scenario] {
        scenarios?.filter { $0.status == .active } ?? []
    }
    
    /// Returns scenarios sorted by type (bull, base, bear, custom)
    var sortedScenarios: [Scenario] {
        scenarios?.sorted { $0.scenarioType.sortOrder < $1.scenarioType.sortOrder } ?? []
    }
    
    /// Display subtitle combining status and scenario count
    var displaySubtitle: String {
        let scenarioText = scenariosCount == 1 ? "scenario" : "scenarios"
        return "\(status.displayName) • \(scenariosCount) \(scenarioText)"
    }
    
    // MARK: - Methods
    
    /**
     Updates the research question content.
     
     - Parameters:
       - questionText: New question text
       - context: New context
       - priority: New priority level
     */
    func update(
        questionText: String,
        context: String?,
        priority: Int?
    ) {
        self.questionText = questionText.trimmingCharacters(in: .whitespacesAndNewlines)
        self.context = context?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.priority = priority
        self.updatedAt = Date()
    }
    
    /**
     Marks the research question as answered with a conclusion.
     
     - Parameter conclusion: The answer or conclusion text
     */
    func markAnswered(conclusion: String) {
        self.status = .answered
        self.conclusion = conclusion.trimmingCharacters(in: .whitespacesAndNewlines)
        self.updatedAt = Date()
    }
}

// MARK: - ResearchQuestionStatus Enum

/**
 Represents the lifecycle status of a research question.
 */
enum ResearchQuestionStatus: String, Codable, CaseIterable, Identifiable {
    case open = "Open"
    case answered = "Answered"
    case parked = "Parked"
    
    var id: String { rawValue }
    
    /// Display label for the status
    var displayName: String { rawValue }
    
    /// Icon name for visual representation
    var iconName: String {
        switch self {
        case .open: return "questionmark.circle"
        case .answered: return "checkmark.circle.fill"
        case .parked: return "pause.circle"
        }
    }
    
    /// Color identifier for UI theming
    var colorName: String {
        switch self {
        case .open: return "blue"
        case .answered: return "green"
        case .parked: return "gray"
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
        
        if let priority = priority, (priority < 1 || priority > 5) {
            errors.append("Priority must be between 1 and 5")
        }
        
        return errors
    }
}

