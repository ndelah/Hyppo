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

// MARK: - Confidence

/**
 Represents the user's confidence level in a research question or log entry.
 
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

// MARK: - Display Settings

/**
 Represents the display density preference for content.
 
 Controls how much information is shown at once in lists
 and detail views.
 */
enum DisplayDensity: String, Codable, CaseIterable, Identifiable {
    case compact = "Compact"
    case comfortable = "Comfortable"
    case expanded = "Expanded"
    
    var id: String { rawValue }
    
    /// Display label for the density
    var displayName: String { rawValue }
    
    /// Number of lines to show for body previews
    var bodyPreviewLines: Int {
        switch self {
        case .compact: return 1
        case .comfortable: return 2
        case .expanded: return 4
        }
    }
    
    /// Whether to show the metadata row in cards
    var showMetadataRow: Bool {
        switch self {
        case .compact: return false
        case .comfortable, .expanded: return true
        }
    }
    
    /// Whether sections should be expanded by default
    var expandSectionsByDefault: Bool {
        switch self {
        case .compact: return false
        case .comfortable: return true
        case .expanded: return true
        }
    }
}
