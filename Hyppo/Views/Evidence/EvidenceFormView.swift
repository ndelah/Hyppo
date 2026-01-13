/**
 EvidenceFormView provides a form for creating or editing evidence.
 
 Supports different evidence types (Article, Filing, KPI, Quote, Note)
 with appropriate fields for each type.
 */

import SwiftUI
import SwiftData

/// Form mode for add vs edit
enum EvidenceFormMode {
    case add(logEntry: LogEntry)
    case edit(Evidence)
    
    var title: String {
        switch self {
        case .add: return "Add Evidence"
        case .edit: return "Edit Evidence"
        }
    }
    
    var saveButtonTitle: String {
        switch self {
        case .add: return "Add"
        case .edit: return "Save"
        }
    }
}

/// Form for creating or editing evidence
struct EvidenceFormView: View {
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Properties
    
    let mode: EvidenceFormMode
    let onSave: (Evidence) -> Void
    
    // MARK: - State
    
    @State private var evidenceType: EvidenceType = .article
    @State private var url: String = ""
    @State private var displayTitle: String = ""
    @State private var snippetText: String = ""
    @State private var annotationText: String = ""
    
    // KPI-specific fields
    @State private var metricName: String = ""
    @State private var metricValue: String = ""
    @State private var metricUnit: String = ""
    @State private var metricPeriod: String = ""
    @State private var metricNote: String = ""
    
    @State private var validationErrors: [String] = []
    
    // MARK: - Initialization
    
    init(mode: EvidenceFormMode, onSave: @escaping (Evidence) -> Void) {
        self.mode = mode
        self.onSave = onSave
        
        // Pre-populate for edit mode
        if case .edit(let evidence) = mode {
            _evidenceType = State(initialValue: evidence.evidenceType)
            _url = State(initialValue: evidence.urlRaw ?? "")
            _displayTitle = State(initialValue: evidence.displayTitle ?? "")
            _snippetText = State(initialValue: evidence.snippetText ?? "")
            _annotationText = State(initialValue: evidence.annotationText ?? "")
            _metricName = State(initialValue: evidence.metricName ?? "")
            _metricValue = State(initialValue: evidence.metricValue ?? "")
            _metricUnit = State(initialValue: evidence.metricUnit ?? "")
            _metricPeriod = State(initialValue: evidence.metricPeriod ?? "")
            _metricNote = State(initialValue: evidence.metricNote ?? "")
        }
    }
    
    // MARK: - Computed Properties
    
