/**
 GlobalSearchView provides app-wide search across all entities.
 
 Searches across Assets, Research Questions, Log Entries, and Evidence
 to help users quickly find relevant information.
 */

import SwiftUI
import SwiftData

/// Global search view that searches across all entity types
struct GlobalSearchView: View {
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Navigation State
    
    @Binding var selectedAsset: Asset?
    @Binding var selectedResearchQuestion: ResearchQuestion?
    
    /// Optional callback for NavigationStack-based navigation
    var onSelectQuestion: ((ResearchQuestion) -> Void)?
    
    // MARK: - Queries
    
    @Query(sort: \Asset.tickerNormalized) private var allAssets: [Asset]
    @Query(sort: \ResearchQuestion.updatedAt, order: .reverse) private var allResearchQuestions: [ResearchQuestion]
    @Query(sort: \LogEntry.occurredAt, order: .reverse) private var allLogEntries: [LogEntry]
    @Query(sort: \Evidence.capturedAt, order: .reverse) private var allEvidence: [Evidence]
    @Query(sort: \Tag.name) private var allTags: [Tag]
    
    // MARK: - State
    
    @State private var searchText = ""
    @State private var selectedEntityType: EntityType? = nil
    @State private var selectedTag: Tag? = nil
    @State private var selectedConfidence: ConfidenceLevel? = nil
    @State private var dateRange: DateRange? = nil
    @State private var showingAdvancedFilters = false
    
    // MARK: - Entity Type Filter
    
    enum EntityType: String, CaseIterable, Identifiable {
        case all = "All"
        case assets = "Assets"
        case researchQuestions = "Research Questions"
        case logEntries = "Log Entries"
        case evidence = "Evidence"
        
        var id: String { rawValue }
        
        var iconName: String {
            switch self {
            case .all: return "magnifyingglass"
            case .assets: return "building.2"
            case .researchQuestions: return "questionmark.circle"
            case .logEntries: return "note.text"
            case .evidence: return "link"
            }
        }
    }
    
    // MARK: - Date Range
    
    struct DateRange {
        var startDate: Date?
        var endDate: Date?
        
        func contains(_ date: Date) -> Bool {
            if let start = startDate, date < start {
                return false
            }
            if let end = endDate, date > end {
                return false
            }
            return true
        }
    }
    
    // MARK: - Search Results
    
    struct SearchResult: Identifiable {
        let id: UUID
        let entityType: EntityType
        let title: String
        let subtitle: String
        let entity: Any
        
        init(asset: Asset) {
            self.id = asset.assetId
            self.entityType = .assets
            self.title = "\(asset.ticker) - \(asset.name)"
            self.subtitle = "\(asset.researchQuestionsCount) research questions"
            self.entity = asset
        }
        
        init(question: ResearchQuestion) {
            self.id = question.questionId
            self.entityType = .researchQuestions
            self.title = question.questionText
            if let asset = question.asset {
                self.subtitle = "\(asset.ticker) - \(asset.name)"
            } else {
                self.subtitle = "No asset"
            }
            self.entity = question
        }
        
        init(logEntry: LogEntry) {
            self.id = logEntry.logEntryId
            self.entityType = .logEntries
            self.title = logEntry.title
            if let question = logEntry.researchQuestion, let asset = question.asset {
                self.subtitle = "\(asset.ticker) • \(question.questionText.prefix(30))..."
            } else {
                self.subtitle = logEntry.entryType.displayName
            }
            self.entity = logEntry
        }
        
