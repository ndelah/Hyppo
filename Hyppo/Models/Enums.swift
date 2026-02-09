/**
 Shared enumerations for the Hyppo data model.
 
 Contains type definitions for scenario types, confidence levels,
 log entry types, evidence types, and review outcomes used throughout the application.
 */

import Foundation

// MARK: - Scenario Type

/**
 Represents the type of a scenario outcome.
 
 Users can create multiple scenarios per research question to represent different
 possible outcomes (bull case, bear case, base case, or custom).
 */
enum ScenarioType: String, Codable, CaseIterable, Identifiable {
    case base = "Base"
    case bull = "Bull"
    case bear = "Bear"
    case custom = "Custom"
    
    var id: String { rawValue }
    
    /// Display label for the scenario type
    var displayName: String { rawValue }
    
    /// Icon name for visual representation
    var iconName: String {
        switch self {
        case .base: return "equal.circle"
        case .bull: return "arrow.up.circle"
        case .bear: return "arrow.down.circle"
        case .custom: return "square.and.pencil"
        }
    }
    
    /// Sort order for displaying scenarios
    var sortOrder: Int {
        switch self {
        case .bull: return 0
        case .base: return 1
        case .bear: return 2
        case .custom: return 3
        }
    }
}

// MARK: - Research Type

/**
 Represents the primary category for a research question.
 
 Research type is a single-select field (Stock/Crypto/Macro/Commodity)
 used for filtering and quick visual context in lists.
 */
enum ResearchType: String, Codable, CaseIterable, Identifiable {
    case stock = "Stock"
    case crypto = "Crypto"
    case macro = "Macro"
    case commodity = "Commodity"
    
    var id: String { rawValue }
    
    /// Display label for the type
    var displayName: String { rawValue }
    
    /// SF Symbol icon name for visual representation
    var iconName: String {
        switch self {
        case .stock: return "chart.line.uptrend.xyaxis"
        case .crypto: return "bitcoinsign.circle"
        case .macro: return "globe"
        case .commodity: return "shippingbox"
        }
    }
    
    /// Sort order for consistent UI display
    var sortOrder: Int {
        switch self {
        case .stock: return 0
        case .crypto: return 1
        case .macro: return 2
        case .commodity: return 3
        }
    }
    
    /**
     Maps a tag name to a research type if it matches known labels.
     
     - Parameter name: The tag name to evaluate
     - Returns: A matching research type, or nil if no match
     */
    static func fromTagName(_ name: String) -> ResearchType? {
        let normalized = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalized {
        case "stock": return .stock
        case "crypto": return .crypto
        case "macro": return .macro
        case "commodity": return .commodity
        default: return nil
        }
    }
}

// MARK: - Log Entry Enums

/**
 Represents the type of a log entry.
 
 Log entries are categorized to help users quickly identify
 the nature of each journal entry in the research question timeline.
 */
enum LogEntryType: String, Codable, CaseIterable, Identifiable {
    case observation = "Observation"
    case update = "Update"
    case risk = "Risk"
    case catalyst = "Catalyst"
    case review = "Review"
    
    var id: String { rawValue }
    
    /// Display label for the entry type
    var displayName: String { rawValue }
    
    /// Icon name for visual representation
    var iconName: String {
        switch self {
        case .observation: return "eye"
        case .update: return "pencil.circle"
        case .risk: return "exclamationmark.triangle"
        case .catalyst: return "bolt"
        case .review: return "magnifyingglass"
        }
    }
    
    /// Color identifier for UI theming
    var colorName: String {
        switch self {
        case .observation: return "blue"
        case .update: return "purple"
        case .risk: return "red"
        case .catalyst: return "orange"
        case .review: return "green"
        }
    }
}

// MARK: - Evidence Enums

/**
 Represents the sentiment of an evidence item relative to its parent driver.
 */
enum EvidenceSentiment: String, Codable, CaseIterable, Identifiable {
    case supporting = "Supporting"
    case contradicting = "Contradicting"
    case neutral = "Neutral"
    
