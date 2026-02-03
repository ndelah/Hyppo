/**
 ResearchQuestionDetailView displays the full detail of a selected research question.
 
 Shows thesis content (statement, drivers, risks, scenarios, etc.) at the top
 and the chronological timeline of log entries below. Each research question
 is now a single "report" page containing all relevant information.
 */

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// Tab selection for the detail menu
enum ResearchDetailTab: String, CaseIterable, Identifiable {
    case description = "Description"
    case health = "Health"
    case tasks = "Tasks"
    
    var id: String { rawValue }
}

/// Detail view for a selected research question showing all content and timeline
struct ResearchQuestionDetailView: View {
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - App Storage (User Preferences)
    
    @AppStorage("displayDensity") private var displayDensityRaw: String = DisplayDensity.comfortable.rawValue
    @AppStorage("showSystemLogs") private var showSystemLogs: Bool = true
    
    private var displayDensity: DisplayDensity {
        DisplayDensity(rawValue: displayDensityRaw) ?? .comfortable
    }
    
    // MARK: - Properties
    
    @Bindable var researchQuestion: ResearchQuestion
    
    // MARK: - State
    
    @State private var showingEditQuestion = false
    @State private var showingAddLogEntry = false
    @State private var selectedLogEntry: LogEntry?
    @State private var logEntryForEvidence: LogEntry?
    
    // Tab selection state
    @State private var selectedTab: ResearchDetailTab = .description
    
    // Section expansion states
    @State private var isThesisStatementExpanded = true
    @State private var isKeyDriversExpanded = true
    @State private var isScenariosExpanded = true
    @State private var isCatalystsExpanded = true
    @State private var isKeyRisksExpanded = true
    @State private var isPreMortemExpanded = true
    @State private var isConclusionExpanded = true
    
    // Export state
    @State private var showingMarkdownExport = false
    @State private var markdownDocument: MarkdownDocument?
    
    // Review wizard state
    @State private var showingReviewWizard = false
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Research question header (includes inline review reminder badge)
                questionHeader
                
                Divider()
                
                // Tabbed menu section
                tabbedMenuSection
                
                Divider()
                
