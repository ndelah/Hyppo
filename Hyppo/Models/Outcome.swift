/**
 Outcome model representing the post-mortem assessment of an investment thesis.
 
 Outcomes capture what actually happened after an investment decision,
 enabling comparison of expectations vs reality. Recording an outcome
 is required after Exit or Abandon decisions to complete the thesis lifecycle.
 
 The Outcome is the "cash flow statement" that reconciles the "P&L" (research)
 with the "balance sheet" (decisions).
 */

import Foundation
import SwiftData

@Model
final class Outcome {
    // MARK: - Properties
    
    /// Unique identifier for the outcome
    @Attribute(.unique) var outcomeId: UUID
    
    // MARK: - What Actually Happened
    
    /// Narrative description of what actually occurred
    var actualResult: String
    
    /// How long the position was held (or thesis was watched)
    var actualTimeframe: String?
    
    /// Actual exit price if applicable
    var exitPrice: String?
    
    // MARK: - Assessments
    
    /// Assessment of whether the thesis was correct
    var thesisAssessmentRaw: String
    
    /// Assessment of decision timing
    var timingAssessmentRaw: String
    
    // MARK: - Reflection
    
    /// What the user learned from this investment
    var lessonsLearned: String?
    
    /// What the user would do differently next time
    var whatWouldIDoDifferently: String?
    
    // MARK: - Relationships
    
    /// Parent research question this outcome belongs to
    var researchQuestion: ResearchQuestion?
    
    // MARK: - Metadata
    
    /// When the outcome was formally recorded
    var recordedAt: Date
    
    /// Timestamp when the outcome record was created
    var createdAt: Date
    
    /// Timestamp when the outcome record was last updated
    var updatedAt: Date
    
    // MARK: - Initialization
    
    /**
     Creates a new outcome with the required fields.
     
     - Parameters:
       - actualResult: Narrative of what actually happened
       - thesisAssessment: Assessment of thesis accuracy
       - timingAssessment: Assessment of timing accuracy
       - recordedAt: When the outcome was recorded (defaults to now)
     */
    init(
        actualResult: String,
        thesisAssessment: ThesisAssessment,
        timingAssessment: TimingAssessment,
        recordedAt: Date = Date()
    ) {
        self.outcomeId = UUID()
        self.actualResult = actualResult.trimmingCharacters(in: .whitespacesAndNewlines)
        self.thesisAssessmentRaw = thesisAssessment.rawValue
        self.timingAssessmentRaw = timingAssessment.rawValue
        self.recordedAt = recordedAt
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - Computed Properties
    
    /// Thesis assessment as enum
    var thesisAssessment: ThesisAssessment {
        get { ThesisAssessment(rawValue: thesisAssessmentRaw) ?? .inconclusive }
        set {
            thesisAssessmentRaw = newValue.rawValue
            updatedAt = Date()
        }
    }
    
    /// Timing assessment as enum
    var timingAssessment: TimingAssessment {
        get { TimingAssessment(rawValue: timingAssessmentRaw) ?? .notApplicable }
        set {
            timingAssessmentRaw = newValue.rawValue
            updatedAt = Date()
        }
    }
    
    /// Whether this outcome represents a successful thesis
    var wasThesisSuccessful: Bool {
        thesisAssessment == .correct
    }
    
    /// Whether this outcome has reflection notes
    var hasReflection: Bool {
        (lessonsLearned != nil && !lessonsLearned!.isEmpty) ||
        (whatWouldIDoDifferently != nil && !whatWouldIDoDifferently!.isEmpty)
    }
    
    /// Display subtitle with assessments
    var displaySubtitle: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(thesisAssessment.displayName) • \(timingAssessment.displayName) • \(formatter.string(from: recordedAt))"
    }
    
    /// Short summary of the outcome
    var summaryText: String {
        var parts: [String] = []
        parts.append("Thesis: \(thesisAssessment.displayName)")
        parts.append("Timing: \(timingAssessment.displayName)")
        if let timeframe = actualTimeframe, !timeframe.isEmpty {
            parts.append("Duration: \(timeframe)")
        }
        return parts.joined(separator: " • ")
    }
    
    // MARK: - Methods
    
    /**
     Updates the outcome with new values.
     
     - Parameters:
       - actualResult: Updated result narrative
       - actualTimeframe: Updated timeframe
       - exitPrice: Updated exit price
       - thesisAssessment: Updated thesis assessment
       - timingAssessment: Updated timing assessment
       - lessonsLearned: Updated lessons
       - whatWouldIDoDifferently: Updated reflection
     */
    func update(
        actualResult: String? = nil,
        actualTimeframe: String? = nil,
        exitPrice: String? = nil,
        thesisAssessment: ThesisAssessment? = nil,
        timingAssessment: TimingAssessment? = nil,
        lessonsLearned: String? = nil,
        whatWouldIDoDifferently: String? = nil
    ) {
        if let actualResult = actualResult {
            self.actualResult = actualResult.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let actualTimeframe = actualTimeframe {
            self.actualTimeframe = actualTimeframe.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let exitPrice = exitPrice {
            self.exitPrice = exitPrice.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let thesisAssessment = thesisAssessment {
            self.thesisAssessmentRaw = thesisAssessment.rawValue
        }
        if let timingAssessment = timingAssessment {
            self.timingAssessmentRaw = timingAssessment.rawValue
        }
        if let lessonsLearned = lessonsLearned {
            self.lessonsLearned = lessonsLearned.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let whatWouldIDoDifferently = whatWouldIDoDifferently {
            self.whatWouldIDoDifferently = whatWouldIDoDifferently.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        self.updatedAt = Date()
    }
}

// MARK: - Validation

extension Outcome {
    /// Validates that the outcome has all required fields populated
    var isValid: Bool {
        !actualResult.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Returns validation errors if any
    var validationErrors: [String] {
        var errors: [String] = []
        
        if actualResult.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Actual result description is required")
        }
        
        return errors
    }
}

// MARK: - Factory Methods

extension Outcome {
    /**
     Creates an outcome for an abandoned thesis.
     
     - Parameters:
       - reason: Why the thesis was abandoned
       - lessonsLearned: Optional lessons from the experience
     - Returns: A new outcome for abandoned thesis
     */
    static func createForAbandon(
        reason: String,
        lessonsLearned: String? = nil
    ) -> Outcome {
        let outcome = Outcome(
            actualResult: reason,
            thesisAssessment: .inconclusive,
            timingAssessment: .notApplicable
        )
        outcome.lessonsLearned = lessonsLearned
        return outcome
    }
    
    /**
     Creates an outcome for an exited position.
     
     - Parameters:
       - actualResult: What actually happened
       - thesisAssessment: Whether the thesis was correct
       - timingAssessment: Whether timing was good
       - exitPrice: The exit price
       - actualTimeframe: How long position was held
       - lessonsLearned: Optional lessons
     - Returns: A new outcome for exited position
     */
    static func createForExit(
        actualResult: String,
        thesisAssessment: ThesisAssessment,
        timingAssessment: TimingAssessment,
        exitPrice: String? = nil,
        actualTimeframe: String? = nil,
        lessonsLearned: String? = nil
    ) -> Outcome {
        let outcome = Outcome(
            actualResult: actualResult,
            thesisAssessment: thesisAssessment,
            timingAssessment: timingAssessment
        )
        outcome.exitPrice = exitPrice
        outcome.actualTimeframe = actualTimeframe
        outcome.lessonsLearned = lessonsLearned
        return outcome
    }
}

