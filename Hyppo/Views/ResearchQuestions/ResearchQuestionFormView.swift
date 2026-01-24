/**
 ResearchQuestionFormView provides a form for creating or editing a research question.
 
 Supports both add and edit modes with validation and appropriate
 save/cancel actions.
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
    @State private var context: String = ""
    @State private var priority: Int? = nil
    @State private var validationErrors: [String] = []
    
    // MARK: - Initialization
    
    init(mode: ResearchQuestionFormMode, onSave: @escaping (ResearchQuestion) -> Void) {
        self.mode = mode
        self.onSave = onSave
        
        // Pre-populate for edit mode
        if case .edit(let question) = mode {
            _questionText = State(initialValue: question.questionText)
            _context = State(initialValue: question.context ?? "")
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
            Form {
                Section {
                    TextField("Question", text: $questionText, prompt: Text("e.g., Can AAPL sustain services revenue growth?"), axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                } header: {
                    Text("Research Question")
                } footer: {
                    Text("The key question you want to answer about this investment.")
                }
                
                Section {
                    TextField("Context (Optional)", text: $context, prompt: Text("Why does this question matter?"), axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...8)
                } header: {
                    Text("Context")
                } footer: {
                    Text("Background information or why this question is important.")
                }
                
                Section {
                    Picker("Priority", selection: $priority) {
                        Text("None").tag(nil as Int?)
                        ForEach(1...5, id: \.self) { level in
                            Text("\(level)/5").tag(level as Int?)
                        }
                    }
                } header: {
                    Text("Priority (Optional)")
                } footer: {
                    Text("How important is this research question to answer?")
                }
                
                // Validation errors
                if !validationErrors.isEmpty {
                    Section {
                        ForEach(validationErrors, id: \.self) { error in
                            Label(error, systemImage: "exclamationmark.triangle")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(minWidth: 500, minHeight: 400)
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            Text(mode.title)
                .font(.headline)
            
            Spacer()
            
            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)
            
            Button(mode.saveButtonTitle) {
                saveQuestion()
            }
            .keyboardShortcut(.defaultAction)
            .disabled(!isValid)
        }
        .padding()
    }
    
    // MARK: - Actions
    
    private func saveQuestion() {
        // Validate
        validationErrors.removeAll()
        
        let trimmedQuestion = questionText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContext = context.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedQuestion.isEmpty {
            validationErrors.append("Question text is required")
            return
        }
        
        if let priority = priority, (priority < 1 || priority > 5) {
            validationErrors.append("Priority must be between 1 and 5")
            return
        }
        
        // Create or update
        switch mode {
        case .add:
            let question = ResearchQuestion(
                questionText: trimmedQuestion,
                context: trimmedContext.isEmpty ? nil : trimmedContext,
                priority: priority
            )
            onSave(question)
            
        case .edit(let question):
            question.update(
                questionText: trimmedQuestion,
                context: trimmedContext.isEmpty ? nil : trimmedContext,
                priority: priority
            )
            onSave(question)
        }
        
        dismiss()
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
        priority: 4
    )
    return ResearchQuestionFormView(mode: .edit(question)) { _ in }
}

