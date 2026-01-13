/**
 Footnote (Hyppo) application entry point.
 
 Configures the SwiftData model container with all entity types
 and installs the root navigation shell. Provides Settings window access.
 */

import SwiftUI
import SwiftData

@main
struct HyppoApp: App {
    // MARK: - Initialization
    
    init() {
        DebugLogger.info(
            location: "HyppoApp:init",
            message: "Footnote app initializing",
            data: ["models": "Asset, Thesis, LogEntry, Evidence, Tag"]
        )
    }
    
    // MARK: - Model Container
    
    /// Shared SwiftData model container for persistence
    var sharedModelContainer: ModelContainer = {
        DebugLogger.log(
            location: "HyppoApp:sharedModelContainer",
            message: "Creating ModelContainer",
            data: ["isStoredInMemoryOnly": false]
        )
        
        // Define the schema with all model types
        let schema = Schema([
            Asset.self,
            Thesis.self,
            LogEntry.self,
            Evidence.self,
            Tag.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            DebugLogger.info(
                location: "HyppoApp:sharedModelContainer",
                message: "ModelContainer created successfully"
            )
            
            return container
        } catch {
            DebugLogger.error(
                location: "HyppoApp:sharedModelContainer",
                message: "Failed to create ModelContainer",
                error: error
            )
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    // MARK: - Body
    
    var body: some Scene {
        // Main application window
        WindowGroup {
            MainNavigationView()
        }
        .modelContainer(sharedModelContainer)
        .windowStyle(.automatic)
        .defaultSize(width: 1200, height: 800)
        .commands {
            // Custom menu commands
            CommandGroup(after: .newItem) {
                Button("New Asset") {
                    NotificationCenter.default.post(name: .addAsset, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command])
                
                Button("New Thesis") {
                    NotificationCenter.default.post(name: .addThesis, object: nil)
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])
                
                Button("New Log Entry") {
                    NotificationCenter.default.post(name: .addLogEntry, object: nil)
                }
                .keyboardShortcut("l", modifiers: [.command, .shift])
            }
        }
        
        // Settings window
        Settings {
            SettingsView()
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Notification to trigger Add Asset action
    static let addAsset = Notification.Name("addAsset")
    
    /// Notification to trigger Add Thesis action
    static let addThesis = Notification.Name("addThesis")
    
    /// Notification to trigger Add Log Entry action
    static let addLogEntry = Notification.Name("addLogEntry")
}
