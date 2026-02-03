/**
 AllTasksListView displays all research tasks in a Todoist-style flat list.
 
 Features:
 - Always-visible task input field at the top with @ and # mention support
 - Flat list of tasks (not grouped by driver)
 - Tasks show @question and #driver badges
 - Supports filtering, searching, and pagination
 - Click task to edit, click badges to navigate
 */

import SwiftUI
import SwiftData

/// View displaying all tasks in a Todoist-style flat list
struct AllTasksListView: View {
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Queries
    
    @Query(sort: \ResearchTask.createdAt, order: .reverse)
    private var allTasks: [ResearchTask]
    
    // MARK: - Properties
    
    @Binding var navigationPath: NavigationPath
    
    // MARK: - State
    
    @State private var searchText = ""
    @State private var showCompletedTasks = false
    @State private var showInboxOnly = false
    @State private var currentPage = 0
    private let pageSize = 25
    
    // MARK: - Computed Properties
    
    /// Incomplete tasks (shown first)
    private var incompleteTasks: [ResearchTask] {
        allTasks.filter { !$0.isCompleted }
    }
    
    /// Completed tasks
    private var completedTasks: [ResearchTask] {
        allTasks.filter { $0.isCompleted }
    }
    
    /// Filtered tasks based on search and filters
    private var filteredTasks: [ResearchTask] {
        var result = showCompletedTasks ? allTasks : incompleteTasks
        
        // Filter to inbox only
        if showInboxOnly {
            result = result.filter { $0.isInbox }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            result = result.filter { task in
                task.text.lowercased().contains(searchLower) ||
                (task.driver?.title.lowercased().contains(searchLower) ?? false) ||
                (task.effectiveResearchQuestion?.questionText.lowercased().contains(searchLower) ?? false) ||
                (task.effectiveResearchQuestion?.asset?.ticker.lowercased().contains(searchLower) ?? false)
            }
        }
        
        return result
    }
    
    /// Total number of pages
    private var totalPages: Int {
        max(1, (filteredTasks.count + pageSize - 1) / pageSize)
    }
    
    /// Tasks for the current page
    private var pagedTasks: [ResearchTask] {
        let startIndex = currentPage * pageSize
        let endIndex = min(startIndex + pageSize, filteredTasks.count)
        
        guard startIndex < filteredTasks.count else { return [] }
        return Array(filteredTasks[startIndex..<endIndex])
    }
    
    /// Display range for pagination (e.g., "1-25")
    private var displayRange: String {
        guard !filteredTasks.isEmpty else { return "0" }
        let startIndex = currentPage * pageSize + 1
        let endIndex = min((currentPage + 1) * pageSize, filteredTasks.count)
        return "\(startIndex)-\(endIndex)"
    }
    
    /// Inbox task count
    private var inboxCount: Int {
        allTasks.filter { $0.isInbox && !$0.isCompleted }.count
    }
    
