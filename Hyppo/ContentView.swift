/**
 ContentView serves as a wrapper for the main navigation view.
 
 This file is kept for compatibility but the main UI is now
 implemented in MainNavigationView.swift.
 */

import SwiftUI
import SwiftData

/// Main content view wrapper - redirects to MainNavigationView
struct ContentView: View {
    var body: some View {
        MainNavigationView()
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: [Asset.self, Thesis.self, LogEntry.self, Evidence.self, Tag.self, ReviewReminder.self], inMemory: true)
}
