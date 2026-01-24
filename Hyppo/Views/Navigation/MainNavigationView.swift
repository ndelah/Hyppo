/**
 MainNavigationView is the root navigation container for the app.
 
 Provides a three-column layout: sidebar (assets), content (research questions),
 and detail (research question detail or scenario detail). On smaller windows, columns collapse appropriately.
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
    @State private var selectedScenario: Scenario?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    // Shortcut-triggered sheets
    @State private var showingAddAssetSheet = false
    @State private var showingAddLogSheet = false
    @State private var showingNoScenarioAlert = false
    
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
            // Detail - Research Question detail (with scenarios) or Scenario detail
            if let scenario = selectedScenario {
                ScenarioDetailView(scenario: scenario)
            } else if let question = selectedResearchQuestion {
                ResearchQuestionDetailView(researchQuestion: question, selectedScenario: $selectedScenario)
            } else if selectedAsset != nil {
                EmptyStateView(
                    iconName: "questionmark.circle",
                    title: "Select a Research Question",
                    description: "Choose a research question from the list to view its scenarios."
                )
            } else {
                EmptyStateView.noSelection
            }
        }
        .onChange(of: selectedAsset) { oldValue, newValue in
            // Clear research question and scenario selection when asset changes
            if oldValue != newValue {
                selectedResearchQuestion = nil
                selectedScenario = nil
            }
        }
        .onChange(of: selectedResearchQuestion) { oldValue, newValue in
            // Clear scenario selection when research question changes
            if oldValue != newValue {
                selectedScenario = nil
            }
        }
        // Handle menu shortcut notifications
        .onReceive(NotificationCenter.default.publisher(for: .addAsset)) { _ in
            showingAddAssetSheet = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .addLogEntry)) { _ in
            if selectedScenario != nil {
                showingAddLogSheet = true
            } else {
                showingNoScenarioAlert = true
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
            if let scenario = selectedScenario {
                LogEntryFormView(mode: .add(scenario: scenario)) { newLogEntry in
                    modelContext.insert(newLogEntry)
                    newLogEntry.scenario = scenario
                }
            }
        }
        .alert("No Scenario Selected", isPresented: $showingNoScenarioAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please select a scenario first to add a log entry. Use ⌘⇧L after selecting a scenario.")
        }
    }
}

// MARK: - Preview

#Preview {
    MainNavigationView()
        .modelContainer(for: [Asset.self, ResearchQuestion.self, Scenario.self, LogEntry.self, Evidence.self, Tag.self, ReviewReminder.self], inMemory: true)
}








