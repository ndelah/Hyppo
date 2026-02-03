/**
 RecordTableView displays research questions in a sortable table format.
 
 Features:
 - Clickable column headers for sorting
 - Resizable columns via drag handles
 - Column visibility settings button in header
 - Click row to navigate to detail view
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
    
    // MARK: - Layout Constants
    
    private let maxContentWidth: CGFloat = 1200
    
    // MARK: - State
    
    @State private var draggedColumn: RecordColumn?
    @State private var showingColumnPopover = false
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Table header with resizable columns (centered with max width)
            HStack {
                Spacer(minLength: 0)
                tableHeader
                    .frame(maxWidth: maxContentWidth)
                Spacer(minLength: 0)
            }
            
            Divider()
            
            // Table body
            if questions.isEmpty {
                emptyState
            } else {
                tableBody
            }
        }
    }
    
    // MARK: - Table Header
    
    private var tableHeader: some View {
        HStack(spacing: 0) {
            // Left margin spacer
            Spacer()
                .frame(width: 16)
            
            ForEach(config.orderedVisibleColumns) { column in
                HStack(spacing: 0) {
                    // Column header content
                    // Add extra leading padding for left-aligned columns so text doesn't stick to divider
                    columnHeader(for: column)
                        .frame(width: config.widthForColumn(column) - 16, alignment: column.alignment)
                        .padding(.leading, column.alignment == .leading ? 12 : 8)
                        .padding(.trailing, 8)
                        .padding(.vertical, 10)
                    
                    // Resizable divider (not on the last column)
                    if column != config.orderedVisibleColumns.last {
                        ResizableDivider(
                            column: column,
                            config: config
                        )
                    }
                }
                .frame(width: config.widthForColumn(column))
            }
            
            Spacer(minLength: 0)
            
            // Column settings button at the end
            columnSettingsButton
        }
        .background(Color(nsColor: .controlBackgroundColor))
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
        .padding(.vertical, 10)
        .help("Edit columns")
        .popover(isPresented: $showingColumnPopover, arrowEdge: .bottom) {
            ColumnVisibilityPopover(config: config)
        }
    }
    
    // MARK: - Table Body
    
    private var tableBody: some View {
        ScrollView {
            HStack {
                Spacer(minLength: 0)
                LazyVStack(spacing: 0) {
                    ForEach(sortedQuestions) { question in
                        VStack(spacing: 0) {
                            RecordRowView(
                                question: question,
                                columns: config.orderedVisibleColumns,
                                columnWidths: columnWidthsDict,
                                isSelected: false
                            )
                            .onTapGesture {
                                navigationPath.append(question)
                            }
                            .contextMenu {
                                contextMenu(for: question)
                            }
                            
                            Divider()
                                .padding(.leading, 8)
                        }
                    }
                }
                .frame(maxWidth: maxContentWidth)
                Spacer(minLength: 0)
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
    
    // MARK: - Computed Properties
    
    private var columnWidthsDict: [RecordColumn: CGFloat] {
        var dict: [RecordColumn: CGFloat] = [:]
        for column in config.orderedVisibleColumns {
            dict[column] = config.widthForColumn(column)
        }
        return dict
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
                
            case .drivers, .scenarios, .logEntries, .tags:
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
    
    @State private var isDragging = false
    
    var body: some View {
        Rectangle()
            .fill(isDragging ? Color.accentColor : Color(nsColor: .separatorColor))
            .frame(width: isDragging ? 3 : 1, height: 20)
            .contentShape(Rectangle().size(width: 10, height: 40))
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        isDragging = true
                        let currentWidth = config.widthForColumn(column)
                        let newWidth = currentWidth + value.translation.width
                        config.setWidthForColumn(column, width: newWidth)
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