                // Timeline section
                timelineSection
            }
            .padding()
        }
        .navigationTitle(researchQuestion.questionText)
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
                    let content = ExportService.shared.exportResearchQuestionToMarkdown(researchQuestion)
                    markdownDocument = MarkdownDocument(content: content)
                    showingMarkdownExport = true
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .help("Export to Markdown")
                .fileExporter(
                    isPresented: $showingMarkdownExport,
                    document: markdownDocument ?? MarkdownDocument(content: ""),
                    contentType: .text,
                    defaultFilename: "\(researchQuestion.asset?.ticker ?? "research")_\(sanitizedQuestionTitle).md"
                ) { _ in
                    markdownDocument = nil
                }
                
                Button {
                    showingEditQuestion = true
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
        .sheet(isPresented: $showingAddLogEntry) {
            LogEntryFormView(mode: .add(researchQuestion: researchQuestion)) { newLogEntry in
                modelContext.insert(newLogEntry)
                newLogEntry.researchQuestion = researchQuestion
                
                // Explicitly update inverse relationship for immediate UI refresh
                if researchQuestion.logEntries == nil {
                    researchQuestion.logEntries = []
                }
                researchQuestion.logEntries?.append(newLogEntry)
                researchQuestion.updatedAt = Date()
                
                // Save the context to ensure all relationships are persisted
                try? modelContext.save()
            }
        }
        .sheet(isPresented: $showingEditQuestion) {
            ResearchQuestionFormView(mode: .edit(researchQuestion), asset: researchQuestion.asset) { _ in }
        }
        .sheet(item: $selectedLogEntry) { logEntry in
            LogEntryDetailSheet(logEntry: logEntry)
        }
        .sheet(item: $logEntryForEvidence) { logEntry in
            EvidenceFormView(mode: .addToLogEntry(logEntry: logEntry)) { newEvidence in
                modelContext.insert(newEvidence)
            }
        }
        .sheet(isPresented: $showingReviewWizard) {
            ReviewWizardView(researchQuestion: researchQuestion) { }
        }
    }
    
    /// Sanitized question title for filename
    private var sanitizedQuestionTitle: String {
        researchQuestion.questionText
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: "?", with: "")
            .filter { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" }
            .prefix(30)
            .description
    }
    
    // MARK: - Subviews
    
    /// Tabbed menu section with Description, Health, and Tasks tabs
    private var tabbedMenuSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Tab bar
            tabBar
            
            // Tab content
            tabContent
        }
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor).opacity(0.5), lineWidth: 1)
        )
    }
    
    /// Tab bar with Description, Health, and Tasks tabs
    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(ResearchDetailTab.allCases) { tab in
                tabButton(for: tab)
            }
            Spacer()
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
    
    /// Individual tab button
    private func tabButton(for tab: ResearchDetailTab) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 0) {
                Text(tab.rawValue)
                    .font(.subheadline)
                    .fontWeight(selectedTab == tab ? .semibold : .regular)
                    .foregroundStyle(selectedTab == tab ? .primary : .secondary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                
                // Active indicator
                Rectangle()
                    .fill(selectedTab == tab ? Color.accentColor : Color.clear)
                    .frame(height: 2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(tab.rawValue) tab")
        .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
    }
    
    /// Tab content based on selected tab
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .description:
            descriptionTabContent
                .padding()
                .transition(.opacity)
        case .health:
            healthTabContent
                .padding()
                .transition(.opacity)
        case .tasks:
            tasksTabContent
                .transition(.opacity)
        }
    }
    
    /// Description tab content - shows thesis summary, context, drivers, subdrivers, and logic
    private var descriptionTabContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Thesis Statement
            if let thesis = researchQuestion.thesisStatement, !thesis.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Thesis Statement", systemImage: "text.quote")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    
                    Text(thesis)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            
            // Context
            if let context = researchQuestion.context, !context.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Context", systemImage: "info.circle")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    
                    Text(context)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Drivers with logic and subdrivers
            if !(researchQuestion.drivers?.isEmpty ?? true) {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Key Assumptions", systemImage: "target")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    
                    VStack(spacing: 12) {
                        ForEach(researchQuestion.topLevelDrivers) { driver in
                            DriverDescriptionCard(driver: driver)
                        }
                    }
                }
            }
            
            // Scenarios
            if !researchQuestion.scenarios.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Scenarios", systemImage: "arrow.up.arrow.down.circle")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(researchQuestion.scenarios.sorted { $0.scenarioType.sortOrder < $1.scenarioType.sortOrder }) { scenario in
                            ScenarioRow(scenario: scenario)
                        }
                    }
                }
            }
            
            // Conclusion (when resolved)
            if let conclusion = researchQuestion.conclusion, !conclusion.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Conclusion", systemImage: "flag.checkered")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    
                    Text(conclusion)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.green.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    
                    // Driver resolution summary
                    if researchQuestion.allDriversResolved {
                        HStack(spacing: 12) {
                            Label("\(researchQuestion.confirmedDriversCount) confirmed", systemImage: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                            Label("\(researchQuestion.discardedDriversCount) discarded", systemImage: "xmark.seal.fill")
                                .foregroundStyle(.red)
                        }
                        .font(.caption)
                    }
                }
            }
            
            // Empty state
            if researchQuestion.thesisStatement == nil && researchQuestion.context == nil && (researchQuestion.drivers?.isEmpty ?? true) {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text")
                        .font(.title)
                        .foregroundStyle(.tertiary)
                    Text("No description yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Add a thesis statement, context, and assumptions to describe your investment thesis.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
        }
    }
    
    /// Health tab content - shows conviction health dashboard
    private var healthTabContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !(researchQuestion.drivers?.isEmpty ?? true) {
                ConvictionHealthView(drivers: researchQuestion.drivers ?? [])
            } else {
                // Empty state for health
                VStack(spacing: 8) {
                    Image(systemName: "heart.text.square")
                        .font(.title)
                        .foregroundStyle(.tertiary)
                    Text("No health data available")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Add assumptions and evidence to track conviction health.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
        }
    }
    
    /// Tasks tab content - shows research tasks
    private var tasksTabContent: some View {
        ResearchTasksView(researchQuestion: researchQuestion)
    }
    
    private var questionHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title and status
            HStack {
                Image(systemName: researchQuestion.status.iconName)
                    .font(.title2)
                    .foregroundStyle(statusColor)
                
                Text(researchQuestion.questionText)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Status badge
                statusBadge
            }
            
            // Asset reference
            if let asset = researchQuestion.asset {
                Text("Asset: \(asset.ticker) - \(asset.name)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Context if available
            if let context = researchQuestion.context, !context.isEmpty {
                Text(context)
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 2)
            }
            
            // Metadata row
            HStack(spacing: 16) {
                if let confidence = researchQuestion.confidence {
                    Label(confidence.shortLabel, systemImage: "gauge")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Review reminder badge (inline)
                ReviewReminderBadge(researchQuestion: researchQuestion)
                
                Label("v\(researchQuestion.versionNumber)", systemImage: "number")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Label("\(researchQuestion.logEntriesCount) logs", systemImage: "note.text")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if !researchQuestion.scenarios.isEmpty {
                    Label("\(researchQuestion.scenariosCount) scenarios", systemImage: "arrow.up.arrow.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text("Updated \(researchQuestion.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
    
    private var thesisContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Thesis statement
            if let thesis = researchQuestion.thesisStatement, !thesis.isEmpty {
                CollapsibleSection(
                    title: "Thesis Statement",
                    iconName: "text.quote",
                    isExpanded: $isThesisStatementExpanded
                ) {
                    Text(thesis)
                        .font(.subheadline)
                }
            }
            
            // Key drivers (now using Driver model)
            if !(researchQuestion.drivers?.isEmpty ?? true) {
                CollapsibleSection(
                    title: "Assumptions",
                    iconName: "target",
                    isExpanded: $isKeyDriversExpanded,
                    itemCount: researchQuestion.drivers?.count ?? 0
                ) {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(researchQuestion.topLevelDrivers) { driver in
                            DriverStatusRow(driver: driver)
                            if let subs = driver.subDrivers, !subs.isEmpty {
                                ForEach(subs) { sub in
                                    DriverStatusRow(driver: sub, isSubDriver: true)
                                        .padding(.leading, 20)
                                }
                            }
                        }
                    }
                }
            }
            
            // Scenarios
            if !researchQuestion.scenarios.isEmpty {
                CollapsibleSection(
                    title: "Scenarios",
                    iconName: "arrow.up.arrow.down.circle",
                    isExpanded: $isScenariosExpanded,
                    itemCount: researchQuestion.scenarios.count
                ) {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(researchQuestion.scenarios.sorted { $0.scenarioType.sortOrder < $1.scenarioType.sortOrder }) { scenario in
                            ScenarioRow(scenario: scenario)
                        }
                    }
                }
            }
            
            // Conclusion (shown when research is complete)
            if let conclusion = researchQuestion.conclusion, !conclusion.isEmpty {
                CollapsibleSection(
                    title: "Conclusion",
                    iconName: "flag.checkered",
                    isExpanded: $isConclusionExpanded,
                    itemCount: nil
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(conclusion)
                            .font(.subheadline)
                        
                        // Show driver resolution summary
                        if researchQuestion.allDriversResolved {
                            HStack(spacing: 12) {
                                Label("\(researchQuestion.confirmedDriversCount) confirmed", systemImage: "checkmark.seal.fill")
                                    .foregroundStyle(.green)
                                Label("\(researchQuestion.discardedDriversCount) discarded", systemImage: "xmark.seal.fill")
                                    .foregroundStyle(.red)
                            }
                            .font(.caption)
                            .padding(.top, 4)
                        }
                    }
                }
            }
            
            // Conviction Health Dashboard
            if !(researchQuestion.drivers?.isEmpty ?? true) {
                CollapsibleSection(
                    title: "Conviction Health",
                    iconName: "heart.text.square",
                    isExpanded: $isCatalystsExpanded,
                    itemCount: nil
                ) {
                    ConvictionHealthView(drivers: researchQuestion.drivers ?? [], isCompact: true)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 2)
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
            isScenariosExpanded = shouldExpand
            isCatalystsExpanded = shouldExpand
            isKeyRisksExpanded = shouldExpand
            isPreMortemExpanded = shouldExpand
            isConclusionExpanded = shouldExpand
        }
    }
    
    private var allSectionsExpanded: Bool {
        isThesisStatementExpanded && isKeyDriversExpanded && isScenariosExpanded && isCatalystsExpanded && isKeyRisksExpanded && isPreMortemExpanded && isConclusionExpanded
    }
    
    private func toggleAllSections() {
        let newState = !allSectionsExpanded
        isThesisStatementExpanded = newState
        isKeyDriversExpanded = newState
        isScenariosExpanded = newState
        isCatalystsExpanded = newState
        isKeyRisksExpanded = newState
        isPreMortemExpanded = newState
        isConclusionExpanded = newState
    }
    
    /// Filtered log entries based on user preferences
    private var filteredLogEntries: [LogEntry] {
        var entries = researchQuestion.sortedLogEntries
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
                
                if !showSystemLogs && researchQuestion.sortedLogEntries.count != filteredLogEntries.count {
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
                    title: researchQuestion.sortedLogEntries.isEmpty ? "No Log Entries" : "No Visible Entries",
                    description: researchQuestion.sortedLogEntries.isEmpty
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
            Image(systemName: researchQuestion.status.iconName)
                .font(.caption)
            Text(researchQuestion.status.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.15))
        .foregroundStyle(statusColor)
        .clipShape(Capsule())
    }
    
    private var statusColor: Color {
        switch researchQuestion.status {
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

// MARK: - Scenario Row

/// Display row for a simple scenario
private struct ScenarioRow: View {
    let scenario: SimpleScenario
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: scenario.scenarioType.iconName)
                .font(.subheadline)
                .foregroundStyle(typeColor)
                .frame(width: 20)
            
            Text(scenario.scenarioType.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .leading)
            
            Text(scenario.title)
                .font(.subheadline)
        }
        .padding(.vertical, 2)
    }
    
    private var typeColor: Color {
        switch scenario.scenarioType {
        case .bull: return .green
        case .bear: return .red
        case .base: return .blue
        case .custom: return .purple
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
            .padding(.vertical, 4)
            
            // Content (collapsible)
            if isExpanded {
                content()
                    .padding(.leading, 24)
                    .padding(.top, 2)
            }
        }
        .padding(8)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Bullet Point

/// Bullet point for list items
private struct BulletPoint: View {
    let text: String
    var color: Color = .primary
    
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Circle()
                .fill(color.opacity(0.6))
                .frame(width: 5, height: 5)
                .padding(.top, 5)
            
            Text(text)
                .font(.subheadline)
        }
    }
}

// MARK: - Driver Description Card

/// Card view displaying a driver with its logic and subdrivers in the Description tab
private struct DriverDescriptionCard: View {
    let driver: Driver
    
    /// Color for the driver's current status
    private var statusColor: Color {
        switch driver.status {
        case .confirmed: return .green
        case .discarded: return .red
        case .needsRevision: return .orange
        case .pending: return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Driver header with status
            HStack(alignment: .top, spacing: 10) {
                // Status indicator
                Image(systemName: driver.status.iconName)
                    .font(.body)
                    .foregroundStyle(statusColor)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 4) {
                    // Title
                    Text(driver.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .strikethrough(driver.status == .discarded, color: .red)
                        .foregroundStyle(driver.status == .discarded ? .secondary : .primary)
                    
                    // Status badge
                    if driver.status != .pending {
                        Text(driver.status.displayName)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(statusColor.opacity(0.15))
                            .foregroundStyle(statusColor)
                            .clipShape(Capsule())
                    }
                }
                
                Spacer()
            }
            
            // Logic/reasoning (if provided)
            if let logic = driver.logic, !logic.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Logic")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.tertiary)
                    
                    Text(logic)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 30)
                }
            }
            
            // Description (if provided)
            if let description = driver.driverDescription, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 30)
            }
            
            // Sub-drivers
            if let subDrivers = driver.subDrivers, !subDrivers.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(subDrivers.sorted(by: { $0.position < $1.position })) { subDriver in
                        SubDriverRow(driver: subDriver)
                    }
                }
                .padding(.leading, 30)
            }
        }
        .padding(12)
        .background(Color(nsColor: .textBackgroundColor).opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(statusColor.opacity(0.3), lineWidth: 1)
        )
    }
}

