/**
 TaskInputField provides a Todoist-style task input with @ and # mentions.
 
 Features:
 - Detects @ to show research question picker
 - Detects # to show driver picker (filtered by selected question)
 - Shows selected question/driver as inline badges
 - Submit creates the task with proper relationships
 - Can be pre-filled with a research question (when used in question detail view)
 */

import SwiftUI
import SwiftData

/// Reusable task input field with @ and # mention support
struct TaskInputField: View {
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Queries
    
    @Query(filter: #Predicate<ResearchQuestion> { $0.statusRaw == "Active" }, sort: \ResearchQuestion.updatedAt, order: .reverse)
    private var activeQuestions: [ResearchQuestion]
    
    // MARK: - Properties
    
    /// Optional pre-selected research question (when used in question detail view)
    var preselectedQuestion: ResearchQuestion?
    
    /// Callback when a task is created
    var onTaskCreated: ((ResearchTask) -> Void)?
    
    /// Placeholder text
    var placeholder: String = "Add a task... (@ for project, # for driver)"
    
    // MARK: - State
    
    @State private var taskText: String = ""
    @State private var selectedQuestion: ResearchQuestion?
    @State private var selectedDriver: Driver?
    
    // Mention detection state
    @State private var showQuestionPicker = false
    @State private var showDriverPicker = false
    @State private var mentionFilterText = ""
    @State private var cursorPositionAtMention: Int = 0
    
    @FocusState private var isTextFieldFocused: Bool
    
    // MARK: - Computed Properties
    
    /// Research question mentions for the picker
    private var questionMentions: [ResearchQuestionMention] {
        activeQuestions.map { ResearchQuestionMention(question: $0) }
    }
    
    /// Driver mentions for the picker (filtered by selected question if any)
    private var driverMentions: [DriverMention] {
        let effectiveQuestion = selectedQuestion ?? preselectedQuestion
        
        if let question = effectiveQuestion {
            // Show only drivers from the selected question
            return question.allDriversFlattened.map { driver in
                DriverMention(driver: driver, isSubDriver: driver.parentDriver != nil)
            }
        } else {
            // Show all drivers from all active questions
            var mentions: [DriverMention] = []
            for question in activeQuestions {
                for driver in question.allDriversFlattened {
                    mentions.append(DriverMention(driver: driver, isSubDriver: driver.parentDriver != nil))
                }
            }
            return mentions
        }
    }
    
    /// The effective research question (selected or preselected)
    private var effectiveQuestion: ResearchQuestion? {
        selectedQuestion ?? preselectedQuestion
    }
    
    /// Clean task text without mention syntax
    private var cleanTaskText: String {
        var text = taskText
        
        // Remove @mention and #mention syntax if present
        // This is a simplified cleanup - in production you might want more sophisticated parsing
        if let atRange = text.range(of: #"@\S*"#, options: .regularExpression) {
            text.removeSubrange(atRange)
        }
        if let hashRange = text.range(of: #"#\S*"#, options: .regularExpression) {
            text.removeSubrange(hashRange)
        }
        
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Whether the input is valid for creating a task
    private var isValidInput: Bool {
        !cleanTaskText.isEmpty
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main input area
            HStack(spacing: 8) {
                // Add icon
                Image(systemName: "plus.circle")
                    .font(.body)
                    .foregroundStyle(.secondary)
                
                // Badges for selected items
                if let question = effectiveQuestion {
                    QuestionBadge(question: question, isPreselected: preselectedQuestion != nil && selectedQuestion == nil) {
                        if preselectedQuestion == nil {
                            selectedQuestion = nil
                            selectedDriver = nil
                        }
                    }
                }
                
                if let driver = selectedDriver {
                    DriverBadge(driver: driver) {
                        selectedDriver = nil
                    }
                }
                
                // Text field
                TextField(placeholder, text: $taskText)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        createTask()
                    }
                    .onChange(of: taskText) { oldValue, newValue in
                        handleTextChange(oldValue: oldValue, newValue: newValue)
                    }
                
                // Submit button
                if isValidInput {
                    Button {
                        createTask()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.return, modifiers: [])
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isTextFieldFocused ? Color.accentColor : Color(nsColor: .separatorColor), lineWidth: 1)
            )
            
            // Mention popovers
            .popover(isPresented: $showQuestionPicker, arrowEdge: .bottom) {
                MentionPopover(
                    mentionType: .researchQuestion,
                    items: questionMentions,
                    filterText: mentionFilterText,
                    onSelect: { mention in
                        selectQuestion(mention.question)
                    },
                    onDismiss: {
                        dismissMentionPicker()
                    }
                )
            }
            .popover(isPresented: $showDriverPicker, arrowEdge: .bottom) {
                MentionPopover(
                    mentionType: .driver,
                    items: driverMentions,
                    filterText: mentionFilterText,
                    onSelect: { mention in
                        selectDriver(mention.driver)
                    },
                    onDismiss: {
                        dismissMentionPicker()
                    }
                )
            }
            
            // Hint text
            if isTextFieldFocused && taskText.isEmpty {
                HStack(spacing: 16) {
                    Label("@ for project", systemImage: "at")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    
                    Label("# for driver", systemImage: "number")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 4)
            }
        }
    }
    
    // MARK: - Actions
    
