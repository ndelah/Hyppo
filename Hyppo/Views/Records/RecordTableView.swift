/**
 RecordTableView displays research questions in a sortable table format.
 
 Features:
 - Clickable column headers for sorting
 - Configurable column visibility
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
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Table header
            tableHeader
            
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
            ForEach(config.orderedVisibleColumns) { column in
                columnHeader(for: column)
                    .frame(width: column.suggestedWidth, alignment: .leading)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 10)
                
                if column != config.orderedVisibleColumns.last {
                    Divider()
                        .frame(height: 20)
                }
            }
            
            Spacer(minLength: 0)
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
    
    // MARK: - Table Body
    
    private var tableBody: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(sortedQuestions) { question in
                    VStack(spacing: 0) {
                        RecordRowView(
                            question: question,
                            columns: config.orderedVisibleColumns,
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
        config: ViewConfiguration.shared
    )
    .frame(width: 800, height: 400)
}
