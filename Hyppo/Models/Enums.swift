/**
 Shared enumerations for the Footnote data model.
 
 Contains type definitions for thesis types, statuses, confidence levels,
 log entry types, and evidence types used throughout the application.
 */

import Foundation

// MARK: - Scenario Enums

/**
 Represents the type/scenario of a scenario.
 
 Users can create multiple scenarios per research question to represent different
 investment scenarios (bull case, bear case, base case, or custom).
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

/**
 Represents the lifecycle status of a scenario.
 
 A scenario progresses through these states as the user validates
 or invalidates their investment hypothesis over time.
 */
enum ScenarioStatus: String, Codable, CaseIterable, Identifiable {
    case active = "Active"
    case onHold = "On Hold"
    case invalidated = "Invalidated"
    case archived = "Archived"
    
    var id: String { rawValue }
    
    /// Display label for the status
    var displayName: String { rawValue }
    
    /// Color identifier for UI theming
    var colorName: String {
        switch self {
        case .active: return "green"
        case .onHold: return "orange"
        case .invalidated: return "red"
        case .archived: return "gray"
        }
    }
    
    /// Icon name for visual representation
    var iconName: String {
        switch self {
        case .active: return "checkmark.circle.fill"
        case .onHold: return "pause.circle.fill"
        case .invalidated: return "xmark.circle.fill"
        case .archived: return "archivebox.fill"
        }
    }
}

// MARK: - Legacy Type Aliases (for compatibility during migration)

typealias ThesisType = ScenarioType
typealias ThesisStatus = ScenarioStatus

// MARK: - Log Entry Enums

/**
 Represents the type of a log entry.
 
 Log entries are categorized to help users quickly identify
 the nature of each journal entry in the thesis timeline.
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
 Represents the outcome of a thesis review session.
 
 When reviewing a thesis, users choose one of these outcomes
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

// MARK: - Confidence

/**
 Represents the user's confidence level in a thesis or log entry.
 
 Confidence is rated on a 1-5 scale, where 1 is lowest
 and 5 is highest conviction.
 */
enum ConfidenceLevel: Int, Codable, CaseIterable, Identifiable {
    case veryLow = 1
    case low = 2
    case medium = 3
    case high = 4
    case veryHigh = 5
    
    var id: Int { rawValue }
    
    /// Display label for the confidence level
    var displayName: String {
        switch self {
        case .veryLow: return "Very Low"
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .veryHigh: return "Very High"
        }
    }
    
    /// Short label for compact display
    var shortLabel: String {
        String(repeating: "★", count: rawValue) + String(repeating: "☆", count: 5 - rawValue)
    }
}

