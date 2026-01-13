/**
 ExportService handles exporting and importing data in various formats.
 
 Supports JSON export/import for full data backup and restore,
 and Markdown export for individual theses.
 */

import Foundation
import SwiftData
import UniformTypeIdentifiers

// MARK: - Export Data Structures

/// Codable representation of the full database for JSON export
struct ExportData: Codable {
    let version: String
    let exportedAt: Date
    let assets: [AssetExport]
    
    static let currentVersion = "1.0"
}

struct AssetExport: Codable {
    let id: String
    let ticker: String
    let name: String
    let exchange: String?
    let currency: String?
    let createdAt: Date
    let updatedAt: Date
    let archivedAt: Date?
    let tags: [String]
    let theses: [ThesisExport]
}

struct ThesisExport: Codable {
    let id: String
    let thesisType: String
    let title: String
    let thesisStatement: String
    let keyDrivers: [String]
    let invalidationRules: [String]
    let catalysts: [String]
    let keyRisks: [String]
    let confidence: Int?
    let status: String
    let versionNumber: Int
    let createdAt: Date
    let updatedAt: Date
    let lastReviewedAt: Date?
    let tags: [String]
    let logEntries: [LogEntryExport]
    let reviewReminder: ReviewReminderExport?
}

struct LogEntryExport: Codable {
    let id: String
    let title: String
    let body: String
    let entryType: String
    let confidence: Int?
    let isSystemGenerated: Bool
    let isPinned: Bool
    let occurredAt: Date
    let createdAt: Date
    let tags: [String]
    let evidence: [EvidenceExport]
}

struct EvidenceExport: Codable {
    let id: String
    let evidenceType: String
    let url: String?
    let displayTitle: String?
    let snippetText: String?
    let annotationText: String?
    let metricName: String?
    let metricValue: String?
    let metricUnit: String?
    let metricPeriod: String?
    let capturedAt: Date
}

struct ReviewReminderExport: Codable {
    let cadence: String
    let customIntervalDays: Int?
    let nextReviewDueAt: Date?
    let isEnabled: Bool
}

// MARK: - Export Service

/// Service for exporting and importing data
final class ExportService {
    
    // MARK: - Singleton
    
    static let shared = ExportService()
    private init() {}
    
    // MARK: - JSON Export
    
