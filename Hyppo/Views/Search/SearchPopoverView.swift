/**
 SearchPopoverView provides an advanced search interface with filters, grouping, and saved searches.
 
 Modeled after Odoo's search bar, this popover contains three sections:
 - Filters: Status, confidence, tags, and date range filters
 - Group By: Options to group records by various properties
 - Favorites: Save and apply search configurations
 */

import SwiftUI
import SwiftData

/// Advanced search popover with filters, group by, and saved searches
struct SearchPopoverView: View {
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Queries
    
    @Query(sort: \Tag.name) private var allTags: [Tag]
    
    // MARK: - Properties
    
    @Bindable var config: ViewConfiguration
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
            
            // Content
            ScrollView {
                VStack(spacing: 0) {
                    // Filters Section
                    collapsibleSection(
                        title: "Filters",
                        icon: "line.3.horizontal.decrease.circle",
                        section: .filters,
                        badgeCount: activeFilterCount
                    ) {
                        filtersContent
                    }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Group By Section
                    collapsibleSection(
                        title: "Group By",
                        icon: "rectangle.3.group",
                        section: .groupBy,
                        badgeCount: config.groupByColumn != .none ? 1 : 0
                    ) {
                        groupByContent
                    }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Favorites Section
                    collapsibleSection(
                        title: "Favorites",
                        icon: "star",
                        section: .favorites,
                        badgeCount: config.savedSearches.count
                    ) {
                        favoritesContent
                    }
                }
                .padding(.vertical, 8)
            }
            
            Divider()
            
            // Footer
            footer
        }
        .frame(width: 320, height: 450)
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
            
            Text("\(activeFilterCount) filter\(activeFilterCount == 1 ? "" : "s") active")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
    
    // MARK: - Collapsible Section
    
    @ViewBuilder
    private func collapsibleSection<Content: View>(
        title: String,
        icon: String,
        section: ExpandedSection,
        badgeCount: Int,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            // Section header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedSection = expandedSection == section ? section : section
                }
            } label: {
                HStack {
                    Image(systemName: icon)
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    if badgeCount > 0 {
                        Text("\(badgeCount)")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.2))
                            .foregroundStyle(Color.accentColor)
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                    
                    Image(systemName: expandedSection == section ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            .padding(.vertical, 10)
            
            // Section content
            if expandedSection == section {
                content()
                    .padding(.horizontal)
                    .padding(.bottom, 12)
            }
        }
    }
    
    // MARK: - Filters Content
    
    private var filtersContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Status filters (multi-select)
            VStack(alignment: .leading, spacing: 6) {
                Text("Status")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                FlowLayout(spacing: 6) {
                    ForEach(ResearchQuestionStatus.allCases) { status in
                        FilterChip(
                            title: status.displayName,
                            icon: status.iconName,
                            isSelected: config.activeStatusFilters.contains(status.rawValue),
                            color: statusColor(for: status)
                        ) {
                            toggleStatusFilter(status)
                        }
                    }
                }
            }
            
            // Confidence filter
            VStack(alignment: .leading, spacing: 6) {
                Text("Confidence")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                FlowLayout(spacing: 6) {
                    ForEach(ConfidenceLevel.allCases) { level in
                        FilterChip(
                            title: level.displayName,
                            icon: "gauge",
                            isSelected: config.activeConfidenceFilter == level.rawValue,
                            color: confidenceColor(for: level)
                        ) {
                            toggleConfidenceFilter(level)
                        }
                    }
                }
            }
            
            // Tags filter
            if !allTags.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Tags")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    FlowLayout(spacing: 6) {
                        ForEach(allTags) { tag in
                            FilterChip(
                                title: tag.name,
                                icon: "tag",
                                isSelected: config.activeTagIds.contains(tag.tagId),
                                color: tagColor(for: tag)
                            ) {
                                toggleTagFilter(tag)
                            }
                        }
                    }
                }
            }
            
            // Date range
            VStack(alignment: .leading, spacing: 6) {
                Text("Date Range")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 8) {
                    DatePicker(
                        "From",
                        selection: Binding(
                            get: { config.activeStartDate ?? Date().addingTimeInterval(-30 * 24 * 60 * 60) },
                            set: { config.activeStartDate = $0 }
                        ),
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                    
                    Text("to")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    DatePicker(
                        "To",
                        selection: Binding(
                            get: { config.activeEndDate ?? Date() },
                            set: { config.activeEndDate = $0 }
                        ),
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                }
                
                if config.activeStartDate != nil || config.activeEndDate != nil {
                    Button {
                        config.activeStartDate = nil
                        config.activeEndDate = nil
                    } label: {
                        Label("Clear dates", systemImage: "xmark.circle")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    // MARK: - Group By Content
    
    private var groupByContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(GroupByColumn.allCases) { column in
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
    
    // MARK: - Computed Properties
    
    private var activeFilterCount: Int {
        var count = 0
        count += config.activeStatusFilters.count
        if config.activeConfidenceFilter != nil { count += 1 }
        count += config.activeTagIds.count
        if config.activeStartDate != nil { count += 1 }
        if config.activeEndDate != nil { count += 1 }
        return count
    }
    
    // MARK: - Actions
    
    private func toggleStatusFilter(_ status: ResearchQuestionStatus) {
        if config.activeStatusFilters.contains(status.rawValue) {
            config.activeStatusFilters.remove(status.rawValue)
        } else {
            config.activeStatusFilters.insert(status.rawValue)
        }
    }
    
    private func toggleConfidenceFilter(_ level: ConfidenceLevel) {
        if config.activeConfidenceFilter == level.rawValue {
            config.activeConfidenceFilter = nil
        } else {
            config.activeConfidenceFilter = level.rawValue
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
    
    private func applySavedSearch(_ search: SavedSearch) {
        config.applySavedSearch(search)
        searchText = search.searchText
        dismiss()
    }
    
    private func deleteSavedSearch(_ search: SavedSearch) {
        config.deleteSavedSearch(id: search.id)
    }
    
    private func searchSummary(for search: SavedSearch) -> String {
        var parts: [String] = []
        
        if !search.statusFilters.isEmpty {
            parts.append("\(search.statusFilters.count) status")
        }
        if search.confidenceFilter != nil {
            parts.append("confidence")
        }
        if !search.tagIds.isEmpty {
            parts.append("\(search.tagIds.count) tags")
        }
        if search.startDate != nil || search.endDate != nil {
            parts.append("date range")
        }
        if let groupBy = search.groupByColumn, groupBy != "none" {
            parts.append("grouped")
        }
        
        return parts.isEmpty ? "No filters" : parts.joined(separator: ", ")
    }
    
    // MARK: - Colors
    
    private func statusColor(for status: ResearchQuestionStatus) -> Color {
        switch status {
        case .active: return .green
        case .onHold: return .orange
        case .invalidated: return .red
        case .archived: return .gray
        }
    }
    
    private func confidenceColor(for level: ConfidenceLevel) -> Color {
        switch level {
        case .veryLow: return .red
        case .low: return .orange
        case .medium: return .yellow
        case .high: return .green
        case .veryHigh: return .blue
        }
    }
    
    private func tagColor(for tag: Tag) -> Color {
        guard let colorName = tag.colorName,
              let tagColor = TagColor(rawValue: colorName) else {
            return .blue
        }
        return tagColor.color
    }
}

// MARK: - Filter Chip

/// A selectable chip for filter options
private struct FilterChip: View {
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
    SearchPopoverView(
        config: ViewConfiguration.shared,
        searchText: .constant("")
    )
    .modelContainer(for: [Tag.self], inMemory: true)
}

