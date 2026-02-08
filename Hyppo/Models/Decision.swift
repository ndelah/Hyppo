/**
 Decision model representing a discrete investment action point.
 
 Decisions capture the "balance sheet" moments when a user commits to action
 (or inaction) on an investment thesis. Each decision freezes the research state
 at decision time, enabling comparison of expectations vs outcomes.
 
 Valid decision actions depend on the current investment phase:
 - Watching: pass, buy, abandon
 - Entered: hold, add, trim, exit
 */

import Foundation
import SwiftData

@Model
final class Decision {
    // MARK: - Properties
    
    /// Unique identifier for the decision
    @Attribute(.unique) var decisionId: UUID
    
    /// Type of action taken (pass, buy, add, trim, hold, exit, abandon)
    var actionTypeRaw: String
    
    /// User's rationale for this decision - why this action now
    var rationale: String
    
    /// Timestamp when the decision was made (locks intent)
    var decidedAt: Date
    
    // MARK: - Snapshot at Decision Time
    
    /// Frozen confidence level at decision time (1-5)
    var confidenceAtDecision: Int?
    
    /// Count of confirmed drivers at decision time
    var driversConfirmedCount: Int
    
    /// Count of under review (untested) drivers at decision time
    var driversPendingCount: Int
    
    /// Count of discarded drivers at decision time
    var driversDiscardedCount: Int
    
    // MARK: - Expectations (for Buy/Add decisions)
    
    /// Target date for checking expectations (shown on timeline)
    var expectedTargetDate: Date?
    
    /// Legacy expected outcome (kept for existing data)
    var expectedOutcome: String?
    
    /// Legacy expected timeframe (kept for existing data)
    var expectedTimeframe: String?
    
    /// Price at decision time (entry/exit price, optional)
    var priceAtDecision: String?
    
    // MARK: - Exit Plan (for Buy decisions)
    
    /// Conditions under which to exit (free text)
    var exitPlan: String?
    
    // MARK: - Pass Decision Fields
    
    /// For Pass decisions: what would need to change to enter
    var whatWouldChangeMyMind: String?
    
    // MARK: - Relationships
    
    /// Parent research question this decision belongs to
    var researchQuestion: ResearchQuestion?
    
    // MARK: - Metadata
    
    /// Timestamp when the decision record was created
    var createdAt: Date
    
    /// Timestamp when the decision record was last updated
    var updatedAt: Date
    
    // MARK: - Initialization
    
    /**
     Creates a new decision with the required fields.
     
     - Parameters:
       - actionType: The type of action being taken
       - rationale: User's reasoning for this decision
       - decidedAt: When the decision was made (defaults to now)
       - confidenceAtDecision: Current confidence level (1-5)
       - driversConfirmedCount: Count of confirmed drivers
       - driversPendingCount: Count of pending drivers
       - driversDiscardedCount: Count of discarded drivers
     */
    init(
        actionType: DecisionAction,
        rationale: String,
        decidedAt: Date = Date(),
        confidenceAtDecision: Int? = nil,
        driversConfirmedCount: Int = 0,
        driversPendingCount: Int = 0,
        driversDiscardedCount: Int = 0
    ) {
        self.decisionId = UUID()
        self.actionTypeRaw = actionType.rawValue
        self.rationale = rationale.trimmingCharacters(in: .whitespacesAndNewlines)
        self.decidedAt = decidedAt
        self.confidenceAtDecision = confidenceAtDecision
        self.driversConfirmedCount = driversConfirmedCount
        self.driversPendingCount = driversPendingCount
        self.driversDiscardedCount = driversDiscardedCount
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - Computed Properties
    
    /// Action type as enum
    var actionType: DecisionAction {
        get { DecisionAction(rawValue: actionTypeRaw) ?? .pass }
        set {
            actionTypeRaw = newValue.rawValue
            updatedAt = Date()
        }
    }
    
    /// Confidence level as enum
    var confidenceLevel: ConfidenceLevel? {
        get {
            guard let value = confidenceAtDecision else { return nil }
            return ConfidenceLevel(rawValue: value)
        }
        set {
            confidenceAtDecision = newValue?.rawValue
        }
    }
    
    /// Total drivers at decision time
    var totalDriversCount: Int {
        driversConfirmedCount + driversPendingCount + driversDiscardedCount
    }
    
    /// Whether this is an entry decision (Buy)
    var isEntryDecision: Bool {
        actionType == .buy
    }
    
    /// Whether this is an exit decision (Exit)
    var isExitDecision: Bool {
        actionType == .exit
    }
    
    /// Whether this decision has expectations set
    var hasExpectations: Bool {
        expectedTargetDate != nil || expectedOutcome != nil || expectedTimeframe != nil
    }
    
    /// Whether this decision has an exit plan
    var hasExitPlan: Bool {
        exitPlan != nil && !exitPlan!.isEmpty
    }
    
    /// Display subtitle with action and date
    var displaySubtitle: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(actionType.displayName) • \(formatter.string(from: decidedAt))"
    }
    
