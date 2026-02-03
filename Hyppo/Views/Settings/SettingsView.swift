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
            
            AppearanceSettingsTab()
                .tabItem {
                    Label("Appearance", systemImage: "textformat.size")
                }
                .tag(SettingsTab.appearance)
            
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
        .frame(minWidth: 500, minHeight: 400)
    }
}

// MARK: - Settings Tabs Enum

private enum SettingsTab: String {
    case general
    case appearance
    case backup
    case about
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
                            // Note: description is not available on the shared DisplayDensity enum
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

// MARK: - Appearance Settings Tab

private struct AppearanceSettingsTab: View {
    @AppStorage("textSizeMultiplier") private var textSizeMultiplier: Double = 1.0
    @AppStorage("reduceMotionEnabled") private var reduceMotionEnabled: Bool = false
    @AppStorage("highContrastEnabled") private var highContrastEnabled: Bool = false
    
    /// Text size presets for easy selection
    private let textSizePresets: [(name: String, value: Double)] = [
        ("Small", 0.85),
        ("Default", 1.0),
        ("Medium", 1.15),
        ("Large", 1.3),
        ("Extra Large", 1.5)
    ]
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Text Size")
                        Spacer()
                        Text(textSizeLabel)
                            .foregroundStyle(.secondary)
                    }
                    
                    Slider(
                        value: $textSizeMultiplier,
                        in: 0.85...1.5,
                        step: 0.05
                    ) {
                        Text("Text Size")
                    } minimumValueLabel: {
                        Text("A")
                            .font(.caption)
                    } maximumValueLabel: {
                        Text("A")
                            .font(.title2)
                    }
                    .accessibilityLabel("Text size multiplier")
                    .accessibilityValue(textSizeLabel)
                    
                    // Preset buttons
                    HStack(spacing: 8) {
                        ForEach(textSizePresets, id: \.value) { preset in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    textSizeMultiplier = preset.value
                                }
                            } label: {
                                Text(preset.name)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(isPresetSelected(preset.value) ? Color.accentColor : Color.secondary.opacity(0.2))
                                    )
                                    .foregroundStyle(isPresetSelected(preset.value) ? .white : .primary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(preset.name) text size")
                            .accessibilityAddTraits(isPresetSelected(preset.value) ? .isSelected : [])
                        }
                    }
                    
                    // Preview text
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preview")
                            .font(.footnote)
                            .foregroundStyle(.tertiary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Research Question Title")
                                .font(.system(size: 15 * textSizeMultiplier, weight: .semibold))
                            Text("This is how body text will appear in the app with your current text size setting.")
                                .font(.system(size: 13 * textSizeMultiplier))
                                .foregroundStyle(.secondary)
                            Text("Caption and metadata text")
                                .font(.system(size: 11 * textSizeMultiplier))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(.top, 8)
                }
            } header: {
                Text("Text Size")
            } footer: {
                Text("Adjusts text size throughout the app. This works in addition to your system accessibility settings.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section {
                Toggle("Reduce motion", isOn: $reduceMotionEnabled)
                    .accessibilityHint("Reduces animations and motion effects in the app")
                
                Toggle("Increase contrast", isOn: $highContrastEnabled)
                    .accessibilityHint("Uses higher contrast colors for better visibility")
            } header: {
                Text("Accessibility")
            } footer: {
                Text("These settings work alongside your macOS accessibility preferences.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
    
    /// Returns a human-readable label for the current text size
    private var textSizeLabel: String {
        let percentage = Int(textSizeMultiplier * 100)
        if let preset = textSizePresets.first(where: { isPresetSelected($0.value) }) {
            return "\(preset.name) (\(percentage)%)"
        }
        return "\(percentage)%"
    }
    
    /// Checks if a preset value matches the current multiplier
    private func isPresetSelected(_ value: Double) -> Bool {
        abs(textSizeMultiplier - value) < 0.01
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

