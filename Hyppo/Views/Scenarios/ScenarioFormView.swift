/**
 ScenarioFormView provides a form for creating or editing a scenario.
 
 Supports structured input for scenario statement, key drivers,
 invalidation rules, catalysts, risks, and confidence level.
 */

import SwiftUI
import SwiftData

/// Form mode for add vs edit
enum ScenarioFormMode {
    case add(researchQuestion: ResearchQuestion)
    case edit(Scenario)
    
    var title: String {
        switch self {
        case .add: return "Add Scenario"
        case .edit: return "Edit Scenario"
        }
    }
    
    var saveButtonTitle: String {
        switch self {
        case .add: return "Add"
        case .edit: return "Save"
        }
    }
}

/// Form for creating or editing a scenario
struct ScenarioFormView: View {
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Properties
    
    let mode: ScenarioFormMode
    let onSave: (Scenario) -> Void
    
    // MARK: - State
    
    @State private var scenarioType: ScenarioType = .base
    @State private var title: String = ""
    @State private var scenarioStatement: String = ""
    @State private var keyDrivers: [String] = [""]
    @State private var invalidationRules: [String] = [""]
    @State private var catalysts: [String] = []
    @State private var keyRisks: [String] = []
    @State private var confidence: Int? = nil
    @State private var validationErrors: [String] = []
    
    // MARK: - Initialization
    
    init(mode: ScenarioFormMode, onSave: @escaping (Scenario) -> Void) {
        self.mode = mode
        self.onSave = onSave
        
        // Pre-populate for edit mode
        if case .edit(let scenario) = mode {
            _scenarioType = State(initialValue: scenario.scenarioType)
            _title = State(initialValue: scenario.title)
            _scenarioStatement = State(initialValue: scenario.scenarioStatement)
            _keyDrivers = State(initialValue: scenario.keyDrivers.isEmpty ? [""] : scenario.keyDrivers)
            _invalidationRules = State(initialValue: scenario.invalidationRules.isEmpty ? [""] : scenario.invalidationRules)
            _catalysts = State(initialValue: scenario.catalysts)
            _keyRisks = State(initialValue: scenario.keyRisks)
            _confidence = State(initialValue: scenario.confidenceCurrent)
        }
    }
    
