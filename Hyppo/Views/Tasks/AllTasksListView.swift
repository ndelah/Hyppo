/**
 AllTasksListView displays all research tasks in a Todoist-style flat list.
 
 Features:
 - Always-visible task input field at the top with @ and # mention support
 - Flat list of tasks (not grouped by driver)
 - Tasks show @question and #driver badges
 - Advanced search bar with filters, group by, and saved searches
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
    
    @Query(sort: \Tag.name) private var allTags: [Tag]
    
    // MARK: - Properties
    
    @Binding var navigationPath: NavigationPath
    
    // MARK: - Accessibility
    
    @AppStorage("textSizeMultiplier") private var textSizeMultiplier: Double = 1.0
    
    // MARK: - State
    
    @State private var config = TaskViewConfiguration.shared
    @State private var searchText = ""
    @State private var showingSearchPopover = false
    @State private var currentPage = 0
    private let pageSize = 50
    
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
        var result = config.activeShowCompletedTasks ? allTasks : incompleteTasks
        
        // Filter to inbox only
        if config.activeShowInboxOnly {
            result = result.filter { $0.isInbox }
        }
        
        // Filter by research question IDs
        if !config.activeResearchQuestionIds.isEmpty {
            result = result.filter { task in
                guard let question = task.effectiveResearchQuestion else { return false }
                return config.activeResearchQuestionIds.contains(question.questionId)
            }
        }
        
        // Filter by tag IDs (through research question tags)
        if !config.activeTagIds.isEmpty {
            result = result.filter { task in
                guard let question = task.effectiveResearchQuestion,
                      let questionTags = question.tags else { return false }
                return questionTags.contains { config.activeTagIds.contains($0.tagId) }
            }
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
    
    /// Group tasks based on the current group by setting (uses pagedTasks for pagination)
    private var groupedTasks: [(String, [ResearchTask])] {
        switch config.groupByColumn {
        case .none:
            return [("", pagedTasks)]
            
        case .researchQuestion:
            let grouped = Dictionary(grouping: pagedTasks) { task -> String in
                if let question = task.effectiveResearchQuestion {
                    if let ticker = question.asset?.ticker {
                        return ticker
                    }
                    let text = question.questionText
                    return text.count > 30 ? String(text.prefix(27)) + "..." : text
                }
                return "Inbox"
            }
            return grouped.sorted { $0.key < $1.key }
            
        case .driver:
            let grouped = Dictionary(grouping: pagedTasks) { task -> String in
                if let driver = task.driver {
                    return driver.title
                }
                return "No Driver"
            }
            return grouped.sorted { $0.key < $1.key }
            
        case .tags:
            // Group by first tag of the research question
            let grouped = Dictionary(grouping: pagedTasks) { task -> String in
                if let question = task.effectiveResearchQuestion,
                   let firstTag = question.tags?.first {
                    return firstTag.name
                }
                return "Untagged"
            }
            return grouped.sorted { $0.key < $1.key }
            
        case .status:
            let grouped = Dictionary(grouping: pagedTasks) { task -> String in
                task.isCompleted ? "Completed" : "Incomplete"
            }
            // Show incomplete first
            return grouped.sorted { $0.key > $1.key }
            
        case .createdDate:
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"
            let grouped = Dictionary(grouping: pagedTasks) { task -> String in
                formatter.string(from: task.createdAt)
            }
            return grouped.sorted { $0.key > $1.key }
        }
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
    private var activeFilterTags: [TaskActiveFilterTag] {
        var tags: [TaskActiveFilterTag] = []
        
        if config.activeShowInboxOnly {
            tags.append(TaskActiveFilterTag(
                id: "inbox",
                label: "Inbox",
                icon: "tray",
                color: .purple,
                filterType: .inbox
            ))
        }
        
        if config.activeShowCompletedTasks {
            tags.append(TaskActiveFilterTag(
                id: "completed",
                label: "Including Completed",
                icon: "checkmark.circle",
                color: Color.statusActive,
                filterType: .completed
            ))
        }
        
        // Research question filters
        for questionId in config.activeResearchQuestionIds {
            if let question = filteredTasks.first(where: { $0.effectiveResearchQuestion?.questionId == questionId })?.effectiveResearchQuestion {
                let label = question.asset?.ticker ?? String(question.questionText.prefix(15))
                tags.append(TaskActiveFilterTag(
                    id: "question_\(questionId.uuidString)",
                    label: label,
                    icon: "doc.text.magnifyingglass",
                    color: Color.accentColor,
                    filterType: .researchQuestion(questionId)
                ))
            }
        }
        
        // Tag filters
        for tagId in config.activeTagIds {
            if let tag = allTags.first(where: { $0.tagId == tagId }) {
                tags.append(TaskActiveFilterTag(
                    id: "tag_\(tagId.uuidString)",
                    label: tag.name,
                    icon: "tag",
                    color: tagColor(for: tag),
                    filterType: .tag(tagId)
                ))
            }
        }
        
        // Group by
        if config.groupByColumn != .none {
            tags.append(TaskActiveFilterTag(
                id: "groupby",
                label: config.groupByColumn.displayName,
                icon: "rectangle.3.group",
                color: .purple,
                filterType: .groupBy
            ))
        }
        
        return tags
    }
    
    /// Get color for a tag
    private func tagColor(for tag: Tag) -> Color {
        guard let colorName = tag.colorName,
              let tagColorEnum = TagColor(rawValue: colorName) else {
            return Color.accentColor
        }
        return tagColorEnum.color
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar (with search bar)
            toolbar
            
            Divider()
            
            // Task input below search bar (full width)
            TaskInputField(
                placeholder: "Add a task... (@ for project, # for driver)"
            )
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.surface)
            
            Divider()
            
            // Content (centered with max width)
            if filteredTasks.isEmpty {
                emptyState
            } else {
                tasksList
            }
        }
        .navigationTitle("")
        .onChange(of: filteredTasks.count) { _, _ in
            // Reset to first page when filtered tasks change (e.g., filtering)
            currentPage = 0
        }
    }
    
    // MARK: - Toolbar
    
    private var toolbar: some View {
        HStack(spacing: 12) {
            // Left side: Title with counts
            HStack(spacing: 8) {
                Text("Tasks")
                    .font(.system(size: 15 * textSizeMultiplier, weight: .semibold))
                
                // Inbox badge
                if inboxCount > 0 {
                    Button {
                        config.activeShowInboxOnly.toggle()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "tray")
                                .font(.system(size: 10 * textSizeMultiplier))
                            Text("\(inboxCount)")
                                .font(.system(size: 11 * textSizeMultiplier))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(config.activeShowInboxOnly ? Color.purple.opacity(0.2) : Color.surface)
                        .foregroundStyle(config.activeShowInboxOnly ? .purple : .secondary)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .help("Show inbox tasks only")
                }
            }
            
            Spacer()
            
            // Search bar with filter tags (Odoo-style popover)
            searchBarWithFilterTags
            
            Spacer()
            
            // Right side: Pagination
            paginationControls
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(Color.surfaceSecondary)
    }
    
    // MARK: - Search Bar with Filter Tags (Odoo-style)
    
    /// Search bar that displays active filters as rectangular tags and opens popover
    private var searchBarWithFilterTags: some View {
        Button {
            showingSearchPopover = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 11 * textSizeMultiplier))
                
                // Active filter tags displayed inside the search bar
                ForEach(activeFilterTags) { tag in
                    TaskFilterTagView(tag: tag) {
                        removeFilter(tag)
                    }
                }
                
                // Search text or placeholder
                if !searchText.isEmpty {
                    Text(searchText)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .font(.system(size: 13 * textSizeMultiplier))
                    
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 11 * textSizeMultiplier))
                    }
                    .buttonStyle(.plain)
                } else if activeFilterTags.isEmpty {
                    Text("Search...")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 13 * textSizeMultiplier))
                }
                
                Spacer(minLength: 0)
                
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(minWidth: 300, maxWidth: 500)
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.appBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showingSearchPopover, arrowEdge: .bottom) {
            VStack(spacing: 0) {
                // Inline search field in popover
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    
                    TextField("Search tasks, projects...", text: $searchText)
                        .textFieldStyle(.plain)
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                .background(Color.surface)
                
                Divider()
                
                TaskSearchPopoverView(config: config, searchText: $searchText)
            }
        }
    }
    
    // MARK: - Pagination Controls
    
    private var paginationControls: some View {
        HStack(spacing: 8) {
            Text("\(displayRange) / \(filteredTasks.count)")
                .font(.system(size: 11 * textSizeMultiplier))
                .foregroundStyle(.secondary)
                .monospacedDigit()
            
            HStack(spacing: 2) {
                Button {
                    if currentPage > 0 {
                        currentPage -= 1
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11 * textSizeMultiplier))
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
                        .font(.system(size: 11 * textSizeMultiplier))
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
                .font(.system(size: 48 * textSizeMultiplier))
                .foregroundStyle(.tertiary)
            
            Text(emptyStateTitle)
                .font(.system(size: 15 * textSizeMultiplier, weight: .semibold))
                .foregroundStyle(.secondary)
            
            Text(emptyStateDescription)
                .font(.system(size: 13 * textSizeMultiplier))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.surface)
    }
    
    private var emptyStateTitle: String {
        if config.activeShowInboxOnly {
            return "Inbox Empty"
        } else if !searchText.isEmpty {
            return "No Matching Tasks"
        } else {
            return "No Tasks Yet"
        }
    }
    
    private var emptyStateDescription: String {
        if config.activeShowInboxOnly {
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
                // Handle grouping
                if config.groupByColumn != .none {
                    ForEach(groupedTasks, id: \.0) { groupName, tasks in
                        // Group header
                        HStack {
                            Text(groupName)
                                .font(.system(size: 12 * textSizeMultiplier, weight: .semibold))
                                .foregroundStyle(.secondary)
                            
                            Text("(\(tasks.count))")
                                .font(.system(size: 11 * textSizeMultiplier))
                                .foregroundStyle(.tertiary)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 16)
                        .padding(.bottom, 4)
                        
                        // Tasks in group
                        ForEach(tasks) { task in
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
                } else {
                    // Flat list (no grouping)
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
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 24)
        }
        .id("\(currentPage)-\(config.groupByColumn.rawValue)") // Force re-render when page or grouping changes
        .background(Color.surface)
    }
    
    // MARK: - Actions
    
    private func removeFilter(_ tag: TaskActiveFilterTag) {
        switch tag.filterType {
        case .inbox:
            config.activeShowInboxOnly = false
        case .completed:
            config.activeShowCompletedTasks = false
        case .researchQuestion(let questionId):
            config.activeResearchQuestionIds.remove(questionId)
        case .tag(let tagId):
            config.activeTagIds.remove(tagId)
        case .groupBy:
            config.groupByColumn = .none
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
/// Responsive: hides less important badges at narrow widths
/// Supports @ and # mentions when editing
struct TodoistTaskRow: View {
    @Bindable var task: ResearchTask
    let onNavigateToQuestion: () -> Void
    let onDelete: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    @AppStorage("textSizeMultiplier") private var textSizeMultiplier: Double = 1.0
    
    @State private var isHovering = false
    @State private var isEditing = false
    @State private var rowWidth: CGFloat = 600
    
    // MARK: - Responsive Thresholds
    
    /// Width below which driver badge is hidden
    private let hideDriverThreshold: CGFloat = 500
    /// Width below which date is hidden
    private let hideDateThreshold: CGFloat = 400
    /// Width below which inbox badge is hidden
    private let hideInboxThreshold: CGFloat = 450
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    task.toggleCompletion()
                }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14 * textSizeMultiplier))
                    .foregroundStyle(task.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
            
            // Task text (editable with @ and # mention support)
            if isEditing {
                EditableTaskField(
                    task: task,
                    onSave: {
                        isEditing = false
                    },
                    onCancel: {
                        isEditing = false
                    }
                )
            } else {
                Text(task.text)
                    .font(.system(size: 14 * textSizeMultiplier))
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .lineLimit(2)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        startEditing()
                    }
            }
            
            Spacer()
            
            // Badges and metadata (responsive) - hide when editing
            if !isEditing {
                HStack(spacing: 8) {
                    // Research question badge (always shown - most important)
                    if let question = task.effectiveResearchQuestion {
                        Button {
                            onNavigateToQuestion()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "at")
                                    .font(.system(size: 11 * textSizeMultiplier))
                                Text(questionBadgeText(question))
                                    .font(.system(size: 12 * textSizeMultiplier))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.assetColor.opacity(0.12))
                            .foregroundStyle(Color.assetColor)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        .buttonStyle(.plain)
                        .help(question.questionText)
                    }
                    
                    // Driver badge (hidden at narrow widths)
                    if let driver = task.driver, rowWidth >= hideDriverThreshold {
                        HStack(spacing: 4) {
                            Image(systemName: "number")
                                .font(.system(size: 11 * textSizeMultiplier))
                            Text(driverBadgeText(driver))
                                .font(.system(size: 12 * textSizeMultiplier))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.statusOnHold.opacity(0.12))
                        .foregroundStyle(Color.statusOnHold)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .help(driver.title)
                    }
                    
                    // Inbox indicator (hidden at narrow widths)
                    if task.isInbox && rowWidth >= hideInboxThreshold {
                        HStack(spacing: 4) {
                            Image(systemName: "tray")
                                .font(.system(size: 11 * textSizeMultiplier))
                            Text("Inbox")
                                .font(.system(size: 12 * textSizeMultiplier))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.12))
                        .foregroundStyle(.purple)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    
                    // Date (hidden at very narrow widths)
                    if rowWidth >= hideDateThreshold {
                        Text(dateText)
                            .font(.system(size: 12 * textSizeMultiplier))
                            .foregroundStyle(.tertiary)
                            .frame(minWidth: 50, alignment: .trailing)
                    }
                    
                    // Delete button (visible on hover)
                    if isHovering {
                        Button {
                            onDelete()
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 12 * textSizeMultiplier))
                                .foregroundStyle(Color.statusInvalidated.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear { rowWidth = geometry.size.width }
                    .onChange(of: geometry.size.width) { _, newWidth in
                        rowWidth = newWidth
                    }
            }
        )
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovering || isEditing ? Color.surface : Color.clear)
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
        isEditing = true
    }
}

// MARK: - Task Active Filter Tag Model

/// Filter type for task filters
enum TaskFilterType {
    case inbox
    case completed
    case researchQuestion(UUID)
    case tag(UUID)
    case groupBy
}

/// Represents an active filter displayed as a tag in the search bar
struct TaskActiveFilterTag: Identifiable {
    let id: String
    let label: String
    let icon: String
    let color: Color
    let filterType: TaskFilterType
}

// MARK: - Task Filter Tag View

/// Displays an active filter as a rectangular tag with icon, color, and remove button (Odoo-style)
struct TaskFilterTagView: View {
    let tag: TaskActiveFilterTag
    let onRemove: () -> Void
    
    @AppStorage("textSizeMultiplier") private var textSizeMultiplier: Double = 1.0
    
    var body: some View {
        HStack(spacing: 4) {
            // Colored icon
            Image(systemName: tag.icon)
                .font(.system(size: 11 * textSizeMultiplier))
                .foregroundStyle(tag.color)
            
            // Label
            Text(tag.label)
                .font(.system(size: 12 * textSizeMultiplier))
                .foregroundStyle(.primary)
                .lineLimit(1)
            
            // Remove button
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9 * textSizeMultiplier, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(tag.color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(tag.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    AllTasksListView(navigationPath: .constant(NavigationPath()))
        .modelContainer(for: [ResearchTask.self, Driver.self, ResearchQuestion.self, Asset.self], inMemory: true)
        .frame(width: 900, height: 600)
}