    /**
     Exports all data to JSON format.
     
     - Parameter modelContext: The SwiftData model context
     - Returns: JSON data ready to be saved
     */
    func exportToJSON(modelContext: ModelContext) throws -> Data {
        // Fetch all assets with their relationships
        let descriptor = FetchDescriptor<Asset>(sortBy: [SortDescriptor(\.ticker)])
        let assets = try modelContext.fetch(descriptor)
        
        let assetExports = assets.map { asset -> AssetExport in
            let thesisExports = (asset.theses ?? []).map { thesis -> ThesisExport in
                let logEntryExports = (thesis.logEntries ?? []).map { logEntry -> LogEntryExport in
                    let evidenceExports = (logEntry.evidenceItems ?? []).map { evidence -> EvidenceExport in
                        EvidenceExport(
                            id: evidence.evidenceId.uuidString,
                            evidenceType: evidence.evidenceTypeRaw,
                            url: evidence.urlRaw,
                            displayTitle: evidence.displayTitle,
                            snippetText: evidence.snippetText,
                            annotationText: evidence.annotationText,
                            metricName: evidence.metricName,
                            metricValue: evidence.metricValue,
                            metricUnit: evidence.metricUnit,
                            metricPeriod: evidence.metricPeriod,
                            capturedAt: evidence.capturedAt
                        )
                    }
                    
                    return LogEntryExport(
                        id: logEntry.logEntryId.uuidString,
                        title: logEntry.title,
                        body: logEntry.body,
                        entryType: logEntry.entryTypeRaw,
                        confidence: logEntry.confidence,
                        isSystemGenerated: logEntry.isSystemGenerated,
                        isPinned: logEntry.isPinned,
                        occurredAt: logEntry.occurredAt,
                        createdAt: logEntry.createdAt,
                        tags: (logEntry.tags ?? []).map { $0.name },
                        evidence: evidenceExports
                    )
                }
                
                var reminderExport: ReviewReminderExport? = nil
                if let reminder = thesis.reviewReminder {
                    reminderExport = ReviewReminderExport(
                        cadence: reminder.cadenceRaw,
                        customIntervalDays: reminder.customIntervalDays,
                        nextReviewDueAt: reminder.nextReviewDueAt,
                        isEnabled: reminder.isEnabled
                    )
                }
                
                return ThesisExport(
                    id: thesis.thesisId.uuidString,
                    thesisType: thesis.thesisTypeRaw,
                    title: thesis.title,
                    thesisStatement: thesis.thesisStatement,
                    keyDrivers: thesis.keyDrivers,
                    invalidationRules: thesis.invalidationRules,
                    catalysts: thesis.catalysts,
                    keyRisks: thesis.keyRisks,
                    confidence: thesis.confidenceCurrent,
                    status: thesis.statusRaw,
                    versionNumber: thesis.versionNumber,
                    createdAt: thesis.createdAt,
                    updatedAt: thesis.updatedAt,
                    lastReviewedAt: thesis.lastReviewedAt,
                    tags: (thesis.tags ?? []).map { $0.name },
                    logEntries: logEntryExports,
                    reviewReminder: reminderExport
                )
            }
            
            return AssetExport(
                id: asset.assetId.uuidString,
                ticker: asset.ticker,
                name: asset.name,
                exchange: asset.exchange,
                currency: asset.currency,
                createdAt: asset.createdAt,
                updatedAt: asset.updatedAt,
                archivedAt: asset.archivedAt,
                tags: (asset.tags ?? []).map { $0.name },
                theses: thesisExports
            )
        }
        
        let exportData = ExportData(
            version: ExportData.currentVersion,
            exportedAt: Date(),
            assets: assetExports
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        return try encoder.encode(exportData)
    }
    
    // MARK: - JSON Import
    
    /**
     Imports data from JSON format.
     
     - Parameters:
       - data: The JSON data to import
       - modelContext: The SwiftData model context
       - mode: Whether to merge or replace existing data
     - Returns: Import statistics
     */
    func importFromJSON(data: Data, modelContext: ModelContext, mode: ImportMode = .merge) throws -> ImportResult {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let exportData = try decoder.decode(ExportData.self, from: data)
        
        var result = ImportResult()
        
        // Get or create tags
        func getOrCreateTag(name: String) -> Tag {
            let normalizedName = name.lowercased()
            let descriptor = FetchDescriptor<Tag>(predicate: #Predicate { $0.nameNormalized == normalizedName })
            if let existing = try? modelContext.fetch(descriptor).first {
                return existing
            }
            let tag = Tag(name: name)
            modelContext.insert(tag)
            result.tagsCreated += 1
            return tag
        }
        
        for assetExport in exportData.assets {
            // Check if asset already exists
            let normalizedTicker = assetExport.ticker.uppercased()
            let existingDescriptor = FetchDescriptor<Asset>(
                predicate: #Predicate { $0.tickerNormalized == normalizedTicker }
            )
            
            if let existing = try? modelContext.fetch(existingDescriptor).first {
                if mode == .merge {
                    result.assetsSkipped += 1
                    continue
                } else {
                    modelContext.delete(existing)
                }
            }
            
            // Create asset
            let asset = Asset(
                ticker: assetExport.ticker,
                name: assetExport.name,
                exchange: assetExport.exchange,
                currency: assetExport.currency
            )
            asset.createdAt = assetExport.createdAt
            asset.updatedAt = assetExport.updatedAt
            asset.archivedAt = assetExport.archivedAt
            asset.tags = assetExport.tags.map { getOrCreateTag(name: $0) }
            
            modelContext.insert(asset)
            result.assetsImported += 1
            
            // Create theses
            for thesisExport in assetExport.theses {
                let thesis = Thesis(
                    thesisType: ThesisType(rawValue: thesisExport.thesisType) ?? .custom,
                    title: thesisExport.title,
                    thesisStatement: thesisExport.thesisStatement,
                    keyDrivers: thesisExport.keyDrivers,
                    invalidationRules: thesisExport.invalidationRules,
                    catalysts: thesisExport.catalysts,
                    keyRisks: thesisExport.keyRisks,
                    confidence: thesisExport.confidence
                )
                thesis.statusRaw = thesisExport.status
                thesis.versionNumber = thesisExport.versionNumber
                thesis.createdAt = thesisExport.createdAt
                thesis.updatedAt = thesisExport.updatedAt
                thesis.lastReviewedAt = thesisExport.lastReviewedAt
                thesis.tags = thesisExport.tags.map { getOrCreateTag(name: $0) }
                thesis.asset = asset
                
                modelContext.insert(thesis)
                result.thesesImported += 1
                
                // Create review reminder if present
                if let reminderExport = thesisExport.reviewReminder {
                    let reminder = ReviewReminder(
                        cadence: ReviewCadence(rawValue: reminderExport.cadence) ?? .weekly,
                        customIntervalDays: reminderExport.customIntervalDays,
                        isEnabled: reminderExport.isEnabled
                    )
                    reminder.nextReviewDueAt = reminderExport.nextReviewDueAt
                    modelContext.insert(reminder)
                    thesis.reviewReminder = reminder
                }
                
                // Create log entries
                for logExport in thesisExport.logEntries {
                    let logEntry = LogEntry(
                        title: logExport.title,
                        body: logExport.body,
                        entryType: LogEntryType(rawValue: logExport.entryType) ?? .observation,
                        confidence: logExport.confidence,
                        occurredAt: logExport.occurredAt,
                        isSystemGenerated: logExport.isSystemGenerated
                    )
                    logEntry.isPinned = logExport.isPinned
                    logEntry.createdAt = logExport.createdAt
                    logEntry.tags = logExport.tags.map { getOrCreateTag(name: $0) }
                    logEntry.thesis = thesis
                    
                    modelContext.insert(logEntry)
                    result.logEntriesImported += 1
                    
                    // Create evidence
                    for evidenceExport in logExport.evidence {
                        let evidence = Evidence(
                            url: evidenceExport.url,
                            evidenceType: EvidenceType(rawValue: evidenceExport.evidenceType) ?? .note,
                            displayTitle: evidenceExport.displayTitle,
                            snippetText: evidenceExport.snippetText,
                            annotationText: evidenceExport.annotationText
                        )
                        if evidenceExport.evidenceType == EvidenceType.kpi.rawValue {
                            evidence.metricName = evidenceExport.metricName
                            evidence.metricValue = evidenceExport.metricValue
                            evidence.metricUnit = evidenceExport.metricUnit
                            evidence.metricPeriod = evidenceExport.metricPeriod
                        }
                        evidence.capturedAt = evidenceExport.capturedAt
                        evidence.logEntry = logEntry
                        
                        modelContext.insert(evidence)
                        result.evidenceImported += 1
                    }
                }
            }
        }
        
        return result
    }
    
    // MARK: - Markdown Export
    
    /**
     Exports a thesis to Markdown format.
     
     - Parameter thesis: The thesis to export
     - Returns: Markdown string
     */
    func exportThesisToMarkdown(_ thesis: Thesis) -> String {
        var md = ""
        
        // Header
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        
        md += "# \(thesis.title)\n\n"
        md += "**Asset:** \(thesis.asset?.ticker ?? "Unknown") - \(thesis.asset?.name ?? "Unknown")\n"
        md += "**Type:** \(thesis.thesisType.displayName)\n"
        md += "**Status:** \(thesis.status.displayName)\n"
        if let confidence = thesis.confidence {
            md += "**Confidence:** \(confidence.rawValue)/5 (\(confidence.displayName))\n"
        }
        md += "**Version:** \(thesis.versionNumber)\n"
        md += "**Created:** \(dateFormatter.string(from: thesis.createdAt))\n"
        md += "**Last Updated:** \(dateFormatter.string(from: thesis.updatedAt))\n"
        if let reviewed = thesis.lastReviewedAt {
            md += "**Last Reviewed:** \(dateFormatter.string(from: reviewed))\n"
        }
        md += "\n---\n\n"
        
        // Thesis Statement
        md += "## Thesis Statement\n\n"
        md += "\(thesis.thesisStatement)\n\n"
        
        // Key Drivers
        md += "## Key Drivers\n\n"
        for driver in thesis.keyDrivers {
            md += "- \(driver)\n"
        }
        md += "\n"
        
        // Invalidation Rules
        md += "## Invalidation Rules\n\n"
        for rule in thesis.invalidationRules {
            md += "- \(rule)\n"
        }
        md += "\n"
        
        // Catalysts (if any)
        if !thesis.catalysts.isEmpty {
            md += "## Catalysts\n\n"
            for catalyst in thesis.catalysts {
                md += "- \(catalyst)\n"
            }
            md += "\n"
        }
        
        // Key Risks (if any)
        if !thesis.keyRisks.isEmpty {
            md += "## Key Risks\n\n"
            for risk in thesis.keyRisks {
                md += "- \(risk)\n"
            }
            md += "\n"
        }
        
        // Timeline / Log Entries
        let logEntries = thesis.sortedLogEntries
        if !logEntries.isEmpty {
            md += "---\n\n"
            md += "## Research Timeline\n\n"
            
            for entry in logEntries {
                let entryDate = dateFormatter.string(from: entry.occurredAt)
                let typeEmoji = entryTypeEmoji(entry.entryType)
                
                md += "### \(typeEmoji) \(entry.title)\n\n"
                md += "**Date:** \(entryDate)\n"
                md += "**Type:** \(entry.entryType.displayName)\n"
                if let confidence = entry.confidenceLevel {
                    md += "**Confidence:** \(confidence.rawValue)/5\n"
                }
                if entry.isSystemGenerated {
                    md += "*System generated*\n"
                }
                md += "\n"
                md += "\(entry.body)\n\n"
                
                // Evidence
                let evidence = entry.sortedEvidence
                if !evidence.isEmpty {
                    md += "**Evidence:**\n\n"
                    for ev in evidence {
                        md += "- **\(ev.effectiveTitle)** (\(ev.evidenceType.displayName))\n"
                        if let url = ev.urlRaw {
                            md += "  - URL: \(url)\n"
                        }
                        if let snippet = ev.snippetText {
                            md += "  - Snippet: \"\(snippet)\"\n"
                        }
                        if ev.isKPI, let kpi = ev.kpiDisplayString {
                            md += "  - KPI: \(kpi)\n"
                        }
                    }
                    md += "\n"
                }
            }
        }
        
        // Footer
        md += "---\n\n"
        md += "*Exported from Footnote on \(dateFormatter.string(from: Date()))*\n"
        
        return md
    }
    
    private func entryTypeEmoji(_ type: LogEntryType) -> String {
        switch type {
        case .observation: return "👁"
        case .update: return "✏️"
        case .risk: return "⚠️"
        case .catalyst: return "⚡"
        case .review: return "🔍"
        }
    }
}

// MARK: - Import Mode

enum ImportMode {
    case merge   // Skip existing items
    case replace // Delete and recreate
}

// MARK: - Import Result

struct ImportResult {
    var assetsImported: Int = 0
    var assetsSkipped: Int = 0
    var thesesImported: Int = 0
    var logEntriesImported: Int = 0
    var evidenceImported: Int = 0
    var tagsCreated: Int = 0
    
    var summary: String {
        var parts: [String] = []
        if assetsImported > 0 { parts.append("\(assetsImported) assets") }
        if assetsSkipped > 0 { parts.append("\(assetsSkipped) skipped") }
        if thesesImported > 0 { parts.append("\(thesesImported) theses") }
        if logEntriesImported > 0 { parts.append("\(logEntriesImported) log entries") }
        if evidenceImported > 0 { parts.append("\(evidenceImported) evidence items") }
        if tagsCreated > 0 { parts.append("\(tagsCreated) tags created") }
        return parts.isEmpty ? "No data imported" : parts.joined(separator: ", ")
    }
}