        init(evidence: Evidence) {
            self.id = evidence.evidenceId
            self.entityType = .evidence
            self.title = evidence.effectiveTitle
            if let logEntry = evidence.logEntry, let question = logEntry.researchQuestion, let asset = question.asset {
                self.subtitle = "\(asset.ticker) • \(question.questionText.prefix(30))..."
            } else {
                self.subtitle = evidence.evidenceType.displayName
            }
            self.entity = evidence
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredResults: [SearchResult] {
        var results: [SearchResult] = []
        
        // Search assets
        if selectedEntityType == nil || selectedEntityType == .all || selectedEntityType == .assets {
            for asset in allAssets {
                if matchesSearch(asset: asset) && matchesFilters(asset: asset) {
                    results.append(SearchResult(asset: asset))
                }
            }
        }
        
        // Search research questions
        if selectedEntityType == nil || selectedEntityType == .all || selectedEntityType == .researchQuestions {
            for question in allResearchQuestions {
                if matchesSearch(question: question) && matchesFilters(question: question) {
                    results.append(SearchResult(question: question))
                }
            }
        }
        
        // Search log entries
        if selectedEntityType == nil || selectedEntityType == .all || selectedEntityType == .logEntries {
            for logEntry in allLogEntries {
                if matchesSearch(logEntry: logEntry) && matchesFilters(logEntry: logEntry) {
                    results.append(SearchResult(logEntry: logEntry))
                }
            }
        }
        
        // Search evidence
        if selectedEntityType == nil || selectedEntityType == .all || selectedEntityType == .evidence {
            for evidence in allEvidence {
                if matchesSearch(evidence: evidence) && matchesFilters(evidence: evidence) {
                    results.append(SearchResult(evidence: evidence))
                }
            }
        }
        
        return results
    }
    
    // MARK: - Search Matching
    
    private func matchesSearch(asset: Asset) -> Bool {
        if searchText.isEmpty { return true }
        let searchLower = searchText.lowercased()
        return asset.tickerNormalized.contains(searchLower) ||
               asset.name.lowercased().contains(searchLower) ||
               (asset.exchange?.lowercased().contains(searchLower) ?? false)
    }
    
    private func matchesSearch(question: ResearchQuestion) -> Bool {
        if searchText.isEmpty { return true }
        let searchLower = searchText.lowercased()
        
        // Search in basic fields
        if question.questionText.lowercased().contains(searchLower) ||
           (question.context?.lowercased().contains(searchLower) ?? false) ||
           (question.thesisStatement?.lowercased().contains(searchLower) ?? false) {
            return true
        }
        
        // Search in drivers
        if let drivers = question.drivers {
            let driverText = drivers.map { $0.title }.joined(separator: " ")
            if driverText.lowercased().contains(searchLower) {
                return true
            }
        }
        
        return false
    }
    
    private func matchesSearch(logEntry: LogEntry) -> Bool {
        if searchText.isEmpty { return true }
        let searchLower = searchText.lowercased()
        return logEntry.title.lowercased().contains(searchLower) ||
               logEntry.body.lowercased().contains(searchLower)
    }
    
    private func matchesSearch(evidence: Evidence) -> Bool {
        if searchText.isEmpty { return true }
        let searchLower = searchText.lowercased()
        return (evidence.displayTitle?.lowercased().contains(searchLower) ?? false) ||
               (evidence.snippetText?.lowercased().contains(searchLower) ?? false) ||
               (evidence.annotationText?.lowercased().contains(searchLower) ?? false) ||
               (evidence.urlRaw?.lowercased().contains(searchLower) ?? false)
    }
    
    // MARK: - Filter Matching
    
    private func matchesFilters(asset: Asset) -> Bool {
        // Tag filter
        if let tag = selectedTag {
            guard let assetTags = asset.tags, assetTags.contains(where: { $0.tagId == tag.tagId }) else {
                return false
            }
        }
        
        // Date filter (on created/updated date)
        if let range = dateRange {
            if !range.contains(asset.createdAt) && !range.contains(asset.updatedAt) {
                return false
            }
        }
        
        return true
    }
    
    private func matchesFilters(question: ResearchQuestion) -> Bool {
        // Tag filter
        if let tag = selectedTag {
            guard let questionTags = question.tags, questionTags.contains(where: { $0.tagId == tag.tagId }) else {
                return false
            }
        }
        
        // Confidence filter
        if let confidence = selectedConfidence {
            guard let questionConfidence = question.confidence, questionConfidence == confidence else {
                return false
            }
        }
        
        // Date filter
        if let range = dateRange {
            if !range.contains(question.createdAt) && !range.contains(question.updatedAt) {
                return false
            }
        }
        
        return true
    }
    
    private func matchesFilters(logEntry: LogEntry) -> Bool {
        // Tag filter
        if let tag = selectedTag {
            guard let logTags = logEntry.tags, logTags.contains(where: { $0.tagId == tag.tagId }) else {
                return false
            }
        }
        
        // Date filter (on occurred date)
        if let range = dateRange {
            if !range.contains(logEntry.occurredAt) {
                return false
            }
        }
        
        return true
    }
    
    private func matchesFilters(evidence: Evidence) -> Bool {
        // Tag filter
        if let tag = selectedTag {
            guard let evidenceTags = evidence.tags, evidenceTags.contains(where: { $0.tagId == tag.tagId }) else {
                return false
            }
        }
        
        // Date filter (on captured date)
        if let range = dateRange {
            if !range.contains(evidence.capturedAt) {
                return false
            }
        }
        
        return true
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar and filters
                VStack(spacing: 12) {
                    // Search field
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search all entities...", text: $searchText)
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
                    .padding(10)
                    .background(Color.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    // Quick filters
                    HStack(spacing: 8) {
                        // Entity type filter
                        Menu {
                            ForEach(EntityType.allCases) { type in
                                Button {
                                    selectedEntityType = type == .all ? nil : type
                                } label: {
                                    if (selectedEntityType == nil && type == .all) || selectedEntityType == type {
                                        Label(type.rawValue, systemImage: "checkmark")
                                    } else {
                                        Label(type.rawValue, systemImage: type.iconName)
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: selectedEntityType?.iconName ?? "magnifyingglass")
                                Text(selectedEntityType?.rawValue ?? "All Types")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.surface)
                            .clipShape(Capsule())
                        }
                        
                        // Tag filter
                        if !allTags.isEmpty {
                            Menu {
                                Button {
                                    selectedTag = nil
                                } label: {
                                    if selectedTag == nil {
                                        Label("All Tags", systemImage: "checkmark")
                                    } else {
                                        Text("All Tags")
                                    }
                                }
                                
                                Divider()
                                
                                ForEach(allTags) { tag in
                                    Button {
                                        selectedTag = selectedTag?.tagId == tag.tagId ? nil : tag
                                    } label: {
                                        if selectedTag?.tagId == tag.tagId {
                                            Label(tag.name, systemImage: "checkmark")
                                        } else {
                                            Label(tag.name, systemImage: "tag")
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "tag")
                                    Text(selectedTag?.name ?? "All Tags")
                                        .font(.caption)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(selectedTag != nil ? Color.accentColor.opacity(0.2) : Color.surface)
                                .clipShape(Capsule())
                            }
                        }
                        
                        // Confidence filter
                        Menu {
                            Button {
                                selectedConfidence = nil
                            } label: {
                                if selectedConfidence == nil {
                                    Label("All Confidence", systemImage: "checkmark")
                                } else {
                                    Text("All Confidence")
                                }
                            }
                            
                            Divider()
                            
                            ForEach(ConfidenceLevel.allCases) { level in
                                Button {
                                    selectedConfidence = selectedConfidence == level ? nil : level
                                } label: {
                                    if selectedConfidence == level {
                                        Label("\(level.shortLabel) - \(level.displayName)", systemImage: "checkmark")
                                    } else {
                                        Text("\(level.shortLabel) - \(level.displayName)")
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "gauge")
                                Text(selectedConfidence?.shortLabel ?? "All Confidence")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(selectedConfidence != nil ? Color.accentColor.opacity(0.2) : Color.surface)
                            .clipShape(Capsule())
                        }
                        
                        Spacer()
                        
                        // Advanced filters toggle
                        Button {
                            showingAdvancedFilters.toggle()
                        } label: {
                            Label("Date Range", systemImage: showingAdvancedFilters ? "chevron.up" : "chevron.down")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                    }
                    
                    // Advanced filters (date range)
                    if showingAdvancedFilters {
                        HStack(spacing: 12) {
                            DatePicker("From", selection: Binding(
                                get: { dateRange?.startDate ?? Date().addingTimeInterval(-30 * 24 * 60 * 60) },
                                set: { newValue in
                                    if dateRange == nil {
                                        dateRange = DateRange(startDate: newValue, endDate: nil)
                                    } else {
                                        dateRange?.startDate = newValue
                                    }
                                }
                            ), displayedComponents: .date)
                            .labelsHidden()
                            
                            DatePicker("To", selection: Binding(
                                get: { dateRange?.endDate ?? Date() },
                                set: { newValue in
                                    if dateRange == nil {
                                        dateRange = DateRange(startDate: nil, endDate: newValue)
                                    } else {
                                        dateRange?.endDate = newValue
                                    }
                                }
                            ), displayedComponents: .date)
                            .labelsHidden()
                            
                            Button {
                                dateRange = nil
                            } label: {
                                Text("Clear")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderless)
                            
                            Spacer()
                        }
                        .padding(8)
                        .background(Color.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding()
                .background(Color.surface)
                
                Divider()
                
                // Results
                if filteredResults.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text(searchText.isEmpty ? "Start typing to search" : "No results found")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        if !searchText.isEmpty {
                            Text("Try adjusting your filters or search terms")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(groupedResults.keys.sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { entityType in
                            Section {
                                ForEach(groupedResults[entityType] ?? []) { result in
                                    Button {
                                        handleResultTap(result)
                                    } label: {
                                        SearchResultRow(result: result)
                                    }
                                    .buttonStyle(.plain)
                                }
                            } header: {
                                HStack {
                                    Image(systemName: entityType.iconName)
                                    Text(entityType.rawValue)
                                    Text("(\(groupedResults[entityType]?.count ?? 0))")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .listStyle(.sidebar)
                }
            }
            .navigationTitle("Global Search")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Text("\(filteredResults.count) result\(filteredResults.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(minWidth: 600, minHeight: 500)
    }
    
    // MARK: - Grouped Results
    
    private var groupedResults: [EntityType: [SearchResult]] {
        Dictionary(grouping: filteredResults) { $0.entityType }
    }
    
    // MARK: - Actions
    
    private func handleResultTap(_ result: SearchResult) {
        // Use the new callback-based navigation if available
        if let onSelectQuestion = onSelectQuestion {
            if let question = result.entity as? ResearchQuestion {
                onSelectQuestion(question)
            } else if let logEntry = result.entity as? LogEntry, let question = logEntry.researchQuestion {
                onSelectQuestion(question)
            } else if let evidence = result.entity as? Evidence, let question = evidence.logEntry?.researchQuestion {
                onSelectQuestion(question)
            }
            // Note: Assets are no longer the primary navigation target
        } else {
            // Legacy binding-based navigation
            if let asset = result.entity as? Asset {
                selectedAsset = asset
                selectedResearchQuestion = nil
            } else if let question = result.entity as? ResearchQuestion {
                selectedAsset = question.asset
                selectedResearchQuestion = question
            } else if let logEntry = result.entity as? LogEntry {
                selectedAsset = logEntry.researchQuestion?.asset
                selectedResearchQuestion = logEntry.researchQuestion
            } else if let evidence = result.entity as? Evidence {
                selectedAsset = evidence.logEntry?.researchQuestion?.asset
                selectedResearchQuestion = evidence.logEntry?.researchQuestion
            }
        }
        
        dismiss()
    }
}

// MARK: - Search Result Row

private struct SearchResultRow: View {
    let result: GlobalSearchView.SearchResult
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: result.entityType.iconName)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(result.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(result.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    GlobalSearchView(
        selectedAsset: .constant(nil),
        selectedResearchQuestion: .constant(nil)
    )
    .modelContainer(for: [Asset.self, ResearchQuestion.self, LogEntry.self, Evidence.self, Tag.self], inMemory: true)
}
