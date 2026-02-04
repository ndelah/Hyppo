/**
 RecordTableView displays research questions in a sortable table format.
 
 Features:
 - Clickable column headers for sorting
 - Resizable columns via drag handles
 - Column visibility settings button in header
 - Click question title to navigate to detail view
 - Inline editing for asset, status, and confidence (with auto-logging)
 - Bulk editing: when multiple rows are selected, clicking on asset/status/confidence
   opens a popover that applies the change to all selected rows
 */

import SwiftUI
import SwiftData

/// Table view for displaying research question records
struct RecordTableView: View {
    // MARK: - Properties
    
    let questions: [ResearchQuestion]
    @Binding var navigationPath: NavigationPath
    @Bindable var config: ViewConfiguration
    @Binding var showingColumnSettings: Bool
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Queries
    
    @Query(sort: \Asset.ticker) private var allAssets: [Asset]
    
    // MARK: - State
    
    @State private var draggedColumn: RecordColumn?
    @State private var showingColumnPopover = false
    @State private var availableWidth: CGFloat = 800
    @State private var currentPage = 0
    @State private var selectedQuestionIDs: Set<PersistentIdentifier> = []
    private let pageSize = 50
    
    /// Width of the selection checkbox column
    private let checkboxColumnWidth: CGFloat = 40
    
    // MARK: - Bulk Edit State
    
    @State private var showingBulkAssetPopover = false
    @State private var showingBulkStatusPopover = false
    @State private var showingBulkConfidencePopover = false
    
    // MARK: - Computed Properties (Responsive)
    
    /// Columns that fit in the current width, hiding low-priority columns as needed
    private var responsiveColumns: [RecordColumn] {
        config.responsiveVisibleColumns(for: availableWidth)
    }
    
    /// Proportionally calculated widths for visible columns
    private var responsiveWidths: [RecordColumn: CGFloat] {
        config.responsiveWidths(for: responsiveColumns, availableWidth: availableWidth)
    }
    
    // MARK: - Pagination Computed Properties
    
    /// Total number of pages
    private var totalPages: Int {
        max(1, (sortedQuestions.count + pageSize - 1) / pageSize)
    }
    
    /// Questions for the current page
    private var pagedQuestions: [ResearchQuestion] {
        let startIndex = currentPage * pageSize
        let endIndex = min(startIndex + pageSize, sortedQuestions.count)
        
        guard startIndex < sortedQuestions.count else { return [] }
        return Array(sortedQuestions[startIndex..<endIndex])
    }
    
    /// Display range for pagination (e.g., "1-50")
    private var displayRange: String {
        guard !sortedQuestions.isEmpty else { return "0" }
        let startIndex = currentPage * pageSize + 1
        let endIndex = min((currentPage + 1) * pageSize, sortedQuestions.count)
        return "\(startIndex)-\(endIndex)"
    }
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Table header with responsive columns
                tableHeader
                
                Divider()
                
