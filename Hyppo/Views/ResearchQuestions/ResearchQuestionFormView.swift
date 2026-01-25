/**
 ResearchQuestionFormView provides a form for creating or editing a research question.
 
 Includes thesis statement, key drivers, invalidation rules, scenarios,
 and optional fields like catalysts, risks, and pre-mortem.
 */

import SwiftUI
import SwiftData

/// Form mode for add vs edit
enum ResearchQuestionFormMode {
    case add
    case edit(ResearchQuestion)
    
    var title: String {
        switch self {
        case .add: return "Add Research Question"
        case .edit: return "Edit Research Question"
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
    
    // MARK: - Properties
    
    let mode: ResearchQuestionFormMode
    let onSave: (ResearchQuestion) -> Void
    
    // MARK: - State
    
    @State private var questionText: String = ""
    @State private var thesisStatement: String = ""
    @State private var drivers: [DriverDTO] = []
    @State private var killCriteria: [KillCriteriaDTO] = []
    @State private var confidence: Int? = nil
    @State private var priority: Int? = nil
    @State private var validationErrors: [String] = []
    
    // MARK: - Initialization
    
    init(mode: ResearchQuestionFormMode, onSave: @escaping (ResearchQuestion) -> Void) {
        self.mode = mode
        self.onSave = onSave
        
        // Pre-populate for edit mode
        if case .edit(let question) = mode {
            _questionText = State(initialValue: question.questionText)
            _thesisStatement = State(initialValue: question.thesisStatement ?? "")
            
            let dtos = (question.drivers ?? []).filter { $0.parentDriver == nil }.map { d in
                DriverDTO(
                    title: d.title,
                    description: d.driverDescription ?? "",
                    validationQuestion: d.validationQuestion ?? "",
                    dataSources: d.dataSources ?? [],
                    proofThreshold: d.proofThreshold ?? "",
                    subDrivers: (d.subDrivers ?? []).map { sd in
                        DriverDTO(
                            title: sd.title,
                            description: sd.driverDescription ?? "",
                            validationQuestion: sd.validationQuestion ?? "",
                            dataSources: sd.dataSources ?? [],
                            proofThreshold: sd.proofThreshold ?? "",
                            isSubDriver: true
                        )
                    }
                )
            }
            _drivers = State(initialValue: dtos)
            
            let kcDtos = (question.killCriteria ?? []).map { KillCriteriaDTO(condition: $0.condition) }
            _killCriteria = State(initialValue: kcDtos)
            
            _confidence = State(initialValue: question.confidenceCurrent)
            _priority = State(initialValue: question.priority)
        }
    }
    
    // MARK: - Computed Properties
    
    private var isValid: Bool {
        !questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Form content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Core question section
                    coreQuestionSection
                    
                    // Thesis statement section
                    thesisStatementSection
                    
                    // Key drivers section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Assumptions")
                            .font(.headline)
                        DriverOutlineView(drivers: $drivers, prompt: "What assumptions must be true?")
                    }
                    
                    // Invalidation rules section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Kill Criteria")
                            .font(.headline)
                        ForEach(killCriteria.indices, id: \.self) { index in
                            HStack {
                                TextField("Condition", text: $killCriteria[index].condition)
                                    .textFieldStyle(.roundedBorder)
                                Button { killCriteria.remove(at: index) } label: {
                                    Image(systemName: "minus.circle.fill").foregroundStyle(.red)
                                }.buttonStyle(.plain)
                            }
                        }
                        Button { killCriteria.append(KillCriteriaDTO(condition: "")) } label: {
                            Label("Add Kill Criteria", systemImage: "plus.circle").font(.caption)
                        }.buttonStyle(.plain).foregroundStyle(.blue)
                    }
                    
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
    
    private var coreQuestionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Research Question")
                .font(.headline)
            
            TextField("e.g., Can AAPL sustain services revenue growth?", text: $questionText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)
            
            TextField("Context (optional): Why does this question matter?", text: $context, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 8) {
                Text("Priority")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Picker("Priority", selection: $priority) {
                    Text("None").tag(nil as Int?)
                    ForEach(1...5, id: \.self) { level in
                        Text("\(level)/5").tag(level as Int?)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 260)
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
            Text("Key Drivers")
                .font(.headline)
            
            Text("What factors support your thesis?")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            EditableListSection(items: $keyDrivers, placeholder: "Add a key driver...")
        }
    }
    
    private var invalidationRulesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Invalidation Rules")
                .font(.headline)
            
            Text("What would prove your thesis wrong?")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            EditableListSection(items: $invalidationRules, placeholder: "Add an invalidation rule...")
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
                            Image(systemName: (confidence ?? 0) >= level.rawValue ? "star.fill" : "star")
                                .font(.title3)
                            Text(level.displayName)
                                .font(.caption2)
                        }
                        .frame(width: 70, height: 50)
                        .background(confidence == level.rawValue ? Color.blue : Color(nsColor: .controlBackgroundColor))
                        .foregroundStyle(confidence == level.rawValue ? .white : ((confidence ?? 0) >= level.rawValue ? .orange : .primary))
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
        
        let trimmedQuestion = questionText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedQuestion.isEmpty {
            validationErrors.append("Question text is required")
            return
        }
        
        let trimmedThesis = thesisStatement.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Create or update
        switch mode {
        case .add:
            let question = ResearchQuestion(
                questionText: trimmedQuestion,
                thesisStatement: trimmedThesis.isEmpty ? nil : trimmedThesis,
                confidence: confidence,
                priority: priority
            )
            saveDriversAndCriteria(to: question)
            onSave(question)
            
        case .edit(let question):
            question.update(
                questionText: trimmedQuestion,
                context: nil,
                thesisStatement: trimmedThesis.isEmpty ? nil : trimmedThesis,
                confidence: confidence,
                priority: priority
            )
            
            // Clear existing and re-save
            question.drivers?.forEach { modelContext.delete($0) }
            question.killCriteria?.forEach { modelContext.delete($0) }
            
            saveDriversAndCriteria(to: question)
            onSave(question)
        }
        
        dismiss()
    }
    
    private func saveDriversAndCriteria(to rq: ResearchQuestion) {
        for (index, d) in drivers.enumerated() {
            if !d.title.isEmpty {
                let driver = Driver(
                    title: d.title,
                    driverDescription: d.description,
                    position: index,
                    validationQuestion: d.validationQuestion,
                    dataSources: d.dataSources,
                    proofThreshold: d.proofThreshold
                )
                driver.researchQuestion = rq
                
                for (subIndex, sd) in d.subDrivers.enumerated() {
                    if !sd.title.isEmpty {
                        let subDriver = Driver(
                            title: sd.title,
                            driverDescription: sd.description,
                            position: subIndex,
                            validationQuestion: sd.validationQuestion,
                            dataSources: sd.dataSources,
                            proofThreshold: sd.proofThreshold,
                            parentDriver: driver
                        )
                        subDriver.researchQuestion = rq
                    }
                }
            }
        }
        
        for kc in killCriteria {
            if !kc.condition.isEmpty {
                let criteria = KillCriteria(condition: kc.condition)
                criteria.researchQuestion = rq
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
        questionText: "Can AAPL sustain services revenue growth?",
        context: "Services now represent 20% of revenue",
        thesisStatement: "Apple's services segment will grow 15%+ annually",
        keyDrivers: ["Growing installed base", "High switching costs"],
        invalidationRules: ["Services growth below 10%"],
        priority: 4
    )
    return ResearchQuestionFormView(mode: .edit(question)) { _ in }
}
