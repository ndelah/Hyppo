/**
 ThesisDetailView displays the full detail of a selected thesis.
 
 Shows thesis content (statement, drivers, risks, etc.) at the top
 and the chronological timeline of log entries below.
 */

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// Detail view for a selected thesis showing content and timeline
struct ThesisDetailView: View {
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - App Storage (User Preferences)
    
    @AppStorage("displayDensity") private var displayDensityRaw: String = DisplayDensity.comfortable.rawValue
    @AppStorage("showSystemLogs") private var showSystemLogs: Bool = true
    
    private var displayDensity: DisplayDensity {
        DisplayDensity(rawValue: displayDensityRaw) ?? .comfortable
    }
    
    // MARK: - Properties
    
    @Bindable var thesis: Thesis
    
    // MARK: - State
    
    @State private var showingEditThesis = false
    @State private var showingAddLogEntry = false
    @State private var selectedLogEntry: LogEntry?
    @State private var showingLogEntryDetail = false
    @State private var logEntryForEvidence: LogEntry?
    
    // Section expansion states
    @State private var isThesisStatementExpanded = true
    @State private var isKeyDriversExpanded = true
    @State private var isInvalidationRulesExpanded = true
    @State private var isCatalystsExpanded = true
    @State private var isKeyRisksExpanded = true
    
    // Export state
    @State private var showingMarkdownExport = false
    @State private var markdownContent: String = ""
    
    // Review wizard state
    @State private var showingReviewWizard = false
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Thesis header
                thesisHeader
                
                Divider()
                
                // Review reminder section
                ReviewReminderView(thesis: thesis)
                
                Divider()
                
                // Thesis content sections
                thesisContent
                
                Divider()
                
