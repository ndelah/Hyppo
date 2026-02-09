/**
 RecordListView is the main container for displaying research question records.
 
 Features:
 - Odoo-style toolbar with filter tags displayed in search bar
 - View mode switcher (Table, Kanban, Cards)
 - Advanced search bar with filters, group by, and saved searches
 - Pagination with counter and navigation arrows
 - Column visibility settings (for table view)
 - Hosts the three different view modes
 - Full-screen navigation to detail view
 */

import SwiftUI
import SwiftData

/// Main record list view with view mode switching
struct RecordListView: View {
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Queries
    
    @Query(sort: \ResearchQuestion.updatedAt, order: .reverse)
    private var allQuestions: [ResearchQuestion]
    
    @Query(sort: \Tag.name) private var allTags: [Tag]
    
    // MARK: - Properties
    
    @Binding var navigationPath: NavigationPath
    
    // MARK: - State
    
    @State private var config = ViewConfiguration.shared
    @State private var searchText = ""
    @State private var showingColumnSettings = false
    @State private var showingAddQuestion = false
    @State private var showingSearchPopover = false
    @State private var showingRowActionsPopover = false
    @State private var currentPage = 0
    @State private var selectedQuestionIDs: Set<PersistentIdentifier> = []
    private let pageSize = 25
    
    // MARK: - Computed Properties
    
    /// Filtered questions based on search text and active filters from config
    private var filteredQuestions: [ResearchQuestion] {
        var result = allQuestions
        
        // Filter by status (multi-select from config)
        if !config.activeStatusFilters.isEmpty {
            result = result.filter { config.activeStatusFilters.contains($0.statusRaw) }
        }
        
        // Filter by confidence
        if let confidenceFilter = config.activeConfidenceFilter {
            result = result.filter { $0.confidenceCurrent == confidenceFilter }
        }
        
        // Filter by tags
        if !config.activeTagIds.isEmpty {
            result = result.filter { question in
                guard let questionTags = question.tags else { return false }
                return questionTags.contains { config.activeTagIds.contains($0.tagId) }
            }
        }
        
        // Filter by date range
        if let startDate = config.activeStartDate {
            result = result.filter { $0.updatedAt >= startDate }
        }
        if let endDate = config.activeEndDate {
            result = result.filter { $0.updatedAt <= endDate }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            result = result.filter { question in
                question.questionText.lowercased().contains(searchLower) ||
                (question.context?.lowercased().contains(searchLower) ?? false) ||
                (question.asset?.ticker.lowercased().contains(searchLower) ?? false) ||
                (question.asset?.name.lowercased().contains(searchLower) ?? false)
            }
        }
        
        return result
    }
    
    /// Total number of pages
    private var totalPages: Int {
        max(1, (filteredQuestions.count + pageSize - 1) / pageSize)
    }
    
    /// Questions for the current page
    private var pagedQuestions: [ResearchQuestion] {
        let startIndex = currentPage * pageSize
        let endIndex = min(startIndex + pageSize, filteredQuestions.count)
        
        guard startIndex < filteredQuestions.count else { return [] }
        return Array(filteredQuestions[startIndex..<endIndex])
    }
    
    /// Display range for pagination (e.g., "1-25")
    private var displayRange: String {
        guard !filteredQuestions.isEmpty else { return "0" }
        let startIndex = currentPage * pageSize + 1
        let endIndex = min((currentPage + 1) * pageSize, filteredQuestions.count)
        return "\(startIndex)-\(endIndex)"
    }
    
    /// Active filter count for badge display
    private var activeFilterCount: Int {
        var count = 0
        count += config.activeStatusFilters.count
        if config.activeConfidenceFilter != nil { count += 1 }
        count += config.activeTagIds.count
        if config.activeStartDate != nil { count += 1 }
        if config.activeEndDate != nil { count += 1 }
        return count
    }
    