    /// Driver summary at decision time
    var driverSummary: String {
        var parts: [String] = []
        if driversConfirmedCount > 0 {
            parts.append("\(driversConfirmedCount) confirmed")
        }
        if driversPendingCount > 0 {
            parts.append("\(driversPendingCount) under review")
        }
        if driversDiscardedCount > 0 {
            parts.append("\(driversDiscardedCount) discarded")
        }
        return parts.isEmpty ? "No drivers" : parts.joined(separator: ", ")
    }
    
    // MARK: - Methods
    
    /**
     Updates the decision with new values.
     
     - Parameters:
       - rationale: Updated rationale
       - expectedTargetDate: Updated target date for expectations
       - expectedOutcome: Updated expected outcome
       - expectedTimeframe: Updated expected timeframe
       - priceAtDecision: Updated price
       - exitPlan: Updated exit plan
       - whatWouldChangeMyMind: Updated change-my-mind text
     */
    func update(
        rationale: String? = nil,
        expectedTargetDate: Date? = nil,
        expectedOutcome: String? = nil,
        expectedTimeframe: String? = nil,
        priceAtDecision: String? = nil,
        exitPlan: String? = nil,
        whatWouldChangeMyMind: String? = nil
    ) {
        if let rationale = rationale {
            self.rationale = rationale.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let expectedTargetDate = expectedTargetDate {
            self.expectedTargetDate = expectedTargetDate
        }
        if let expectedOutcome = expectedOutcome {
            self.expectedOutcome = expectedOutcome.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let expectedTimeframe = expectedTimeframe {
            self.expectedTimeframe = expectedTimeframe.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let priceAtDecision = priceAtDecision {
            self.priceAtDecision = priceAtDecision.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let exitPlan = exitPlan {
            self.exitPlan = exitPlan.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let whatWouldChangeMyMind = whatWouldChangeMyMind {
            self.whatWouldChangeMyMind = whatWouldChangeMyMind.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        self.updatedAt = Date()
    }
}

// MARK: - Validation

extension Decision {
    /// Validates that the decision has all required fields populated
    var isValid: Bool {
        !rationale.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Returns validation errors if any
    var validationErrors: [String] {
        var errors: [String] = []
        
        if rationale.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Rationale is required")
        }
        
        if let confidence = confidenceAtDecision, (confidence < 1 || confidence > 5) {
            errors.append("Confidence must be between 1 and 5")
        }
        
        return errors
    }
}

// MARK: - Factory Methods

extension Decision {
    /**
     Creates a decision with the current research question state snapshot.
     
     - Parameters:
       - actionType: The type of action being taken
       - rationale: User's reasoning for this decision
       - researchQuestion: The research question to snapshot
     - Returns: A new decision with frozen research state
     */
    static func create(
        actionType: DecisionAction,
        rationale: String,
        from researchQuestion: ResearchQuestion
    ) -> Decision {
        let decision = Decision(
            actionType: actionType,
            rationale: rationale,
            confidenceAtDecision: researchQuestion.confidenceCurrent,
            driversConfirmedCount: researchQuestion.confirmedDriversCount,
            driversPendingCount: researchQuestion.pendingDriversCount,
            driversDiscardedCount: researchQuestion.discardedDriversCount
        )
        decision.researchQuestion = researchQuestion
        return decision
    }
}