                // Timeline section
                timelineSection
            }
            .padding()
        }
        .navigationTitle(thesis.title)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Review wizard
                Button {
                    showingReviewWizard = true
                } label: {
                    Label("Review", systemImage: "wand.and.stars")
                }
                .help("Start structured review")
                
                // Export to Markdown
                Button {
                    markdownContent = ExportService.shared.exportThesisToMarkdown(thesis)
                    showingMarkdownExport = true
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .help("Export to Markdown")
                
                Button {
                    showingEditThesis = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                
                Button {
                    showingAddLogEntry = true
                } label: {
                    Label("Add Log", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingEditThesis) {
            if thesis.asset != nil {
                ThesisFormView(mode: .edit(thesis)) { _ in }
            }
        }
        .sheet(isPresented: $showingAddLogEntry) {
            LogEntryFormView(mode: .add(thesis: thesis)) { newLogEntry in
                modelContext.insert(newLogEntry)
                newLogEntry.thesis = thesis
            }
        }
        .sheet(item: $selectedLogEntry) { logEntry in
            LogEntryDetailSheet(logEntry: logEntry)
        }
        .sheet(item: $logEntryForEvidence) { logEntry in
            EvidenceFormView(mode: .add(logEntry: logEntry)) { newEvidence in
                modelContext.insert(newEvidence)
                newEvidence.logEntry = logEntry
            }
        }
        .fileExporter(
            isPresented: $showingMarkdownExport,
            document: MarkdownDocument(content: markdownContent),
            contentType: .text,
            defaultFilename: "\(thesis.asset?.ticker ?? "thesis")_\(sanitizedThesisTitle).md"
        ) { _ in }
        .sheet(isPresented: $showingReviewWizard) {
            ReviewWizardView(thesis: thesis) { }
        }
    }
    
    /// Sanitized thesis title for filename
    private var sanitizedThesisTitle: String {
        thesis.title
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" }
            .prefix(30)
            .description
    }
    
    // MARK: - Subviews
    
    private var thesisHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title and type
            HStack {
                Image(systemName: thesis.thesisType.iconName)
                    .font(.title2)
                    .foregroundStyle(typeColor)
                
                Text(thesis.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Status badge
                statusBadge
            }
            
            // Asset reference
            if let asset = thesis.asset {
                Text("Asset: \(asset.ticker) - \(asset.name)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Metadata row
            HStack(spacing: 16) {
                if let confidence = thesis.confidence {
                    Label(confidence.shortLabel, systemImage: "gauge")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Label("v\(thesis.versionNumber)", systemImage: "number")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Label("\(thesis.logEntriesCount) logs", systemImage: "note.text")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("Updated \(thesis.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
    
    private var thesisContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Thesis statement
            CollapsibleSection(
                title: "Thesis Statement",
                iconName: "text.quote",
                isExpanded: $isThesisStatementExpanded
            ) {
                Text(thesis.thesisStatement)
                    .font(.body)
            }
            
            // Key drivers
            CollapsibleSection(
                title: "Key Drivers",
                iconName: "arrow.up.forward",
                isExpanded: $isKeyDriversExpanded,
                itemCount: thesis.keyDrivers.count
            ) {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(thesis.keyDrivers, id: \.self) { driver in
                        BulletPoint(text: driver)
                    }
                }
            }
            
            // Invalidation rules
            CollapsibleSection(
                title: "Invalidation Rules",
                iconName: "xmark.circle",
                isExpanded: $isInvalidationRulesExpanded,
                itemCount: thesis.invalidationRules.count
            ) {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(thesis.invalidationRules, id: \.self) { rule in
                        BulletPoint(text: rule, color: .red)
                    }
                }
            }
            
            // Catalysts (if any)
            if !thesis.catalysts.isEmpty {
                CollapsibleSection(
                    title: "Catalysts",
                    iconName: "bolt",
                    isExpanded: $isCatalystsExpanded,
                    itemCount: thesis.catalysts.count
                ) {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(thesis.catalysts, id: \.self) { catalyst in
                            BulletPoint(text: catalyst, color: .orange)
                        }
                    }
                }
            }
            
            // Key risks (if any)
            if !thesis.keyRisks.isEmpty {
                CollapsibleSection(
                    title: "Key Risks",
                    iconName: "exclamationmark.triangle",
                    isExpanded: $isKeyRisksExpanded,
                    itemCount: thesis.keyRisks.count
                ) {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(thesis.keyRisks, id: \.self) { risk in
                            BulletPoint(text: risk, color: .yellow)
                        }
                    }
                }
            }
            
            // Expand/Collapse all button
            HStack {
                Spacer()
                Button {
                    toggleAllSections()
                } label: {
                    Label(
                        allSectionsExpanded ? "Collapse All" : "Expand All",
                        systemImage: allSectionsExpanded ? "rectangle.compress.vertical" : "rectangle.expand.vertical"
                    )
                    .font(.caption)
                }
                .buttonStyle(.borderless)
            }
        }
        .onAppear {
            // Set initial expansion state based on density preference
            let shouldExpand = displayDensity.expandSectionsByDefault
            isThesisStatementExpanded = shouldExpand
            isKeyDriversExpanded = shouldExpand
            isInvalidationRulesExpanded = shouldExpand
            isCatalystsExpanded = shouldExpand
            isKeyRisksExpanded = shouldExpand
        }
    }
    
    private var allSectionsExpanded: Bool {
        isThesisStatementExpanded && isKeyDriversExpanded && isInvalidationRulesExpanded
    }
    
    private func toggleAllSections() {
        let newState = !allSectionsExpanded
        isThesisStatementExpanded = newState
        isKeyDriversExpanded = newState
        isInvalidationRulesExpanded = newState
        isCatalystsExpanded = newState
        isKeyRisksExpanded = newState
    }
    
    /// Filtered log entries based on user preferences
    private var filteredLogEntries: [LogEntry] {
        var entries = thesis.sortedLogEntries
        if !showSystemLogs {
            entries = entries.filter { !$0.isSystemGenerated }
        }
        return entries
    }
    
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Timeline")
                    .font(.headline)
                
                // Show count with filter indicator
                Text("(\(filteredLogEntries.count))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if !showSystemLogs && thesis.sortedLogEntries.count != filteredLogEntries.count {
                    Text("• filtered")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                
                Spacer()
                
                // Density indicator
                Menu {
                    ForEach(DisplayDensity.allCases) { density in
                        Button {
                            displayDensityRaw = density.rawValue
                        } label: {
                            if displayDensity == density {
                                Label(density.displayName, systemImage: "checkmark")
                            } else {
                                Text(density.displayName)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "text.alignleft")
                        .font(.caption)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 24)
                .help("Change display density")
                
                Button {
                    showingAddLogEntry = true
                } label: {
                    Label("Add Log", systemImage: "plus")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
            
            if filteredLogEntries.isEmpty {
                EmptyStateView(
                    iconName: "note.text",
                    title: thesis.sortedLogEntries.isEmpty ? "No Log Entries" : "No Visible Entries",
                    description: thesis.sortedLogEntries.isEmpty
                        ? "Start documenting your research by adding log entries."
                        : "System-generated logs are hidden. Enable them in Settings.",
                    actionTitle: "Add Log Entry"
                ) {
                    showingAddLogEntry = true
                }
                .frame(height: 200)
            } else {
                LazyVStack(spacing: displayDensity == .compact ? 8 : 12) {
                    ForEach(filteredLogEntries) { logEntry in
                        LogEntryCard(logEntry: logEntry, density: displayDensity) {
                            logEntryForEvidence = logEntry
                        }
                        .onTapGesture {
                            selectedLogEntry = logEntry
                        }
                        .contextMenu {
                            logEntryContextMenu(for: logEntry)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    private var statusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: thesis.status.iconName)
                .font(.caption)
            Text(thesis.status.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.15))
        .foregroundStyle(statusColor)
        .clipShape(Capsule())
    }
    
    private var typeColor: Color {
        switch thesis.thesisType {
        case .bull: return .green
        case .bear: return .red
        case .base: return .blue
        case .custom: return .purple
        }
    }
    
    private var statusColor: Color {
        switch thesis.status {
        case .active: return .green
        case .onHold: return .orange
        case .invalidated: return .red
        case .archived: return .gray
        }
    }
    
    // MARK: - Context Menu
    
    @ViewBuilder
    private func logEntryContextMenu(for logEntry: LogEntry) -> some View {
        Button {
            logEntry.togglePinned()
        } label: {
            Label(logEntry.isPinned ? "Unpin" : "Pin", systemImage: logEntry.isPinned ? "pin.slash" : "pin")
        }
        
        Divider()
        
        Button(role: .destructive) {
            modelContext.delete(logEntry)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
}

// MARK: - Collapsible Section

/// Reusable collapsible section component for thesis content
private struct CollapsibleSection<Content: View>: View {
    let title: String
    let iconName: String
    @Binding var isExpanded: Bool
    var itemCount: Int?
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (always visible, clickable)
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 16)
                    
                    Label(title, systemImage: iconName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    
                    if let count = itemCount {
                        Text("(\(count))")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.vertical, 6)
            
            // Content (collapsible)
            if isExpanded {
                content()
                    .padding(.leading, 24)
                    .padding(.top, 4)
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Bullet Point

/// Bullet point for list items
private struct BulletPoint: View {
    let text: String
    var color: Color = .primary
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(color.opacity(0.6))
                .frame(width: 6, height: 6)
                .padding(.top, 6)
            
            Text(text)
                .font(.body)
        }
    }
}

// MARK: - Log Entry Card

/// Card view for displaying a log entry in the timeline
struct LogEntryCard: View {
    let logEntry: LogEntry
    var density: DisplayDensity = .comfortable
    let onAddEvidence: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: density == .compact ? 4 : 8) {
            // Header row
            HStack {
                // Type icon
                Image(systemName: logEntry.entryType.iconName)
                    .foregroundStyle(typeColor)
                    .font(density == .compact ? .caption : .body)
                
                Text(logEntry.title)
                    .font(density == .compact ? .subheadline : .headline)
                    .lineLimit(1)
                
                if logEntry.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                
                // Compact: show type badge inline
                if density == .compact {
                    Text(logEntry.entryType.displayName)
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(typeColor.opacity(0.15))
                        .foregroundStyle(typeColor)
                        .clipShape(Capsule())
                }
                
                Spacer()
                
                // Date
                Text(logEntry.occurredAt.formatted(date: .abbreviated, time: density == .compact ? .omitted : .shortened))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            // Body preview (respect density line limits)
            if density != .compact || !logEntry.bodyPreview.isEmpty {
                Text(bodyPreviewText)
                    .font(density == .compact ? .caption : .subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(density.bodyPreviewLines)
            }
            
            // Metadata row (hide in compact mode)
            if density.showMetadataRow {
                HStack(spacing: 12) {
                    // Entry type badge (not in compact, shown in header)
                    if density != .compact {
                        Text(logEntry.entryType.displayName)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(typeColor.opacity(0.15))
                            .foregroundStyle(typeColor)
                            .clipShape(Capsule())
                    }
                    
                    // Confidence
                    if let confidence = logEntry.confidenceLevel {
                        Label(confidence.shortLabel, systemImage: "gauge")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Evidence count
                    if logEntry.evidenceCount > 0 {
                        Label("\(logEntry.evidenceCount)", systemImage: "link")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Tags
                    if let tags = logEntry.tags, !tags.isEmpty {
                        HStack(spacing: 2) {
                            ForEach(tags.prefix(3)) { tag in
                                Circle()
                                    .fill(colorFor(tag))
                                    .frame(width: 6, height: 6)
                            }
                            if tags.count > 3 {
                                Text("+\(tags.count - 3)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    if logEntry.isSystemGenerated {
                        Label("Auto", systemImage: "gearshape")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    
                    // Add Evidence button
                    Button {
                        onAddEvidence()
                    } label: {
                        Label("Add Evidence", systemImage: "link.badge.plus")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
        .padding(density == .compact ? 10 : 16)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: density == .compact ? 8 : 10))
        .overlay(
            RoundedRectangle(cornerRadius: density == .compact ? 8 : 10)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        )
    }
    
    /// Body preview text with density-appropriate truncation
    private var bodyPreviewText: String {
        let text = logEntry.body
        let maxLength = density == .compact ? 80 : (density == .comfortable ? 150 : 300)
        if text.count <= maxLength {
            return text
        }
        return String(text.prefix(maxLength)) + "..."
    }
    
    private var typeColor: Color {
        switch logEntry.entryType {
        case .observation: return .blue
        case .update: return .purple
        case .risk: return .red
        case .catalyst: return .orange
        case .review: return .green
        }
    }
    
    private func colorFor(_ tag: Tag) -> Color {
        guard let colorName = tag.colorName,
              let tagColor = TagColor(rawValue: colorName) else {
            return .blue
        }
        return tagColor.color
    }
}

// MARK: - Log Entry Detail Sheet

/// Sheet view for displaying full log entry details
struct LogEntryDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var logEntry: LogEntry
    
    @State private var showingAddEvidence = false
    @State private var showingEditLogEntry = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: logEntry.entryType.iconName)
                                .foregroundStyle(typeColor)
                            Text(logEntry.entryType.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Text(logEntry.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(logEntry.occurredAt.formatted(date: .complete, time: .shortened))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Divider()
                    
                    // Body
                    Text(logEntry.body)
                        .font(.body)
                    
                    // Evidence section
                    if !logEntry.sortedEvidence.isEmpty {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Evidence")
                                .font(.headline)
                            
                            ForEach(logEntry.sortedEvidence) { evidence in
                                EvidenceRow(evidence: evidence)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Log Entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        showingEditLogEntry = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button {
                        showingAddEvidence = true
                    } label: {
                        Label("Add Evidence", systemImage: "link.badge.plus")
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .sheet(isPresented: $showingAddEvidence) {
            EvidenceFormView(mode: .add(logEntry: logEntry)) { newEvidence in
                modelContext.insert(newEvidence)
                newEvidence.logEntry = logEntry
            }
        }
        .sheet(isPresented: $showingEditLogEntry) {
            if let thesis = logEntry.thesis {
                LogEntryFormView(mode: .edit(logEntry)) { _ in }
            }
        }
    }
    
    private var typeColor: Color {
        switch logEntry.entryType {
        case .observation: return .blue
        case .update: return .purple
        case .risk: return .red
        case .catalyst: return .orange
        case .review: return .green
        }
    }
}

// MARK: - Evidence Row

/// Row view for displaying evidence in a list
struct EvidenceRow: View {
    let evidence: Evidence
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: evidence.evidenceType.iconName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(evidence.effectiveTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Spacer()
            }
            
            if let url = evidence.urlRaw {
                Text(url)
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .lineLimit(1)
            }
            
            if let snippet = evidence.snippetText {
                Text(snippet)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(10)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Preview

#Preview {
    let thesis = Thesis(
        thesisType: .bull,
        title: "Cloud Growth Thesis",
        thesisStatement: "Apple's services segment will continue to grow at 15%+ annually as the installed base expands.",
        keyDrivers: ["Growing installed base", "High switching costs", "App Store dominance"],
        invalidationRules: ["Services growth falls below 10%", "Major regulatory action against App Store"],
        catalysts: ["New subscription service launch", "iPhone sales exceed expectations"],
        keyRisks: ["Regulatory pressure", "Competition from Android"],
        confidence: 4
    )
    
    return ThesisDetailView(thesis: thesis)
        .modelContainer(for: [Thesis.self, LogEntry.self, Evidence.self, ReviewReminder.self], inMemory: true)
}

