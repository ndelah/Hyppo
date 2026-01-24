/**
 MainNavigationView is the root navigation container for the app.
 
 Provides a three-column layout: sidebar (assets), content (theses/logs),
 and detail (thesis detail). On smaller windows, columns collapse appropriately.
 */

import SwiftUI
import SwiftData

/// Root navigation view with sidebar and detail areas
struct MainNavigationView: View {
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - State
    
    @State private var selectedAsset: Asset?
    @State private var selectedThesis: Thesis?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    // Shortcut-triggered sheets
    @State private var showingAddAssetSheet = false
    @State private var showingAddLogSheet = false
    @State private var showingNoThesisAlert = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar - Asset list
            SidebarView(selectedAsset: $selectedAsset)
                .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 350)
        } content: {
            // Content - Thesis list for selected asset
            if let asset = selectedAsset {
                AssetDetailView(asset: asset, selectedThesis: $selectedThesis)
                    .navigationSplitViewColumnWidth(min: 300, ideal: 350, max: 450)
            } else {
                EmptyStateView.noSelection
            }
        } detail: {
            // Detail - Thesis detail view
            if let thesis = selectedThesis {
                ThesisDetailView(thesis: thesis)
            } else if selectedAsset != nil {
                EmptyStateView(
                    iconName: "doc.text",
                    title: "Select a Thesis",
                    description: "Choose a thesis from the list to view its details and timeline."
                )
            } else {
                EmptyStateView.noSelection
            }
        }
        .onChange(of: selectedAsset) { oldValue, newValue in
            // Clear thesis selection when asset changes
            if oldValue != newValue {
                selectedThesis = nil
            }
        }
        // Handle menu shortcut notifications
        .onReceive(NotificationCenter.default.publisher(for: .addAsset)) { _ in
            showingAddAssetSheet = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .addLogEntry)) { _ in
            if selectedThesis != nil {
                showingAddLogSheet = true
            } else {
                showingNoThesisAlert = true
            }
        }
        // Shortcut-triggered sheets
        .sheet(isPresented: $showingAddAssetSheet) {
            AssetFormView(mode: .add) { newAsset in
                modelContext.insert(newAsset)
                selectedAsset = newAsset
            }
        }
        .sheet(isPresented: $showingAddLogSheet) {
            if let thesis = selectedThesis {
                LogEntryFormView(mode: .add(thesis: thesis)) { newLogEntry in
                    modelContext.insert(newLogEntry)
                    newLogEntry.thesis = thesis
                }
            }
        }
        .alert("No Thesis Selected", isPresented: $showingNoThesisAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please select a thesis first to add a log entry. Use ⌘⇧L after selecting a thesis.")
        }
    }
}

// MARK: - Preview

#Preview {
    MainNavigationView()
        .modelContainer(for: [Asset.self, Thesis.self, LogEntry.self, Evidence.self, Tag.self, ReviewReminder.self], inMemory: true)
}