    var id: String { rawValue }
    
    /// Icon name for visual representation
    var iconName: String {
        switch self {
        case .supporting: return "plus.circle.fill"
        case .contradicting: return "minus.circle.fill"
        case .neutral: return "circle"
        }
    }
    
    /// Color identifier for UI theming
    var colorName: String {
        switch self {
        case .supporting: return "green"
        case .contradicting: return "red"
        case .neutral: return "gray"
        }
    }
}

/**
 Represents the source taxonomy for investment research.
 */
enum SourceType: String, Codable, CaseIterable, Identifiable {
    case secFiling = "SEC Filing"
    case earningsCall = "Earnings Call"
    case analystReport = "Analyst Report"
    case newsArticle = "News Article"
    case industryReport = "Industry Report"
    case managementCommentary = "Management"
    case dataProvider = "Data Provider"
    case personalNote = "Note"
    case other = "Other"
    
    var id: String { rawValue }
    
    /// Display label for the source type
    var displayName: String { rawValue }
    
    /// Icon name for visual representation
    var iconName: String {
        switch self {
        case .secFiling: return "doc.text.fill"
        case .earningsCall: return "phone.fill"
        case .analystReport: return "chart.line.uptrend.xyaxis"
        case .newsArticle: return "newspaper.fill"
        case .industryReport: return "building.2.fill"
        case .managementCommentary: return "person.2.fill"
        case .dataProvider: return "server.rack"
        case .personalNote: return "note.text"
        case .other: return "ellipsis.circle"
        }
    }
}

/**
 Represents the type of evidence attached to a log entry.
 
 Evidence types help categorize the source material that
 supports or contradicts an investment thesis.
 */
enum EvidenceType: String, Codable, CaseIterable, Identifiable {
    case article = "Article"
    case filing = "Filing"
    case kpi = "KPI"
    case quote = "Quote"
    case note = "Note"
    
    var id: String { rawValue }
    
    /// Display label for the evidence type
    var displayName: String { rawValue }
    
    /// Icon name for visual representation
    var iconName: String {
        switch self {
        case .article: return "newspaper"
        case .filing: return "doc.text"
        case .kpi: return "chart.bar"
        case .quote: return "quote.bubble"
        case .note: return "note.text"
        }
    }
}

// MARK: - Review Enums

/**
 Represents the outcome of a research question review session.
 
 When reviewing a research question, users choose one of these outcomes
 to indicate how their conviction has changed.
 */
enum ReviewOutcome: String, Codable, CaseIterable, Identifiable {
    case reinforce = "Reinforce"
    case revise = "Revise"
    case invalidate = "Invalidate"
    
    var id: String { rawValue }
    
    /// Display label for the outcome
    var displayName: String { rawValue }
    
    /// Icon name for visual representation
    var iconName: String {
        switch self {
        case .reinforce: return "checkmark.seal"
        case .revise: return "arrow.triangle.2.circlepath"
        case .invalidate: return "xmark.seal"
        }
    }
    
    /// Color identifier for UI theming
    var colorName: String {
        switch self {
        case .reinforce: return "green"
        case .revise: return "orange"
        case .invalidate: return "red"
        }
    }
}

// MARK: - Driver Status

/**
 Represents the validation status of a key driver in the investment thesis.
 
 Follows McKinsey's hypothesis-driven approach where drivers are tested
 and either confirmed or discarded as evidence is gathered.
 */
enum DriverStatus: String, Codable, CaseIterable, Identifiable {
    case pending = "Pending"
    case confirmed = "Confirmed"
    case discarded = "Discarded"
    case needsRevision = "NeedsRevision"
    
    var id: String { rawValue }
    
    /// Display label for the status
    var displayName: String {
        switch self {
        case .pending: return "Under Review"
        case .confirmed: return "Confirmed"
        case .discarded: return "Discarded"
        case .needsRevision: return "Needs Revision"
        }
    }
    
