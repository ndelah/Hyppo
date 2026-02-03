/**
 TaskSearchPopoverView provides an advanced search interface for tasks.
 
 Modeled after SearchPopoverView but tailored for task filtering:
 - Filters: Inbox, completed, research projects, tags
 - Group By: Options to group tasks by project, driver, tags, or status
 - Favorites: Save and apply search configurations
 */

import SwiftUI
import SwiftData

/// Advanced search popover for tasks with filters, group by, and saved searches
struct TaskSearchPopoverView: View {
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Queries
    
    @Query(filter: #Predicate<ResearchQuestion> { $0.statusRaw == "Active" }, sort: \ResearchQuestion.updatedAt, order: .reverse)
    private var activeQuestions: [ResearchQuestion]
    
    @Query(sort: \Tag.name) private var allTags: [Tag]
    
    // MARK: - Properties
    
    @Bindable var config: TaskViewConfiguration
    @Binding var searchText: String
    
    // MARK: - State
    
    @State private var showingSaveDialog = false
    @State private var newSearchName = ""
    @State private var expandedSection: ExpandedSection = .filters
    
    // MARK: - Section Enum
    
    enum ExpandedSection: String, CaseIterable {
        case filters = "Filters"
        case groupBy = "Group By"
        case favorites = "Favorites"
        
        var iconName: String {
            switch self {
            case .filters: return "line.3.horizontal.decrease.circle"
            case .groupBy: return "rectangle.3.group"
            case .favorites: return "star"
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
            
            // Horizontal tab bar
            tabBar
            
            Divider()
            
            // Content area
            ScrollView {
                selectedSectionContent
                    .padding()
            }
            
            Divider()
            
            // Footer
            footer
        }
        .frame(width: 580, height: 400)
        .background(Color(nsColor: .windowBackgroundColor))
        .alert("Save Search", isPresented: $showingSaveDialog) {
            TextField("Search name", text: $newSearchName)
            Button("Cancel", role: .cancel) {
                newSearchName = ""
            }
            Button("Save") {
                saveCurrentSearch()
            }
            .disabled(newSearchName.trimmingCharacters(in: .whitespaces).isEmpty)
        } message: {
            Text("Enter a name for this search configuration")
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Text("Search Options")
                .font(.headline)
            
            Spacer()
            
            if config.hasActiveFilters || config.groupByColumn != .none {
                Button {
                    clearAll()
                } label: {
                    Text("Clear All")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
    }
    
    // MARK: - Tab Bar
    
    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(ExpandedSection.allCases, id: \.self) { section in
                tabButton(for: section)
                
                if section != ExpandedSection.allCases.last {
                    Divider()
                        .frame(height: 24)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func tabButton(for section: ExpandedSection) -> some View {
        let badgeCount: Int = {
            switch section {
            case .filters: return config.activeFilterCount
            case .groupBy: return config.groupByColumn != .none ? 1 : 0
            case .favorites: return config.savedSearches.count
            }
        }()
        
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                expandedSection = section
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: section.iconName)
                    .font(.caption)
                
                Text(section.rawValue)
                    .font(.subheadline)
                    .fontWeight(expandedSection == section ? .semibold : .regular)
                
                if badgeCount > 0 {
                    Text("\(badgeCount)")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Color.accentColor.opacity(0.2))
                        .foregroundStyle(Color.accentColor)
                        .clipShape(Capsule())
                }
            }
            .foregroundStyle(expandedSection == section ? Color.accentColor : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(expandedSection == section ? Color.accentColor.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Section Content
    
    @ViewBuilder
    private var selectedSectionContent: some View {
        switch expandedSection {
        case .filters:
            filtersContent
        case .groupBy:
            groupByContent
        case .favorites:
            favoritesContent
        }
    }
    
    // MARK: - Footer
    
    private var footer: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Text("Done")
            }
            .keyboardShortcut(.return)
            
            Spacer()
            
            Text("\(config.activeFilterCount) filter\(config.activeFilterCount == 1 ? "" : "s") active")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
    
    // MARK: - Filters Content
    
    private var filtersContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Top row: Basic filters
            HStack(alignment: .top, spacing: 24) {
                // Status filters
                VStack(alignment: .leading, spacing: 6) {
                    Text("Task Status")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    FlowLayout(spacing: 6) {
                        TaskFilterChip(
                            title: "Inbox Only",
                            icon: "tray",
                            isSelected: config.activeShowInboxOnly,
                            color: .purple
                        ) {
                            config.activeShowInboxOnly.toggle()
                        }
                        
                        TaskFilterChip(
                            title: "Include Completed",
                            icon: "checkmark.circle",
                            isSelected: config.activeShowCompletedTasks,
                            color: .green
                        ) {
                            config.activeShowCompletedTasks.toggle()
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Research Projects filter
            VStack(alignment: .leading, spacing: 6) {
                Text("Research Projects")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if !activeQuestions.isEmpty {
                    FlowLayout(spacing: 6) {
                        ForEach(activeQuestions) { question in
                            TaskFilterChip(
                                title: questionDisplayName(question),
                                icon: "doc.text.magnifyingglass",
                                isSelected: config.activeResearchQuestionIds.contains(question.questionId),
                                color: .blue
                            ) {
                                toggleQuestionFilter(question)
                            }
                        }
                    }
                } else {
                    Text("No active research projects")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            
            // Tags filter (from research question tags)
            VStack(alignment: .leading, spacing: 6) {
                Text("Tags")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if !allTags.isEmpty {
                    FlowLayout(spacing: 6) {
                        ForEach(allTags) { tag in
                            TaskFilterChip(
                                title: tag.name,
                                icon: "tag",
                                isSelected: config.activeTagIds.contains(tag.tagId),
                                color: tagColor(for: tag)
                            ) {
                                toggleTagFilter(tag)
                            }
                        }
                    }
                } else {
                    Text("No tags available")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
    
    // MARK: - Group By Content
    
    private var groupByContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(TaskGroupByColumn.allCases) { column in
                Button {
                    config.groupByColumn = column
                } label: {
                    HStack {
                        Image(systemName: column.iconName)
                            .frame(width: 20)
                            .foregroundStyle(.secondary)
                        
                        Text(column.displayName)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        if config.groupByColumn == column {
                            Image(systemName: "checkmark")
                                .font(.caption)
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)
            }
        }
    }
    
    // MARK: - Favorites Content
    
    private var favoritesContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Save current search button
            Button {
                showingSaveDialog = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle")
                        .frame(width: 20)
                    
                    Text("Save current search")
                        .font(.subheadline)
                    
                    Spacer()
                }
                .foregroundStyle(Color.accentColor)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.vertical, 4)
            
            if !config.savedSearches.isEmpty {
                Divider()
                    .padding(.vertical, 4)
                
                // List of saved searches
                ForEach(config.savedSearches) { search in
                    HStack {
                        Button {
                            applySavedSearch(search)
                        } label: {
                            HStack {
                                Image(systemName: "star.fill")
                                    .frame(width: 20)
                                    .foregroundStyle(.yellow)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(search.name)
                                        .font(.subheadline)
                                    
                                    Text(searchSummary(for: search))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            deleteSavedSearch(search)
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundStyle(.red.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                }
            } else {
                Text("No saved searches yet")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - Actions
    
    private func toggleQuestionFilter(_ question: ResearchQuestion) {
        if config.activeResearchQuestionIds.contains(question.questionId) {
            config.activeResearchQuestionIds.remove(question.questionId)
        } else {
            config.activeResearchQuestionIds.insert(question.questionId)
        }
    }
    
    private func toggleTagFilter(_ tag: Tag) {
        if config.activeTagIds.contains(tag.tagId) {
            config.activeTagIds.remove(tag.tagId)
        } else {
            config.activeTagIds.insert(tag.tagId)
        }
    }
    
    private func clearAll() {
        config.clearActiveFilters()
        config.groupByColumn = .none
        searchText = ""
    }
    
    private func saveCurrentSearch() {
        guard !newSearchName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        config.activeSearchText = searchText
        config.saveCurrentSearch(name: newSearchName)
        newSearchName = ""
    }
    
    private func applySavedSearch(_ search: TaskSavedSearch) {
        config.applySavedSearch(search)
        searchText = search.searchText
        dismiss()
    }
    
    private func deleteSavedSearch(_ search: TaskSavedSearch) {
        config.deleteSavedSearch(id: search.id)
    }
    
    private func searchSummary(for search: TaskSavedSearch) -> String {
        var parts: [String] = []
        
        if search.showInboxOnly {
            parts.append("inbox")
        }
        if search.showCompletedTasks {
            parts.append("completed")
        }
        if !search.researchQuestionIds.isEmpty {
            parts.append("\(search.researchQuestionIds.count) projects")
        }
        if !search.tagIds.isEmpty {
            parts.append("\(search.tagIds.count) tags")
        }
        if let groupBy = search.groupByColumn, groupBy != "none" {
            parts.append("grouped")
        }
        
        return parts.isEmpty ? "No filters" : parts.joined(separator: ", ")
    }
    
    // MARK: - Helpers
    
    private func questionDisplayName(_ question: ResearchQuestion) -> String {
        if let ticker = question.asset?.ticker {
            return ticker
        }
        let text = question.questionText
        return text.count > 20 ? String(text.prefix(17)) + "..." : text
    }
    
    private func tagColor(for tag: Tag) -> Color {
        guard let colorName = tag.colorName,
              let tagColor = TagColor(rawValue: colorName) else {
            return .blue
        }
        return tagColor.color
    }
}

// MARK: - Task Filter Chip

/// A selectable chip for task filter options
private struct TaskFilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(title)
                    .font(.caption)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(isSelected ? color.opacity(0.2) : Color(nsColor: .controlBackgroundColor))
            .foregroundStyle(isSelected ? color : .primary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? color : Color(nsColor: .separatorColor), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    TaskSearchPopoverView(
        config: TaskViewConfiguration.shared,
        searchText: .constant("")
    )
    .modelContainer(for: [ResearchQuestion.self, Tag.self], inMemory: true)
}


