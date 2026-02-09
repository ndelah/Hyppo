/**
 ResearchTasksView displays a Todoist-style flat list of tasks for a research question.
 
 Features:
 - Task input field at top with @ and # mention support
 - Pre-filled with current research question
 - @ works to reassign to different question
 - # can assign to any driver of the selected question
 - Simple flat list like Todoist
 - Completion progress indicator
 */

import SwiftUI
import SwiftData

struct ResearchTasksView: View {
    let researchQuestion: ResearchQuestion
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - State
    
    @State private var showCompletedTasks = false
    
    // MARK: - Computed Properties
    
    /// All tasks for this research question (direct + through drivers)
    private var allTasks: [ResearchTask] {
        researchQuestion.sortedTasks
    }
    
    /// Incomplete tasks
    private var incompleteTasks: [ResearchTask] {
        allTasks.filter { !$0.isCompleted }
    }
    
    /// Completed tasks
    private var completedTasks: [ResearchTask] {
        allTasks.filter { $0.isCompleted }
    }
    
    /// Tasks to display based on filter
    private var displayedTasks: [ResearchTask] {
        showCompletedTasks ? allTasks : incompleteTasks
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with progress
            headerView
            
            Divider()
            
            // Task input
            TaskInputField(
                preselectedQuestion: researchQuestion,
                placeholder: "Add a task... (# for driver)"
            )
            .padding(12)
            
            Divider()
            
            // Tasks list
            if displayedTasks.isEmpty {
                emptyState
            } else {
                tasksList
            }
            
            // Completed section toggle
            if !completedTasks.isEmpty {
                completedToggle
            }
        }
        .background(Color.surface.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.appBorder, lineWidth: 1)
        )
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            Text("Tasks")
                .font(.headline)
            
            Spacer()
            
            // Progress indicator
            if !allTasks.isEmpty {
                progressBadge
            }
        }
        .padding()
        .background(Color.surface)
    }
    
    private var progressBadge: some View {
        HStack(spacing: 6) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.appBorder)
                        .frame(height: 4)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 2)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * progressRatio, height: 4)
                }
            }
            .frame(width: 40, height: 4)
            
            // Count text
            Text("\(completedTasks.count)/\(allTasks.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.surface)
        .clipShape(Capsule())
    }
    
    private var progressRatio: CGFloat {
        guard !allTasks.isEmpty else { return 0 }
        return CGFloat(completedTasks.count) / CGFloat(allTasks.count)
    }
    
    private var progressColor: Color {
        if progressRatio >= 1.0 { return Color.statusActive }
        if progressRatio >= 0.5 { return Color.accentColor }
        return .statusOnHold
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "checklist")
                .font(.title)
                .foregroundStyle(.tertiary)
            Text("No tasks yet")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Add tasks above to track your research progress")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Tasks List
    
    private var tasksList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(displayedTasks) { task in
                    SimpleTaskRow(
                        task: task,
                        showDriver: true,
                        onDelete: { deleteTask(task) }
                    )
                    
                    if task.taskId != displayedTasks.last?.taskId {
                        Divider()
                            .padding(.leading, 40)
                    }
                }
            }
            .padding(.horizontal, 8)
        }
    }
    
    // MARK: - Completed Toggle
    
    private var completedToggle: some View {
        VStack(spacing: 0) {
            Divider()
            
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showCompletedTasks.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: showCompletedTasks ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 16)
                    
                    Text("Completed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("(\(completedTasks.count))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(Color.surface)
        }
    }
    
    // MARK: - Actions
    
    private func deleteTask(_ task: ResearchTask) {
        // Remove from relationships
        if let question = task.researchQuestion {
            question.tasks?.removeAll { $0.taskId == task.taskId }
        }
        if let driver = task.driver {
            driver.tasks?.removeAll { $0.taskId == task.taskId }
        }
        modelContext.delete(task)
    }
}

// MARK: - Simple Task Row

/// A minimal task row for display within a research question
struct SimpleTaskRow: View {
    @Bindable var task: ResearchTask
    var showDriver: Bool = true
    let onDelete: () -> Void
    
