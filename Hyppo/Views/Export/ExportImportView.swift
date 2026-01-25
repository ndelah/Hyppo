/**
 ExportImportView provides UI for exporting and importing data.
 
 Supports JSON export/import for full data backup and restore.
 */

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// View for managing data export and import
struct ExportImportView: View {
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - State
    
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var importMode: ImportMode = .merge
    @State private var showingImportSheet = false
    @State private var showingExportSuccess = false
    @State private var showingImportSuccess = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var importResult: ImportResult?
    @State private var exportedURL: URL?
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            Text("Data Management")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Export your data for backup or import previously exported data.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Divider()
            
            // Export Section
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Export Data", systemImage: "square.and.arrow.up")
                        .font(.headline)
                    
                    Text("Export all assets, research questions, scenarios, log entries, and evidence to a JSON file. This file can be imported later to restore your data.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        Button {
                            exportData()
                        } label: {
                            Label("Export to JSON", systemImage: "doc.badge.arrow.up")
                        }
                        .disabled(isExporting)
                        
                        if isExporting {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            
            // Import Section
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Import Data", systemImage: "square.and.arrow.down")
                        .font(.headline)
                    
                    Text("Import data from a previously exported JSON file. You can choose to merge with existing data or replace it entirely.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Picker("Import Mode", selection: $importMode) {
                        Text("Merge (skip existing assets)").tag(ImportMode.merge)
                        Text("Replace (delete existing data)").tag(ImportMode.replace)
                    }
                    .pickerStyle(.segmented)
                    
                    if importMode == .replace {
                        Label("Warning: Replace mode will delete all existing data!", systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    
                    HStack {
                        Button {
                            showingImportSheet = true
                        } label: {
                            Label("Import from JSON", systemImage: "doc.badge.arrow.down")
                        }
                        .disabled(isImporting)
                        
                        if isImporting {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            
            Spacer()
            
            // Footer
            Text("Tip: Export your data regularly to prevent data loss.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .frame(width: 450, height: 400)
        .fileExporter(
            isPresented: $showingExportSuccess,
            document: JSONDocument(data: exportedData),
            contentType: .json,
            defaultFilename: "footnote_export_\(dateString)"
        ) { result in
            switch result {
            case .success(let url):
                exportedURL = url
            case .failure(let error):
                showError("Export failed: \(error.localizedDescription)")
            }
        }
        .fileImporter(
            isPresented: $showingImportSheet,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    importData(from: url)
                }
            case .failure(let error):
                showError("Import failed: \(error.localizedDescription)")
            }
        }
        .alert("Import Complete", isPresented: $showingImportSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            if let result = importResult {
                Text(result.summary)
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - State for Export
    
    @State private var exportedData: Data = Data()
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    // MARK: - Actions
    
    private func exportData() {
        isExporting = true
        
        Task {
            do {
                let data = try ExportService.shared.exportToJSON(modelContext: modelContext)
                await MainActor.run {
                    exportedData = data
                    isExporting = false
                    showingExportSuccess = true
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                    showError("Export failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func importData(from url: URL) {
        isImporting = true
        
        Task {
            do {
                // Start accessing security-scoped resource
                guard url.startAccessingSecurityScopedResource() else {
                    throw NSError(domain: "ExportImport", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot access file"])
                }
                defer { url.stopAccessingSecurityScopedResource() }
                
                let data = try Data(contentsOf: url)
                let result = try ExportService.shared.importFromJSON(
                    data: data,
                    modelContext: modelContext,
                    mode: importMode
                )
                
                await MainActor.run {
                    isImporting = false
                    importResult = result
                    showingImportSuccess = true
                }
            } catch {
                await MainActor.run {
                    isImporting = false
                    showError("Import failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

// MARK: - JSON Document for File Export

struct JSONDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    var data: Data
    
    init(data: Data) {
        self.data = data
    }
    
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            self.data = data
        } else {
            self.data = Data()
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Markdown Document for File Export

struct MarkdownDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.text] }
    
    var content: String
    
    init(content: String) {
        self.content = content
    }
    
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents,
           let string = String(data: data, encoding: .utf8) {
            self.content = string
        } else {
            self.content = ""
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = content.data(using: .utf8) ?? Data()
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Preview

#Preview {
    ExportImportView()
        .modelContainer(for: [Asset.self, ResearchQuestion.self, LogEntry.self, Evidence.self, Tag.self, ReviewReminder.self], inMemory: true)
}

