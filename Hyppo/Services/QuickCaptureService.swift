/**
 QuickCaptureService manages state and business logic for the Quick Capture HUD.
 
 Coordinates clipboard detection, destination selection, and evidence creation.
 Maintains session state for rapid successive captures.
 */

import Foundation
import SwiftUI
import SwiftData
import Combine

// MARK: - Quick Capture State

/**
 Represents the current state of a Quick Capture session.
 */
struct QuickCaptureState {
    // Input fields
    var url: String = ""
    var displayTitle: String = ""
    var snippetText: String = ""
    var annotationText: String = ""
    var evidenceType: EvidenceType = .article
    
    // KPI-specific fields
    var metricName: String = ""
    var metricValue: String = ""
    var metricUnit: String = ""
    var metricPeriod: String = ""
    var metricNote: String = ""
    
    // Destination selection
    var selectedAsset: Asset?
    var selectedResearchQuestion: ResearchQuestion?
    var selectedDriver: Driver?
    
    // Metadata
    var sentiment: EvidenceSentiment = .neutral
    var sourceType: SourceType = .other
    
    // UI state
    var isCompactMode: Bool = false
    var showInlineAssetForm: Bool = false
    var showInlineQuestionForm: Bool = false
    
    // Validation
    var validationError: String?
    
    /// Resets the input fields while keeping destination selection
    mutating func resetInputs() {
        url = ""
        displayTitle = ""
        snippetText = ""
        annotationText = ""
        evidenceType = .article
        sentiment = .neutral
        sourceType = .other
        metricName = ""
        metricValue = ""
        metricUnit = ""
        metricPeriod = ""
        metricNote = ""
        validationError = nil
    }
    
    /// Fully resets the state
    mutating func reset() {
        resetInputs()
        selectedAsset = nil
        selectedResearchQuestion = nil
        selectedDriver = nil
        isCompactMode = false
        showInlineAssetForm = false
        showInlineQuestionForm = false
    }
}

// MARK: - Quick Capture Service

/**
 Singleton service for managing Quick Capture functionality.
 
 Provides:
 - HUD visibility management
 - Clipboard integration
 - Evidence creation
 - Session state persistence
 */
@MainActor
final class QuickCaptureService: ObservableObject {
    // MARK: - Singleton
    
    static let shared = QuickCaptureService()
    
    // MARK: - Published Properties
    
    /// Whether the HUD is currently visible
    @Published var isHUDVisible: Bool = false
    
    /// Current capture state
    @Published var state = QuickCaptureState()
    
    /// Clipboard detector instance
    @Published var clipboardDetector = ClipboardDetector()
    
    /// Whether a save operation is in progress
    @Published var isSaving: Bool = false
    
    /// Last successful save timestamp (for feedback)
    @Published var lastSaveTime: Date?
    
    // MARK: - Session Persistence
    
    /// Last used asset ID (persisted across HUD sessions)
    private var lastAssetId: UUID?
    
    /// Last used research question ID
    private var lastQuestionId: UUID?
    
    /// Last used driver ID
    private var lastDriverId: UUID?
    
    /// Last used evidence type
    private var lastEvidenceType: EvidenceType = .article
    
    // MARK: - Initialization
    
    private init() {
        DebugLogger.info(
            location: "QuickCaptureService:init",
            message: "Quick Capture service initialized"
        )
    }
    
    // MARK: - HUD Management
    
    /**
     Shows the Quick Capture HUD.
     
     Refreshes clipboard content and applies smart defaults.
     */
    func showHUD() {
        DebugLogger.info(
            location: "QuickCaptureService:showHUD",
            message: "Showing Quick Capture HUD"
        )
        
        // Refresh clipboard
        clipboardDetector.forceRefresh()
        
        // Apply clipboard content to state
        applyClipboardContent()
        
        // Apply last used evidence type
        state.evidenceType = lastEvidenceType
        
        // Show HUD
        isHUDVisible = true
    }
    
    /**
     Hides the Quick Capture HUD.
     
     Optionally preserves state for "Save & Continue" mode.
     
     - Parameter preserveState: Whether to keep the destination selection
     */
    func hideHUD(preserveState: Bool = false) {
        DebugLogger.info(
            location: "QuickCaptureService:hideHUD",
            message: "Hiding Quick Capture HUD",
            data: ["preserveState": preserveState]
        )
        
        isHUDVisible = false
        
        if !preserveState {
            // Reset state but remember last selections
            lastAssetId = state.selectedAsset?.assetId
            lastQuestionId = state.selectedResearchQuestion?.questionId
            state.reset()
        } else {
            // Just reset inputs for rapid capture
            state.resetInputs()
        }
    }
    