    // Active filter tags for display
    private var activeFilterTags: [ActiveFilterTag] {
        var tags: [ActiveFilterTag] = []
        
        if showInboxOnly {
            tags.append(ActiveFilterTag(
                id: "inbox",
                label: "Inbox",
                icon: "tray",
                color: .purple
            ))
        }
        
        if showCompletedTasks {
            tags.append(ActiveFilterTag(
                id: "completed",
                label: "Including Completed",
                icon: "checkmark.circle",
                color: .green
            ))
        }
        
        return tags
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar (with search bar)
            toolbar
            
            Divider()
            
            // Task input below search bar
            TaskInputField(
                placeholder: "Add a task... (@ for project, # for driver)"
            )
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
            // Content
            if filteredTasks.isEmpty {
                emptyState
            } else {
                tasksList
            }
        }
        .navigationTitle("")
    }
    
    // MARK: - Toolbar
    
    private var toolbar: some View {
        HStack(spacing: 12) {
            // Left side: Title with counts
            HStack(spacing: 8) {
                Text("Tasks")
                    .font(.headline)
                
                // Inbox badge
                if inboxCount > 0 {
                    Button {
                        showInboxOnly.toggle()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "tray")
                                .font(.caption2)
                            Text("\(inboxCount)")
                                .font(.caption)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(showInboxOnly ? Color.purple.opacity(0.2) : Color(nsColor: .controlBackgroundColor))
                        .foregroundStyle(showInboxOnly ? .purple : .secondary)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .help("Show inbox tasks only")
                }
            }
            
            Spacer()
            
            // Search bar with filter tags
            searchBarWithFilters
            
            Spacer()
            
            // Right side: Filters and pagination
            HStack(spacing: 16) {
                // Show completed toggle
                Toggle("Completed", isOn: $showCompletedTasks)
                    .toggleStyle(.checkbox)
                    .font(.caption)
                
                Divider()
                    .frame(height: 16)
                
                // Pagination
                paginationControls
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
    }
    
    // MARK: - Search Bar with Filter Tags
    
    private var searchBarWithFilters: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.caption)
            
            // Active filter tags
            ForEach(activeFilterTags) { tag in
                FilterTagView(tag: tag) {
                    removeFilter(tag)
                }
            }
            
            // Search field
            TextField("Search tasks...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.subheadline)
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(minWidth: 300, maxWidth: 450)
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        )
    }
    
    // MARK: - Pagination Controls
    
    private var paginationControls: some View {
        HStack(spacing: 8) {
            Text("\(displayRange) / \(filteredTasks.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
            
            HStack(spacing: 2) {
                Button {
                    if currentPage > 0 {
                        currentPage -= 1
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.caption)
                        .foregroundStyle(currentPage > 0 ? .primary : .tertiary)
                }
                .buttonStyle(.plain)
                .disabled(currentPage == 0)
                
                Button {
                    if currentPage < totalPages - 1 {
                        currentPage += 1
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(currentPage < totalPages - 1 ? .primary : .tertiary)
                }
                .buttonStyle(.plain)
                .disabled(currentPage >= totalPages - 1)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "checklist")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            
            Text(emptyStateTitle)
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text(emptyStateDescription)
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    private var emptyStateTitle: String {
        if showInboxOnly {
            return "Inbox Empty"
        } else if !searchText.isEmpty {
            return "No Matching Tasks"
        } else {
            return "No Tasks Yet"
        }
    }
    
    private var emptyStateDescription: String {
        if showInboxOnly {
            return "Tasks without a project or driver will appear here."
        } else if !searchText.isEmpty {
            return "Try a different search term or clear filters."
        } else {
            return "Add your first task using the input above. Use @ to assign a project and # to assign a driver."
        }
    }
    
    // MARK: - Tasks List
    
    private var tasksList: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(pagedTasks) { task in
                    TodoistTaskRow(
                        task: task,
                        onNavigateToQuestion: {
                            if let question = task.effectiveResearchQuestion {
                                navigationPath.append(question)
                            }
                        },
                        onDelete: {
                            deleteTask(task)
                        }
                    )
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 24)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    // MARK: - Actions
    
    private func removeFilter(_ tag: ActiveFilterTag) {
        switch tag.id {
        case "inbox":
            showInboxOnly = false
        case "completed":
            showCompletedTasks = false
        default:
            break
        }
    }
    
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

// MARK: - Todoist-Style Task Row

/// A Todoist-inspired task row with checkbox, text, badges, and date
struct TodoistTaskRow: View {
    @Bindable var task: ResearchTask
    let onNavigateToQuestion: () -> Void
    let onDelete: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    
    @State private var isHovering = false
    @State private var isEditing = false
    @State private var editText = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
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
            
            // Task text (editable)
            if isEditing {
                TextField("Task description", text: $editText)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        saveEdit()
                    }
                    .onExitCommand {
                        cancelEdit()
                    }
            } else {
                Text(task.text)
                    .font(.body)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .lineLimit(2)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        startEditing()
                    }
            }
            
            Spacer()
            
            // Badges and metadata
            HStack(spacing: 8) {
                // Research question badge
                if let question = task.effectiveResearchQuestion {
                    Button {
                        onNavigateToQuestion()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "at")
                                .font(.caption2)
                            Text(questionBadgeText(question))
                                .font(.caption)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.blue.opacity(0.12))
                        .foregroundStyle(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)
                    .help(question.questionText)
                }
                
                // Driver badge
                if let driver = task.driver {
                    HStack(spacing: 4) {
                        Image(systemName: "number")
                            .font(.caption2)
                        Text(driverBadgeText(driver))
                            .font(.caption)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.orange.opacity(0.12))
                    .foregroundStyle(.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .help(driver.title)
                }
                
                // Inbox indicator (no question or driver)
                if task.isInbox {
                    HStack(spacing: 4) {
                        Image(systemName: "tray")
                            .font(.caption2)
                        Text("Inbox")
                            .font(.caption)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.purple.opacity(0.12))
                    .foregroundStyle(.purple)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                
                // Date
                Text(dateText)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(minWidth: 50, alignment: .trailing)
                
                // Delete button (visible on hover)
                if isHovering && !isEditing {
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundStyle(.red.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovering || isEditing ? Color(nsColor: .controlBackgroundColor).opacity(0.5) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
    
    // MARK: - Helpers
    
    private func questionBadgeText(_ question: ResearchQuestion) -> String {
        if let ticker = question.asset?.ticker {
            return ticker
        }
        let text = question.questionText
        return text.count > 12 ? String(text.prefix(10)) + "..." : text
    }
    
    private func driverBadgeText(_ driver: Driver) -> String {
        let text = driver.title
        return text.count > 12 ? String(text.prefix(10)) + "..." : text
    }
    
    private var dateText: String {
        let date = task.completedAt ?? task.createdAt
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
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

// MARK: - Active Filter Tag Model

/// Represents an active filter displayed as a tag in the search bar
struct ActiveFilterTag: Identifiable {
    let id: String
    let label: String
    let icon: String
    let color: Color
}

// MARK: - Filter Tag View

/// Displays an active filter as a rectangular tag with icon, color, and remove button
struct FilterTagView: View {
    let tag: ActiveFilterTag
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: tag.icon)
                .font(.caption2)
            
            Text(tag.label)
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
        .background(tag.color.opacity(0.15))
        .foregroundStyle(tag.color)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - Preview

#Preview {
    AllTasksListView(navigationPath: .constant(NavigationPath()))
        .modelContainer(for: [ResearchTask.self, Driver.self, ResearchQuestion.self, Asset.self], inMemory: true)
        .frame(width: 900, height: 600)
}
