/**
 Evidence model representing a link, snippet, or data point attached to a log entry.
 
 Evidence items provide the supporting documentation for investment theses,
 including URLs to articles, filings, KPIs, quotes, and user notes.
 */

import Foundation
import SwiftData

@Model
final class Evidence {
    // MARK: - Properties
    
    /// Unique identifier for the evidence
    @Attribute(.unique) var evidenceId: UUID
    
    /// Type of evidence (article, filing, KPI, quote, note)
    var evidenceTypeRaw: String
    
    /// Raw URL as entered by the user
    var urlRaw: String?
    
    /// Normalized URL for deduplication (lowercase, trimmed)
    var urlNormalized: String?
    
    /// Domain extracted from the URL
    var domain: String?
    
    /// Display title (auto-fetched or user-provided)
    var displayTitle: String?
    
    /// Original source title (from page metadata)
    var sourceTitle: String?
    
    /// Short snippet text (limited length for copyright compliance)
    var snippetText: String?
    
    /// User's annotation or notes about the evidence
    var annotationText: String?
    
    /// Timestamp when the evidence was captured
    var capturedAt: Date
    
    /// Timestamp when the evidence was created
    var createdAt: Date
    
    /// Timestamp when the evidence was last updated
    var updatedAt: Date
    
    // MARK: - KPI-specific fields (only when evidenceType == .kpi)
    
    /// Name of the metric (e.g., "Revenue", "MAU")
    var metricName: String?
    
    /// Value of the metric
    var metricValue: String?
    
    /// Unit of the metric (e.g., "USD", "%", "millions")
    var metricUnit: String?
    
    /// Period of the metric (e.g., "Q3 2025", "FY 2024")
    var metricPeriod: String?
    
    /// Optional comparison note for the metric
    var metricNote: String?
    
    // MARK: - Relationships
    
    /// Parent log entry this evidence belongs to
    var logEntry: LogEntry?
    
    /// Tags associated with this evidence
    var tags: [Tag]?
    
    // MARK: - Initialization
    
