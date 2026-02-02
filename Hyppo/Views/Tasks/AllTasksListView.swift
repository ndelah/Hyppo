/**
 AllTasksListView displays all research tasks across all research questions.
 
 Features:
 - Shows tasks grouped by their parent driver/research question
 - Supports filtering and searching
 - Links back to the parent research question
 - Pagination support
 */

import SwiftUI
import SwiftData

/// View displaying all tasks from all research questions
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
    @State private var showCompletedTasks = true
    @State private var currentPage = 0
    private let pageSize = 25
    
    // MARK: - Computed Properties
    
    /// Filtered tasks based on search and completion filter
    private var filteredTasks: [ResearchTask] {
        var result = allTasks
        
        // Filter by completion status
        if !showCompletedTasks {
            result = result.filter { !$0.isCompleted }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            result = result.filter { task in
                task.text.lowercased().contains(searchLower) ||
                (task.driver?.title.lowercased().contains(searchLower) ?? false) ||
                (task.driver?.researchQuestion?.questionText.lowercased().contains(searchLower) ?? false)
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
    
    // Active filter tags for display
    private var activeFilterTags: [ActiveFilterTag] {
        var tags: [ActiveFilterTag] = []
        
        if !showCompletedTasks {
            tags.append(ActiveFilterTag(
                id: "incomplete",
                label: "Incomplete Only",
                icon: "circle",
                color: .blue
            ))
        }
        
        return tags
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbar
            
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
            // Left side: Title
            Text("All Tasks")
                .font(.headline)
            
            Spacer()
            
            // Search bar with filter tags
            searchBarWithFilters
            
            Spacer()
            
            // Right side: Pagination and toggle
            HStack(spacing: 16) {
                // Show completed toggle
                Toggle("Show Completed", isOn: $showCompletedTasks)
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
            
            Text("No Tasks Found")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text("Tasks will appear here when you create them from research questions.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    // MARK: - Tasks List
    
    private var tasksList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(pagedTasks) { task in
                    TaskCardView(task: task) {
                        // Navigate to the research question
                        if let question = task.driver?.researchQuestion {
                            navigationPath.append(question)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    // MARK: - Actions
    
    private func removeFilter(_ tag: ActiveFilterTag) {
        switch tag.id {
        case "incomplete":
            showCompletedTasks = true
        default:
            break
        }
    }
}

// MARK: - Task Card View

/// Card view for displaying a single task with context
struct TaskCardView: View {
    @Bindable var task: ResearchTask
    let onNavigateToQuestion: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    task.toggleCompletion()
                }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(task.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
            
            // Task content
            VStack(alignment: .leading, spacing: 4) {
                Text(task.text)
                    .font(.body)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                
                // Context info
                HStack(spacing: 8) {
                    if let driver = task.driver {
                        Label(driver.title, systemImage: "target")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    
                    if let question = task.driver?.researchQuestion {
                        Text("•")
                            .foregroundStyle(.tertiary)
                        
                        Button {
                            onNavigateToQuestion()
                        } label: {
                            Text(question.questionText)
                                .font(.caption)
                                .foregroundStyle(.blue)
                                .lineLimit(1)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Spacer()
            
            // Completion date or created date
            if let completedAt = task.completedAt {
                Text(completedAt, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            } else {
                Text(task.createdAt, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovering ? Color(nsColor: .controlBackgroundColor) : Color(nsColor: .textBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        )
        .onHover { hovering in
            isHovering = hovering
        }
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
        .modelContainer(for: [ResearchTask.self, Driver.self, ResearchQuestion.self], inMemory: true)
        .frame(width: 900, height: 600)
}

