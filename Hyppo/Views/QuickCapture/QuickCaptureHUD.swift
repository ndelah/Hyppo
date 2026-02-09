/**
 QuickCaptureHUD is the main floating panel for rapid evidence capture.
 
 Provides a low-friction interface to capture URLs, snippets, and notes
 from anywhere in macOS without interrupting the user's workflow.
 */

import SwiftUI
import SwiftData

// MARK: - Quick Capture HUD View

/**
 The main Quick Capture floating panel.
 
 Features:
 - Auto-detects clipboard content (URLs vs. text)
 - Hierarchical destination selection (Asset → Research Question)
 - Evidence type selection
 - Keyboard shortcuts for rapid workflow
 - Compact mode for successive captures
 */
struct QuickCaptureHUD: View {
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Service
    
    @ObservedObject var service: QuickCaptureService
    
    // MARK: - Local State
    
    @FocusState private var focusedField: FocusedField?
    
    private enum FocusedField {
        case url
        case title
        case snippet
        case annotation
        case metricName
        case metricValue
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if service.state.isCompactMode {
                        compactModeContent
                    } else {
                        fullModeContent
                    }
                }
                .padding(16)
            }
            
            Divider()
            
            // Footer with actions
            footerSection
        }
        .frame(width: service.state.isCompactMode ? 400 : 500)
        .frame(minHeight: service.state.isCompactMode ? 200 : 400)
        .background(Color(.windowBackgroundColor))
        .onAppear {
            service.restoreLastDestinations(from: modelContext)
            focusedField = service.clipboardDetector.detectedContent.hasURL ? .title : .snippet
        }
        .onExitCommand {
            service.hideHUD()
        }
    }
    
    // MARK: - Header Section
    
    @ViewBuilder
    private var headerSection: some View {
        HStack {
            Label("Quick Capture", systemImage: "bolt.fill")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Spacer()
            
            // Compact mode toggle
            if !service.state.isCompactMode {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        service.state.isCompactMode = true
                    }
                } label: {
                    Image(systemName: "rectangle.compress.vertical")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Compact mode")
            } else {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        service.state.isCompactMode = false
                    }
                } label: {
                    Image(systemName: "rectangle.expand.vertical")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Expand")
            }
            
            Button {
                service.hideHUD()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Close (Esc)")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Full Mode Content
    
    @ViewBuilder
    private var fullModeContent: some View {
        // Clipboard Detection Section
        clipboardSection
        
        // Destination Picker
        DestinationPicker(
            selectedAsset: $service.state.selectedAsset,
            selectedResearchQuestion: $service.state.selectedResearchQuestion,
            selectedDriver: $service.state.selectedDriver,
            showInlineAssetForm: $service.state.showInlineAssetForm,
            showInlineQuestionForm: $service.state.showInlineQuestionForm
        )
        
        // Sentiment and Source Type
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Sentiment")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("Sentiment", selection: $service.state.sentiment) {
                    ForEach(EvidenceSentiment.allCases) { s in
                        Label(s.rawValue, systemImage: s.iconName).tag(s)
                    }
                }
                .pickerStyle(.menu)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Source")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("Source", selection: $service.state.sourceType) {
                    ForEach(SourceType.allCases) { s in
                        Label(s.displayName, systemImage: s.iconName).tag(s)
                    }
                }
                .pickerStyle(.menu)
            }
        }
        
        // Evidence Type Selection
        evidenceTypeSection
        
        // Evidence Details (based on type)
        evidenceDetailsSection
    }
    
    // MARK: - Compact Mode Content
    
    @ViewBuilder
    private var compactModeContent: some View {
        // Quick input field
        HStack {
            Image(systemName: "doc.on.clipboard")
                .foregroundStyle(.secondary)
            
            TextField("Paste URL or text...", text: $service.state.url)
                .textFieldStyle(.plain)
                .focused($focusedField, equals: .url)
        }
        .padding(10)
        .background(Color(.windowBackgroundColor))
        .cornerRadius(8)
        
        // Compact destination display
        CompactDestinationDisplay(
            asset: service.state.selectedAsset,
            researchQuestion: service.state.selectedResearchQuestion,
            driver: service.state.selectedDriver
        ) {
            withAnimation(.easeInOut(duration: 0.2)) {
                service.state.isCompactMode = false
            }
        }
        
        // Last save confirmation
        if let lastSave = service.lastSaveTime,
           Date().timeIntervalSince(lastSave) < 5 {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.statusActive)
                Text("Saved!")
                    .font(.caption)
                    .foregroundStyle(Color.statusActive)
            }
            .transition(.opacity)
        }
    }
    
    // MARK: - Clipboard Section
    
    @ViewBuilder
    private var clipboardSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Clipboard Content", systemImage: "doc.on.clipboard")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button {
                    service.clipboardDetector.forceRefresh()
                    service.applyClipboardContent()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .help("Refresh clipboard")
            }
            
            // Show detected content
            clipboardContentPreview
        }
    }
    
    @ViewBuilder
    private var clipboardContentPreview: some View {
        Group {
            switch service.clipboardDetector.detectedContent {
            case .url(let url):
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "link")
                            .foregroundStyle(Color.accentColor)
                        Text("URL detected")
                            .font(.caption)
                            .foregroundStyle(Color.accentColor)
                    }
                    Text(url.absoluteString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    
                    if service.clipboardDetector.isFetchingTitle {
                        HStack(spacing: 4) {
                            ProgressView()
                                .controlSize(.mini)
                            Text("Fetching title...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else if let title = service.clipboardDetector.fetchedTitle {
                        Text(title)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                
            case .text(let text):
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "text.quote")
                            .foregroundStyle(Color.statusOnHold)
                        Text("Text snippet detected")
                            .font(.caption)
                            .foregroundStyle(Color.statusOnHold)
                    }
                    Text(ClipboardDetector.truncateSnippet(text))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
                
            case .mixed(let url, let text):
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "link.badge.plus")
                            .foregroundStyle(.purple)
                        Text("URL + Text detected")
                            .font(.caption)
                            .foregroundStyle(.purple)
                    }
                    Text(url.absoluteString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text(ClipboardDetector.truncateSnippet(text))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
            case .empty:
                HStack {
                    Image(systemName: "clipboard")
                        .foregroundStyle(.secondary)
                    Text("Clipboard is empty")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.windowBackgroundColor))
        .cornerRadius(8)
    }
    
    // MARK: - Evidence Type Section
    
    @ViewBuilder
    private var evidenceTypeSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Evidence Type", systemImage: "tag")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 8) {
                ForEach(EvidenceType.allCases) { type in
                    EvidenceTypeButton(
                        type: type,
                        isSelected: service.state.evidenceType == type
                    ) {
                        service.state.evidenceType = type
                    }
                }
            }
        }
    }
    
    // MARK: - Evidence Details Section
    
    @ViewBuilder
    private var evidenceDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch service.state.evidenceType {
            case .kpi:
                kpiFields
            default:
                standardFields
            }
        }
    }
    
    @ViewBuilder
    private var standardFields: some View {
        // URL field (not for notes)
        if service.state.evidenceType != .note {
            VStack(alignment: .leading, spacing: 4) {
                Text("URL")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                TextField("https://...", text: $service.state.url)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .url)
            }
        }
        
        // Title field
        VStack(alignment: .leading, spacing: 4) {
            Text("Title")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            TextField("Display title (auto-filled)", text: $service.state.displayTitle)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: .title)
        }
        
        // Snippet field
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Snippet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(service.state.snippetText.count)/\(ClipboardDetector.maxSnippetLength)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            TextEditor(text: $service.state.snippetText)
                .font(.body)
                .frame(minHeight: 60, maxHeight: 100)
                .padding(4)
                .background(Color(.windowBackgroundColor))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(.separatorColor), lineWidth: 1)
                )
                .focused($focusedField, equals: .snippet)
                .onChange(of: service.state.snippetText) { _, newValue in
                    if newValue.count > ClipboardDetector.maxSnippetLength {
                        service.state.snippetText = ClipboardDetector.truncateSnippet(newValue)
                    }
                }
        }
        
        // Annotation field
        VStack(alignment: .leading, spacing: 4) {
            Text("Your Notes")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            TextField("What's important about this?", text: $service.state.annotationText)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: .annotation)
        }
    }
    
    @ViewBuilder
    private var kpiFields: some View {
        HStack(spacing: 12) {
            // Metric Name
            VStack(alignment: .leading, spacing: 4) {
                Text("Metric Name *")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                TextField("Revenue, MAU, etc.", text: $service.state.metricName)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .metricName)
            }
            
            // Metric Value
            VStack(alignment: .leading, spacing: 4) {
                Text("Value *")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                TextField("100M", text: $service.state.metricValue)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .metricValue)
            }
        }
        
        HStack(spacing: 12) {
            // Unit
            VStack(alignment: .leading, spacing: 4) {
                Text("Unit")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                TextField("USD, %, etc.", text: $service.state.metricUnit)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Period
            VStack(alignment: .leading, spacing: 4) {
                Text("Period")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                TextField("Q3 2025", text: $service.state.metricPeriod)
                    .textFieldStyle(.roundedBorder)
            }
        }
        
        // Source URL (optional for KPIs)
        VStack(alignment: .leading, spacing: 4) {
            Text("Source URL (optional)")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            TextField("https://...", text: $service.state.url)
                .textFieldStyle(.roundedBorder)
        }
        
        // Note
        VStack(alignment: .leading, spacing: 4) {
            Text("Comparison Note")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            TextField("vs. Q2: +15% YoY", text: $service.state.metricNote)
                .textFieldStyle(.roundedBorder)
        }
    }
    
    // MARK: - Footer Section
    
    @ViewBuilder
    private var footerSection: some View {
        HStack {
            // Validation error
            if let error = service.state.validationError {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.statusOnHold)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Color.statusOnHold)
                }
            }
            
            Spacer()
            
            // Cancel button
            Button("Cancel") {
                service.hideHUD()
            }
            .keyboardShortcut(.escape, modifiers: [])
            
            // Save & Continue button
            Button("Save & Continue") {
                service.save(modelContext: modelContext, continueCapturing: true)
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .disabled(service.state.selectedAsset == nil || service.isSaving)
            
            // Save button
            Button("Save") {
                service.save(modelContext: modelContext, continueCapturing: false)
            }
            .keyboardShortcut(.return, modifiers: [])
            .buttonStyle(.borderedProminent)
            .disabled(service.state.selectedAsset == nil || service.isSaving)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Evidence Type Button

/**
 A selectable button for evidence type.
 */
struct EvidenceTypeButton: View {
    let type: EvidenceType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: type.iconName)
                    .font(.system(size: 16))
                Text(type.displayName)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            .foregroundStyle(isSelected ? Color.accentColor : .secondary)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.accentColor : Color(.separatorColor), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Quick Capture Window

/**
 A window wrapper for the Quick Capture HUD.
 
 Can be used with WindowGroup or as a floating panel.
 */
struct QuickCaptureWindow: View {
    @StateObject private var service = QuickCaptureService.shared
    
    var body: some View {
        QuickCaptureHUD(service: service)
    }
}

// MARK: - Preview

#Preview {
    QuickCaptureHUD(service: QuickCaptureService.shared)
        .modelContainer(for: [Asset.self, ResearchQuestion.self, LogEntry.self, Evidence.self])
}

