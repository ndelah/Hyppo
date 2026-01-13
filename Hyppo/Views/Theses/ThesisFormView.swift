/**
 ThesisFormView provides a form for creating or editing a thesis.
 
 Supports structured input for thesis statement, key drivers,
 invalidation rules, catalysts, risks, and confidence level.
 */

import SwiftUI
import SwiftData

/// Form mode for add vs edit
enum ThesisFormMode {
    case add(asset: Asset)
    case edit(Thesis)
    
    var title: String {
        switch self {
        case .add: return "Add Thesis"
        case .edit: return "Edit Thesis"
        }
    }
    
    var saveButtonTitle: String {
        switch self {
        case .add: return "Add"
        case .edit: return "Save"
        }
    }
}

/// Form for creating or editing a thesis
struct ThesisFormView: View {
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Properties
    
    let mode: ThesisFormMode
    let onSave: (Thesis) -> Void
    
    // MARK: - State
    
    @State private var thesisType: ThesisType = .base
    @State private var title: String = ""
    @State private var thesisStatement: String = ""
    @State private var keyDrivers: [String] = [""]
    @State private var invalidationRules: [String] = [""]
    @State private var catalysts: [String] = []
    @State private var keyRisks: [String] = []
    @State private var confidence: Int? = nil
    @State private var validationErrors: [String] = []
    
    // MARK: - Initialization
    
    init(mode: ThesisFormMode, onSave: @escaping (Thesis) -> Void) {
        self.mode = mode
        self.onSave = onSave
        
        // Pre-populate for edit mode
        if case .edit(let thesis) = mode {
            _thesisType = State(initialValue: thesis.thesisType)
            _title = State(initialValue: thesis.title)
            _thesisStatement = State(initialValue: thesis.thesisStatement)
            _keyDrivers = State(initialValue: thesis.keyDrivers.isEmpty ? [""] : thesis.keyDrivers)
            _invalidationRules = State(initialValue: thesis.invalidationRules.isEmpty ? [""] : thesis.invalidationRules)
            _catalysts = State(initialValue: thesis.catalysts)
            _keyRisks = State(initialValue: thesis.keyRisks)
            _confidence = State(initialValue: thesis.confidenceCurrent)
        }
    }
    
    // MARK: - Computed Properties
    
    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !thesisStatement.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
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
                    
                    // Thesis statement section
                    thesisStatementSection
                    
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
                    
                    Picker("Type", selection: $thesisType) {
                        ForEach(ThesisType.allCases) { type in
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
                    
                    TextField("e.g., Growth thesis on cloud expansion", text: $title)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
    }
    
    private var thesisStatementSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Thesis Statement")
                .font(.headline)
            
            Text("What must be true for this investment to work?")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            TextEditor(text: $thesisStatement)
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
            
            Text("What factors support this thesis?")
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
            
            Text("What would prove this thesis wrong?")
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
                    
                    Text("What are the main risks to this thesis?")
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
        
        if thesisStatement.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors.append("Thesis statement is required")
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
            let newThesis = Thesis(
                thesisType: thesisType,
                title: title,
                thesisStatement: thesisStatement,
                keyDrivers: cleanDrivers,
                invalidationRules: cleanRules,
                catalysts: cleanCatalysts.isEmpty ? nil : cleanCatalysts,
                keyRisks: cleanRisks.isEmpty ? nil : cleanRisks,
                confidence: confidence
            )
            onSave(newThesis)
            
        case .edit(let thesis):
            thesis.update(
                title: title,
                thesisStatement: thesisStatement,
                keyDrivers: cleanDrivers,
                invalidationRules: cleanRules,
                catalysts: cleanCatalysts.isEmpty ? nil : cleanCatalysts,
                keyRisks: cleanRisks.isEmpty ? nil : cleanRisks,
                confidence: confidence
            )
            onSave(thesis)
        }
        
        dismiss()
    }
}

// MARK: - Editable List Section

/// Reusable component for editing a list of strings
struct EditableListSection: View {
    @Binding var items: [String]
    let placeholder: String
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(items.indices, id: \.self) { index in
                HStack {
                    TextField(placeholder, text: $items[index])
                        .textFieldStyle(.roundedBorder)
                    
                    if items.count > 1 || !items[index].isEmpty {
                        Button {
                            removeItem(at: index)
                        } label: {
                            Image(systemName: "minus.circle")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
            
            Button {
                addItem()
            } label: {
                Label("Add", systemImage: "plus")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
        }
    }
    
    private func addItem() {
        items.append("")
    }
    
    private func removeItem(at index: Int) {
        if items.count > 1 {
            items.remove(at: index)
        } else {
            items[index] = ""
        }
    }
}

// MARK: - Preview

#Preview {
    ThesisFormView(
        mode: .add(asset: Asset(ticker: "AAPL", name: "Apple Inc."))
    ) { _ in }
}