/// Sub-driver row for the description tab
private struct SubDriverRow: View {
    let driver: Driver
    
    private var statusColor: Color {
        switch driver.status {
        case .confirmed: return .green
        case .discarded: return .red
        case .needsRevision: return .orange
        case .pending: return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 6) {
                Text("→")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                
                Image(systemName: driver.status.iconName)
                    .font(.caption)
                    .foregroundStyle(statusColor)
                
                Text(driver.title)
                    .font(.caption)
                    .strikethrough(driver.status == .discarded, color: .red)
                    .foregroundStyle(driver.status == .discarded ? .tertiary : .secondary)
                
                if driver.status != .pending {
                    Text(driver.status.displayName)
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(statusColor.opacity(0.1))
                        .foregroundStyle(statusColor)
                        .clipShape(Capsule())
                }
            }
            
            // Logic for sub-driver (if provided)
            if let logic = driver.logic, !logic.isEmpty {
                Text(logic)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 30)
            }
        }
    }
}

// MARK: - Driver Status Row

/// Displays a driver with its validation status indicator
private struct DriverStatusRow: View {
    let driver: Driver
    var isSubDriver: Bool = false
    
    /// Color for the driver's current status
    private var statusColor: Color {
        switch driver.status {
        case .confirmed: return .green
        case .discarded: return .red
        case .needsRevision: return .orange
        case .pending: return .gray
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Status indicator icon
            Image(systemName: driver.status.iconName)
                .font(.caption)
                .foregroundStyle(statusColor)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                // Driver title with sub-driver indicator
                HStack(spacing: 4) {
                    if isSubDriver {
                        Text("→")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    Text(driver.title)
                        .font(.subheadline)
                        .strikethrough(driver.status == .discarded, color: .red)
                        .foregroundStyle(driver.status == .discarded ? .secondary : .primary)
                }
                
                // Status label (only show for non-pending)
                if driver.status != .pending {
                    Text(driver.status.displayName)
                        .font(.caption2)
                        .foregroundStyle(statusColor)
                }
            }
            
            Spacer()
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
                
                // Show sentiment badge if linked to driver
                if let sentiment = logEntry.sentiment {
                    sentimentBadge(sentiment)
                }
                
                Spacer()
                
                // Date
                Text(logEntry.occurredAt.formatted(date: .abbreviated, time: density == .compact ? .omitted : .shortened))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            // Driver linkage indicator (show in non-compact mode)
            if density != .compact, let driver = logEntry.driver {
                HStack(spacing: 4) {
                    Image(systemName: "target")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                    Text(driver.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
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
                    
                    // Add Evidence button (only show if not linked to driver)
                    if logEntry.driver == nil {
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
        }
        .padding(density == .compact ? 10 : 16)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: density == .compact ? 8 : 10))
        .overlay(
            RoundedRectangle(cornerRadius: density == .compact ? 8 : 10)
                .stroke(logEntry.driver != nil ? Color.blue.opacity(0.3) : Color(nsColor: .separatorColor), lineWidth: 1)
        )
    }
    
    private func sentimentBadge(_ sentiment: EvidenceSentiment) -> some View {
        HStack(spacing: 2) {
            Image(systemName: sentiment.iconName)
        }
        .font(.caption2)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(sentimentColor(sentiment).opacity(0.15))
        .foregroundStyle(sentimentColor(sentiment))
        .clipShape(Capsule())
    }
    
    private func sentimentColor(_ sentiment: EvidenceSentiment) -> Color {
        switch sentiment {
        case .supporting: return .green
        case .contradicting: return .red
        case .neutral: return .gray
        }
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
                            
                            Spacer()
                            
                            // Show sentiment badge if linked to driver
                            if let sentiment = logEntry.sentiment {
                                sentimentBadge(sentiment)
                            }
                        }
                        
                        Text(logEntry.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(logEntry.occurredAt.formatted(date: .complete, time: .shortened))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        // Driver linkage indicator
                        if let driver = logEntry.driver {
                            HStack(spacing: 6) {
                                Image(systemName: "target")
                                    .foregroundStyle(.blue)
                                Text("Linked to:")
                                    .foregroundStyle(.secondary)
                                Text(driver.title)
                                    .fontWeight(.medium)
                            }
                            .font(.caption)
                            .padding(.top, 4)
                        }
                        
                        // Source URL if available
                        if let url = logEntry.sourceUrl, !url.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "link")
                                    .foregroundStyle(.blue)
                                Text(url)
                                    .foregroundStyle(.blue)
                                    .lineLimit(1)
                            }
                            .font(.caption)
                        }
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
                    