    /// Icon name for visual representation
    var iconName: String {
        switch self {
        case .pending: return "circle.dashed"
        case .confirmed: return "checkmark.circle.fill"
        case .discarded: return "xmark.circle.fill"
        case .needsRevision: return "exclamationmark.circle.fill"
        }
    }
    
    /// Color identifier for UI theming
    var colorName: String {
        switch self {
        case .pending: return "gray"
        case .confirmed: return "green"
        case .discarded: return "red"
        case .needsRevision: return "orange"
        }
    }
    
    /// Whether this status represents a resolved (non-pending) state
    var isResolved: Bool {
        self != .pending
    }
}

// MARK: - Confidence

/**
 Represents the user's confidence level in a research question or log entry.
 
 Confidence is stored on a 1-5 scale, but displayed as three tiers
 (Low / Med / High) for legibility and accountability.
 */
enum ConfidenceLevel: Int, Codable, CaseIterable, Identifiable {
    case veryLow = 1
    case low = 2
    case medium = 3
    case high = 4
    case veryHigh = 5
    
    var id: Int { rawValue }
    
    /// Display label for the confidence level (normalized to three tiers)
    var displayName: String {
        switch self {
        case .veryLow, .low: return "Low"
        case .medium: return "Med"
        case .high, .veryHigh: return "High"
        }
    }
    
    /// Short label for compact display
    var shortLabel: String {
        displayName
    }
    
    /// Confidence options presented in pickers (Low / Med / High)
    static var selectableCases: [ConfidenceLevel] {
        [.low, .medium, .high]
    }
    
    /// Representative raw value for the tier this level belongs to.
    var tierRawValue: Int {
        switch self {
        case .veryLow, .low:
            return ConfidenceLevel.low.rawValue
        case .medium:
            return ConfidenceLevel.medium.rawValue
        case .high, .veryHigh:
            return ConfidenceLevel.high.rawValue
        }
    }
    
    /// Normalizes a raw value to its tier representative (Low/Med/High).
    static func normalizedRawValue(_ rawValue: Int?) -> Int? {
        guard let rawValue,
              let level = ConfidenceLevel(rawValue: rawValue) else {
            return rawValue
        }
        return level.tierRawValue
    }
    
    /// Returns true when the confidence is in the same tier as the filter.
    static func matchesTier(confidenceRaw: Int?, filterRaw: Int) -> Bool {
        guard let confidenceRaw,
              let confidenceLevel = ConfidenceLevel(rawValue: confidenceRaw),
              let filterLevel = ConfidenceLevel(rawValue: filterRaw) else {
            return false
        }
        return confidenceLevel.tierRawValue == filterLevel.tierRawValue
    }
}

// MARK: - Display Settings

/**
 Represents the date format preference for displaying dates.
 
 Controls how dates are formatted throughout the app.
 */
enum DateFormatPreference: String, Codable, CaseIterable, Identifiable {
    case short = "short"           // 1/15/26
    case medium = "medium"         // Jan 15, 2026
    case long = "long"             // January 15, 2026
    case iso = "iso"               // 2026-01-15
    case european = "european"     // 15/01/2026
    
    var id: String { rawValue }
    
    /// Display name for the preference
    var displayName: String {
        switch self {
        case .short: return "Short (1/15/26)"
        case .medium: return "Medium (Jan 15, 2026)"
        case .long: return "Long (January 15, 2026)"
        case .iso: return "ISO (2026-01-15)"
        case .european: return "European (15/01/2026)"
        }
    }
    
    /// Formats a date according to this preference
    func format(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        switch self {
        case .short:
            formatter.dateStyle = .short
        case .medium:
            formatter.dateStyle = .medium
        case .long:
            formatter.dateStyle = .long
        case .iso:
            formatter.dateFormat = "yyyy-MM-dd"
        case .european:
            formatter.dateFormat = "dd/MM/yyyy"
        }
        
        return formatter.string(from: date)
    }
    
