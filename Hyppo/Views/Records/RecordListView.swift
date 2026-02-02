/**
 RecordListView is the main container for displaying research question records.
 
 Features:
 - View mode switcher (Table, Kanban, Cards)
 - Advanced search bar with filters, group by, and saved searches
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
            // Left: New button
            Button {
                showingAddQuestion = true
            } label: {
                Label("New", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
            
            // Center: Search bar with popover
            searchBar
            
            Spacer()
            
            // Right: Record count and view mode picker
            Text("\(filteredQuestions.count) \(filteredQuestions.count == 1 ? "record" : "records")")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Divider()
                .frame(height: 24)
            
            viewModePicker
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    private var searchBar: some View {
        Button {
            showingSearchPopover = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                
                if !searchText.isEmpty {
                    Text(searchText)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                } else {
                    Text("Search...")
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Filter badge
                if activeFilterCount > 0 {
                    Text("\(activeFilterCount)")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                
                // Group by indicator
                if config.groupByColumn != .none {
                    Image(systemName: "rectangle.3.group")
                        .font(.caption)
                        .foregroundStyle(.accentColor)
                }
                
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(minWidth: 280, maxWidth: 400)
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
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
                .background(Color(nsColor: .controlBackgroundColor))
                
                Divider()
                
                SearchPopoverView(config: config, searchText: $searchText)
            }
        }
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
                config: config,
                showingColumnSettings: $showingColumnSettings
            )
            
        case .kanban:
            RecordKanbanView(
                questions: filteredQuestions,
                navigationPath: $navigationPath,
                config: config
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