    @State private var isHovering = false
    @State private var isEditing = false
    @State private var editText = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Checkbox
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    task.toggleCompletion()
                }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.body)
                    .foregroundStyle(task.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
            
            // Task text
            if isEditing {
                HStack(spacing: 6) {
                    TextField("Task description", text: $editText)
                        .textFieldStyle(.plain)
                        .font(.subheadline)
                        .focused($isTextFieldFocused)
                        .onSubmit { saveEdit() }
                        .onExitCommand { cancelEdit() }
                    
                    Button { saveEdit() } label: {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .foregroundStyle(Color.statusActive)
                    }
                    .buttonStyle(.plain)
                    
                    Button { cancelEdit() } label: {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.text)
                        .font(.subheadline)
                        .strikethrough(task.isCompleted)
                        .foregroundStyle(task.isCompleted ? .secondary : .primary)
                        .lineLimit(2)
                        .contentShape(Rectangle())
                        .onTapGesture { startEditing() }
                    
                    // Driver badge
                    if showDriver, let driver = task.driver {
                        HStack(spacing: 4) {
                            Image(systemName: "number")
                                .font(.caption2)
                            Text(driver.title)
                                .font(.caption2)
                                .lineLimit(1)
                        }
                        .foregroundStyle(Color.statusOnHold.opacity(0.8))
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            // Delete button (visible on hover)
            if isHovering && !isEditing {
                Button {
                    withAnimation {
                        onDelete()
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(Color.statusInvalidated.opacity(0.6))
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isHovering || isEditing ? Color.surface : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovering = hovering
            }
        }
    }
    
    // MARK: - Edit Actions
    
    private func startEditing() {
        editText = task.text
        isEditing = true
        isTextFieldFocused = true
    }
    
    private func saveEdit() {
        let trimmed = editText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            task.text = trimmed
        }
        isEditing = false
    }
    
    private func cancelEdit() {
        isEditing = false
        editText = ""
    }
}

// MARK: - Legacy Support

/// Legacy view that accepts drivers array for backward compatibility
/// This redirects to the new implementation using ResearchQuestion
extension ResearchTasksView {
    init(drivers: [Driver]) {
        // Get the research question from the first driver
        if let firstDriver = drivers.first, let question = firstDriver.researchQuestion {
            self.init(researchQuestion: question)
        } else {
            // Fallback: create a placeholder question (should not happen in practice)
            self.init(researchQuestion: ResearchQuestion(questionText: "Unknown"))
        }
    }
}

// MARK: - Preview

#Preview("Research Tasks") {
    let container = try! ModelContainer(
        for: Driver.self, ResearchQuestion.self, ResearchTask.self, Asset.self,
        configurations: .init(isStoredInMemoryOnly: true)
    )
    
    let asset = Asset(ticker: "NVDA", name: "NVIDIA Corporation")
    let rq = ResearchQuestion(questionText: "Can NVDA sustain AI growth?")
    rq.asset = asset
    
    let driver1 = Driver(title: "AI demand continues growing", position: 0)
    driver1.researchQuestion = rq
    
    let driver2 = Driver(title: "NVIDIA maintains hardware lead", position: 1)
    driver2.researchQuestion = rq
    
    let task1 = ResearchTask(text: "Read Q4 earnings call commentary", position: 0, isCompleted: true, researchQuestion: rq, driver: driver1)
    let task2 = ResearchTask(text: "Find YoY datacenter revenue growth", position: 1, researchQuestion: rq, driver: driver1)
    let task3 = ResearchTask(text: "Check hyperscaler capex guidance", position: 2, researchQuestion: rq)
    
    container.mainContext.insert(asset)
    container.mainContext.insert(rq)
    container.mainContext.insert(driver1)
    container.mainContext.insert(driver2)
    container.mainContext.insert(task1)
    container.mainContext.insert(task2)
    container.mainContext.insert(task3)
    
    return ResearchTasksView(researchQuestion: rq)
        .frame(width: 400, height: 500)
        .padding()
        .modelContainer(container)
}
