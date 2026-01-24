/**
 AssetDetailView displays the detail view for a selected asset.
 
 Shows asset information header and lists all research questions for the asset,
 allowing the user to select a research question for detailed viewing.
 */

import SwiftUI
import SwiftData

/// Detail view for a selected asset showing its research questions
struct AssetDetailView: View {
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Properties
    
    @Bindable var asset: Asset
    @Binding var selectedResearchQuestion: ResearchQuestion?
    
    // MARK: - State
    
    @State private var showingAddQuestion = false
    @State private var showingEditAsset = false
    @State private var searchText = ""
    @State private var statusFilter: ResearchQuestionStatus? = nil
    
    // MARK: - Computed Properties
    
    /// Filtered and sorted research questions
    private var filteredQuestions: [ResearchQuestion] {
        var result = asset.researchQuestions ?? []
        
        // Filter by status
        if let status = statusFilter {
            result = result.filter { $0.status == status }
        }
        
        // Filter by search
        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            result = result.filter { question in
                question.questionText.lowercased().contains(searchLower) ||
                (question.context?.lowercased().contains(searchLower) ?? false)
            }
        }
        
        // Sort by updated date (most recent first)
        return result.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Asset header
            assetHeader
            
            Divider()
            
            // Inline search bar
            if !(asset.researchQuestions ?? []).isEmpty {
                searchBar
                Divider()
            }
            
            // Research questions list
            if (asset.researchQuestions ?? []).isEmpty {
                EmptyStateView(
                    iconName: "questionmark.circle",
                    title: "No Research Questions",
                    description: "Start by adding a research question about this asset.",
                    actionTitle: "Add Research Question"
                ) {
                    showingAddQuestion = true
                }
            } else {
                questionsList
            }
        }
        .navigationTitle(asset.ticker)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Status filter menu
                Menu {
                    Button("All Statuses") {
                        statusFilter = nil
                    }
                    Divider()
                    ForEach(ResearchQuestionStatus.allCases) { status in
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
                
                Button(action: { showingAddQuestion = true }) {
                    Label("Add Research Question", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddQuestion) {
            ResearchQuestionFormView(mode: .add) { newQuestion in
                modelContext.insert(newQuestion)
                newQuestion.asset = asset
                selectedResearchQuestion = newQuestion
            }
        }
        .sheet(isPresented: $showingEditAsset) {
            AssetFormView(mode: .edit(asset)) { _ in }
        }
    }
    
    // MARK: - Subviews
    
    /// Inline search bar to avoid duplicate toolbar search items
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search research questions", text: $searchText)
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
    
    private var assetHeader: some View {
        HStack(spacing: 16) {
            // Ticker badge
            Text(asset.ticker)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Asset info
            VStack(alignment: .leading, spacing: 4) {
                Text(asset.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                HStack(spacing: 8) {
                    if let exchange = asset.exchange {
                        Text(exchange)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let currency = asset.currency {
                        Text("• \(currency)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text("• \(asset.researchQuestionsCount) \(asset.researchQuestionsCount == 1 ? "question" : "questions")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Edit button
            Button {
                showingEditAsset = true
            } label: {
                Image(systemName: "pencil")
            }
            .buttonStyle(.borderless)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    private var questionsList: some View {
        List(selection: $selectedResearchQuestion) {
            if filteredQuestions.isEmpty && !searchText.isEmpty {
                Text("No matching research questions")
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ForEach(filteredQuestions) { question in
                    ResearchQuestionRowView(question: question)
                        .tag(question)
                        .contextMenu {
                            questionContextMenu(for: question)
                        }
                }
                .onDelete(perform: deleteQuestions)
            }
        }
        .listStyle(.inset)
    }
    
    // MARK: - Context Menu
    
    @ViewBuilder
    private func questionContextMenu(for question: ResearchQuestion) -> some View {
        Button {
            // Edit - handled elsewhere
        } label: {
            Label("Edit", systemImage: "pencil")
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
        
        Divider()
        
        Button(role: .destructive) {
            deleteQuestion(question)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    
    // MARK: - Actions
    
    private func deleteQuestions(at offsets: IndexSet) {
        for index in offsets {
            let question = filteredQuestions[index]
            if selectedResearchQuestion == question {
                selectedResearchQuestion = nil
            }
            modelContext.delete(question)
        }
    }
    
    private func deleteQuestion(_ question: ResearchQuestion) {
        if selectedResearchQuestion == question {
            selectedResearchQuestion = nil
        }
        modelContext.delete(question)
    }
}

// MARK: - Research Question Row View

/// Row view for displaying a research question in the list
struct ResearchQuestionRowView: View {
    let question: ResearchQuestion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Question text and status
            HStack {
                Image(systemName: question.status.iconName)
                    .foregroundStyle(statusColor)
                    .font(.body)
                
                Text(question.questionText)
                    .font(.headline)
                    .lineLimit(2)
                
                Spacer()
                
                // Status badge
                statusBadge
            }
            
            // Context preview
            if let context = question.context, !context.isEmpty {
                Text(context)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            // Metadata row
            HStack(spacing: 12) {
                // Priority
                if let priority = question.priority {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                        Text("\(priority)/5")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
                
                // Scenarios count
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.arrow.down.circle")
                        .font(.caption)
                    Text("\(question.scenariosCount)")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
                
                Spacer()
                
                // Last updated
                Text(question.updatedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var statusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: question.status.iconName)
                .font(.caption2)
            Text(question.status.displayName)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(statusColor.opacity(0.15))
        .foregroundStyle(statusColor)
        .clipShape(Capsule())
    }
    
    private var statusColor: Color {
        switch question.status {
        case .open: return .blue
        case .answered: return .green
        case .parked: return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    let asset = Asset(ticker: "AAPL", name: "Apple Inc.", exchange: "NASDAQ", currency: "USD")
    return AssetDetailView(
        asset: asset,
        selectedResearchQuestion: .constant(nil)
    )
    .modelContainer(for: [Asset.self, ResearchQuestion.self, Scenario.self, ReviewReminder.self], inMemory: true)
}


