/**
 SearchPopoverView provides an advanced search interface with filters, grouping, and saved searches.
 
 Modeled after Odoo's search bar, this popover contains three sections:
 - Filters: Status, tags, and date range filters
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
            case .filters: return activeFilterCount
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
            
            Text("\(activeFilterCount) filter\(activeFilterCount == 1 ? "" : "s") active")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
    
    // MARK: - Filters Content
    
    private var filtersContent: some View {
        VStack(alignment: .leading, spacing: 16) {
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
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Bottom row: Tags and Date Range side by side
            HStack(alignment: .top, spacing: 24) {
                // Tags filter
                VStack(alignment: .leading, spacing: 6) {
                    Text("Tags")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if !allTags.isEmpty {
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
                    } else {
                        Text("No tags")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
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
                .frame(maxWidth: .infinity, alignment: .leading)
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
    
    private func tagColor(for tag: Tag) -> Color {
        guard let colorName = tag.colorName,
              let tagColor = TagColor(rawValue: colorName) else {
            return .blue
        }
        return tagColor.color
    }
}

// MARK: - Flow Layout

/// A layout that arranges views in a horizontal flow, wrapping to new lines as needed
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        
        for (index, subview) in subviews.enumerated() {
            let point = result.points[index]
            subview.place(
                at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y),
                proposal: .unspecified
            )
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var points: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    // Wrap to next line
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                points.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
                
                self.size.width = max(self.size.width, x - spacing)
            }
            
            self.size.height = y + lineHeight
        }
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
            .background(isSelected ? color.opacity(0.2) : Color(nsColor: .windowBackgroundColor))
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

