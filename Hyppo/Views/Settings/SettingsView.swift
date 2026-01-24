/**
 SettingsView provides application preferences and configuration options.
 
 This view is accessible from the app menu (Preferences) and allows
 users to configure backup settings, export options, and app behavior.
 */

import SwiftUI
import SwiftData

/// Main settings/preferences view
struct SettingsView: View {
    // MARK: - State
    
    /// Selected settings tab
    @State private var selectedTab: SettingsTab = .general
    
    // MARK: - Body
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsTab()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(SettingsTab.general)
            
            BackupSettingsTab()
                .tabItem {
                    Label("Backup", systemImage: "externaldrive")
                }
                .tag(SettingsTab.backup)
            
            AboutSettingsTab()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(SettingsTab.about)
        }
        .frame(width: 500, height: 350)
    }
}

// MARK: - Settings Tabs Enum

private enum SettingsTab: String {
    case general
    case backup
    case about
}

// MARK: - Display Density

/// Controls the amount of information shown in the UI
enum DisplayDensity: String, CaseIterable, Identifiable {
    case compact = "compact"
    case comfortable = "comfortable"
    case expanded = "expanded"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .compact: return "Compact"
        case .comfortable: return "Comfortable"
        case .expanded: return "Expanded"
        }
    }
    
    var description: String {
        switch self {
        case .compact: return "Minimal info, collapsed sections"
        case .comfortable: return "Balanced view (default)"
        case .expanded: return "All details visible"
        }
    }
    
    /// Number of lines to show in log entry body preview
    var bodyPreviewLines: Int {
        switch self {
        case .compact: return 1
        case .comfortable: return 3
        case .expanded: return 6
        }
    }
    
    /// Whether to expand scenario sections by default
    var expandSectionsByDefault: Bool {
        switch self {
        case .compact: return false
        case .comfortable: return true
        case .expanded: return true
        }
    }
    
    /// Whether to show metadata row in log cards
    var showMetadataRow: Bool {
        switch self {
        case .compact: return false
        case .comfortable: return true
        case .expanded: return true
        }
    }
}

// MARK: - General Settings Tab

private struct GeneralSettingsTab: View {
    @AppStorage("defaultConfidenceLevel") private var defaultConfidenceLevel: Int = 3
    @AppStorage("showSystemLogs") private var showSystemLogs: Bool = true
    @AppStorage("displayDensity") private var displayDensity: String = DisplayDensity.comfortable.rawValue
    
    private var density: DisplayDensity {
        DisplayDensity(rawValue: displayDensity) ?? .comfortable
    }
    
    var body: some View {
        Form {
            Section {
                Picker("UI Density", selection: $displayDensity) {
                    ForEach(DisplayDensity.allCases) { density in
                        VStack(alignment: .leading) {
                            Text(density.displayName)
                            Text(density.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .tag(density.rawValue)
                    }
                }
                .pickerStyle(.inline)
                
                Picker("Default Confidence Level", selection: $defaultConfidenceLevel) {
                    ForEach(ConfidenceLevel.allCases, id: \.rawValue) { level in
                        Text(level.displayName).tag(level.rawValue)
                    }
                }
                .pickerStyle(.menu)
                
                Toggle("Show system-generated log entries", isOn: $showSystemLogs)
            } header: {
                Text("Display")
            }
            
            Section {
                Text("UI Density controls how much information is shown at once. Compact hides details until you expand them.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("About Density")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Backup Settings Tab

private struct BackupSettingsTab: View {
    @Environment(\.modelContext) private var modelContext
    
    @AppStorage("autoBackupEnabled") private var autoBackupEnabled: Bool = false
    @AppStorage("backupFolderPath") private var backupFolderPath: String = ""
    @AppStorage("maxBackupCount") private var maxBackupCount: Int = 10
    
    @State private var showFolderPicker = false
    @State private var showingExportImportSheet = false
    @State private var lastBackupDate: Date?
    
    var body: some View {
        Form {
            Section {
                Toggle("Enable automatic backups", isOn: $autoBackupEnabled)
                
                HStack {
                    Text("Backup folder:")
                    Spacer()
                    Text(backupFolderPath.isEmpty ? "Not set" : backupFolderPath)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Button("Choose...") {
                        showFolderPicker = true
                    }
                    .disabled(!autoBackupEnabled)
                }
                
                Stepper("Keep last \(maxBackupCount) backups", value: $maxBackupCount, in: 1...100)
                    .disabled(!autoBackupEnabled)
            } header: {
                Text("Automatic Backup")
            } footer: {
                Text("Automatic backups will be available in a future update.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            Section {
                Button {
                    showingExportImportSheet = true
                } label: {
                    Label("Open Export / Import...", systemImage: "arrow.up.arrow.down.square")
                }
                
                Text("Export all your data to JSON for backup, or import previously exported data.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if let lastBackup = lastBackupDate {
                    Text("Last export: \(lastBackup.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Export & Import")
            } footer: {
                Text("Use the Export button on individual scenarios to export as Markdown.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .formStyle(.grouped)
        .padding()
        .sheet(isPresented: $showingExportImportSheet) {
            ExportImportView()
        }
    }
}

// MARK: - About Settings Tab

private struct AboutSettingsTab: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // App icon placeholder
            Image(systemName: "note.text.badge.plus")
                .font(.system(size: 64))
                .foregroundStyle(.blue)
            
            VStack(spacing: 4) {
                Text("Footnote")
                    .font(.title)
                    .fontWeight(.semibold)
                
                Text("Version 1.0.0 (MVP 0)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Text("Track investment research and scenarios, not just portfolio performance.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
            
            Divider()
                .frame(width: 200)
            
            VStack(spacing: 8) {
                Text("Privacy First")
                    .font(.headline)
                
                Text("All your data stays on your device. No cloud sync, no telemetry, no tracking.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 350)
            }
            
            Spacer()
            
            Text("© 2026 Footnote. All rights reserved.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}

