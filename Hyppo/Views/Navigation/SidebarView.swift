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
    @Query(sort: \Tag.name) private var allTags: [Tag]
    
    // MARK: - State
    
    @Binding var selectedAsset: Asset?
    @State private var searchText = ""
    @State private var showingAddAsset = false
    @State private var showingArchived = false
    @State private var filterTag: Tag?
    @State private var showingTagManagement = false
    
    // MARK: - Computed Properties
    
    /// Filtered assets based on search, archive state, and tag filter
    private var filteredAssets: [Asset] {
        var result = assets
        
        // Filter by archive state
        if !showingArchived {
            result = result.filter { !$0.isArchived }
        }
        
        // Filter by tag
        if let tag = filterTag {
            result = result.filter { asset in
                asset.tags?.contains { $0.tagId == tag.tagId } ?? false
            }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            result = result.filter { asset in
                asset.tickerNormalized.lowercased().contains(searchLower) ||
                asset.ticker.lowercased().contains(searchLower) ||
                asset.name.lowercased().contains(searchLower)
            }
        }
        
        return result
    }
    
    /// Tags that have assets assigned
    private var tagsWithAssets: [Tag] {
        allTags.filter { tag in
            (tag.assets?.count ?? 0) > 0
        }
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
            // Tag filter section (only show if there are tags with assets)
            if !tagsWithAssets.isEmpty {
                Section {
                    // All assets option
                    Button {
                        filterTag = nil
                    } label: {
                        HStack {
                            Image(systemName: "square.grid.2x2")
                                .foregroundStyle(.secondary)
                            Text("All Assets")
                            Spacer()
                            if filterTag == nil {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    
                    // Tag filters
                    ForEach(tagsWithAssets) { tag in
                        Button {
                            filterTag = tag
                        } label: {
                            HStack {
                                Circle()
                                    .fill(colorFor(tag))
                                    .frame(width: 10, height: 10)
                                Text(tag.name)
                                Spacer()
                                Text("\(tag.assets?.count ?? 0)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if filterTag?.tagId == tag.tagId {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    HStack {
                        Text("Filter by Tag")
                        Spacer()
                        Button {
                            showingTagManagement = true
                        } label: {
                            Image(systemName: "gear")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
            
            // Assets section
            Section {
                if filteredAssets.isEmpty {
                    if assets.isEmpty {
                        // No assets at all - show empty state inline
                        Text("No assets yet")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                            .padding(.vertical, 4)
                    } else if !searchText.isEmpty || filterTag != nil {
                        // No search/filter results
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
                    if let tag = filterTag {
                        TagChip(tag: tag, isSelected: true) {
                            filterTag = nil
                        }
                    }
                    Spacer()
                    Text("\(filteredAssets.count)")
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
        .sheet(isPresented: $showingTagManagement) {
            TagManagementSheet()
        }
    }
    
    // MARK: - Helpers
    
    private func colorFor(_ tag: Tag) -> Color {
        guard let colorName = tag.colorName,
              let tagColor = TagColor(rawValue: colorName) else {
            return .blue
        }
        return tagColor.color
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
            
            // Name and scenario count
            VStack(alignment: .leading, spacing: 2) {
                Text(asset.name)
                    .font(.body)
                    .lineLimit(1)
                    .foregroundStyle(asset.isArchived ? .secondary : .primary)
                
                HStack(spacing: 6) {
                    Text("\(asset.researchQuestionsCount) \(asset.researchQuestionsCount == 1 ? "question" : "questions")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    // Show tag dots
                    if let tags = asset.tags, !tags.isEmpty {
                        HStack(spacing: 2) {
                            ForEach(tags.prefix(3)) { tag in
                                Circle()
                                    .fill(colorFor(tag))
                                    .frame(width: 6, height: 6)
                            }
                            if tags.count > 3 {
                                Text("+\(tags.count - 3)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
    
    private func colorFor(_ tag: Tag) -> Color {
        guard let colorName = tag.colorName,
              let tagColor = TagColor(rawValue: colorName) else {
            return .blue
        }
        return tagColor.color
    }
}

// MARK: - Preview

#Preview {
    NavigationSplitView {
        SidebarView(selectedAsset: .constant(nil))
            .modelContainer(for: [Asset.self, Tag.self], inMemory: true)
    } detail: {
        Text("Detail")
    }
}

