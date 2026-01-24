/**
 ResearchQuestionDetailView displays the detail view for a selected research question.
 
 Shows research question information and lists all scenarios for the question,
 allowing the user to select a scenario for detailed viewing.
 */

import SwiftUI
import SwiftData

/// Detail view for a selected research question showing its scenarios
struct ResearchQuestionDetailView: View {
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Properties
    
    @Bindable var researchQuestion: ResearchQuestion
    @Binding var selectedScenario: Scenario?
    
    // MARK: - State
    
    @State private var showingAddScenario = false
    @State private var showingEditQuestion = false
    @State private var searchText = ""
    @State private var statusFilter: ScenarioStatus? = nil
    
    // MARK: - Computed Properties
    
    /// Filtered and sorted scenarios
    private var filteredScenarios: [Scenario] {
        var result = researchQuestion.scenarios ?? []
        
        // Filter by status
        if let status = statusFilter {
            result = result.filter { $0.status == status }
        }
        
        // Filter by search
        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            result = result.filter { scenario in
                scenario.title.lowercased().contains(searchLower) ||
                scenario.scenarioStatement.lowercased().contains(searchLower)
            }
        }
        
        // Sort by type (bull, base, bear, custom) then by updated date
        return result.sorted { first, second in
            if first.scenarioType.sortOrder != second.scenarioType.sortOrder {
                return first.scenarioType.sortOrder < second.scenarioType.sortOrder
            }
            return first.updatedAt > second.updatedAt
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Research question header
            questionHeader
            
            Divider()
            
            // Inline search bar
            if !(researchQuestion.scenarios ?? []).isEmpty {
                searchBar
                Divider()
            }
            
            // Scenarios list
            if (researchQuestion.scenarios ?? []).isEmpty {
                EmptyStateView(
                    iconName: "arrow.up.arrow.down.circle",
                    title: "No Scenarios",
                    description: "Add scenarios (bull/base/bear) to explore different outcomes for this research question.",
                    actionTitle: "Add Scenario"
                ) {
                    showingAddScenario = true
                }
            } else {
                scenariosList
            }
        }
        .navigationTitle(researchQuestion.questionText)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Status filter menu
                Menu {
                    Button("All Statuses") {
                        statusFilter = nil
                    }
                    Divider()
                    ForEach(ScenarioStatus.allCases) { status in
                        Button {
                            statusFilter = status
                        } label: {
                            if statusFilter == status {
                                Label(status.displayName, systemImage: "checkmark")
                            } else {
                                Text(status.displayName)
                            }
                        }
                    }
                } label: {
                    Label("Filter", systemImage: statusFilter == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                }
                
                Button(action: { showingAddScenario = true }) {
                    Label("Add Scenario", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddScenario) {
            ScenarioFormView(mode: .add(researchQuestion: researchQuestion)) { newScenario in
                modelContext.insert(newScenario)
                newScenario.researchQuestion = researchQuestion
                selectedScenario = newScenario
            }
        }
        .sheet(isPresented: $showingEditQuestion) {
            ResearchQuestionFormView(mode: .edit(researchQuestion)) { _ in }
        }
    }
    
    // MARK: - Subviews
    
    /// Inline search bar to avoid duplicate toolbar search items
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search scenarios", text: $searchText)
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
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    private var questionHeader: some View {
        HStack(spacing: 16) {
            // Status icon
            Image(systemName: researchQuestion.status.iconName)
                .font(.title)
                .foregroundStyle(statusColor)
            
            // Question info
            VStack(alignment: .leading, spacing: 6) {
                Text(researchQuestion.questionText)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .lineLimit(3)
                
                HStack(spacing: 8) {
                    // Status
                    Text(researchQuestion.status.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    // Priority
                    if let priority = researchQuestion.priority {
                        Text("• Priority: \(priority)/5")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Scenario count
                    Text("• \(researchQuestion.scenariosCount) \(researchQuestion.scenariosCount == 1 ? "scenario" : "scenarios")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Context if available
                if let context = researchQuestion.context, !context.isEmpty {
                    Text(context)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(2)
                        .padding(.top, 2)
                }
            }
            
            Spacer()
            
            // Edit button
            Button {
                showingEditQuestion = true
            } label: {
                Image(systemName: "pencil")
            }
            .buttonStyle(.borderless)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    private var scenariosList: some View {
        List(selection: $selectedScenario) {
            if filteredScenarios.isEmpty && !searchText.isEmpty {
                Text("No matching scenarios")
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ForEach(filteredScenarios) { scenario in
                    ScenarioRowView(scenario: scenario)
                        .tag(scenario)
                        .contextMenu {
                            scenarioContextMenu(for: scenario)
                        }
                }
                .onDelete(perform: deleteScenarios)
            }
        }
        .listStyle(.inset)
    }
    
    // MARK: - Context Menu
    
    @ViewBuilder
    private func scenarioContextMenu(for scenario: Scenario) -> some View {
        Button {
            // Edit - handled elsewhere
        } label: {
            Label("Edit", systemImage: "pencil")
        }
        
        Divider()
        
        Menu("Change Status") {
            ForEach(ScenarioStatus.allCases) { status in
                Button {
                    changeScenarioStatus(scenario, to: status)
                } label: {
                    if scenario.status == status {
                        Label(status.displayName, systemImage: "checkmark")
                    } else {
                        Text(status.displayName)
                    }
                }
            }
        }
        
        Divider()
        
        Button(role: .destructive) {
            deleteScenario(scenario)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    
    // MARK: - Actions
    
    private func deleteScenarios(at offsets: IndexSet) {
        for index in offsets {
            let scenario = filteredScenarios[index]
            if selectedScenario == scenario {
                selectedScenario = nil
            }
            modelContext.delete(scenario)
        }
    }
    
    private func deleteScenario(_ scenario: Scenario) {
        if selectedScenario == scenario {
            selectedScenario = nil
        }
        modelContext.delete(scenario)
    }
    
    private func changeScenarioStatus(_ scenario: Scenario, to newStatus: ScenarioStatus) {
        // Update status and get the old status for logging
        if let oldStatus = scenario.updateStatus(newStatus) {
            // Create auto-generated log entry for the status change
            let logEntry = LogEntry.createStatusChangeLog(
                fromStatus: oldStatus,
                toStatus: newStatus
            )
            modelContext.insert(logEntry)
            logEntry.scenario = scenario
        }
    }
    
    private var statusColor: Color {
        switch researchQuestion.status {
        case .open: return .blue
        case .answered: return .green
        case .parked: return .gray
        }
    }
}

// MARK: - Scenario Row View

/// Row view for displaying a scenario in the list
struct ScenarioRowView: View {
    let scenario: Scenario
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title and type/status
            HStack {
                // Type icon
                Image(systemName: scenario.scenarioType.iconName)
                    .foregroundStyle(typeColor)
                    .font(.body)
                
                Text(scenario.title)
                    .font(.headline)
                    .lineLimit(1)
                
                // Review due badge
                ReviewDueBadge(reminder: scenario.reviewReminder)
                
                Spacer()
                
                // Status badge
                statusBadge
            }
            
            // Scenario statement preview
            Text(scenario.scenarioStatement)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            
            // Metadata row
            HStack(spacing: 12) {
                // Confidence
                if let confidence = scenario.confidence {
                    HStack(spacing: 4) {
                        Image(systemName: "gauge")
                            .font(.caption)
                        Text(confidence.shortLabel)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
                
                // Log entries count
                HStack(spacing: 4) {
                    Image(systemName: "note.text")
                        .font(.caption)
                    Text("\(scenario.logEntriesCount)")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
                
                Spacer()
                
                // Last updated
                Text(scenario.updatedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var typeColor: Color {
        switch scenario.scenarioType {
        case .bull: return .green
        case .bear: return .red
        case .base: return .blue
        case .custom: return .purple
        }
    }
    
    private var statusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: scenario.status.iconName)
                .font(.caption2)
            Text(scenario.status.displayName)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(statusColor.opacity(0.15))
        .foregroundStyle(statusColor)
        .clipShape(Capsule())
    }
    
    private var statusColor: Color {
        switch scenario.status {
        case .active: return .green
        case .onHold: return .orange
        case .invalidated: return .red
        case .archived: return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    let question = ResearchQuestion(
        questionText: "Can AAPL sustain services revenue growth?",
        context: "Services now represent 20% of revenue",
        priority: 4
    )
    
    return ResearchQuestionDetailView(
        researchQuestion: question,
        selectedScenario: .constant(nil)
    )
    .modelContainer(for: [Asset.self, ResearchQuestion.self, Scenario.self, ReviewReminder.self], inMemory: true)
}

