/**
 LogEntryFormView provides a form for creating or editing a log entry.
 
 Supports quick capture with minimal required fields while allowing
 optional metadata like confidence level, entry type, and tags.
 */

import SwiftUI
import SwiftData

/// Form mode for add vs edit
enum LogEntryFormMode {
    case add(scenario: Scenario)
    case edit(LogEntry)
    
    var title: String {
        switch self {
        case .add: return "Add Log Entry"
        case .edit: return "Edit Log Entry"
        }
    }
    
    var saveButtonTitle: String {
        switch self {
        case .add: return "Add"
        case .edit: return "Save"
        }
    }
}

/// Form for creating or editing a log entry
struct LogEntryFormView: View {
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Properties
    
    let mode: LogEntryFormMode
    let onSave: (LogEntry) -> Void
    
    // MARK: - State
    
    @State private var title: String = ""
    @State private var bodyText: String = ""
    @State private var entryType: LogEntryType = .observation
    @State private var confidence: Int? = nil
    @State private var occurredAt: Date = Date()
    @State private var selectedTags: [Tag] = []
    @State private var validationErrors: [String] = []
    
    // MARK: - Initialization
    
    init(mode: LogEntryFormMode, onSave: @escaping (LogEntry) -> Void) {
        self.mode = mode
        self.onSave = onSave
        
        // Pre-populate for edit mode
        if case .edit(let logEntry) = mode {
            _title = State(initialValue: logEntry.title)
            _bodyText = State(initialValue: logEntry.body)
            _entryType = State(initialValue: logEntry.entryType)
            _confidence = State(initialValue: logEntry.confidence)
            _occurredAt = State(initialValue: logEntry.occurredAt)
            _selectedTags = State(initialValue: logEntry.tags ?? [])
        }
    }
    
    // MARK: - Computed Properties
    
    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var scenarioTitle: String {
        switch mode {
        case .add(let scenario):
            return scenario.title
        case .edit(let logEntry):
            return logEntry.scenario?.title ?? "Unknown Scenario"
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
                    // Scenario reference
                    HStack {
                        Text("Scenario:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(scenarioTitle)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    // Entry type and date row
                    HStack(spacing: 16) {
                        // Entry type picker
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Type")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Picker("Type", selection: $entryType) {
                                ForEach(LogEntryType.allCases) { type in
                                    Label(type.displayName, systemImage: type.iconName)
                                        .tag(type)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 140)
                        }
                        
                        // Date picker
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Date & Time")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            DatePicker("", selection: $occurredAt, displayedComponents: [.date, .hourAndMinute])
                                .labelsHidden()
                        }
                        
                        Spacer()
                    }
                    
                    // Title field
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Title")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        TextField("Brief summary of this entry", text: $title)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // Body field
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Details")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        TextEditor(text: $bodyText)
                            .font(.body)
                            .frame(minHeight: 150)
                            .padding(4)
                            .background(Color(nsColor: .textBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                            )
                    }
                    
                    // Confidence level
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confidence Level (Optional)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 10) {
                            ForEach(ConfidenceLevel.allCases, id: \.rawValue) { level in
                                Button {
                                    if confidence == level.rawValue {
                                        confidence = nil
                                    } else {
                                        confidence = level.rawValue
                                    }
                                } label: {
                                    Text("\(level.rawValue)")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .frame(width: 36, height: 36)
                                        .background(confidence == level.rawValue ? Color.blue : Color(nsColor: .controlBackgroundColor))
                                        .foregroundStyle(confidence == level.rawValue ? .white : .primary)
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                            }
                            
                            if confidence != nil {
                                Button("Clear") {
                                    confidence = nil
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    // Tags
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags (Optional)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        TagPickerView(selectedTags: $selectedTags)
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
        .frame(width: 500, height: 620)
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
        
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors.append("Title is required")
        }
        
        if bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors.append("Details are required")
        }
        
        return validationErrors.isEmpty
    }
    
    private func save() {
        guard validate() else { return }
        
        switch mode {
        case .add:
            let newLogEntry = LogEntry(
                title: title,
                body: bodyText,
                entryType: entryType,
                confidence: confidence,
                occurredAt: occurredAt,
                isSystemGenerated: false
            )
            newLogEntry.tags = selectedTags.isEmpty ? nil : selectedTags
            onSave(newLogEntry)
            
        case .edit(let logEntry):
            logEntry.update(
                title: title,
                body: bodyText,
                entryType: entryType,
                confidence: confidence,
                occurredAt: occurredAt
            )
            logEntry.tags = selectedTags.isEmpty ? nil : selectedTags
            onSave(logEntry)
        }
        
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    let scenario = Scenario(
        scenarioType: .base,
        title: "Test Scenario",
        scenarioStatement: "Testing",
        keyDrivers: ["Driver 1"],
        invalidationRules: ["Rule 1"]
    )
    
    return LogEntryFormView(mode: .add(scenario: scenario)) { _ in }
        .modelContainer(for: [Scenario.self, LogEntry.self, Tag.self], inMemory: true)
}

