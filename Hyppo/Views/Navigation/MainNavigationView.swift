/**
 MainNavigationView is the root navigation container for the app.
 
 Uses full-screen navigation with NavigationStack: the record list takes up
 the full window, and clicking a record pushes to a full-screen detail view.
 Back navigation returns to the list.
 */

import SwiftUI
import SwiftData

/// Root navigation view with full-screen list and detail navigation
struct MainNavigationView: View {
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - State
    
    @State private var navigationPath = NavigationPath()
    
    // Shortcut-triggered sheets
    @State private var showingGlobalSearch = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            // Full-screen record list
            RecordListView(navigationPath: $navigationPath)
                .navigationDestination(for: ResearchQuestion.self) { question in
                    ResearchQuestionDetailView(researchQuestion: question)
                }
        }
        // Handle menu shortcut notifications
        .onReceive(NotificationCenter.default.publisher(for: .showGlobalSearch)) { _ in
            showingGlobalSearch = true
        }
        .sheet(isPresented: $showingGlobalSearch) {
            GlobalSearchView(
                selectedAsset: .constant(nil),
                selectedResearchQuestion: .constant(nil),
                onSelectQuestion: { question in
                    navigationPath.append(question)
                }
            )
        }
    }
}

// MARK: - Preview

#Preview {
    MainNavigationView()
        .modelContainer(for: [Asset.self, ResearchQuestion.self, LogEntry.self, Evidence.self, Tag.self, ReviewReminder.self, Driver.self], inMemory: true)
}
