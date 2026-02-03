/**
 EditableTaskField provides an inline task editor with @ and # mention support.
 
 Features:
 - Detects @ to show research question picker
 - Detects # to show driver picker (filtered by selected question)
 - Shows current question/driver as inline badges
 - Updates the task with proper relationships on save
 - Used when editing existing tasks in TodoistTaskRow
 */

import SwiftUI
import SwiftData

/// Reusable editable task field with @ and # mention support for existing tasks
struct EditableTaskField: View {
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Queries
    
    @Query(filter: #Predicate<ResearchQuestion> { $0.statusRaw == "Active" }, sort: \ResearchQuestion.updatedAt, order: .reverse)
    private var activeQuestions: [ResearchQuestion]
    
    // MARK: - Properties
    
    /// The task being edited
    @Bindable var task: ResearchTask
    
    /// Callback when editing is complete
    var onSave: () -> Void
    
    /// Callback when editing is cancelled
    var onCancel: () -> Void
    
    // MARK: - State
    
    @State private var editText: String = ""
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
        if let question = selectedQuestion {
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
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 8) {
            // Badges for selected items
            if let question = selectedQuestion {
                EditQuestionBadge(question: question) {
                    selectedQuestion = nil
                    selectedDriver = nil
                }
            }
            
            if let driver = selectedDriver {
                EditDriverBadge(driver: driver) {
                    selectedDriver = nil
                }
            }
            
            // Text field
            TextField("Task description", text: $editText)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .focused($isTextFieldFocused)
                .onSubmit {
                    saveEdit()
                }
                .onExitCommand {
                    onCancel()
                }
                .onChange(of: editText) { oldValue, newValue in
                    handleTextChange(oldValue: oldValue, newValue: newValue)
                }
        }
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
        .onAppear {
            // Initialize with current task values
            editText = task.text
            selectedQuestion = task.effectiveResearchQuestion
            selectedDriver = task.driver
            isTextFieldFocused = true
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
        if selectedQuestion == nil {
            selectedQuestion = driver.researchQuestion
        }
        removeMentionTextFromInput()
        dismissMentionPicker()
    }
    
    /// Removes the mention text (e.g., "@nvda" or "#ai") from the input
    private func removeMentionTextFromInput() {
        guard cursorPositionAtMention < editText.count else { return }
        
        let startIndex = editText.index(editText.startIndex, offsetBy: cursorPositionAtMention)
        var endIndex = editText.endIndex
        
        // Find the end of the mention (space or end of string)
        let searchRange = startIndex..<editText.endIndex
        if let spaceIndex = editText[searchRange].firstIndex(of: " ") {
            endIndex = spaceIndex
        }
        
        editText.removeSubrange(startIndex..<endIndex)
        editText = editText.trimmingCharacters(in: .whitespaces)
    }
    
    /// Dismisses the mention picker
    private func dismissMentionPicker() {
        showQuestionPicker = false
        showDriverPicker = false
        mentionFilterText = ""
    }
    
    /// Saves the edit with updated relationships
    private func saveEdit() {
        let trimmedText = editText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            onCancel()
            return
        }
        
        // Update task text
        task.text = trimmedText
        
        // Update research question relationship
        let oldQuestion = task.researchQuestion
        let newQuestion = selectedQuestion
        
        if oldQuestion?.questionId != newQuestion?.questionId {
            // Remove from old question
            if let old = oldQuestion {
                old.tasks?.removeAll { $0.taskId == task.taskId }
            }
            
            // Add to new question (if no driver, link directly)
            if selectedDriver == nil, let newQ = newQuestion {
                task.researchQuestion = newQ
                if newQ.tasks == nil {
                    newQ.tasks = []
                }
                newQ.tasks?.append(task)
            } else if selectedDriver == nil {
                task.researchQuestion = nil
            }
        }
        
        // Update driver relationship
        let oldDriver = task.driver
        let newDriver = selectedDriver
        
        if oldDriver?.driverId != newDriver?.driverId {
            // Remove from old driver
            if let old = oldDriver {
                old.tasks?.removeAll { $0.taskId == task.taskId }
            }
            
            // Add to new driver
            if let newD = newDriver {
                task.driver = newD
                if newD.tasks == nil {
                    newD.tasks = []
                }
                newD.tasks?.append(task)
                
                // If there's a driver, the question link goes through the driver
                // so clear direct question link
                task.researchQuestion = nil
            } else {
                task.driver = nil
                // Link directly to question if no driver
                if let newQ = newQuestion {
                    task.researchQuestion = newQ
                    if newQ.tasks == nil {
                        newQ.tasks = []
                    }
                    if !(newQ.tasks?.contains(where: { $0.taskId == task.taskId }) ?? false) {
                        newQ.tasks?.append(task)
                    }
                }
            }
        }
        
        onSave()
    }
}

// MARK: - Edit Question Badge

/// Badge displaying the selected research question during editing
private struct EditQuestionBadge: View {
    let question: ResearchQuestion
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "at")
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
        .background(Color.cyan.opacity(0.15))
        .foregroundStyle(.cyan)
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

// MARK: - Edit Driver Badge

/// Badge displaying the selected driver during editing
private struct EditDriverBadge: View {
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

#Preview {
    let container = try! ModelContainer(
        for: ResearchTask.self, ResearchQuestion.self, Driver.self,
        configurations: .init(isStoredInMemoryOnly: true)
    )
    
    let task = ResearchTask(text: "Test task")
    container.mainContext.insert(task)
    
    return EditableTaskField(
        task: task,
        onSave: { print("Saved") },
        onCancel: { print("Cancelled") }
    )
    .padding()
    .modelContainer(container)
}