    /**
     Creates a new evidence item with a URL.
     
     - Parameters:
       - url: The URL to the evidence source
       - evidenceType: Type of evidence
       - displayTitle: Optional display title
       - snippetText: Optional snippet text
       - annotationText: Optional user annotation
     */
    init(
        url: String?,
        evidenceType: EvidenceType,
        displayTitle: String? = nil,
        snippetText: String? = nil,
        annotationText: String? = nil
    ) {
        self.evidenceId = UUID()
        self.evidenceTypeRaw = evidenceType.rawValue
        self.urlRaw = url?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.urlNormalized = url?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        self.domain = Evidence.extractDomain(from: url)
        self.displayTitle = displayTitle?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.snippetText = Evidence.truncateSnippet(snippetText)
        self.annotationText = annotationText?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.capturedAt = Date()
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    /**
     Creates a new KPI evidence item.
     
     - Parameters:
       - metricName: Name of the metric
       - metricValue: Value of the metric
       - metricUnit: Unit of the metric
       - metricPeriod: Period of the metric
       - metricNote: Optional comparison note
       - url: Optional source URL
       - annotationText: Optional user annotation
     */
    convenience init(
        metricName: String,
        metricValue: String,
        metricUnit: String?,
        metricPeriod: String?,
        metricNote: String? = nil,
        url: String? = nil,
        annotationText: String? = nil
    ) {
        self.init(
            url: url,
            evidenceType: .kpi,
            displayTitle: "\(metricName): \(metricValue)",
            annotationText: annotationText
        )
        self.metricName = metricName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.metricValue = metricValue.trimmingCharacters(in: .whitespacesAndNewlines)
        self.metricUnit = metricUnit?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.metricPeriod = metricPeriod?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.metricNote = metricNote?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Computed Properties
    
    /// Evidence type as enum
    var evidenceType: EvidenceType {
        get { EvidenceType(rawValue: evidenceTypeRaw) ?? .note }
        set { evidenceTypeRaw = newValue.rawValue }
    }
    
    /// Returns the best available title for display
    var effectiveTitle: String {
        displayTitle ?? sourceTitle ?? domain ?? "Untitled Evidence"
    }
    
    /// Returns true if this is a KPI evidence type
    var isKPI: Bool {
        evidenceType == .kpi
    }
    
    /// Returns formatted KPI display string
    var kpiDisplayString: String? {
        guard isKPI, let name = metricName, let value = metricValue else { return nil }
        var result = "\(name): \(value)"
        if let unit = metricUnit {
            result += " \(unit)"
        }
        if let period = metricPeriod {
            result += " (\(period))"
        }
        return result
    }
    
    /// Display subtitle with type and date
    var displaySubtitle: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(evidenceType.displayName) • \(formatter.string(from: capturedAt))"
    }
    
    // MARK: - Methods
    
    /**
     Updates the evidence item.
     
     - Parameters:
       - url: New URL
       - displayTitle: New display title
       - snippetText: New snippet text
       - annotationText: New annotation
     */
    func update(
        url: String?,
        displayTitle: String?,
        snippetText: String?,
        annotationText: String?
    ) {
        self.urlRaw = url?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.urlNormalized = url?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        self.domain = Evidence.extractDomain(from: url)
        self.displayTitle = displayTitle?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.snippetText = Evidence.truncateSnippet(snippetText)
        self.annotationText = annotationText?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.updatedAt = Date()
    }
    
    /**
     Updates KPI-specific fields.
     
     - Parameters:
       - metricName: New metric name
       - metricValue: New metric value
       - metricUnit: New metric unit
       - metricPeriod: New metric period
       - metricNote: New comparison note
     */
    func updateKPI(
        metricName: String,
        metricValue: String,
        metricUnit: String?,
        metricPeriod: String?,
        metricNote: String?
    ) {
        self.metricName = metricName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.metricValue = metricValue.trimmingCharacters(in: .whitespacesAndNewlines)
        self.metricUnit = metricUnit?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.metricPeriod = metricPeriod?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.metricNote = metricNote?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.displayTitle = kpiDisplayString
        self.updatedAt = Date()
    }
    
    // MARK: - Static Helpers
    
    /// Maximum allowed snippet length (for copyright compliance)
    static let maxSnippetLength = 500
    
    /**
     Extracts the domain from a URL string.
     
     - Parameter urlString: The URL string to parse
     - Returns: The domain portion of the URL, or nil
     */
    static func extractDomain(from urlString: String?) -> String? {
        guard let urlString = urlString,
              let url = URL(string: urlString) else { return nil }
        return url.host
    }
    
    /**
     Truncates snippet text to the maximum allowed length.
     
     - Parameter text: The snippet text to truncate
     - Returns: Truncated text with ellipsis if needed
     */
    static func truncateSnippet(_ text: String?) -> String? {
        guard let text = text?.trimmingCharacters(in: .whitespacesAndNewlines) else { return nil }
        if text.count <= maxSnippetLength {
            return text
        }
        return String(text.prefix(maxSnippetLength)) + "..."
    }
}

// MARK: - Validation

extension Evidence {
    /// Validates that the evidence has required fields based on type
    var isValid: Bool {
        switch evidenceType {
        case .kpi:
            return metricName?.isEmpty == false && metricValue?.isEmpty == false
        case .note:
            // Notes don't require a URL
            return snippetText?.isEmpty == false || annotationText?.isEmpty == false
        default:
            // Other types require a URL
            return urlRaw?.isEmpty == false
        }
    }
    
    /// Returns validation errors if any
    var validationErrors: [String] {
        var errors: [String] = []
        
        switch evidenceType {
        case .kpi:
            if metricName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false {
                errors.append("Metric name is required for KPI evidence")
            }
            if metricValue?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false {
                errors.append("Metric value is required for KPI evidence")
            }
        case .note:
            if (snippetText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false) &&
               (annotationText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false) {
                errors.append("Either snippet or annotation is required for notes")
            }
        default:
            if urlRaw?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false {
                errors.append("URL is required")
            }
        }
        
        return errors
    }
}
