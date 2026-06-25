/**
 ResearchQuestionFormView provides a form for editing a research question.
 
 Note: For creating new research questions, use ResearchWizardView instead.
 This form is now primarily used for editing existing questions.
 
 Includes thesis statement, key drivers, scenarios, and optional fields
 like catalysts, risks, and pre-mortem.
 */

import SwiftUI
import SwiftData

/// Form mode for add vs edit
enum ResearchQuestionFormMode {
    case add
    case edit(ResearchQuestion)
    
    var title: String {
        switch self {
        case .add: return "Add Research"
        case .edit: return "Edit Research"
        }
    }
    
    var saveButtonTitle: String {
        switch self {
        case .add: return "Add"
        case .edit: return "Save"
        }
    }
}

/// Form for creating or editing a research question
struct ResearchQuestionFormView: View {
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Properties
    
    let mode: ResearchQuestionFormMode
    let asset: Asset?
    let onSave: (ResearchQuestion) -> Void
    
    // MARK: - State
    
    /// Investment Thesis - the core belief being tested (maps to questionText for model compatibility)
    @State private var investmentThesis: String = ""
    /// Why This Matters - background context for the research
    @State private var whyThisMatters: String = ""
    @State private var drivers: [DriverDTO] = []
    @State private var scenarios: [SimpleScenario] = []
    @State private var catalysts: [String] = []
    @State private var keyRisks: [String] = []
    @State private var preMortemText: String = ""
    @State private var validationErrors: [String] = []
    
    // MARK: - Initialization
    
    init(mode: ResearchQuestionFormMode, asset: Asset? = nil, onSave: @escaping (ResearchQuestion) -> Void) {
        self.mode = mode
        self.asset = asset
        self.onSave = onSave
        
        // Pre-populate for edit mode
        if case .edit(let question) = mode {
            // Use thesisStatement if available, otherwise fall back to questionText for backwards compat
            _investmentThesis = State(initialValue: question.thesisStatement ?? question.questionText)
            _whyThisMatters = State(initialValue: question.context ?? "")
            _scenarios = State(initialValue: question.scenarios)
            
            let dtos = (question.drivers ?? []).filter { $0.parentDriver == nil }.map { d in
                DriverDTO(
                    title: d.title,
                    description: d.driverDescription ?? "",
                    subDrivers: (d.subDrivers ?? []).map { sd in
                        DriverDTO(
                            title: sd.title,
                            description: sd.driverDescription ?? "",
                            isSubDriver: true
                        )
                    }
                )
            }
            _drivers = State(initialValue: dtos)
        }
    }
    
    // MARK: - Computed Properties
    
    private var isValid: Bool {
        !investmentThesis.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Form content
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 20) {
                    // Investment Thesis section (primary - the title)
                    investmentThesisSection
                    
                    // Why This Matters section (context)
                    whyThisMattersSection
                    
                    // Key drivers section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Assumptions")
                            .font(.headline)
                        DriverOutlineView(drivers: $drivers, prompt: "What assumptions must be true?")
                    }
                    
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
        .frame(width: 650, height: 750)
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
    
    private var investmentThesisSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Investment Thesis")
                    .font(.headline)
                Text("*")
                    .foregroundStyle(.red)
            }
            
            Text("What must be true for this investment to work?")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            TextEditor(text: $investmentThesis)
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
    
    private var whyThisMattersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Why This Matters")
                .font(.headline)
            
            Text("What makes this worth investigating? What's the background?")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            TextEditor(text: $whyThisMatters)
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
    }
    
    private var scenariosSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Scenarios")
                .font(.headline)
            
            Text("Define bull/base/bear case outcomes for your thesis.")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if scenarios.isEmpty {
                Text("No scenarios yet. Add scenarios to outline different possible outcomes.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.vertical, 4)
            } else {
                VStack(spacing: 8) {
                    ForEach(scenarios.indices, id: \.self) { index in
                        ScenarioRowEditor(
                            scenario: $scenarios[index],
                            onDelete: {
                                scenarios.remove(at: index)
                            }
                        )
                    }
                }
            }
            
            Button {
                scenarios.append(SimpleScenario(type: .base, title: ""))
            } label: {
                Label("Add Scenario", systemImage: "plus.circle")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.blue)
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
                    
                    Text("What are the main risks to your thesis?")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    EditableListSection(items: $keyRisks, placeholder: "Add a key risk...")
                }
                
                Divider()
                
                // Pre-Mortem
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pre-Mortem")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Imagine it is 3 years from now, and you have lost 50% of your capital on this investment. What went wrong?")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    TextEditor(text: $preMortemText)
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
            .padding(.top, 8)
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
                saveQuestion()
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .buttonStyle(.borderedProminent)
            .disabled(!isValid)
        }
        .padding()
    }
    
    // MARK: - Actions
    
    private func saveQuestion() {
        // Validate
        validationErrors.removeAll()
        
        let trimmedThesis = investmentThesis.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContext = whyThisMatters.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedThesis.isEmpty {
            validationErrors.append("Investment thesis is required")
            return
        }
        
        // Create or update
        // Note: thesis maps to both questionText (for backwards compat/title) and thesisStatement
        switch mode {
        case .add:
            let question = ResearchQuestion(
                questionText: trimmedThesis,
                context: trimmedContext.isEmpty ? nil : trimmedContext,
                thesisStatement: trimmedThesis
            )
            saveDrivers(to: question)
            onSave(question)
            
        case .edit(let question):
            question.update(
                questionText: trimmedThesis,
                context: trimmedContext.isEmpty ? nil : trimmedContext,
                thesisStatement: trimmedThesis
            )
            
            // Clear existing and re-save
            question.drivers?.forEach { modelContext.delete($0) }
            
            saveDrivers(to: question)
            onSave(question)
        }
        
        dismiss()
    }
    
    private func saveDrivers(to rq: ResearchQuestion) {
        for (index, d) in drivers.enumerated() {
            if !d.title.isEmpty {
                let driver = Driver(
                    title: d.title,
                    driverDescription: d.description,
                    position: index
                )
                driver.researchQuestion = rq
                
                for (subIndex, sd) in d.subDrivers.enumerated() {
                    if !sd.title.isEmpty {
                        let subDriver = Driver(
                            title: sd.title,
                            driverDescription: sd.description,
                            position: subIndex,
                            parentDriver: driver
                        )
                        subDriver.researchQuestion = rq
                    }
                }
            }
        }
    }
}

// MARK: - Scenario Row Editor

/**
 * Inline editor for a single scenario (type picker + title).
 */
struct ScenarioRowEditor: View {
    @Binding var scenario: SimpleScenario
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // Type picker
            Picker("Type", selection: Binding(
                get: { scenario.scenarioType },
                set: { scenario.scenarioType = $0 }
            )) {
                ForEach(ScenarioType.allCases) { type in
                    Label(type.displayName, systemImage: type.iconName)
                        .tag(type)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 100)
            
            // Title field
            TextField("Scenario title...", text: $scenario.title)
                .textFieldStyle(.roundedBorder)
            
            // Delete button
            Button {
                onDelete()
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
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

#Preview("Add Mode") {
    ResearchQuestionFormView(mode: .add) { _ in }
}

#Preview("Edit Mode") {
    let question = ResearchQuestion(
        questionText: "Apple's services segment will compound at 15%+ annually through 2028",
        context: "Services now represent 20% of revenue with higher margins than hardware",
        thesisStatement: "Apple's services segment will compound at 15%+ annually through 2028"
    )
    ResearchQuestionFormView(mode: .edit(question)) { _ in }
}