    /// Generate active filter tags for display in search bar
    private var activeFilterTags: [RecordFilterTag] {
        var tags: [RecordFilterTag] = []
        
        // Status filters
        for statusRaw in config.activeStatusFilters {
            if let status = ResearchQuestionStatus(rawValue: statusRaw) {
                tags.append(RecordFilterTag(
                    id: "status_\(statusRaw)",
                    label: status.displayName,
                    icon: status.iconName,
                    color: statusColor(for: status),
                    filterType: .status(statusRaw)
                ))
            }
        }
        
        // Confidence filter
        if let confidenceRaw = config.activeConfidenceFilter,
           let confidence = ConfidenceLevel(rawValue: confidenceRaw) {
            tags.append(RecordFilterTag(
                id: "confidence_\(confidenceRaw)",
                label: confidence.displayName,
                icon: "gauge",
                color: confidenceColor(for: confidence),
                filterType: .confidence
            ))
        }
        
        // Tag filters
        for tagId in config.activeTagIds {
            if let tag = allTags.first(where: { $0.tagId == tagId }) {
                tags.append(RecordFilterTag(
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
            tags.append(RecordFilterTag(
                id: "groupby",
                label: config.groupByColumn.displayName,
                icon: "rectangle.3.group",
                color: .purple,
                filterType: .groupBy
            ))
        }
        
        return tags
    }
    
    // MARK: - Color Helpers
    
    private func statusColor(for status: ResearchQuestionStatus) -> Color {
        Color.forStatus(status)
    }
    
    private func confidenceColor(for level: ConfidenceLevel) -> Color {
        Color.forConfidence(level)
    }
    
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
            // Toolbar
            toolbar
            
            Divider()
            
            // Content based on view mode
            viewContent
        }
        .navigationTitle("")
        .sheet(isPresented: $showingColumnSettings) {
            ColumnSettingsSheet(config: config)
        }
        .sheet(isPresented: $showingAddQuestion) {
            ResearchWizardView(asset: nil) { newQuestion in
                modelContext.insert(newQuestion)
                // Navigate to the new question
                navigationPath.append(newQuestion)
            }
        }
        .onChange(of: filteredQuestions.count) { _, _ in
            // Reset to first page when filters change
            currentPage = 0
        }
        // Keyboard shortcut: press "n" to create a new research question
        .onKeyPress(characters: .init(charactersIn: "n")) { _ in
            guard !showingSearchPopover && !showingAddQuestion else { return .ignored }
            showingAddQuestion = true
            return .handled
        }
    }
    
    // MARK: - Toolbar (Odoo-style)
    
    private var toolbar: some View {
        HStack(spacing: 12) {
            // Left: New button - directly opens creation wizard
            Button {
                showingAddQuestion = true
            } label: {
                Text("New")
                    .fontWeight(.medium)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .buttonStyle(.plain)
            
            // Title
            Text("Research Questions")
                .font(.headline)
            
            // Gear icon for row actions (only in table view when rows are selected)
            if config.viewMode == .table {
                Button {
                    showingRowActionsPopover = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.subheadline)
                        .foregroundStyle(selectedQuestionIDs.isEmpty ? .tertiary : .secondary)
                }
                .buttonStyle(.plain)
                .disabled(selectedQuestionIDs.isEmpty)
                .help(selectedQuestionIDs.isEmpty ? "Select rows to enable actions" : "Actions for selected rows")
                .popover(isPresented: $showingRowActionsPopover, arrowEdge: .bottom) {
                    RowActionsPopover(
                        selectedCount: selectedQuestionIDs.count,
                        onDuplicate: duplicateSelectedQuestions,
                        onDelete: deleteSelectedQuestions
                    )
                }
            }
            
            Spacer()
            
            // Center: Search bar with filter tags (Odoo-style)
            searchBarWithFilterTags
            
            Spacer()
            
            // Right: Pagination counter and view mode picker
            paginationControls
            
            Divider()
                .frame(height: 16)
            
            viewModePicker
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(Color.surfaceSecondary)
    }
    
    /// Search bar that displays active filters as rectangular tags
    private var searchBarWithFilterTags: some View {
        Button {
            showingSearchPopover = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                
                // Active filter tags displayed inside the search bar
                ForEach(activeFilterTags) { tag in
                    RecordFilterTagView(tag: tag) {
                        removeFilter(tag)
                    }
                }
                
                // Search text or placeholder
                if !searchText.isEmpty {
                    Text(searchText)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .font(.subheadline)
                    
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                } else if activeFilterTags.isEmpty {
                    Text("Search...")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
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
                    
                    TextField("Search questions, assets...", text: $searchText)
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
                
                SearchPopoverView(config: config, searchText: $searchText)
            }
        }
    }
    
    /// Pagination controls showing count and navigation arrows
    private var paginationControls: some View {
        HStack(spacing: 8) {
            Text("\(displayRange) / \(filteredQuestions.count)")
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
                        .frame(width: 20, height: 20)
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
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
                .disabled(currentPage >= totalPages - 1)
            }
        }
    }
    
    private var viewModePicker: some View {
        HStack(spacing: 2) {
            ForEach(ViewMode.allCases) { mode in
                Button {
                    config.viewMode = mode
                } label: {
                    Image(systemName: mode.iconName)
                        .font(.subheadline)
                        .foregroundStyle(config.viewMode == mode ? .primary : .secondary)
                        .frame(width: 28, height: 24)
                        .background(
                            config.viewMode == mode
                                ? Color.surface
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(Color.appBorder.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
    
    // MARK: - Row Actions
    
    /// Selected questions from the full list
    private var selectedQuestions: [ResearchQuestion] {
        allQuestions.filter { selectedQuestionIDs.contains($0.persistentModelID) }
    }
    
    /**
     Duplicates all selected questions.
     Creates copies with " (Copy)" appended to the question text.
     */
    private func duplicateSelectedQuestions() {
        for question in selectedQuestions {
            let duplicate = ResearchQuestion(
                questionText: question.questionText + " (Copy)",
                context: question.context,
                confidence: question.confidenceCurrent
            )
            duplicate.asset = question.asset
            duplicate.status = question.status
            duplicate.tags = question.tags
            
            modelContext.insert(duplicate)
        }
        
        showingRowActionsPopover = false
        selectedQuestionIDs.removeAll()
    }
    
    /**
     Deletes all selected questions from the model context.
     */
    private func deleteSelectedQuestions() {
        for question in selectedQuestions {
            modelContext.delete(question)
        }
        
        showingRowActionsPopover = false
        selectedQuestionIDs.removeAll()
    }
    
    // MARK: - Filter Removal
    
    private func removeFilter(_ tag: RecordFilterTag) {
        switch tag.filterType {
        case .status(let rawValue):
            config.activeStatusFilters.remove(rawValue)
        case .confidence:
            config.activeConfidenceFilter = nil
        case .tag(let tagId):
            config.activeTagIds.remove(tagId)
        case .groupBy:
            config.groupByColumn = .none
        }
    }
    
    // MARK: - View Content
    
    @ViewBuilder
    private var viewContent: some View {
        switch config.viewMode {
        case .table:
            RecordTableView(
                questions: pagedQuestions,
                navigationPath: $navigationPath,
                config: config,
                showingColumnSettings: $showingColumnSettings,
                selectedQuestionIDs: $selectedQuestionIDs
            )
            
        case .kanban:
            // Kanban view shows all filtered questions (grouping handles the layout)
            RecordKanbanView(
                questions: filteredQuestions,
                navigationPath: $navigationPath,
                config: config
            )
            
        case .cards:
            RecordCardGridView(
                questions: pagedQuestions,
                navigationPath: $navigationPath,
                config: config
            )
        }
    }
}

// MARK: - Record Filter Tag Model

/// Represents an active filter displayed as a tag in the search bar
struct RecordFilterTag: Identifiable {
    let id: String
    let label: String
    let icon: String
    let color: Color
    let filterType: FilterType
    
    enum FilterType {
        case status(String)
        case confidence
        case tag(UUID)
        case groupBy
    }
}

// MARK: - Record Filter Tag View

/// Displays an active filter as a rectangular tag with icon, color, and remove button (Odoo-style)
struct RecordFilterTagView: View {
    let tag: RecordFilterTag
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            // Colored icon
            Image(systemName: tag.icon)
                .font(.system(size: 11))
                .foregroundStyle(tag.color)
            
            // Label
            Text(tag.label)
                .font(.system(size: 12))
                .foregroundStyle(.primary)
                .lineLimit(1)
            
            // Remove button
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .semibold))
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

// MARK: - Column Settings Sheet

/// Sheet for configuring visible columns in table view
private struct ColumnSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var config: ViewConfiguration
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Visible Columns") {
                    ForEach(RecordColumn.allCases) { column in
                        Toggle(isOn: Binding(
                            get: { config.visibleColumns.contains(column) },
                            set: { _ in config.toggleColumn(column) }
                        )) {
                            Label(column.displayName, systemImage: column.iconName)
                        }
                        .disabled(column == .question) // Question column always visible
                    }
                }
                
                Section("Sort") {
                    Picker("Sort by", selection: $config.sortColumn) {
                        ForEach(RecordColumn.allCases.filter { $0.isSortable }) { column in
                            Text(column.displayName).tag(column)
                        }
                    }
                    
                    Toggle("Ascending", isOn: $config.sortAscending)
                }
                
                Section {
                    Button("Reset to Defaults") {
                        config.resetToDefaults()
                    }
                    .foregroundStyle(Color.statusInvalidated)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Table Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 350, height: 500)
    }
}

// MARK: - Preview

#Preview {
    RecordListView(navigationPath: .constant(NavigationPath()))
        .modelContainer(for: [ResearchQuestion.self, Asset.self, Driver.self, LogEntry.self, Tag.self], inMemory: true)
        .frame(width: 900, height: 600)
}