                // Table body
                if questions.isEmpty {
                    emptyState
                } else {
                    tableBody
                }
            }
            .frame(maxWidth: geometry.size.width)
            .clipped()
            .onAppear {
                availableWidth = geometry.size.width
            }
            .onChange(of: geometry.size.width) { _, newWidth in
                availableWidth = newWidth
            }
            .onChange(of: questions.count) { _, _ in
                // Reset to first page when questions change (e.g., filtering)
                currentPage = 0
            }
        }
    }
    
    // MARK: - Table Header
    
    /// Whether all visible questions on the current page are selected
    private var allPageSelected: Bool {
        !pagedQuestions.isEmpty && pagedQuestions.allSatisfy { selectedQuestionIDs.contains($0.persistentModelID) }
    }
    
    /// Whether some (but not all) questions on the current page are selected
    private var somePageSelected: Bool {
        !selectedQuestionIDs.isEmpty && !allPageSelected
    }
    
    private var tableHeader: some View {
        HStack(spacing: 0) {
            // Left margin spacer
            Spacer()
                .frame(width: 16)
            
            // Selection checkbox column header
            selectionHeaderCheckbox
            
            ForEach(responsiveColumns) { column in
                let columnWidth = responsiveWidths[column] ?? column.minWidth
                
                HStack(spacing: 0) {
                    // Column header content
                    // Add extra leading padding for left-aligned columns so text doesn't stick to divider
                    columnHeader(for: column)
                        .frame(width: columnWidth - 16, alignment: column.alignment)
                        .padding(.leading, column.alignment == .leading ? 12 : 8)
                        .padding(.trailing, 8)
                        .padding(.vertical, 14)
                    
                    // Resizable divider (not on the last column)
                    if column != responsiveColumns.last {
                        ResizableDivider(
                            column: column,
                            config: config,
                            responsiveWidth: columnWidth
                        )
                    }
                }
                .frame(width: columnWidth)
            }
            
            Spacer(minLength: 0)
            
            // Pagination controls
            paginationControls
            
            // Column settings button at the end
            columnSettingsButton
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipped()
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.95))
    }
    
    // MARK: - Pagination Controls
    
    private var paginationControls: some View {
        HStack(spacing: 8) {
            Text("\(displayRange) / \(sortedQuestions.count)")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .monospacedDigit()
            
            HStack(spacing: 2) {
                Button {
                    if currentPage > 0 {
                        currentPage -= 1
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11))
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
                        .font(.system(size: 11))
                        .foregroundStyle(currentPage < totalPages - 1 ? .primary : .tertiary)
                }
                .buttonStyle(.plain)
                .disabled(currentPage >= totalPages - 1)
            }
        }
        .padding(.trailing, 8)
    }
    
    @ViewBuilder
    private func columnHeader(for column: RecordColumn) -> some View {
        Button {
            if column.isSortable {
                config.setSortColumn(column)
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: column.iconName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(column.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                if column.isSortable && config.sortColumn == column {
                    Image(systemName: config.sortAscending ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
            }
            .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
        .disabled(!column.isSortable)
    }
    
    private var columnSettingsButton: some View {
        Button {
            showingColumnPopover = true
        } label: {
            Image(systemName: "slider.horizontal.3")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
        .help("Edit columns")
        .popover(isPresented: $showingColumnPopover, arrowEdge: .bottom) {
            ColumnVisibilityPopover(config: config)
        }
    }
    
    // MARK: - Selection Checkbox Header
    
    /// Header checkbox that toggles selection of all visible rows
    private var selectionHeaderCheckbox: some View {
        Button {
            toggleSelectAll()
        } label: {
            Image(systemName: allPageSelected ? "checkmark.square.fill" : (somePageSelected ? "minus.square.fill" : "square"))
                .font(.system(size: 16))
                .foregroundStyle(allPageSelected || somePageSelected ? .blue : .secondary)
        }
        .buttonStyle(.plain)
        .frame(width: checkboxColumnWidth)
        .padding(.vertical, 14)
        .help(allPageSelected ? "Deselect all" : "Select all")
    }
    
    /// Toggles selection of all questions on the current page
    private func toggleSelectAll() {
        if allPageSelected {
            // Deselect all on current page
            for question in pagedQuestions {
                selectedQuestionIDs.remove(question.persistentModelID)
            }
        } else {
            // Select all on current page
            for question in pagedQuestions {
                selectedQuestionIDs.insert(question.persistentModelID)
            }
        }
    }
    
    /// Toggles selection of a single question
    private func toggleSelection(for question: ResearchQuestion) {
        if selectedQuestionIDs.contains(question.persistentModelID) {
            selectedQuestionIDs.remove(question.persistentModelID)
        } else {
            selectedQuestionIDs.insert(question.persistentModelID)
        }
    }
    
    /// Whether multiple questions are currently selected (enables bulk edit mode)
    private var hasMultipleSelection: Bool {
        selectedQuestionIDs.count > 1
    }
    
    /// Returns all selected questions from the full questions list
    private var selectedQuestions: [ResearchQuestion] {
        questions.filter { selectedQuestionIDs.contains($0.persistentModelID) }
    }
    
    // MARK: - Table Body
    
    private var tableBody: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(pagedQuestions) { question in
                    let isChecked = selectedQuestionIDs.contains(question.persistentModelID)
                    
                    VStack(spacing: 0) {
                        RecordRowView(
                            question: question,
                            columns: responsiveColumns,
                            columnWidths: responsiveWidths,
                            isSelected: isChecked,
                            isChecked: isChecked,
                            checkboxColumnWidth: checkboxColumnWidth,
                            onToggleSelection: {
                                toggleSelection(for: question)
                            },
                            onQuestionTap: {
                                navigationPath.append(question)
                            },
                            onAssetChange: { oldAsset, newAsset in
                                handleAssetChange(for: question, from: oldAsset, to: newAsset)
                            },
                            onStatusChange: { oldStatus, newStatus in
                                handleStatusChange(for: question, from: oldStatus, to: newStatus)
                            },
                            onConfidenceChange: { oldConfidence, newConfidence in
                                handleConfidenceChange(for: question, from: oldConfidence, to: newConfidence)
                            },
                            availableAssets: allAssets,
                            hasMultipleSelection: hasMultipleSelection,
                            onBulkAssetEdit: {
                                showingBulkAssetPopover = true
                            },
                            onBulkStatusEdit: {
                                showingBulkStatusPopover = true
                            },
                            onBulkConfidenceEdit: {
                                showingBulkConfidencePopover = true
                            }
                        )
                        .contextMenu {
                            contextMenu(for: question)
                        }
                        
                        Divider()
                            .padding(.leading, 8)
                    }
                }
            }
        }
        .id(currentPage) // Force re-render when page changes
        .background(Color(nsColor: .windowBackgroundColor))
        // Bulk edit popovers
        .popover(isPresented: $showingBulkAssetPopover, arrowEdge: .bottom) {
            BulkAssetPickerPopover(
                selectedCount: selectedQuestionIDs.count,
                availableAssets: allAssets,
                onSelect: { newAsset in
                    applyBulkAssetChange(to: newAsset)
                    showingBulkAssetPopover = false
                }
            )
        }
        .popover(isPresented: $showingBulkStatusPopover, arrowEdge: .bottom) {
            BulkStatusPickerPopover(
                selectedCount: selectedQuestionIDs.count,
                onSelect: { newStatus in
                    applyBulkStatusChange(to: newStatus)
                    showingBulkStatusPopover = false
                }
            )
        }
        .popover(isPresented: $showingBulkConfidencePopover, arrowEdge: .bottom) {
            BulkConfidencePickerPopover(
                selectedCount: selectedQuestionIDs.count,
                onSelect: { newConfidence in
                    applyBulkConfidenceChange(to: newConfidence)
                    showingBulkConfidencePopover = false
                }
            )
        }
    }
    
    // MARK: - Change Handlers
    
    /**
     Handles asset change and creates a log entry.
     
     - Parameters:
       - question: The research question being modified
       - oldAsset: The previous asset (nil if none)
       - newAsset: The new asset (nil if removing)
     */
    private func handleAssetChange(for question: ResearchQuestion, from oldAsset: Asset?, to newAsset: Asset?) {
        // Update the question's asset
        question.asset = newAsset
        question.updatedAt = Date()
        
        // Create and attach log entry
        let logEntry = LogEntry.createAssetChangeLog(fromAsset: oldAsset, toAsset: newAsset)
        logEntry.researchQuestion = question
        modelContext.insert(logEntry)
        
        // Append to question's log entries
        if question.logEntries == nil {
            question.logEntries = []
        }
        question.logEntries?.append(logEntry)
    }
    
    /**
     Handles status change and creates a log entry.
     
     - Parameters:
       - question: The research question being modified
       - oldStatus: The previous status
       - newStatus: The new status
     */
    private func handleStatusChange(for question: ResearchQuestion, from oldStatus: ResearchQuestionStatus, to newStatus: ResearchQuestionStatus) {
        // Update the question's status
        question.status = newStatus
        
        // Create and attach log entry
        let logEntry = LogEntry.createStatusChangeLog(fromStatus: oldStatus, toStatus: newStatus)
        logEntry.researchQuestion = question
        modelContext.insert(logEntry)
        
        // Append to question's log entries
        if question.logEntries == nil {
            question.logEntries = []
        }
        question.logEntries?.append(logEntry)
    }
    
    /**
     Handles confidence change and creates a log entry.
     
     - Parameters:
       - question: The research question being modified
       - oldConfidence: The previous confidence level (nil if none)
       - newConfidence: The new confidence level (nil if removing)
     */
    private func handleConfidenceChange(for question: ResearchQuestion, from oldConfidence: ConfidenceLevel?, to newConfidence: ConfidenceLevel?) {
        // Update the question's confidence
        question.confidence = newConfidence
        question.updatedAt = Date()
        
        // Create and attach log entry
        let logEntry = LogEntry.createConfidenceChangeLog(fromConfidence: oldConfidence, toConfidence: newConfidence)
        logEntry.researchQuestion = question
        modelContext.insert(logEntry)
        
        // Append to question's log entries
        if question.logEntries == nil {
            question.logEntries = []
        }
        question.logEntries?.append(logEntry)
    }
    
    // MARK: - Bulk Change Handlers
    
    /**
     Applies asset change to all selected questions.
     
     - Parameter newAsset: The new asset to assign (nil to remove asset)
     */
    private func applyBulkAssetChange(to newAsset: Asset?) {
        for question in selectedQuestions {
            let oldAsset = question.asset
            if oldAsset?.assetId != newAsset?.assetId {
                handleAssetChange(for: question, from: oldAsset, to: newAsset)
            }
        }
    }
    
    /**
     Applies status change to all selected questions.
     
     - Parameter newStatus: The new status to assign
     */
    private func applyBulkStatusChange(to newStatus: ResearchQuestionStatus) {
        for question in selectedQuestions {
            let oldStatus = question.status
            if oldStatus != newStatus {
                handleStatusChange(for: question, from: oldStatus, to: newStatus)
            }
        }
    }
    
    /**
     Applies confidence change to all selected questions.
     
     - Parameter newConfidence: The new confidence level (nil to remove)
     */
    private func applyBulkConfidenceChange(to newConfidence: ConfidenceLevel?) {
        for question in selectedQuestions {
            let oldConfidence = question.confidence
            if oldConfidence != newConfidence {
                handleConfidenceChange(for: question, from: oldConfidence, to: newConfidence)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            
            Text("No Research Questions")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text("Create a research question to get started")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Sorting
    
    private var sortedQuestions: [ResearchQuestion] {
        questions.sorted { lhs, rhs in
            let result: Bool
            
            switch config.sortColumn {
            case .question:
                result = lhs.questionText.localizedCaseInsensitiveCompare(rhs.questionText) == .orderedAscending
                
            case .assetName:
                let lhsTicker = lhs.asset?.ticker ?? ""
                let rhsTicker = rhs.asset?.ticker ?? ""
                result = lhsTicker.localizedCaseInsensitiveCompare(rhsTicker) == .orderedAscending
                
            case .status:
                result = lhs.statusRaw.localizedCaseInsensitiveCompare(rhs.statusRaw) == .orderedAscending
                
            case .confidence:
                let lhsConf = lhs.confidenceCurrent ?? 0
                let rhsConf = rhs.confidenceCurrent ?? 0
                result = lhsConf < rhsConf
                
            case .created:
                result = lhs.createdAt < rhs.createdAt
                
            case .updated:
                result = lhs.updatedAt < rhs.updatedAt
                
            case .drivers, .logEntries, .tags:
                // Non-sortable columns default to updated date
                result = lhs.updatedAt < rhs.updatedAt
            }
            
            return config.sortAscending ? result : !result
        }
    }
    
    // MARK: - Context Menu
    
    @ViewBuilder
    private func contextMenu(for question: ResearchQuestion) -> some View {
        Button {
            navigationPath.append(question)
        } label: {
            Label("View Details", systemImage: "eye")
        }
        
        Divider()
        
        Menu("Change Status") {
            ForEach(ResearchQuestionStatus.allCases) { status in
                Button {
                    question.status = status
                } label: {
                    if question.status == status {
                        Label(status.displayName, systemImage: "checkmark")
                    } else {
                        Text(status.displayName)
                    }
                }
            }
        }
    }
}

// MARK: - Resizable Divider

/// A draggable divider between columns for resizing
private struct ResizableDivider: View {
    let column: RecordColumn
    @Bindable var config: ViewConfiguration
    let responsiveWidth: CGFloat
    
    @State private var isDragging = false
    @State private var dragStartWidth: CGFloat = 0
    
    var body: some View {
        Rectangle()
            .fill(isDragging ? Color.accentColor : Color(nsColor: .separatorColor))
            .frame(width: isDragging ? 3 : 1, height: 24)
            .contentShape(Rectangle().size(width: 10, height: 44))
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            dragStartWidth = responsiveWidth
                        }
                        let newWidth = dragStartWidth + value.translation.width
                        // Enforce minimum width
                        config.setWidthForColumn(column, width: max(newWidth, column.minWidth))
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
            .onHover { hovering in
                if hovering {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
            }
    }
}

// MARK: - Column Visibility Popover

/// Popover for toggling column visibility
private struct ColumnVisibilityPopover: View {
    @Bindable var config: ViewConfiguration
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Visible Columns")
                .font(.headline)
                .padding()
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(RecordColumn.allCases) { column in
                        Toggle(isOn: Binding(
                            get: { config.visibleColumns.contains(column) },
                            set: { _ in config.toggleColumn(column) }
                        )) {
                            HStack(spacing: 6) {
                                Image(systemName: column.iconName)
                                    .frame(width: 16)
                                    .foregroundStyle(.secondary)
                                Text(column.displayName)
                            }
                        }
                        .toggleStyle(.checkbox)
                        .disabled(column == .question) // Question column always visible
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Divider()
            
            HStack {
                Button("Reset Widths") {
                    for column in RecordColumn.allCases {
                        config.resetColumnWidth(column)
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .font(.caption)
                
                Spacer()
                
                Button("Reset All") {
                    config.visibleColumns = Set(RecordColumn.allCases.filter { $0.isDefaultVisible })
                    for column in RecordColumn.allCases {
                        config.resetColumnWidth(column)
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red)
                .font(.caption)
            }
            .padding()
        }
        .frame(width: 220, height: 350)
    }
}

// MARK: - Bulk Edit Popovers

/// Bulk asset picker popover for changing asset on multiple questions
private struct BulkAssetPickerPopover: View {
    let selectedCount: Int
    let availableAssets: [Asset]
    let onSelect: (Asset?) -> Void
    
    @State private var searchText = ""
    
    private var filteredAssets: [Asset] {
        if searchText.isEmpty {
            return availableAssets
        }
        return availableAssets.filter { asset in
            asset.ticker.localizedCaseInsensitiveContains(searchText) ||
            asset.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with selection count
            HStack {
                Image(systemName: "square.stack.3d.up.fill")
                    .foregroundStyle(.blue)
                Text("Change Asset")
                    .font(.headline)
                Spacer()
                Text("\(selectedCount) selected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            
            Divider()
            
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search assets...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(10)
            
            Divider()
            
            // Asset list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    // "None" option to remove asset
                    Button {
                        onSelect(nil)
                    } label: {
                        HStack {
                            Image(systemName: "minus.circle")
                                .foregroundStyle(.secondary)
                            Text("Remove Asset")
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    ForEach(filteredAssets) { asset in
                        Button {
                            onSelect(asset)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(asset.ticker)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(.cyan)
                                    Text(asset.name)
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxHeight: 250)
        }
        .frame(width: 240)
    }
}

/// Bulk status picker popover for changing status on multiple questions
private struct BulkStatusPickerPopover: View {
    let selectedCount: Int
    let onSelect: (ResearchQuestionStatus) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with selection count
            HStack {
                Image(systemName: "flag.fill")
                    .foregroundStyle(.blue)
                Text("Change Status")
                    .font(.headline)
                Spacer()
                Text("\(selectedCount) selected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            
            Divider()
            
            VStack(spacing: 0) {
                ForEach(ResearchQuestionStatus.allCases) { status in
                    Button {
                        onSelect(status)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: status.iconName)
                                .font(.system(size: 14))
                                .foregroundStyle(statusColor(for: status))
                                .frame(width: 20)
                            
                            Text(status.displayName)
                                .font(.system(size: 13))
                            
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    if status != ResearchQuestionStatus.allCases.last {
                        Divider()
                            .padding(.leading, 44)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .frame(width: 220)
    }
    
    private func statusColor(for status: ResearchQuestionStatus) -> Color {
        switch status {
        case .active: return .green
        case .onHold: return .orange
        case .invalidated: return .red
        case .archived: return .gray
        }
    }
}

/// Bulk confidence picker popover for changing confidence on multiple questions
private struct BulkConfidencePickerPopover: View {
    let selectedCount: Int
    let onSelect: (ConfidenceLevel?) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with selection count
            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(.blue)
                Text("Change Confidence")
                    .font(.headline)
                Spacer()
                Text("\(selectedCount) selected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            
            Divider()
            
            VStack(spacing: 0) {
                // "None" option to remove confidence
                Button {
                    onSelect(nil)
                } label: {
                    HStack {
                        Image(systemName: "minus.circle")
                            .foregroundStyle(.secondary)
                        Text("Remove Confidence")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                Divider()
                    .padding(.vertical, 4)
                
                ForEach(ConfidenceLevel.allCases) { level in
                    Button {
                        onSelect(level)
                    } label: {
                        HStack(spacing: 8) {
                            Text(level.shortLabel)
                                .font(.system(size: 12))
                                .foregroundStyle(confidenceColor(for: level))
                                .frame(width: 80, alignment: .leading)
                            
                            Text(level.displayName)
                                .font(.system(size: 13))
                            
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    if level != ConfidenceLevel.allCases.last {
                        Divider()
                            .padding(.leading, 100)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .frame(width: 240)
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
}

// MARK: - Preview

#Preview {
    let question1 = ResearchQuestion(
        questionText: "Can AAPL sustain services revenue growth?",
        context: "Services now represent 20% of revenue",
        confidence: 4
    )
    
    let question2 = ResearchQuestion(
        questionText: "Will AI demand drive semiconductor growth?",
        context: "Data center spending accelerating",
        confidence: 3
    )
    
    return RecordTableView(
        questions: [question1, question2],
        navigationPath: .constant(NavigationPath()),
        config: ViewConfiguration.shared,
        showingColumnSettings: .constant(false)
    )
    .frame(width: 800, height: 400)
}