    // MARK: - Computed Properties
    
    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !scenarioStatement.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        keyDrivers.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } &&
        invalidationRules.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Form content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Type and title section
                    typeAndTitleSection
                    
                    // Scenario statement section
                    scenarioStatementSection
                    
                    // Key drivers section
                    keyDriversSection
                    
                    // Invalidation rules section
                    invalidationRulesSection
                    
                    // Optional sections
                    optionalSections
                    
                    // Confidence section
                    confidenceSection
                    
                    // Validation errors
                    if !validationErrors.isEmpty {
                        validationErrorsSection
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Footer with buttons
            footerView
        }
        .frame(width: 600, height: 700)
    }
    
    // MARK: - Sections
    
    private var headerView: some View {
        HStack {
            Text(mode.title)
                .font(.headline)
            Spacer()
        }
        .padding()
    }
    
    private var typeAndTitleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Basic Information")
                .font(.headline)
            
            HStack(spacing: 16) {
                // Type picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("Type")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Picker("Type", selection: $scenarioType) {
                        ForEach(ScenarioType.allCases) { type in
                            Label(type.displayName, systemImage: type.iconName)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 120)
                }
                
                // Title field
                VStack(alignment: .leading, spacing: 4) {
                    Text("Title")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    TextField("e.g., Growth scenario on cloud expansion", text: $title)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
    }
    
    private var scenarioStatementSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Scenario Statement")
                .font(.headline)
            
            Text("What must be true for this investment to work?")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            TextEditor(text: $scenarioStatement)
                .font(.body)
                .frame(minHeight: 80)
                .padding(4)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                )
        }
    }
    
    private var keyDriversSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Key Drivers")
                    .font(.headline)
                Text("(Required)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text("What factors support this scenario?")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            EditableListSection(items: $keyDrivers, placeholder: "Add a key driver...")
        }
    }
    
    private var invalidationRulesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Invalidation Rules")
                    .font(.headline)
                Text("(Required)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text("What would prove this scenario wrong?")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            EditableListSection(items: $invalidationRules, placeholder: "Add an invalidation rule...")
        }
    }
    
    private var optionalSections: some View {
        DisclosureGroup("Optional Details") {
            VStack(alignment: .leading, spacing: 16) {
                // Catalysts
                VStack(alignment: .leading, spacing: 8) {
                    Text("Catalysts")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("What events could trigger price movement?")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    EditableListSection(items: $catalysts, placeholder: "Add a catalyst...")
                }
                
                // Key Risks
                VStack(alignment: .leading, spacing: 8) {
                    Text("Key Risks")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("What are the main risks to this scenario?")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    EditableListSection(items: $keyRisks, placeholder: "Add a key risk...")
                }
            }
            .padding(.top, 8)
        }
    }
    
    private var confidenceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Confidence Level")
                .font(.headline)
            
            HStack(spacing: 12) {
                ForEach(ConfidenceLevel.allCases, id: \.rawValue) { level in
                    Button {
                        if confidence == level.rawValue {
                            confidence = nil
                        } else {
                            confidence = level.rawValue
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text("\(level.rawValue)")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text(level.displayName)
                                .font(.caption2)
                        }
                        .frame(width: 70, height: 50)
                        .background(confidence == level.rawValue ? Color.blue : Color(nsColor: .controlBackgroundColor))
                        .foregroundStyle(confidence == level.rawValue ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var validationErrorsSection: some View {
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
        
        if scenarioStatement.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors.append("Scenario statement is required")
        }
        
        let validDrivers = keyDrivers.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        if validDrivers.isEmpty {
            validationErrors.append("At least one key driver is required")
        }
        
        let validRules = invalidationRules.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        if validRules.isEmpty {
            validationErrors.append("At least one invalidation rule is required")
        }
        
        return validationErrors.isEmpty
    }
    
    private func save() {
        guard validate() else { return }
        
        // Clean up arrays - remove empty items
        let cleanDrivers = keyDrivers.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let cleanRules = invalidationRules.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let cleanCatalysts = catalysts.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let cleanRisks = keyRisks.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        switch mode {
        case .add:
            let newScenario = Scenario(
                scenarioType: scenarioType,
                title: title,
                scenarioStatement: scenarioStatement,
                keyDrivers: cleanDrivers,
                invalidationRules: cleanRules,
                catalysts: cleanCatalysts.isEmpty ? nil : cleanCatalysts,
                keyRisks: cleanRisks.isEmpty ? nil : cleanRisks,
                confidence: confidence
            )
            onSave(newScenario)
            
        case .edit(let scenario):
            scenario.update(
                title: title,
                scenarioStatement: scenarioStatement,
                keyDrivers: cleanDrivers,
                invalidationRules: cleanRules,
                catalysts: cleanCatalysts.isEmpty ? nil : cleanCatalysts,
                keyRisks: cleanRisks.isEmpty ? nil : cleanRisks,
                confidence: confidence
            )
            onSave(scenario)
        }
        
        dismiss()
    }
}

// MARK: - EditableListSection

/**
 * Reusable component for editing a list of string items.
 * Used for key drivers, invalidation rules, catalysts, and key risks.
 */
struct EditableListSection: View {
    @Binding var items: [String]
    let placeholder: String
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(items.indices, id: \.self) { index in
                HStack {
                    TextField(placeholder, text: $items[index])
                        .textFieldStyle(.roundedBorder)
                    
                    Button {
                        items.remove(at: index)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Button {
                items.append("")
            } label: {
                Label("Add Item", systemImage: "plus.circle")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.blue)
        }
    }
}

// MARK: - Preview

#Preview {
    let question = ResearchQuestion(questionText: "Can AAPL sustain services revenue growth?")
    return ScenarioFormView(
        mode: .add(researchQuestion: question)
    ) { _ in }
}