    /**
     Toggles the HUD visibility.
     */
    func toggleHUD() {
        if isHUDVisible {
            hideHUD()
        } else {
            showHUD()
        }
    }
    
    // MARK: - Content Application
    
    /**
     Applies detected clipboard content to the current state.
     */
    func applyClipboardContent() {
        switch clipboardDetector.detectedContent {
        case .url(let url):
            state.url = url.absoluteString
            state.evidenceType = .article
            if let title = clipboardDetector.fetchedTitle {
                state.displayTitle = title
            }
            
        case .text(let text):
            state.snippetText = ClipboardDetector.truncateSnippet(text)
            state.evidenceType = .note
            
        case .mixed(let url, let text):
            state.url = url.absoluteString
            state.snippetText = ClipboardDetector.truncateSnippet(text)
            state.evidenceType = .article
            if let title = clipboardDetector.fetchedTitle {
                state.displayTitle = title
            }
            
        case .empty:
            break
        }
    }
    
    /**
     Restores last used destinations from a model context.
     
     - Parameter modelContext: The SwiftData model context
     */
    func restoreLastDestinations(from modelContext: ModelContext) {
        // Restore last asset
        if let assetId = lastAssetId {
            let descriptor = FetchDescriptor<Asset>(
                predicate: #Predicate { $0.assetId == assetId }
            )
            if let asset = try? modelContext.fetch(descriptor).first {
                state.selectedAsset = asset
            }
        }
        
        // Restore last research question
        if let questionId = lastQuestionId, state.selectedAsset != nil {
            let descriptor = FetchDescriptor<ResearchQuestion>(
                predicate: #Predicate { $0.questionId == questionId }
            )
            if let question = try? modelContext.fetch(descriptor).first {
                state.selectedResearchQuestion = question
            }
        }
        
        // Restore last driver
        if let driverId = lastDriverId, state.selectedResearchQuestion != nil {
            let descriptor = FetchDescriptor<Driver>(
                predicate: #Predicate { $0.driverId == driverId }
            )
            if let driver = try? modelContext.fetch(descriptor).first {
                state.selectedDriver = driver
            }
        }
    }
    
    // MARK: - Save Operations
    
    /**
     Validates the current state for saving.
     
     - Returns: True if valid, false otherwise
     */
    func validateState() -> Bool {
        state.validationError = nil
        
        // Must have an asset selected
        guard state.selectedAsset != nil else {
            state.validationError = "Please select an asset"
            return false
        }
        
        // Must have a driver selected
        guard state.selectedDriver != nil else {
            state.validationError = "Please select an assumption"
            return false
        }
        
        // Validate based on evidence type
        switch state.evidenceType {
        case .kpi:
            guard !state.metricName.trimmingCharacters(in: .whitespaces).isEmpty else {
                state.validationError = "Metric name is required"
                return false
            }
            guard !state.metricValue.trimmingCharacters(in: .whitespaces).isEmpty else {
                state.validationError = "Metric value is required"
                return false
            }
            return true
            
        case .note:
            guard !state.snippetText.trimmingCharacters(in: .whitespaces).isEmpty ||
                  !state.annotationText.trimmingCharacters(in: .whitespaces).isEmpty else {
                state.validationError = "Please add a snippet or annotation"
                return false
            }
            return true
            
        default:
            guard !state.url.trimmingCharacters(in: .whitespaces).isEmpty else {
                state.validationError = "URL is required"
                return false
            }
            
            // Validate URL format
            guard ClipboardDetector.validateURL(state.url) != nil else {
                state.validationError = "Invalid URL format"
                return false
            }
            return true
        }
    }
    
