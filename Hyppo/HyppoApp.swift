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
            data: ["models": "Asset, ResearchQuestion, Scenario, LogEntry, Evidence, Tag, ReviewReminder"]
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
            ResearchQuestion.self,
            Scenario.self,
            LogEntry.self,
            Evidence.self,
            Tag.self,
            ReviewReminder.self
        ])
        
        do {
            let storeName = "default"
            let storeURL = try SwiftDataStoreReset.defaultStoreURL(storeName: storeName)
            
            DebugLogger.info(
                location: "HyppoApp:sharedModelContainer",
                message: "Using SwiftData store location",
                data: ["url": storeURL.path]
            )
            
            let modelConfiguration = ModelConfiguration(
                storeName,
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
                    message: "Failed to create ModelContainer (will reset store and retry once)",
                    error: error,
                    data: ["storeURL": storeURL.path]
                )
                
                do {
                    try SwiftDataStoreReset.deleteStoreFiles(storeURL: storeURL)
                    
                    DebugLogger.warning(
                        location: "HyppoApp:sharedModelContainer",
                        message: "Deleted SwiftData store files after load failure; recreating ModelContainer",
                        data: ["storeURL": storeURL.path]
                    )
                    
                    let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
                    
                    DebugLogger.info(
                        location: "HyppoApp:sharedModelContainer",
                        message: "ModelContainer created successfully after store reset"
                    )
                    
                    return container
                } catch {
                    DebugLogger.error(
                        location: "HyppoApp:sharedModelContainer",
                        message: "Failed to recreate ModelContainer after store reset",
                        error: error,
                        data: ["storeURL": storeURL.path]
                    )
                    fatalError("Could not create ModelContainer after store reset: \(error)")
                }
            }
        } catch {
            DebugLogger.error(
                location: "HyppoApp:sharedModelContainer",
                message: "Failed to compute SwiftData store URL",
                error: error
            )
            fatalError("Could not compute SwiftData store URL: \(error)")
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
                
                Button("New Research Question") {
                    NotificationCenter.default.post(name: .addResearchQuestion, object: nil)
                }
                .keyboardShortcut("q", modifiers: [.command, .shift])
                
                Button("New Scenario") {
                    NotificationCenter.default.post(name: .addScenario, object: nil)
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
    
    /// Notification to trigger Add Research Question action
    static let addResearchQuestion = Notification.Name("addResearchQuestion")
    
    /// Notification to trigger Add Scenario action
    static let addScenario = Notification.Name("addScenario")
    
    /// Notification to trigger Add Log Entry action
    static let addLogEntry = Notification.Name("addLogEntry")
}