    /// Example date string for preview
    var exampleDate: String {
        format(Date())
    }
}

/**
 Represents the display density preference for content.
 
 Controls how much information is shown at once in lists
 and detail views.
 */
enum DisplayDensity: String, Codable, CaseIterable, Identifiable {
    case compact = "Compact"
    case comfortable = "Comfortable"
    
    var id: String { rawValue }
    
    /// Display label for the density
    var displayName: String { rawValue }
    
    /// Number of lines to show for body previews
    var bodyPreviewLines: Int {
        switch self {
        case .compact: return 1
        case .comfortable: return 2
        }
    }
    
    /// Whether to show the metadata row in cards
    var showMetadataRow: Bool {
        switch self {
        case .compact: return false
        case .comfortable: return true
        }
    }
    
    /// Whether sections should be expanded by default
    var expandSectionsByDefault: Bool {
        switch self {
        case .compact: return false
        case .comfortable: return true
        }
    }
}

// MARK: - Decision Layer Enums

/**
 Represents the type of investment decision being made.
 
 Valid actions depend on the current investment phase:
 - Watching phase: pass, buy, abandon
 - Entered phase: hold, add, trim, exit
 */
enum DecisionAction: String, Codable, CaseIterable, Identifiable {
    // Watching phase actions
    case pass = "Pass"          // Reviewed, decided not to enter (stays Watching)
    case buy = "Buy"            // Enter position (Watching → Entered)
    case abandon = "Abandon"    // Stop pursuing thesis (Watching → Abandoned)
    
    // Entered phase actions
    case hold = "Hold"          // Explicit decision to maintain (stays Entered)
    case add = "Add"            // Increase position (stays Entered)
    case trim = "Trim"          // Reduce position (stays Entered)
    case exit = "Exit"          // Close position (Entered → Exited)
    
    var id: String { rawValue }
    
    /// Display label for the action
    var displayName: String { rawValue }
    
    /// Icon name for visual representation
    var iconName: String {
        switch self {
        case .pass: return "hand.raised"
        case .buy: return "arrow.up.circle.fill"
        case .abandon: return "xmark.circle"
        case .hold: return "pause.circle.fill"
        case .add: return "plus.circle.fill"
        case .trim: return "minus.circle.fill"
        case .exit: return "arrow.down.circle.fill"
        }
    }
    
    /// Color identifier for UI theming
    var colorName: String {
        switch self {
        case .pass: return "gray"
        case .buy: return "green"
        case .abandon: return "red"
        case .hold: return "blue"
        case .add: return "green"
        case .trim: return "orange"
        case .exit: return "red"
        }
    }
    
    /// Whether this action is available in the Watching phase
    var isWatchingAction: Bool {
        switch self {
        case .pass, .buy, .abandon: return true
        case .hold, .add, .trim, .exit: return false
        }
    }
    
    /// Whether this action is available in the Entered phase
    var isEnteredAction: Bool {
        switch self {
        case .hold, .add, .trim, .exit: return true
        case .pass, .buy, .abandon: return false
        }
    }
    
    /// The phase transition this action causes (if any)
    var resultingPhase: InvestmentPhase? {
        switch self {
        case .pass: return nil  // Stays in Watching
        case .buy: return .entered
        case .abandon: return .abandoned
        case .hold, .add, .trim: return nil  // Stays in Entered
        case .exit: return .exited
        }
    }
}

/**
 Represents the investment lifecycle phase of a research question.
 
 State transitions:
 - Watching → Watching (Pass)
 - Watching → Entered (Buy)
 - Watching → Abandoned (Abandon)
 - Entered → Entered (Hold, Add, Trim)
 - Entered → Exited (Exit)
 - Exited → PostMortem (Record Outcome)
 - Abandoned → PostMortem (Record Outcome)
 */
