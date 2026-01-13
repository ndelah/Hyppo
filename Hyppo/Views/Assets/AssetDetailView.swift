/**
 AssetDetailView displays the detail view for a selected asset.
 
 Shows asset information header and lists all theses for the asset,
 allowing the user to select a thesis for detailed viewing.
 */

import SwiftUI
import SwiftData

/// Detail view for a selected asset showing its theses
struct AssetDetailView: View {
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Properties
    
    @Bindable var asset: Asset
    @Binding var selectedThesis: Thesis?
    
    // MARK: - State
    
    @State private var showingAddThesis = false
    @State private var showingEditAsset = false
    @State private var searchText = ""
    @State private var statusFilter: ThesisStatus? = nil
    
    // MARK: - Computed Properties
    
    /// Filtered and sorted theses
    private var filteredTheses: [Thesis] {
        var result = asset.theses ?? []
        
        // Filter by status
        if let status = statusFilter {
            result = result.filter { $0.status == status }
        }
        
        // Filter by search
        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            result = result.filter { thesis in
                thesis.title.lowercased().contains(searchLower) ||
                thesis.thesisStatement.lowercased().contains(searchLower)
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
            
            // Theses list
            if (asset.theses ?? []).isEmpty {
                EmptyStateView.noTheses {
                    showingAddThesis = true
                }
            } else {
                thesesList
            }
        }
        .navigationTitle(asset.ticker)
        .searchable(text: $searchText, prompt: "Search theses")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Status filter menu
                Menu {
                    Button("All Statuses") {
                        statusFilter = nil
                    }
                    Divider()
                    ForEach(ThesisStatus.allCases) { status in
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
                
                Button(action: { showingAddThesis = true }) {
                    Label("Add Thesis", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddThesis) {
            ThesisFormView(mode: .add(asset: asset)) { newThesis in
                modelContext.insert(newThesis)
                newThesis.asset = asset
                selectedThesis = newThesis
            }
        }
        .sheet(isPresented: $showingEditAsset) {
            AssetFormView(mode: .edit(asset)) { _ in }
        }
    }
    
    // MARK: - Subviews
    
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
                    Text("• \(asset.thesesCount) \(asset.thesesCount == 1 ? "thesis" : "theses")")
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
    
    private var thesesList: some View {
        List(selection: $selectedThesis) {
            if filteredTheses.isEmpty && !searchText.isEmpty {
                Text("No matching theses")
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ForEach(filteredTheses) { thesis in
                    ThesisRowView(thesis: thesis)
                        .tag(thesis)
                        .contextMenu {
                            thesisContextMenu(for: thesis)
                        }
                }
                .onDelete(perform: deleteTheses)
            }
        }
        .listStyle(.inset)
    }
    
    // MARK: - Context Menu
    
    @ViewBuilder
    private func thesisContextMenu(for thesis: Thesis) -> some View {
        Button {
            // Edit - handled elsewhere
        } label: {
            Label("Edit", systemImage: "pencil")
        }
        
        Divider()
        
        Menu("Change Status") {
            ForEach(ThesisStatus.allCases) { status in
                Button {
                    thesis.updateStatus(status)
                } label: {
                    if thesis.status == status {
                        Label(status.displayName, systemImage: "checkmark")
                    } else {
                        Text(status.displayName)
                    }
                }
            }
        }
        
        Divider()
        
        Button(role: .destructive) {
            deleteThesis(thesis)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    
    // MARK: - Actions
    
    private func deleteTheses(at offsets: IndexSet) {
        for index in offsets {
            let thesis = filteredTheses[index]
            if selectedThesis == thesis {
                selectedThesis = nil
            }
            modelContext.delete(thesis)
        }
    }
    
    private func deleteThesis(_ thesis: Thesis) {
        if selectedThesis == thesis {
            selectedThesis = nil
        }
        modelContext.delete(thesis)
    }
}

// MARK: - Thesis Row View

/// Row view for displaying a thesis in the list
struct ThesisRowView: View {
    let thesis: Thesis
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title and type/status
            HStack {
                // Type icon
                Image(systemName: thesis.thesisType.iconName)
                    .foregroundStyle(typeColor)
                    .font(.body)
                
                Text(thesis.title)
                    .font(.headline)
                    .lineLimit(1)
                
                // Review due badge
                ReviewDueBadge(reminder: thesis.reviewReminder)
                
                Spacer()
                
                // Status badge
                statusBadge
            }
            
            // Thesis statement preview
            Text(thesis.thesisStatement)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            
            // Metadata row
            HStack(spacing: 12) {
                // Confidence
                if let confidence = thesis.confidence {
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
                    Text("\(thesis.logEntriesCount)")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
                
                Spacer()
                
                // Last updated
                Text(thesis.updatedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var typeColor: Color {
        switch thesis.thesisType {
        case .bull: return .green
        case .bear: return .red
        case .base: return .blue
        case .custom: return .purple
        }
    }
    
    private var statusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: thesis.status.iconName)
                .font(.caption2)
            Text(thesis.status.displayName)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(statusColor.opacity(0.15))
        .foregroundStyle(statusColor)
        .clipShape(Capsule())
    }
    
    private var statusColor: Color {
        switch thesis.status {
        case .active: return .green
        case .onHold: return .orange
        case .invalidated: return .red
        case .archived: return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    AssetDetailView(
        asset: Asset(ticker: "AAPL", name: "Apple Inc.", exchange: "NASDAQ", currency: "USD"),
        selectedThesis: .constant(nil)
    )
    .modelContainer(for: [Asset.self, Thesis.self, ReviewReminder.self], inMemory: true)
}

