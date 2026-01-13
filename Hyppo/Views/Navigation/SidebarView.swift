/**
 SidebarView provides the main navigation sidebar for the app.
 
 Displays the list of assets and provides navigation to asset details,
 as well as access to settings and other app-wide actions.
 */

import SwiftUI
import SwiftData

/// Main sidebar navigation view
struct SidebarView: View {
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Queries
    
    @Query(sort: \Asset.tickerNormalized) private var assets: [Asset]
    
    // MARK: - State
    
    @Binding var selectedAsset: Asset?
    @State private var searchText = ""
    @State private var showingAddAsset = false
    @State private var showingArchived = false
    
    // MARK: - Computed Properties
    
    /// Filtered assets based on search and archive state
    private var filteredAssets: [Asset] {
        var result = assets
        
        // Filter by archive state
        if !showingArchived {
            result = result.filter { !$0.isArchived }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            result = result.filter { asset in
                asset.tickerNormalized.contains(searchLower) ||
                asset.name.lowercased().contains(searchLower)
            }
        }
        
        return result
    }
    
    /// Count of active (non-archived) assets
    private var activeAssetsCount: Int {
        assets.filter { !$0.isArchived }.count
    }
    
    /// Count of archived assets
    private var archivedAssetsCount: Int {
        assets.filter { $0.isArchived }.count
    }
    
    // MARK: - Body
    
    var body: some View {
        List(selection: $selectedAsset) {
            // Assets section
            Section {
                if filteredAssets.isEmpty {
                    if assets.isEmpty {
                        // No assets at all - show empty state inline
                        Text("No assets yet")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                            .padding(.vertical, 4)
                    } else if !searchText.isEmpty {
                        // No search results
                        Text("No matching assets")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                            .padding(.vertical, 4)
                    }
                } else {
                    ForEach(filteredAssets) { asset in
                        AssetRowView(asset: asset)
                            .tag(asset)
                            .contextMenu {
                                assetContextMenu(for: asset)
                            }
                    }
                    .onDelete(perform: deleteAssets)
                }
            } header: {
                HStack {
                    Text("Assets")
                    Spacer()
                    Text("\(activeAssetsCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Archived section (if any archived assets exist)
            if archivedAssetsCount > 0 {
                Section {
                    DisclosureGroup(isExpanded: $showingArchived) {
                        ForEach(assets.filter { $0.isArchived }) { asset in
                            AssetRowView(asset: asset)
                                .tag(asset)
                                .contextMenu {
                                    assetContextMenu(for: asset)
                                }
                        }
                    } label: {
                        HStack {
                            Text("Archived")
                            Spacer()
                            Text("\(archivedAssetsCount)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .searchable(text: $searchText, placement: .sidebar, prompt: "Search assets")
        .navigationTitle("Footnote")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddAsset = true }) {
                    Label("Add Asset", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
        }
        .sheet(isPresented: $showingAddAsset) {
            AssetFormView(mode: .add) { newAsset in
                modelContext.insert(newAsset)
                selectedAsset = newAsset
            }
        }
    }
    
    // MARK: - Context Menu
    
    @ViewBuilder
    private func assetContextMenu(for asset: Asset) -> some View {
        Button {
            // Edit action - handled elsewhere
        } label: {
            Label("Edit", systemImage: "pencil")
        }
        
        Divider()
        
        if asset.isArchived {
            Button {
                asset.unarchive()
            } label: {
                Label("Unarchive", systemImage: "tray.and.arrow.up")
            }
        } else {
            Button {
                asset.archive()
            } label: {
                Label("Archive", systemImage: "archivebox")
            }
        }
        
        Divider()
        
        Button(role: .destructive) {
            deleteAsset(asset)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    
    // MARK: - Actions
    
    private func deleteAssets(at offsets: IndexSet) {
        for index in offsets {
            let asset = filteredAssets[index]
            if selectedAsset == asset {
                selectedAsset = nil
            }
            modelContext.delete(asset)
        }
    }
    
    private func deleteAsset(_ asset: Asset) {
        if selectedAsset == asset {
            selectedAsset = nil
        }
        modelContext.delete(asset)
    }
}

// MARK: - Asset Row View

/// Row view for displaying an asset in the sidebar list
struct AssetRowView: View {
    let asset: Asset
    
    var body: some View {
        HStack(spacing: 10) {
            // Ticker badge
            Text(asset.ticker)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(asset.isArchived ? Color.gray : Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            
            // Name and thesis count
            VStack(alignment: .leading, spacing: 2) {
                Text(asset.name)
                    .font(.body)
                    .lineLimit(1)
                    .foregroundStyle(asset.isArchived ? .secondary : .primary)
                
                Text("\(asset.thesesCount) \(asset.thesesCount == 1 ? "thesis" : "theses")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Preview

#Preview {
    NavigationSplitView {
        SidebarView(selectedAsset: .constant(nil))
            .modelContainer(for: Asset.self, inMemory: true)
    } detail: {
        Text("Detail")
    }
}