enum InvestmentPhase: String, Codable, CaseIterable, Identifiable {
    case watching = "Watching"      // Researching, no position
    case entered = "Entered"        // Position is open
    case exited = "Exited"          // Position closed, awaiting outcome
    case abandoned = "Abandoned"    // Thesis abandoned, awaiting outcome
    case postMortem = "PostMortem"  // Outcome recorded, thesis complete
    
    var id: String { rawValue }
    
    /// Display label for the phase
    var displayName: String {
        switch self {
        case .watching: return "Watching"
        case .entered: return "Position Open"
        case .exited: return "Exited"
        case .abandoned: return "Abandoned"
        case .postMortem: return "Complete"
        }
    }
    
    /// Icon name for visual representation
    var iconName: String {
        switch self {
        case .watching: return "eye"
        case .entered: return "checkmark.circle.fill"
        case .exited: return "arrow.uturn.down.circle"
        case .abandoned: return "xmark.circle"
        case .postMortem: return "flag.checkered"
        }
    }
    
    /// Color identifier for UI theming
    var colorName: String {
        switch self {
        case .watching: return "blue"
        case .entered: return "green"
        case .exited: return "orange"
        case .abandoned: return "red"
        case .postMortem: return "gray"
        }
    }
    
    /// Whether the thesis is awaiting outcome recording
    var isAwaitingOutcome: Bool {
        self == .exited || self == .abandoned
    }
    
    /// Whether the thesis has an open position
    var hasOpenPosition: Bool {
        self == .entered
    }
    
    /// Whether the thesis lifecycle is complete
    var isComplete: Bool {
        self == .postMortem
    }
    
    /// Valid decision actions for this phase
    var validActions: [DecisionAction] {
        switch self {
        case .watching: return [.pass, .buy, .abandon]
        case .entered: return [.hold, .add, .trim, .exit]
        case .exited, .abandoned, .postMortem: return []
        }
    }
}

/**
 Represents the accuracy assessment of whether the investment thesis was correct.
 
 Used in the post-mortem phase to evaluate the quality of the original thesis.
 */
enum ThesisAssessment: String, Codable, CaseIterable, Identifiable {
    case correct = "Correct"            // Thesis played out as expected
    case partial = "Partial"            // Partially correct
    case wrong = "Wrong"                // Thesis was incorrect
    case inconclusive = "Inconclusive"  // Not enough data to assess
    
    var id: String { rawValue }
    
    /// Display label for the assessment
    var displayName: String { rawValue }
    
    /// Icon name for visual representation
    var iconName: String {
        switch self {
        case .correct: return "checkmark.seal.fill"
        case .partial: return "checkmark.seal"
        case .wrong: return "xmark.seal.fill"
        case .inconclusive: return "questionmark.circle"
        }
    }
    
    /// Color identifier for UI theming
    var colorName: String {
        switch self {
        case .correct: return "green"
        case .partial: return "orange"
        case .wrong: return "red"
        case .inconclusive: return "gray"
        }
    }
}

/**
 Represents the accuracy assessment of decision timing.
 
 Used in the post-mortem phase to evaluate whether the entry/exit timing was optimal.
 */
enum TimingAssessment: String, Codable, CaseIterable, Identifiable {
    case early = "Early"                    // Acted too soon
    case onTime = "On Time"                 // Timing was appropriate
    case late = "Late"                      // Acted too late
    case notApplicable = "Not Applicable"   // For pass/abandon decisions
    
    var id: String { rawValue }
    
    /// Display label for the assessment
    var displayName: String { rawValue }
    
    /// Icon name for visual representation
    var iconName: String {
        switch self {
        case .early: return "clock.arrow.2.circlepath"
        case .onTime: return "clock.badge.checkmark"
        case .late: return "clock.badge.exclamationmark"
        case .notApplicable: return "clock"
        }
    }
    
    /// Color identifier for UI theming
    var colorName: String {
        switch self {
        case .early: return "orange"
        case .onTime: return "green"
        case .late: return "red"
        case .notApplicable: return "gray"
        }
    }
}
