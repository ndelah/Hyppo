/**
 ResearchTasksView displays a lightweight checklist of research tasks grouped by driver.
 
 Features:
 - Tasks grouped under their parent driver
 - Inline checkbox toggle for completion
 - Quick-add field per driver
 - Completion progress indicator
 - Minimal chrome, fast interaction
 
 Designed to be iterative: start with 0 tasks, add as you go.
 Tasks are AI-ready: phrased as actionable research actions.
 */

import SwiftUI
import SwiftData

struct ResearchTasksView: View {
    let drivers: [Driver]
    
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Content
            if sortedTopLevelDrivers.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(sortedTopLevelDrivers) { driver in
                            DriverTasksSection(driver: driver)
                            
                            // Include sub-drivers
                            if let subs = driver.subDrivers?.sorted(by: { $0.position < $1.position }) {
                                ForEach(subs) { sub in
                                    DriverTasksSection(driver: sub, isSubDriver: true)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        )
    }
    
    // MARK: - Computed Properties
    
    private var sortedTopLevelDrivers: [Driver] {
        drivers.filter { $0.parentDriver == nil }.sorted { $0.position < $1.position }
    }
    
    private var totalTaskCount: Int {
        drivers.reduce(0) { $0 + $1.taskCount }
    }
    
    private var completedTaskCount: Int {
        drivers.reduce(0) { $0 + $1.completedTaskCount }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            Text("Research Tasks")
                .font(.headline)
            
            Spacer()
            
            if totalTaskCount > 0 {
                Text("\(completedTaskCount)/\(totalTaskCount) complete")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "checklist")
                .font(.title)
                .foregroundStyle(.tertiary)
            Text("No assumptions defined")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Add assumptions to create research tasks")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Driver Tasks Section

/**
 A section showing tasks for a single driver with inline add capability.
 */
struct DriverTasksSection: View {
    @Bindable var driver: Driver
    var isSubDriver: Bool = false
    
    @Environment(\.modelContext) private var modelContext
    
    @State private var newTaskText: String = ""
    @State private var isAddingTask: Bool = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Driver header
            HStack(spacing: 8) {
                if isSubDriver {
                    Text("→")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                
                Text(driver.title)
                    .font(isSubDriver ? .subheadline : .headline)
                    .fontWeight(isSubDriver ? .regular : .medium)
                
                Spacer()
                
                // Progress badge
                if driver.taskCount > 0 {
                    Text("\(driver.completedTaskCount)/\(driver.taskCount)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(progressColor.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            
            // Tasks list
            VStack(alignment: .leading, spacing: 4) {
                ForEach(driver.sortedTasks) { task in
                    TaskRowView(task: task, onDelete: { deleteTask(task) })
                }
                
                // Add task row
                if isAddingTask {
                    HStack(spacing: 8) {
                        Image(systemName: "circle")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        
                        TextField("Describe the research task...", text: $newTaskText)
                            .textFieldStyle(.plain)
                            .font(.subheadline)
                            .focused($isTextFieldFocused)
                            .onSubmit {
                                addTask()
                            }
                            .onExitCommand {
                                cancelAddTask()
                            }
                        
                        Button {
                            addTask()
                        } label: {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                        .buttonStyle(.plain)
                        .disabled(newTaskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        
                        Button {
                            cancelAddTask()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    Button {
                        isAddingTask = true
                        isTextFieldFocused = true
                    } label: {
                        Label("Add task", systemImage: "plus.circle")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.blue)
                    .padding(.top, 4)
                }
            }
            .padding(.leading, isSubDriver ? 16 : 0)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor).opacity(isSubDriver ? 0.3 : 0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - Computed Properties
    
    private var progressColor: Color {
        guard driver.taskCount > 0 else { return .gray }
        let ratio = Double(driver.completedTaskCount) / Double(driver.taskCount)
        if ratio >= 1.0 { return .green }
        if ratio >= 0.5 { return .blue }
        return .orange
    }
    
    // MARK: - Actions
    
    private func addTask() {
        let trimmed = newTaskText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let position = driver.taskCount
        let task = ResearchTask(text: trimmed, position: position, driver: driver)
        modelContext.insert(task)
        
        // Update driver's tasks array
        if driver.tasks == nil {
            driver.tasks = []
        }
        driver.tasks?.append(task)
        driver.updatedAt = Date()
        
        newTaskText = ""
        isAddingTask = false
    }
    
    private func cancelAddTask() {
        newTaskText = ""
        isAddingTask = false
    }
    
    private func deleteTask(_ task: ResearchTask) {
        driver.tasks?.removeAll { $0.taskId == task.taskId }
        modelContext.delete(task)
        driver.updatedAt = Date()
    }
}

// MARK: - Task Row View

/**
 A single task row with checkbox and delete capability.
 */
struct TaskRowView: View {
    @Bindable var task: ResearchTask
    let onDelete: () -> Void
    
    @State private var isHovering: Bool = false
    
    var body: some View {
        HStack(spacing: 8) {
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
            Text(task.text)
                .font(.subheadline)
                .strikethrough(task.isCompleted)
                .foregroundStyle(task.isCompleted ? .secondary : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Delete button (visible on hover)
            if isHovering {
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(isHovering ? Color(nsColor: .controlBackgroundColor).opacity(0.5) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - Preview

#Preview("Research Tasks") {
    let container = try! ModelContainer(
        for: Driver.self, ResearchQuestion.self, Evidence.self, ResearchTask.self,
        configurations: .init(isStoredInMemoryOnly: true)
    )
    
    let rq = ResearchQuestion(questionText: "Test Question")
    
    let driver1 = Driver(title: "AI demand continues growing", position: 0)
    driver1.researchQuestion = rq
    
    let driver2 = Driver(title: "NVIDIA maintains hardware lead", position: 1)
    driver2.researchQuestion = rq
    
    let sub1 = Driver(title: "H100 performance gap", position: 0, parentDriver: driver1)
    sub1.researchQuestion = rq
    
    let task1 = ResearchTask(text: "Read Q4 earnings call commentary", position: 0, isCompleted: true, driver: driver1)
    let task2 = ResearchTask(text: "Find YoY datacenter revenue growth", position: 1, driver: driver1)
    let task3 = ResearchTask(text: "Check hyperscaler capex guidance", position: 2, driver: driver1)
    let task4 = ResearchTask(text: "Compare H100 vs MI300 benchmarks", position: 0, driver: driver2)
    
    driver1.tasks = [task1, task2, task3]
    driver2.tasks = [task4]
    
    container.mainContext.insert(rq)
    container.mainContext.insert(driver1)
    container.mainContext.insert(driver2)
    container.mainContext.insert(sub1)
    container.mainContext.insert(task1)
    container.mainContext.insert(task2)
    container.mainContext.insert(task3)
    container.mainContext.insert(task4)
    
    return ResearchTasksView(drivers: [driver1, driver2])
        .frame(height: 500)
        .padding()
        .modelContainer(container)
}

