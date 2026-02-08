/**
 ExportService handles exporting and importing data in various formats.
 
 Supports JSON export/import for full data backup and restore,
 and Markdown export for individual research questions.
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
    
    static let currentVersion = "2.0"  // Updated for new model structure
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
    let researchQuestions: [ResearchQuestionExport]
}

struct ResearchQuestionExport: Codable {
    let id: String
    let questionText: String
    let context: String?
    let thesisStatement: String?
    let drivers: [DriverExport]
    let scenarios: [SimpleScenarioExport]
    let confidence: Int?
    let status: String
    let investmentPhase: String
    let conclusion: String?
    let versionNumber: Int
    let createdAt: Date
    let updatedAt: Date
    let lastReviewedAt: Date?
    let tags: [String]
    let logEntries: [LogEntryExport]
    let reviewReminder: ReviewReminderExport?
    let decisions: [DecisionExport]
    let outcome: OutcomeExport?
}

struct DriverExport: Codable {
    let id: String
    let title: String
    let driverDescription: String?
    let position: Int
    let subDrivers: [DriverExport]
}

struct SimpleScenarioExport: Codable {
    let id: String
    let type: String
    let title: String
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

struct DecisionExport: Codable {
    let id: String
    let actionType: String
    let rationale: String
    let decidedAt: Date
    let confidenceAtDecision: Int?
    let driversConfirmedCount: Int
    let driversPendingCount: Int
    let driversDiscardedCount: Int
    let expectedOutcome: String?
    let expectedTimeframe: String?
    let priceAtDecision: String?
    let exitPlan: String?
    let whatWouldChangeMyMind: String?
    let createdAt: Date
    let updatedAt: Date
}

struct OutcomeExport: Codable {
    let id: String
    let actualResult: String
    let actualTimeframe: String?
    let exitPrice: String?
    let thesisAssessment: String
    let timingAssessment: String
    let lessonsLearned: String?
    let whatWouldIDoDifferently: String?
    let recordedAt: Date
    let createdAt: Date
    let updatedAt: Date
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
            let researchQuestionExports = (asset.researchQuestions ?? []).map { question -> ResearchQuestionExport in
                let logEntryExports = (question.logEntries ?? []).map { logEntry -> LogEntryExport in
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
                if let reminder = question.reviewReminder {
                    reminderExport = ReviewReminderExport(
                        cadence: reminder.cadenceRaw,
                        customIntervalDays: reminder.customIntervalDays,
                        nextReviewDueAt: reminder.nextReviewDueAt,
                        isEnabled: reminder.isEnabled
                    )
                }
                
                let scenarioExports = question.scenarios.map { scenario -> SimpleScenarioExport in
                    SimpleScenarioExport(
                        id: scenario.id.uuidString,
                        type: scenario.type,
                        title: scenario.title
                    )
                }
                
                // Export drivers recursively
                func exportDriver(_ driver: Driver) -> DriverExport {
                    let subDriverExports = (driver.subDrivers ?? [])
                        .sorted { $0.position < $1.position }
                        .map { exportDriver($0) }
                    
                    return DriverExport(
                        id: driver.driverId.uuidString,
                        title: driver.title,
                        driverDescription: driver.driverDescription,
                        position: driver.position,
                        subDrivers: subDriverExports
                    )
                }
                
                let driverExports = question.topLevelDrivers.map { exportDriver($0) }
                
                // Export decisions
                let decisionExports = question.sortedDecisions.map { decision -> DecisionExport in
                    DecisionExport(
                        id: decision.decisionId.uuidString,
                        actionType: decision.actionTypeRaw,
                        rationale: decision.rationale,
                        decidedAt: decision.decidedAt,
                        confidenceAtDecision: decision.confidenceAtDecision,
                        driversConfirmedCount: decision.driversConfirmedCount,
                        driversPendingCount: decision.driversPendingCount,
                        driversDiscardedCount: decision.driversDiscardedCount,
                        expectedOutcome: decision.expectedOutcome,
                        expectedTimeframe: decision.expectedTimeframe,
                        priceAtDecision: decision.priceAtDecision,
                        exitPlan: decision.exitPlan,
                        whatWouldChangeMyMind: decision.whatWouldChangeMyMind,
                        createdAt: decision.createdAt,
                        updatedAt: decision.updatedAt
                    )
                }
                
                // Export outcome if present
                var outcomeExport: OutcomeExport? = nil
                if let outcome = question.outcome {
                    outcomeExport = OutcomeExport(
                        id: outcome.outcomeId.uuidString,
                        actualResult: outcome.actualResult,
                        actualTimeframe: outcome.actualTimeframe,
                        exitPrice: outcome.exitPrice,
                        thesisAssessment: outcome.thesisAssessmentRaw,
                        timingAssessment: outcome.timingAssessmentRaw,
                        lessonsLearned: outcome.lessonsLearned,
                        whatWouldIDoDifferently: outcome.whatWouldIDoDifferently,
                        recordedAt: outcome.recordedAt,
                        createdAt: outcome.createdAt,
                        updatedAt: outcome.updatedAt
                    )
                }
                
                return ResearchQuestionExport(
                    id: question.questionId.uuidString,
                    questionText: question.questionText,
                    context: question.context,
                    thesisStatement: question.thesisStatement,
                    drivers: driverExports,
                    scenarios: scenarioExports,
                    confidence: question.confidenceCurrent,
                    status: question.statusRaw,
                    investmentPhase: question.investmentPhaseRaw,
                    conclusion: question.conclusion,
                    versionNumber: question.versionNumber,
                    createdAt: question.createdAt,
                    updatedAt: question.updatedAt,
                    lastReviewedAt: question.lastReviewedAt,
                    tags: (question.tags ?? []).map { $0.name },
                    logEntries: logEntryExports,
                    reviewReminder: reminderExport,
                    decisions: decisionExports,
                    outcome: outcomeExport
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
                researchQuestions: researchQuestionExports
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
            
            // Create research questions
            for questionExport in assetExport.researchQuestions {
                // Convert simple scenarios from export
                let importedScenarios = questionExport.scenarios.map { scenarioExport in
                    var scenario = SimpleScenario(
                        type: ScenarioType(rawValue: scenarioExport.type) ?? .base,
                        title: scenarioExport.title
                    )
                    if let uuid = UUID(uuidString: scenarioExport.id) {
                        scenario.id = uuid
                    }
                    return scenario
                }
                
                let researchQuestion = ResearchQuestion(
                    questionText: questionExport.questionText,
                    context: questionExport.context,
                    thesisStatement: questionExport.thesisStatement,
                    confidence: questionExport.confidence
                )
                researchQuestion.scenarios = importedScenarios
                researchQuestion.statusRaw = questionExport.status
                researchQuestion.investmentPhaseRaw = questionExport.investmentPhase
                researchQuestion.conclusion = questionExport.conclusion
                researchQuestion.versionNumber = questionExport.versionNumber
                researchQuestion.createdAt = questionExport.createdAt
                researchQuestion.updatedAt = questionExport.updatedAt
                researchQuestion.lastReviewedAt = questionExport.lastReviewedAt
                researchQuestion.tags = questionExport.tags.map { getOrCreateTag(name: $0) }
                researchQuestion.asset = asset
                
                modelContext.insert(researchQuestion)
                result.researchQuestionsImported += 1
                
                // Import drivers recursively
                func importDriver(_ driverExport: DriverExport, parent: Driver?) -> Driver {
                    let driver = Driver(
                        title: driverExport.title,
                        driverDescription: driverExport.driverDescription,
                        position: driverExport.position,
                        parentDriver: parent
                    )
                    driver.researchQuestion = researchQuestion
                    modelContext.insert(driver)
                    
                    // Import sub-drivers
                    for subExport in driverExport.subDrivers {
                        _ = importDriver(subExport, parent: driver)
                    }
                    
                    return driver
                }
                
                for driverExport in questionExport.drivers {
                    _ = importDriver(driverExport, parent: nil)
                }
                
                // Create review reminder if present
                if let reminderExport = questionExport.reviewReminder {
                    let reminder = ReviewReminder(
                        cadence: ReviewCadence(rawValue: reminderExport.cadence) ?? .weekly,
                        customIntervalDays: reminderExport.customIntervalDays,
                        isEnabled: reminderExport.isEnabled
                    )
                    reminder.nextReviewDueAt = reminderExport.nextReviewDueAt
                    modelContext.insert(reminder)
                    researchQuestion.reviewReminder = reminder
                }
                
                // Create log entries
                for logExport in questionExport.logEntries {
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
                    logEntry.researchQuestion = researchQuestion
                    
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
                
                // Create decisions
                for decisionExport in questionExport.decisions {
                    let decision = Decision(
                        actionType: DecisionAction(rawValue: decisionExport.actionType) ?? .pass,
                        rationale: decisionExport.rationale,
                        decidedAt: decisionExport.decidedAt
                    )
                    decision.confidenceAtDecision = decisionExport.confidenceAtDecision
                    decision.driversConfirmedCount = decisionExport.driversConfirmedCount
                    decision.driversPendingCount = decisionExport.driversPendingCount
                    decision.driversDiscardedCount = decisionExport.driversDiscardedCount
                    decision.expectedOutcome = decisionExport.expectedOutcome
                    decision.expectedTimeframe = decisionExport.expectedTimeframe
                    decision.priceAtDecision = decisionExport.priceAtDecision
                    decision.exitPlan = decisionExport.exitPlan
                    decision.whatWouldChangeMyMind = decisionExport.whatWouldChangeMyMind
                    decision.createdAt = decisionExport.createdAt
                    decision.updatedAt = decisionExport.updatedAt
                    decision.researchQuestion = researchQuestion
                    
                    modelContext.insert(decision)
                    result.decisionsImported += 1
                }
                
                // Create outcome if present
                if let outcomeExport = questionExport.outcome {
                    let outcome = Outcome(
                        actualResult: outcomeExport.actualResult,
                        thesisAssessment: ThesisAssessment(rawValue: outcomeExport.thesisAssessment) ?? .inconclusive,
                        timingAssessment: TimingAssessment(rawValue: outcomeExport.timingAssessment) ?? .notApplicable
                    )
                    outcome.actualTimeframe = outcomeExport.actualTimeframe
                    outcome.exitPrice = outcomeExport.exitPrice
                    outcome.lessonsLearned = outcomeExport.lessonsLearned
                    outcome.whatWouldIDoDifferently = outcomeExport.whatWouldIDoDifferently
                    outcome.recordedAt = outcomeExport.recordedAt
                    outcome.createdAt = outcomeExport.createdAt
                    outcome.updatedAt = outcomeExport.updatedAt
                    outcome.researchQuestion = researchQuestion
                    
                    modelContext.insert(outcome)
                    result.outcomesImported += 1
                }
            }
        }
        
        return result
    }
    
    // MARK: - Markdown Export
    
    /**
     Exports a research question to Markdown format.
     
     - Parameter researchQuestion: The research question to export
     - Returns: Markdown string
     */
    func exportResearchQuestionToMarkdown(_ researchQuestion: ResearchQuestion) -> String {
        var md = ""
        
        // Header
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        
        md += "# \(researchQuestion.questionText)\n\n"
        if let asset = researchQuestion.asset {
            md += "**Asset:** \(asset.ticker) - \(asset.name)\n"
        }
        md += "**Status:** \(researchQuestion.status.displayName)\n"
        if let confidence = researchQuestion.confidence {
            md += "**Confidence:** \(confidence.rawValue)/5 (\(confidence.displayName))\n"
        }
        md += "**Version:** \(researchQuestion.versionNumber)\n"
        md += "**Created:** \(dateFormatter.string(from: researchQuestion.createdAt))\n"
        md += "**Last Updated:** \(dateFormatter.string(from: researchQuestion.updatedAt))\n"
        if let reviewed = researchQuestion.lastReviewedAt {
            md += "**Last Reviewed:** \(dateFormatter.string(from: reviewed))\n"
        }
        md += "\n---\n\n"
        
        // Context
        if let context = researchQuestion.context, !context.isEmpty {
            md += "## Context\n\n"
            md += "\(context)\n\n"
        }
        
        // Thesis Statement
        if let thesis = researchQuestion.thesisStatement, !thesis.isEmpty {
            md += "## Thesis Statement\n\n"
            md += "\(thesis)\n\n"
        }
        
        // Assumptions (Drivers)
        let topLevelDrivers = researchQuestion.topLevelDrivers
        if !topLevelDrivers.isEmpty {
            md += "## Assumptions (Drivers)\n\n"
            for driver in topLevelDrivers {
                md += "### \(driver.title)\n\n"
                if let desc = driver.driverDescription, !desc.isEmpty {
                    md += "\(desc)\n\n"
                }
                
                // Sub-drivers
                if let subs = driver.subDrivers, !subs.isEmpty {
                    md += "**Sub-assumptions:**\n"
                    for sub in subs.sorted(by: { $0.position < $1.position }) {
                        md += "  - \(sub.title)\n"
                    }
                }
                md += "\n"
            }
        }
        
        // Scenarios
        if !researchQuestion.scenarios.isEmpty {
            md += "## Scenarios\n\n"
            for scenario in researchQuestion.scenarios.sorted(by: { $0.scenarioType.sortOrder < $1.scenarioType.sortOrder }) {
                let icon = scenarioTypeIcon(scenario.scenarioType)
                md += "- **\(icon) \(scenario.scenarioType.displayName):** \(scenario.title)\n"
            }
            md += "\n"
        }
        
        // Conviction Health Summary
        if !topLevelDrivers.isEmpty {
            md += "## Conviction Health\n\n"
            let summary = ConvictionHealthSummary.from(drivers: topLevelDrivers)
            md += "- **Supporting Evidence:** \(summary.totalSupporting)\n"
            md += "- **Contradicting Evidence:** \(summary.totalContradicting)\n"
            md += "- **Neutral Evidence:** \(summary.totalNeutral)\n"
            if summary.blindSpotCount > 0 {
                md += "- ⚠️ **Blind Spots:** \(summary.blindSpotCount) assumption(s) with no evidence\n"
            }
            md += "\n"
        }
        
        // Timeline / Log Entries
        let logEntries = researchQuestion.sortedLogEntries
        if !logEntries.isEmpty {
            md += "---\n\n"
            md += "## Research Timeline\n\n"
            
            for entry in logEntries {
                let entryDate = dateFormatter.string(from: entry.occurredAt)
                let typeEmoji = entryTypeEmoji(entry.entryType)
                
                md += "### \(typeEmoji) \(entry.title)\n\n"
                md += "**Date:** \(entryDate)\n"
                md += "**Type:** \(entry.entryType.displayName)\n"
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
        
        // Decision Timeline
        let decisions = researchQuestion.sortedDecisions
        if !decisions.isEmpty {
            md += "---\n\n"
            md += "## Decision Timeline\n\n"
            md += "**Investment Phase:** \(researchQuestion.investmentPhase.displayName)\n\n"
            
            for decision in decisions {
                let decisionDate = dateFormatter.string(from: decision.decidedAt)
                let actionEmoji = decisionActionEmoji(decision.actionType)
                
                md += "### \(actionEmoji) \(decision.actionType.displayName)\n\n"
                md += "**Date:** \(decisionDate)\n"
                md += "**Rationale:** \(decision.rationale)\n"
                
                if let confidence = decision.confidenceAtDecision {
                    md += "**Confidence at Decision:** \(confidence)/5\n"
                }
                
                md += "**Driver Snapshot:** \(decision.driversConfirmedCount) confirmed, \(decision.driversPendingCount) under review, \(decision.driversDiscardedCount) discarded\n"
                
                if let expected = decision.expectedOutcome {
                    md += "**Expected Outcome:** \(expected)\n"
                }
                if let timeframe = decision.expectedTimeframe {
                    md += "**Expected Timeframe:** \(timeframe)\n"
                }
                if let price = decision.priceAtDecision {
                    md += "**Price at Decision:** \(price)\n"
                }
                if let exitPlan = decision.exitPlan {
                    md += "**Exit Plan:** \(exitPlan)\n"
                }
                if let changeMyMind = decision.whatWouldChangeMyMind {
                    md += "**What Would Change My Mind:** \(changeMyMind)\n"
                }
                md += "\n"
            }
        }
        
        // Outcome
        if let outcome = researchQuestion.outcome {
            md += "---\n\n"
            md += "## Outcome & PostMortem\n\n"
            md += "**Recorded:** \(dateFormatter.string(from: outcome.recordedAt))\n"
            md += "**Actual Result:** \(outcome.actualResult)\n"
            md += "**Thesis Assessment:** \(outcome.thesisAssessment.displayName)\n"
            md += "**Timing Assessment:** \(outcome.timingAssessment.displayName)\n"
            
            if let timeframe = outcome.actualTimeframe {
                md += "**Actual Timeframe:** \(timeframe)\n"
            }
            if let price = outcome.exitPrice {
                md += "**Exit Price:** \(price)\n"
            }
            if let lessons = outcome.lessonsLearned, !lessons.isEmpty {
                md += "\n### Lessons Learned\n\n\(lessons)\n"
            }
            if let different = outcome.whatWouldIDoDifferently, !different.isEmpty {
                md += "\n### What I Would Do Differently\n\n\(different)\n"
            }
            md += "\n"
        }
        
        // Footer
        md += "---\n\n"
        md += "*Exported from Hyppo on \(dateFormatter.string(from: Date()))*\n"
        
        return md
    }
    
    private func decisionActionEmoji(_ action: DecisionAction) -> String {
        switch action {
        case .pass: return "⏳"
        case .buy: return "📈"
        case .abandon: return "🚫"
        case .hold: return "✋"
        case .add: return "➕"
        case .trim: return "➖"
        case .exit: return "🏁"
        }
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
    
    private func scenarioTypeIcon(_ type: ScenarioType) -> String {
        switch type {
        case .bull: return "📈"
        case .base: return "➡️"
        case .bear: return "📉"
        case .custom: return "📝"
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
    var researchQuestionsImported: Int = 0
    var logEntriesImported: Int = 0
    var evidenceImported: Int = 0
    var decisionsImported: Int = 0
    var outcomesImported: Int = 0
    var tagsCreated: Int = 0
    
    var summary: String {
        var parts: [String] = []
        if assetsImported > 0 { parts.append("\(assetsImported) assets") }
        if assetsSkipped > 0 { parts.append("\(assetsSkipped) skipped") }
        if researchQuestionsImported > 0 { parts.append("\(researchQuestionsImported) research questions") }
        if logEntriesImported > 0 { parts.append("\(logEntriesImported) log entries") }
        if evidenceImported > 0 { parts.append("\(evidenceImported) evidence items") }
        if decisionsImported > 0 { parts.append("\(decisionsImported) decisions") }
        if outcomesImported > 0 { parts.append("\(outcomesImported) outcomes") }
        if tagsCreated > 0 { parts.append("\(tagsCreated) tags created") }
        return parts.isEmpty ? "No data imported" : parts.joined(separator: ", ")
    }
}
