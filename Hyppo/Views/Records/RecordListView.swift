/**
 RecordListView is the main container for displaying research question records.
 
 Features:
 - View mode switcher (Table, Kanban, Cards)
 - Search bar for filtering records
 - Status filter dropdown
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
    
    // MARK: - Properties
    
    @Binding var navigationPath: NavigationPath
    
    // MARK: - State
    
    @State private var config = ViewConfiguration.shared
    @State private var searchText = ""
    @State private var statusFilter: ResearchQuestionStatus?
    @State private var showingColumnSettings = false
    @State private var showingAddQuestion = false
    
    // MARK: - Computed Properties
    
    /// Filtered questions based on search and status filter
    private var filteredQuestions: [ResearchQuestion] {
        var result = allQuestions
        
        // Filter by status
        if let status = statusFilter {
            result = result.filter { $0.status == status }
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
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbar
            
            Divider()
            
            // Content based on view mode
            viewContent
        }
        .navigationTitle("Research Questions")
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
    }
    
    // MARK: - Toolbar
    
    private var toolbar: some View {
        HStack(spacing: 12) {
            // Search
            searchField
            
            Divider()
                .frame(height: 24)
            
            // Status filter
            statusFilterMenu
            
            Divider()
                .frame(height: 24)
            
            // View mode picker
            viewModePicker
            
            // Column settings (table view only)
            if config.viewMode == .table {
                Button {
                    showingColumnSettings = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .buttonStyle(.borderless)
                .help("Column settings")
            }
            
            Spacer()
            
            // Record count
            Text("\(filteredQuestions.count) \(filteredQuestions.count == 1 ? "record" : "records")")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // Add button
            Button {
                showingAddQuestion = true
            } label: {
                Label("New Question", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    private var searchField: some View {
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
        .padding(8)
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .frame(maxWidth: 300)
    }
    
    private var statusFilterMenu: some View {
        Menu {
            Button {
                statusFilter = nil
            } label: {
                if statusFilter == nil {
                    Label("All Statuses", systemImage: "checkmark")
                } else {
                    Text("All Statuses")
                }
            }
            
            Divider()
            
            ForEach(ResearchQuestionStatus.allCases) { status in
                Button {
                    statusFilter = status
                } label: {
                    HStack {
                        Image(systemName: status.iconName)
                        Text(status.displayName)
                        if statusFilter == status {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: statusFilter == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                if let filter = statusFilter {
                    Text(filter.displayName)
                        .font(.caption)
                }
            }
        }
        .menuStyle(.borderlessButton)
        .frame(width: statusFilter == nil ? 30 : 100)
    }
    
    private var viewModePicker: some View {
        Picker("View Mode", selection: $config.viewMode) {
            ForEach(ViewMode.allCases) { mode in
                Label(mode.displayName, systemImage: mode.iconName)
                    .tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 150)
    }
    
    // MARK: - View Content
    
    @ViewBuilder
    private var viewContent: some View {
        switch config.viewMode {
        case .table:
            RecordTableView(
                questions: filteredQuestions,
                navigationPath: $navigationPath,
                config: config
            )
            
        case .kanban:
            RecordKanbanView(
                questions: filteredQuestions,
                navigationPath: $navigationPath
            )
            
        case .cards:
            RecordCardGridView(
                questions: filteredQuestions,
                navigationPath: $navigationPath,
                config: config
            )
        }
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
                    .foregroundStyle(.red)
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
