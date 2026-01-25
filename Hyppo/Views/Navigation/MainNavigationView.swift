/**
 MainNavigationView is the root navigation container for the app.
 
 Provides a three-column layout: sidebar (assets), content (research questions),
 and detail (research question detail). On smaller windows, columns collapse appropriately.
 */

import SwiftUI
import SwiftData

/// Root navigation view with sidebar and detail areas
struct MainNavigationView: View {
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - State
    
    @State private var selectedAsset: Asset?
    @State private var selectedResearchQuestion: ResearchQuestion?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    // Shortcut-triggered sheets
    @State private var showingAddAssetSheet = false
    @State private var showingAddLogSheet = false
    @State private var showingNoResearchQuestionAlert = false
    @State private var showingGlobalSearch = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar - Asset list
            SidebarView(selectedAsset: $selectedAsset)
                .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 350)
        } content: {
            // Content - Research Questions for selected asset
            if let asset = selectedAsset {
                AssetDetailView(asset: asset, selectedResearchQuestion: $selectedResearchQuestion)
                    .navigationSplitViewColumnWidth(min: 300, ideal: 350, max: 450)
            } else {
                EmptyStateView.noSelection
            }
        } detail: {
            // Detail - Research Question detail (single report view)
            if let question = selectedResearchQuestion {
                ResearchQuestionDetailView(researchQuestion: question)
            } else if selectedAsset != nil {
                EmptyStateView(
                    iconName: "questionmark.circle",
                    title: "Select a Research Question",
                    description: "Choose a research question from the list to view its details and timeline."
                )
            } else {
                EmptyStateView.noSelection
            }
        }
        .onChange(of: selectedAsset) { oldValue, newValue in
            // Clear research question selection when asset changes
            if oldValue != newValue {
                selectedResearchQuestion = nil
            }
        }
        // Handle menu shortcut notifications
        .onReceive(NotificationCenter.default.publisher(for: .addAsset)) { _ in
            showingAddAssetSheet = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .addLogEntry)) { _ in
            if selectedResearchQuestion != nil {
                showingAddLogSheet = true
            } else {
                showingNoResearchQuestionAlert = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showGlobalSearch)) { _ in
            showingGlobalSearch = true
        }
        // Shortcut-triggered sheets
        .sheet(isPresented: $showingAddAssetSheet) {
            AssetFormView(mode: .add) { newAsset in
                modelContext.insert(newAsset)
                selectedAsset = newAsset
            }
        }
        .sheet(isPresented: $showingAddLogSheet) {
            if let researchQuestion = selectedResearchQuestion {
                LogEntryFormView(mode: .add(researchQuestion: researchQuestion)) { newLogEntry in
                    modelContext.insert(newLogEntry)
                    newLogEntry.researchQuestion = researchQuestion
                }
            }
        }
        .alert("No Research Question Selected", isPresented: $showingNoResearchQuestionAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please select a research question first to add a log entry. Use ⌘⇧L after selecting a research question.")
        }
        .sheet(isPresented: $showingGlobalSearch) {
            GlobalSearchView(
                selectedAsset: $selectedAsset,
                selectedResearchQuestion: $selectedResearchQuestion
            )
        }
    }
}

// MARK: - Preview

#Preview {
    MainNavigationView()
        .modelContainer(for: [Asset.self, ResearchQuestion.self, LogEntry.self, Evidence.self, Tag.self, ReviewReminder.self], inMemory: true)
}
