/**
 ContentView serves as a wrapper for the main navigation view.
 
 Uses OdooStyleNavigationView for the main UI with top menu bar navigation
 including Research Questions, Tasks, Reporting, and Configuration tabs.
 */

import SwiftUI
import SwiftData

/// Main content view wrapper - uses OdooStyleNavigationView
struct ContentView: View {
    var body: some View {
        OdooStyleNavigationView()
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: [Asset.self, ResearchQuestion.self, LogEntry.self, Evidence.self, Tag.self, ReviewReminder.self, Driver.self, ResearchTask.self], inMemory: true)
}