                    // Only show Add Evidence button if not already linked to a driver
                    // (since driver-linked logs auto-create evidence)
                    if logEntry.driver == nil {
                        Button {
                            showingAddEvidence = true
                        } label: {
                            Label("Add Evidence", systemImage: "link.badge.plus")
                        }
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .sheet(isPresented: $showingAddEvidence) {
            EvidenceFormView(mode: .addToLogEntry(logEntry: logEntry)) { newEvidence in
                modelContext.insert(newEvidence)
            }
        }
        .sheet(isPresented: $showingEditLogEntry) {
            if logEntry.researchQuestion != nil {
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
    
    private func sentimentBadge(_ sentiment: EvidenceSentiment) -> some View {
        HStack(spacing: 4) {
            Image(systemName: sentiment.iconName)
            Text(sentiment.rawValue)
        }
        .font(.caption2.bold())
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(sentimentColor(sentiment).opacity(0.15))
        .foregroundStyle(sentimentColor(sentiment))
        .clipShape(Capsule())
    }
    
    private func sentimentColor(_ sentiment: EvidenceSentiment) -> Color {
        switch sentiment {
        case .supporting: return .green
        case .contradicting: return .red
        case .neutral: return .gray
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

struct ResearchQuestionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let question = ResearchQuestion(
            questionText: "Can AAPL sustain services revenue growth?",
            context: "Services now represent 20% of revenue",
            thesisStatement: "Apple's services segment will continue to grow at 15%+ annually as the installed base expands.",
            confidence: 4
        )
        
        return ResearchQuestionDetailView(researchQuestion: question)
            .modelContainer(for: [Asset.self, ResearchQuestion.self, LogEntry.self, Evidence.self, ReviewReminder.self, Driver.self], inMemory: true)
    }
}
