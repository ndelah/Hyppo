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

// MARK: - General Settings Tab

private struct GeneralSettingsTab: View {
    @AppStorage("defaultConfidenceLevel") private var defaultConfidenceLevel: Int = 3
    @AppStorage("showSystemLogs") private var showSystemLogs: Bool = true
    @AppStorage("compactTimelineView") private var compactTimelineView: Bool = false
    
    var body: some View {
        Form {
            Section {
                Picker("Default Confidence Level", selection: $defaultConfidenceLevel) {
                    ForEach(ConfidenceLevel.allCases, id: \.rawValue) { level in
                        Text(level.displayName).tag(level.rawValue)
                    }
                }
                .pickerStyle(.menu)
                
                Toggle("Show system-generated log entries", isOn: $showSystemLogs)
                
                Toggle("Compact timeline view", isOn: $compactTimelineView)
            } header: {
                Text("Display")
            }
            
            Section {
                Text("Keyboard shortcuts and additional settings will be available in future updates.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Behavior")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Backup Settings Tab

private struct BackupSettingsTab: View {
    @AppStorage("autoBackupEnabled") private var autoBackupEnabled: Bool = false
    @AppStorage("backupFolderPath") private var backupFolderPath: String = ""
    @AppStorage("maxBackupCount") private var maxBackupCount: Int = 10
    
    @State private var showFolderPicker = false
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
            }
            
            Section {
                HStack {
                    Button("Export JSON...") {
                        // TODO: Implement JSON export
                    }
                    
                    Button("Export Markdown...") {
                        // TODO: Implement Markdown export
                    }
                }
                
                if let lastBackup = lastBackupDate {
                    Text("Last backup: \(lastBackup.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Manual Export")
            }
            
            Section {
                Button("Import from JSON...") {
                    // TODO: Implement JSON import
                }
                
                Text("Importing will merge with existing data. Duplicates will be skipped.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Import")
            }
        }
        .formStyle(.grouped)
        .padding()
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
            
            Text("Track investment theses, not just portfolio performance.")
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