    /// Handles text changes to detect @ and # mentions
    private func handleTextChange(oldValue: String, newValue: String) {
        // Check for new @ character
        if newValue.hasSuffix("@") && !oldValue.hasSuffix("@") {
            cursorPositionAtMention = newValue.count - 1
            mentionFilterText = ""
            showQuestionPicker = true
            showDriverPicker = false
            return
        }
        
        // Check for new # character
        if newValue.hasSuffix("#") && !oldValue.hasSuffix("#") {
            cursorPositionAtMention = newValue.count - 1
            mentionFilterText = ""
            showDriverPicker = true
            showQuestionPicker = false
            return
        }
        
        // Update filter text if picker is open
        if showQuestionPicker || showDriverPicker {
            // Extract filter text after the mention symbol
            let mentionStart = cursorPositionAtMention
            if newValue.count > mentionStart {
                let startIndex = newValue.index(newValue.startIndex, offsetBy: mentionStart + 1)
                let filterPart = String(newValue[startIndex...])
                // Stop at space or end
                if let spaceIndex = filterPart.firstIndex(of: " ") {
                    mentionFilterText = String(filterPart[..<spaceIndex])
                    dismissMentionPicker()
                } else {
                    mentionFilterText = filterPart
                }
            }
            
            // Dismiss if user deleted the mention symbol
            if newValue.count <= cursorPositionAtMention {
                dismissMentionPicker()
            }
        }
    }
    
    /// Selects a research question from the picker
    private func selectQuestion(_ question: ResearchQuestion) {
        selectedQuestion = question
        // Clear driver if it doesn't belong to the new question
        if let driver = selectedDriver, driver.researchQuestion?.questionId != question.questionId {
            selectedDriver = nil
        }
        removeMentionTextFromInput()
        dismissMentionPicker()
    }
    
    /// Selects a driver from the picker
    private func selectDriver(_ driver: Driver) {
        selectedDriver = driver
        // Auto-set question if not already set
        if selectedQuestion == nil && preselectedQuestion == nil {
            selectedQuestion = driver.researchQuestion
        }
        removeMentionTextFromInput()
        dismissMentionPicker()
    }
    
    /// Removes the mention text (e.g., "@nvda" or "#ai") from the input
    private func removeMentionTextFromInput() {
        guard cursorPositionAtMention < taskText.count else { return }
        
        let startIndex = taskText.index(taskText.startIndex, offsetBy: cursorPositionAtMention)
        var endIndex = taskText.endIndex
        
        // Find the end of the mention (space or end of string)
        let searchRange = startIndex..<taskText.endIndex
        if let spaceIndex = taskText[searchRange].firstIndex(of: " ") {
            endIndex = spaceIndex
        }
        
        taskText.removeSubrange(startIndex..<endIndex)
        taskText = taskText.trimmingCharacters(in: .whitespaces)
    }
    
    /// Dismisses the mention picker
    private func dismissMentionPicker() {
        showQuestionPicker = false
        showDriverPicker = false
        mentionFilterText = ""
    }
    
    /// Creates a new task with the current input
    private func createTask() {
        let text = cleanTaskText
        guard !text.isEmpty else { return }
        
        // Determine the next position
        let position = (effectiveQuestion?.totalTaskCount ?? 0)
        
        let task = ResearchTask(
            text: text,
            position: position,
            isCompleted: false,
            researchQuestion: effectiveQuestion,
            driver: selectedDriver
        )
        
        modelContext.insert(task)
        
        // Update relationships
        if let question = effectiveQuestion {
            if selectedDriver == nil {
                // Direct link to question
                if question.tasks == nil {
                    question.tasks = []
                }
                question.tasks?.append(task)
            }
        }
        
        if let driver = selectedDriver {
            if driver.tasks == nil {
                driver.tasks = []
            }
            driver.tasks?.append(task)
        }
        
        // Call completion handler
        onTaskCreated?(task)
        
        // Reset input (keep preselected question but clear manual selections)
        taskText = ""
        if preselectedQuestion == nil {
            selectedQuestion = nil
        }
        selectedDriver = nil
        
        // Keep focus for rapid task entry
        isTextFieldFocused = true
    }
}

// MARK: - Question Badge

/// Badge displaying the selected research question
private struct QuestionBadge: View {
    let question: ResearchQuestion
    let isPreselected: Bool
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "at")
                .font(.caption2)
            
            Text(displayText)
                .font(.caption)
                .lineLimit(1)
            
            if !isPreselected {
                Button {
                    onRemove()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.15))
        .foregroundStyle(.blue)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
    
    private var displayText: String {
        if let ticker = question.asset?.ticker {
            return ticker
        }
        let text = question.questionText
        return text.count > 15 ? String(text.prefix(12)) + "..." : text
    }
}

// MARK: - Driver Badge

/// Badge displaying the selected driver
private struct DriverBadge: View {
    let driver: Driver
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "number")
                .font(.caption2)
            
            Text(displayText)
                .font(.caption)
                .lineLimit(1)
            
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.orange.opacity(0.15))
        .foregroundStyle(.orange)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
    
    private var displayText: String {
        let text = driver.title
        return text.count > 15 ? String(text.prefix(12)) + "..." : text
    }
}

// MARK: - Preview

#Preview("Task Input - Empty") {
    TaskInputField()
        .padding()
        .modelContainer(for: [ResearchTask.self, ResearchQuestion.self, Driver.self], inMemory: true)
}

#Preview("Task Input - With Preselected Question") {
    let container = try! ModelContainer(
        for: ResearchTask.self, ResearchQuestion.self, Driver.self,
        configurations: .init(isStoredInMemoryOnly: true)
    )
    
    let question = ResearchQuestion(questionText: "Can NVDA sustain AI growth?")
    container.mainContext.insert(question)
    
    return TaskInputField(preselectedQuestion: question)
        .padding()
        .modelContainer(container)
}