    private var isValid: Bool {
        switch evidenceType {
        case .kpi:
            return !metricName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   !metricValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .note:
            return !snippetText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                   !annotationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        default:
            return !url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
    
    private var logEntryTitle: String {
        switch mode {
        case .add(let logEntry):
            return logEntry.title
        case .edit(let evidence):
            return evidence.logEntry?.title ?? "Unknown Log Entry"
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Form content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Log entry reference
                    HStack {
                        Text("Log Entry:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(logEntryTitle)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    // Evidence type picker
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Evidence Type")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Picker("Type", selection: $evidenceType) {
                            ForEach(EvidenceType.allCases) { type in
                                Label(type.displayName, systemImage: type.iconName)
                                    .tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // Type-specific fields
                    if evidenceType == .kpi {
                        kpiFields
                    } else {
                        standardFields
                    }
                    
                    // Annotation (always available)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Notes (Optional)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        TextEditor(text: $annotationText)
                            .font(.body)
                            .frame(minHeight: 60)
                            .padding(4)
                            .background(Color(nsColor: .textBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                            )
                    }
                    
                    // Validation errors
                    if !validationErrors.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(validationErrors, id: \.self) { error in
                                Label(error, systemImage: "exclamationmark.circle")
                                    .foregroundStyle(.red)
                                    .font(.caption)
                            }
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Footer with buttons
            footerView
        }
        .frame(width: 500, height: 500)
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            Text(mode.title)
                .font(.headline)
            Spacer()
        }
        .padding()
    }
    
    private var standardFields: some View {
        VStack(alignment: .leading, spacing: 16) {
            // URL field
            if evidenceType != .note {
                VStack(alignment: .leading, spacing: 4) {
                    Text("URL")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    TextField("https://...", text: $url)
                        .textFieldStyle(.roundedBorder)
                }
            }
            
            // Display title
            VStack(alignment: .leading, spacing: 4) {
                Text("Title (Optional)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                TextField("Custom title for this evidence", text: $displayTitle)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Snippet text
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(evidenceType == .quote ? "Quote Text" : "Snippet (Optional)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("\(snippetText.count)/\(Evidence.maxSnippetLength)")
                        .font(.caption2)
                        .foregroundStyle(snippetText.count > Evidence.maxSnippetLength ? Color.red : Color.gray)
                }
                
                TextEditor(text: $snippetText)
                    .font(.body)
                    .frame(minHeight: 80)
                    .padding(4)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                    )
                
                Text("Keep snippets brief for copyright compliance")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
    
    private var kpiFields: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Metric name and value row
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Metric Name")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    TextField("e.g., Revenue", text: $metricName)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Value")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    TextField("e.g., 394.3", text: $metricValue)
                        .textFieldStyle(.roundedBorder)
                }
            }
            
            // Unit and period row
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Unit (Optional)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    TextField("e.g., USD billion", text: $metricUnit)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Period (Optional)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    TextField("e.g., Q3 2025", text: $metricPeriod)
                        .textFieldStyle(.roundedBorder)
                }
            }
            
            // Source URL (optional for KPI)
            VStack(alignment: .leading, spacing: 4) {
                Text("Source URL (Optional)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                TextField("https://...", text: $url)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Comparison note
            VStack(alignment: .leading, spacing: 4) {
                Text("Comparison Note (Optional)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                TextField("e.g., +12% YoY", text: $metricNote)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
    
    private var footerView: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.escape, modifiers: [])
            
            Spacer()
            
            Button(mode.saveButtonTitle) {
                save()
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .buttonStyle(.borderedProminent)
            .disabled(!isValid)
        }
        .padding()
    }
    
    // MARK: - Actions
    
    private func validate() -> Bool {
        validationErrors = []
        
        switch evidenceType {
        case .kpi:
            if metricName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                validationErrors.append("Metric name is required")
            }
            if metricValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                validationErrors.append("Metric value is required")
            }
        case .note:
            if snippetText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               annotationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                validationErrors.append("Either snippet or notes are required")
            }
        default:
            if url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                validationErrors.append("URL is required")
            }
        }
        
        return validationErrors.isEmpty
    }
    
    private func save() {
        guard validate() else { return }
        
        switch mode {
        case .add:
            let newEvidence: Evidence
            
            if evidenceType == .kpi {
                newEvidence = Evidence(
                    metricName: metricName,
                    metricValue: metricValue,
                    metricUnit: metricUnit.isEmpty ? nil : metricUnit,
                    metricPeriod: metricPeriod.isEmpty ? nil : metricPeriod,
                    metricNote: metricNote.isEmpty ? nil : metricNote,
                    url: url.isEmpty ? nil : url,
                    annotationText: annotationText.isEmpty ? nil : annotationText
                )
            } else {
                newEvidence = Evidence(
                    url: evidenceType == .note && url.isEmpty ? nil : url,
                    evidenceType: evidenceType,
                    displayTitle: displayTitle.isEmpty ? nil : displayTitle,
                    snippetText: snippetText.isEmpty ? nil : snippetText,
                    annotationText: annotationText.isEmpty ? nil : annotationText
                )
            }
            
            onSave(newEvidence)
            
        case .edit(let evidence):
            if evidenceType == .kpi {
                evidence.updateKPI(
                    metricName: metricName,
                    metricValue: metricValue,
                    metricUnit: metricUnit.isEmpty ? nil : metricUnit,
                    metricPeriod: metricPeriod.isEmpty ? nil : metricPeriod,
                    metricNote: metricNote.isEmpty ? nil : metricNote
                )
                evidence.update(
                    url: url.isEmpty ? nil : url,
                    displayTitle: nil,
                    snippetText: nil,
                    annotationText: annotationText.isEmpty ? nil : annotationText
                )
            } else {
                evidence.evidenceType = evidenceType
                evidence.update(
                    url: evidenceType == .note && url.isEmpty ? nil : url,
                    displayTitle: displayTitle.isEmpty ? nil : displayTitle,
                    snippetText: snippetText.isEmpty ? nil : snippetText,
                    annotationText: annotationText.isEmpty ? nil : annotationText
                )
            }
            
            onSave(evidence)
        }
        
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    let logEntry = LogEntry(
        title: "Test Log Entry",
        body: "Testing the evidence form",
        entryType: .observation
    )
    
    return EvidenceFormView(mode: .add(logEntry: logEntry)) { _ in }
}