    /**
     Saves the current capture as evidence.
     
     Creates or reuses a log entry and attaches the evidence.
     
     - Parameters:
       - modelContext: The SwiftData model context
       - continueCapturing: Whether to keep HUD open for more captures
     - Returns: True if save was successful
     */
    @discardableResult
    func save(modelContext: ModelContext, continueCapturing: Bool = false) -> Bool {
        guard validateState() else { return false }
        
        isSaving = true
        defer { isSaving = false }
        
        // Get or create research question
        let researchQuestion: ResearchQuestion
        if let selected = state.selectedResearchQuestion {
            researchQuestion = selected
        } else if let asset = state.selectedAsset {
            // Create a default research question for quick capture
            researchQuestion = ResearchQuestion(
                questionText: "Quick Capture Evidence",
                context: "Evidence captured via Quick Capture"
            )
            researchQuestion.asset = asset
            modelContext.insert(researchQuestion)
            
            // Update asset's relationship
            if asset.researchQuestions == nil {
                asset.researchQuestions = []
            }
            asset.researchQuestions?.append(researchQuestion)
        } else {
            state.validationError = "No destination selected"
            return false
        }
        
        // Create log entry
        let logEntry = LogEntry(
            title: createLogTitle(),
            body: createLogBody(),
            entryType: .observation,
            occurredAt: Date()
        )
        logEntry.researchQuestion = researchQuestion
        modelContext.insert(logEntry)
        
        // Update research question's relationship
        if researchQuestion.logEntries == nil {
            researchQuestion.logEntries = []
        }
        researchQuestion.logEntries?.append(logEntry)
        
        // Create evidence
        let evidence = createEvidence()
        evidence.driver = state.selectedDriver
        modelContext.insert(evidence)
        
        // Update driver's relationship
        if state.selectedDriver?.evidence == nil {
            state.selectedDriver?.evidence = []
        }
        state.selectedDriver?.evidence?.append(evidence)
        
        // Update timestamps
        researchQuestion.updatedAt = Date()
        researchQuestion.lastUpdatedAt = Date()
        state.selectedAsset?.updatedAt = Date()
        
        // Save context
        do {
            try modelContext.save()
            
            DebugLogger.info(
                location: "QuickCaptureService:save",
                message: "Evidence saved successfully",
                data: [
                    "evidenceType": state.evidenceType.rawValue,
                    "assetTicker": state.selectedAsset?.ticker ?? "unknown"
                ]
            )
            
            // Remember last used values
            lastAssetId = state.selectedAsset?.assetId
            lastQuestionId = state.selectedResearchQuestion?.questionId
            lastDriverId = state.selectedDriver?.driverId
            lastEvidenceType = state.evidenceType
            lastSaveTime = Date()
            
            // Handle HUD state
            if continueCapturing {
                state.resetInputs()
                state.isCompactMode = true
                clipboardDetector.forceRefresh()
                applyClipboardContent()
            } else {
                hideHUD()
            }
            
            return true
            
        } catch {
            DebugLogger.error(
                location: "QuickCaptureService:save",
                message: "Failed to save evidence",
                error: error
            )
            state.validationError = "Failed to save: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Private Helpers
    
    /**
     Creates the log entry title based on evidence type.
     */
    private func createLogTitle() -> String {
        switch state.evidenceType {
        case .article:
            return state.displayTitle.isEmpty ? "Article captured" : state.displayTitle
        case .filing:
            return state.displayTitle.isEmpty ? "Filing captured" : state.displayTitle
        case .kpi:
            return "\(state.metricName): \(state.metricValue)"
        case .quote:
            return state.displayTitle.isEmpty ? "Quote captured" : state.displayTitle
        case .note:
            return "Quick note"
        }
    }
    
    /**
     Creates the log entry body content.
     */
    private func createLogBody() -> String {
        var parts: [String] = []
        
        if !state.snippetText.isEmpty {
            parts.append(state.snippetText)
        }
        
        if !state.annotationText.isEmpty {
            if !parts.isEmpty {
                parts.append("")
            }
            parts.append("Note: \(state.annotationText)")
        }
        
        if !state.url.isEmpty {
            if !parts.isEmpty {
                parts.append("")
            }
            parts.append("Source: \(state.url)")
        }
        
        return parts.isEmpty ? "Evidence captured via Quick Capture" : parts.joined(separator: "\n")
    }
    
    /**
     Creates the Evidence object from current state.
     */
    private func createEvidence() -> Evidence {
        let evidence: Evidence
        switch state.evidenceType {
        case .kpi:
            evidence = Evidence(
                metricName: state.metricName,
                metricValue: state.metricValue,
                metricUnit: state.metricUnit.isEmpty ? nil : state.metricUnit,
                metricPeriod: state.metricPeriod.isEmpty ? nil : state.metricPeriod,
                metricNote: state.metricNote.isEmpty ? nil : state.metricNote,
                url: state.url.isEmpty ? nil : state.url,
                annotationText: state.annotationText.isEmpty ? nil : state.annotationText
            )
            
        default:
            evidence = Evidence(
                url: state.url.isEmpty ? nil : state.url,
                evidenceType: state.evidenceType,
                sentiment: state.sentiment,
                sourceType: state.sourceType,
                displayTitle: state.displayTitle.isEmpty ? nil : state.displayTitle,
                snippetText: state.snippetText.isEmpty ? nil : state.snippetText,
                annotationText: state.annotationText.isEmpty ? nil : state.annotationText
            )
        }
        
        evidence.sentiment = state.sentiment
        evidence.sourceType = state.sourceType
        return evidence
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    /// Notification to trigger Quick Capture HUD
    static let showQuickCapture = Notification.Name("showQuickCapture")
}

