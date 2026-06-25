/**
 Shared enumerations for the Hyppo data model.
 
 Contains type definitions for scenario types,
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
        case .pending: return "Pending"
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
