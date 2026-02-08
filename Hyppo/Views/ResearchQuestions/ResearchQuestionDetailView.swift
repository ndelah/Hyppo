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
    case researchConviction = "Research Conviction"
    case confidence = "Confidence"
    case decisions = "Decisions"
    case tasks = "Tasks"
    
    var id: String { rawValue }
}

/// Timeline filter mode for showing narrative events vs all entries
enum TimelineFilter: String, CaseIterable, Identifiable {
    case narrative = "Narrative"  // Reviews + decisions only
    case all = "All"              // Everything
    
    var id: String { rawValue }
    
    var displayName: String { rawValue }
}

/// Protocol for items that can appear in the timeline
protocol TimelineItem {
    var timelineDate: Date { get }
    var timelineId: UUID { get }
}

/// Wrapper to make LogEntry conform to TimelineItem
extension LogEntry: TimelineItem {
    var timelineDate: Date { occurredAt }
    var timelineId: UUID { logEntryId }
}

/// Wrapper to make Decision conform to TimelineItem
extension Decision: TimelineItem {
    var timelineDate: Date { decidedAt }
    var timelineId: UUID { decisionId }
}

/// Type-erased wrapper for timeline items
enum AnyTimelineItem: Identifiable {
    case logEntry(LogEntry)
    case decision(Decision)
    
    var id: UUID {
        switch self {
        case .logEntry(let entry): return entry.logEntryId
        case .decision(let decision): return decision.decisionId
        }
    }
    
    var timelineDate: Date {
        switch self {
        case .logEntry(let entry): return entry.occurredAt
        case .decision(let decision): return decision.decidedAt
        }
    }
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
    
    // Decision Layer state
    @State private var showingDecisionForm = false
    @State private var showingOutcomeForm = false
    @State private var selectedDecision: Decision?
    
    // Timeline filter state
    @State private var timelineFilter: TimelineFilter = .all
    
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
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Record Decision button (prominent when actions available)
                if !researchQuestion.validDecisionActions.isEmpty {
                    Button {
                        showingDecisionForm = true
                    } label: {
                        Label("Record Decision", systemImage: "checkmark.circle")
                    }
                    .help("Record an investment decision")
                }
                
                // Record Outcome button (when awaiting outcome)
                if researchQuestion.isAwaitingOutcome {
                    Button {
                        showingOutcomeForm = true
                    } label: {
                        Label("Record Outcome", systemImage: "flag.checkered")
                    }
                    .buttonStyle(.borderedProminent)
                    .help("Record the outcome to complete this thesis")
                }
                
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
        .sheet(isPresented: $showingDecisionForm) {
            DecisionFormView(
                researchQuestion: researchQuestion,
                onSave: { decision in
                    modelContext.insert(decision)
                    researchQuestion.recordDecision(decision)
                    try? modelContext.save()
                    
                    // If this was an exit or abandon, prompt for outcome
                    if researchQuestion.isAwaitingOutcome {
                        showingOutcomeForm = true
                    }
                },
                onExitWithOutcome: {
                    showingOutcomeForm = true
                }
            )
        }
        .sheet(isPresented: $showingOutcomeForm) {
            OutcomeFormView(
                researchQuestion: researchQuestion,
                onSave: { outcome in
                    modelContext.insert(outcome)
                    try? researchQuestion.recordOutcome(outcome)
                    try? modelContext.save()
                }
            )
        }
        .sheet(item: $selectedDecision) { decision in
            DecisionDetailView(decision: decision)
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
    
    /// Tabbed menu section with Description, Research Conviction, Confidence, and Tasks tabs
    private var tabbedMenuSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Tab bar
            tabBar
            
            // Tab content
            tabContent
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor).opacity(0.5), lineWidth: 1)
        )
    }
    
    /// Tab bar with Description, Research Conviction, Confidence, and Tasks tabs
    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(ResearchDetailTab.allCases) { tab in
                tabButton(for: tab)
            }
            Spacer()
        }
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
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
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                
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
        case .researchConviction:
            researchConvictionTabContent
                .padding()
                .transition(.opacity)
        case .confidence:
            confidenceTabContent
                .padding()
                .transition(.opacity)
        case .decisions:
            decisionsTabContent
                .padding()
                .transition(.opacity)
        case .tasks:
            tasksTabContent
                .transition(.opacity)
        }
    }
    
    /// Decisions tab content - shows decision timeline and actions
    private var decisionsTabContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Investment phase header
            investmentPhaseHeader
            
            // Awaiting outcome banner
            if researchQuestion.isAwaitingOutcome {
                awaitingOutcomeBanner
            }
            
            // Outcome summary (if in PostMortem)
            if let outcome = researchQuestion.outcome {
                outcomeSummarySection(outcome)
            }
            
            // Decision timeline
            DecisionTimelineView(researchQuestion: researchQuestion) { decision in
                selectedDecision = decision
            }
            
            // Record decision button (if actions available)
            if !researchQuestion.validDecisionActions.isEmpty {
                Button {
                    showingDecisionForm = true
                } label: {
                    Label("Record Decision", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
    
    /// Investment phase header showing current lifecycle state
    private var investmentPhaseHeader: some View {
        HStack(spacing: 12) {
            // Phase icon
            ZStack {
                Circle()
                    .fill(Color(researchQuestion.investmentPhase.colorName).opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: researchQuestion.investmentPhase.iconName)
                    .font(.title3)
                    .foregroundStyle(Color(researchQuestion.investmentPhase.colorName))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Investment Phase")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(researchQuestion.investmentPhase.displayName)
                    .font(.headline)
                    .foregroundStyle(Color(researchQuestion.investmentPhase.colorName))
            }
            
            Spacer()
            
            // Decision count
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(researchQuestion.decisionsCount)")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("decisions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(researchQuestion.investmentPhase.colorName).opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(researchQuestion.investmentPhase.colorName).opacity(0.2), lineWidth: 1)
        )
    }
    
    /// Banner shown when thesis is awaiting outcome recording
    private var awaitingOutcomeBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Outcome Required")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("Record the outcome to complete this thesis and enable calibration tracking.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button("Record Now") {
                showingOutcomeForm = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    /// Outcome summary section for completed theses
    private func outcomeSummarySection(_ outcome: Outcome) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "flag.checkered")
                    .foregroundStyle(.purple)
                Text("Outcome")
                    .font(.headline)
                Spacer()
                Text(outcome.recordedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(outcome.actualResult)
                .font(.subheadline)
            
            HStack(spacing: 16) {
                // Thesis assessment
                HStack(spacing: 4) {
                    Image(systemName: outcome.thesisAssessment.iconName)
                        .foregroundStyle(Color(outcome.thesisAssessment.colorName))
                    Text(outcome.thesisAssessment.displayName)
                        .fontWeight(.medium)
                }
                .font(.caption)
                
                // Timing assessment
                HStack(spacing: 4) {
                    Image(systemName: outcome.timingAssessment.iconName)
                        .foregroundStyle(Color(outcome.timingAssessment.colorName))
                    Text(outcome.timingAssessment.displayName)
                }
                .font(.caption)
            }
            
            if let lessons = outcome.lessonsLearned, !lessons.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Lessons Learned")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(lessons)
                        .font(.caption)
                        .italic()
                }
            }
        }
        .padding()
        .background(Color.purple.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
        )
    }
    
    /// Description tab content - shows context, drivers with logic, subdrivers, and scenarios
    private var descriptionTabContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Context (always visible, no dropdown)
            if let context = researchQuestion.context, !context.isEmpty {
                DescriptionSection(title: "Context", iconName: "info.circle") {
                    Text(context)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            
            // Drivers with logic and subdrivers (always visible, no dropdown)
            if !(researchQuestion.drivers?.isEmpty ?? true) {
                DescriptionSection(
                    title: "Key Assumptions",
                    iconName: "target",
                    itemCount: researchQuestion.topLevelDrivers.count
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(researchQuestion.topLevelDrivers) { driver in
                            CompactDriverRow(driver: driver)
                        }
                    }
                }
            }
            
            // Scenarios (collapsible)
            if !researchQuestion.scenarios.isEmpty {
                CollapsibleSection(
                    title: "Scenarios",
                    iconName: "arrow.up.arrow.down.circle",
                    isExpanded: $isScenariosExpanded,
                    itemCount: researchQuestion.scenarios.count
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(researchQuestion.scenarios.sorted { $0.scenarioType.sortOrder < $1.scenarioType.sortOrder }) { scenario in
                            ScenarioRow(scenario: scenario)
                        }
                    }
                }
            }
            
            // Conclusion (when resolved, collapsible)
            if let conclusion = researchQuestion.conclusion, !conclusion.isEmpty {
                CollapsibleSection(
                    title: "Conclusion",
                    iconName: "flag.checkered",
                    isExpanded: $isConclusionExpanded
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(conclusion)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.green.opacity(0.08))
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
                            .fontWeight(.medium)
                        }
                    }
                }
            }
            
            // Empty state
            if researchQuestion.context == nil && (researchQuestion.drivers?.isEmpty ?? true) {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 40))
                        .foregroundStyle(.tertiary)
                    Text("No description yet")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Add context and key assumptions to describe your investment thesis.")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 300)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            }
        }
    }
    
    /// Research conviction tab content - shows conviction health dashboard
    private var researchConvictionTabContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Conviction health dashboard
            if !(researchQuestion.drivers?.isEmpty ?? true) {
                ConvictionHealthView(drivers: researchQuestion.drivers ?? [])
            } else {
                // Empty state for conviction
                VStack(spacing: 8) {
                    Image(systemName: "heart.text.square")
                        .font(.title)
                        .foregroundStyle(.tertiary)
                    Text("No conviction data available")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Add assumptions and evidence to track research conviction.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
        }
    }

    /// Confidence tab content - shows confidence over time
    private var confidenceTabContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            ConfidenceChartView(researchQuestion: researchQuestion)
        }
    }
    
    /// Tasks tab content - shows research tasks
    private var tasksTabContent: some View {
        ResearchTasksView(researchQuestion: researchQuestion)
    }
    
    private var questionHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title row with ticker badge and status
            HStack(alignment: .top, spacing: 12) {
                // Ticker badge (prominent display)
                if let asset = researchQuestion.asset {
                    VStack(spacing: 2) {
                        Text(asset.ticker)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.assetColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                // Question title and status
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(researchQuestion.questionText)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        // Status badge
                        statusBadge
                    }
                    
                    // Asset name (secondary info below title)
                    if let asset = researchQuestion.asset {
                        Text(asset.name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Metadata rows
                    VStack(alignment: .leading, spacing: 8) {
                        // Investment phase badge
                        HStack(spacing: 4) {
                            Image(systemName: researchQuestion.investmentPhase.iconName)
                            Text(researchQuestion.investmentPhase.displayName)
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(researchQuestion.investmentPhase.colorName).opacity(0.15))
                        .foregroundStyle(Color(researchQuestion.investmentPhase.colorName))
                        .clipShape(Capsule())
                        
                        HStack(spacing: 16) {
                            // Review reminder badge (inline)
                            ReviewReminderBadge(researchQuestion: researchQuestion)
                            
                            Text("v\(researchQuestion.versionNumber)")
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
    
    /// Timeline items (log entries and decisions) filtered and sorted by date
    private var timelineItems: [AnyTimelineItem] {
        var items: [AnyTimelineItem] = []
        
        if timelineFilter == .narrative {
            // Narrative mode: only reviews, decisions, and key system logs
            
            // Add review log entries
            let reviewLogs = filteredLogEntries.filter { $0.entryType == .review }
            items.append(contentsOf: reviewLogs.map { AnyTimelineItem.logEntry($0) })
            
            // Add status change logs (system-generated with "Status:" in title)
            let statusLogs = filteredLogEntries.filter { 
                $0.isSystemGenerated && $0.title.contains("Status:")
            }
            items.append(contentsOf: statusLogs.map { AnyTimelineItem.logEntry($0) })
            
            // Add confidence change logs (system-generated with "Confidence:" in title)
            let confidenceLogs = filteredLogEntries.filter { 
                $0.isSystemGenerated && $0.title.contains("Confidence:")
            }
            items.append(contentsOf: confidenceLogs.map { AnyTimelineItem.logEntry($0) })
            
            // Add decisions
            let decisions = researchQuestion.sortedDecisions
            items.append(contentsOf: decisions.map { AnyTimelineItem.decision($0) })
        } else {
            // All mode: all log entries
            items.append(contentsOf: filteredLogEntries.map { AnyTimelineItem.logEntry($0) })
            
            // Also include decisions in all mode
            let decisions = researchQuestion.sortedDecisions
            items.append(contentsOf: decisions.map { AnyTimelineItem.decision($0) })
        }
        
        // Sort by date (most recent first)
        return items.sorted { $0.timelineDate > $1.timelineDate }
    }
    
    /// Count of items in the filtered timeline
    private var timelineItemsCount: Int {
        timelineItems.count
    }
    
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Timeline header with slightly different coloring
            HStack {
                Text("Timeline")
                    .font(.headline)
                
                // Show count with filter indicator
                Text("(\(timelineItemsCount))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if timelineFilter == .narrative {
                    Text("• narrative")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                } else if !showSystemLogs && researchQuestion.sortedLogEntries.count != filteredLogEntries.count {
                    Text("• filtered")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                
                Spacer()
                
                // Timeline filter toggle
                Picker("Filter", selection: $timelineFilter) {
                    ForEach(TimelineFilter.allCases) { filter in
                        Text(filter.displayName).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
                
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
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            if timelineItems.isEmpty {
                EmptyStateView(
                    iconName: "note.text",
                    title: timelineFilter == .narrative ? "No Narrative Events" : (researchQuestion.sortedLogEntries.isEmpty ? "No Log Entries" : "No Visible Entries"),
                    description: timelineFilter == .narrative
                        ? "Narrative mode shows reviews and decisions. Switch to 'All' to see all log entries."
                        : (researchQuestion.sortedLogEntries.isEmpty
                            ? "Start documenting your research by adding log entries."
                            : "System-generated logs are hidden. Enable them in Settings."),
                    actionTitle: timelineFilter == .narrative ? nil : "Add Log Entry"
                ) {
                    if timelineFilter != .narrative {
                        showingAddLogEntry = true
                    }
                }
                .frame(height: 200)
            } else {
                LazyVStack(spacing: displayDensity == .compact ? 8 : 12) {
                    ForEach(timelineItems) { item in
                        switch item {
                        case .logEntry(let logEntry):
                            LogEntryCard(logEntry: logEntry, density: displayDensity) {
                                logEntryForEvidence = logEntry
                            }
                            .onTapGesture {
                                selectedLogEntry = logEntry
                            }
                            .contextMenu {
                                logEntryContextMenu(for: logEntry)
                            }
                            
                        case .decision(let decision):
                            DecisionTimelineCard(decision: decision, density: displayDensity) {
                                selectedDecision = decision
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    private var statusBadge: some View {
        Menu {
            ForEach(ResearchQuestionStatus.allCases) { status in
                Button {
                    researchQuestion.status = status
                } label: {
                    if researchQuestion.status == status {
                        Label(status.displayName, systemImage: "checkmark")
                    } else {
                        Text(status.displayName)
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: researchQuestion.status.iconName)
                    .font(.caption)
                    .foregroundColor(statusColor)
                Text(researchQuestion.status.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(statusColor)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.15))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .help("Change status")
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
        HStack(spacing: 10) {
            // Type icon with background
            Image(systemName: scenario.scenarioType.iconName)
                .font(.caption)
                .foregroundStyle(typeColor)
                .frame(width: 20, height: 20)
                .background(typeColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 4))
            
            // Scenario type label
            Text(scenario.scenarioType.rawValue.capitalized)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(typeColor)
                .frame(width: 50, alignment: .leading)
            
            // Scenario title
            Text(scenario.title)
                .font(.subheadline)
                .foregroundStyle(.primary)
            
            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(typeColor.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 6))
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
            // Header (always visible, clickable) - slightly different coloring
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 12)
                    
                    Image(systemName: iconName)
                        .font(.subheadline)
                        .foregroundStyle(Color.accentColor)
                    
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    if let count = itemCount {
                        Text("\(count)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.1))
                            .foregroundStyle(Color.accentColor)
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
            
            // Content (collapsible)
            if isExpanded {
                content()
                    .padding(.leading, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                    .padding(.horizontal, 12)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor).opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Description Section (Non-Collapsible)

/// Non-collapsible section header for description tab - always shows content
private struct DescriptionSection<Content: View>: View {
    let title: String
    let iconName: String
    var itemCount: Int?
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (always visible, not clickable) - slightly different coloring
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.subheadline)
                    .foregroundStyle(Color.accentColor)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                if let count = itemCount {
                    Text("\(count)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.1))
                        .foregroundStyle(Color.accentColor)
                        .clipShape(Capsule())
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
            
            // Content (always visible)
            content()
                .padding(.leading, 24)
                .padding(.top, 8)
                .padding(.bottom, 4)
                .padding(.horizontal, 12)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
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

// MARK: - Compact Driver Row

/// Compact driver row with sub-drivers and logic for the Description tab
private struct CompactDriverRow: View {
    let driver: Driver
    @State private var isExpanded: Bool = true
    
    /// Color for the driver's current status
    private var statusColor: Color {
        switch driver.status {
        case .confirmed: return .green
        case .discarded: return .red
        case .needsRevision: return .orange
        case .pending: return .gray
        }
    }
    
    private var hasSubDrivers: Bool {
        guard let subs = driver.subDrivers else { return false }
        return !subs.isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Driver header row
            HStack(spacing: 8) {
                // Disclosure indicator (only if has subdrivers)
                if hasSubDrivers {
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 14)
                    }
                    .buttonStyle(.plain)
                } else {
                    // Empty space for alignment
                    Spacer()
                        .frame(width: 14)
                }
                
                // Driver type pill (fixed width, right-aligned for alignment with sub-driver pills)
                HStack(spacing: 4) {
                    Image(systemName: "number")
                        .font(.caption2)
                    Text("Driver")
                        .font(.caption)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.orange.opacity(0.12))
                .foregroundStyle(.orange)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .frame(width: 70, alignment: .trailing)
                
                // Status indicator
                Image(systemName: statusIconName)
                    .font(.subheadline)
                    .foregroundStyle(statusColor)
                    .frame(width: 16)
                
                // Driver title
                Text(driver.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(driver.status == .discarded ? .secondary : .primary)
                    .strikethrough(driver.status == .discarded, color: .red)
                
                // Status badge for non-pending
                if driver.status != .pending {
                    Text(driver.status.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(statusColor.opacity(0.15))
                        .foregroundStyle(statusColor)
                        .clipShape(Capsule())
                }
                
                Spacer()
            }
            
            // Logic/reasoning (if provided)
            if let logic = driver.logic, !logic.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .frame(width: 14)
                    
                    Text(logic)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .italic()
                }
                .padding(.leading, 30)
            }
            
            // Sub-drivers (collapsible)
            if hasSubDrivers && isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(driver.subDrivers!.sorted(by: { $0.position < $1.position })) { subDriver in
                        CompactSubDriverRow(driver: subDriver)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var statusIconName: String {
        switch driver.status {
        case .confirmed: return "checkmark.circle.fill"
        case .discarded: return "xmark.circle.fill"
        case .needsRevision: return "exclamationmark.circle.fill"
        case .pending: return "circle"
        }
    }
}

/// Compact sub-driver row for nested items with logic
private struct CompactSubDriverRow: View {
    let driver: Driver
    
    private var statusColor: Color {
        switch driver.status {
        case .confirmed: return .green
        case .discarded: return .red
        case .needsRevision: return .orange
        case .pending: return .gray
        }
    }
    
    private var statusIconName: String {
        switch driver.status {
        case .confirmed: return "checkmark.circle.fill"
        case .discarded: return "xmark.circle.fill"
        case .needsRevision: return "exclamationmark.circle.fill"
        case .pending: return "circle"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Sub-driver header row
            HStack(spacing: 8) {
                // Empty space for alignment with driver chevron area
                Spacer()
                    .frame(width: 14)
                
                // Sub-driver type pill (fixed width, right-aligned to match driver pills)
                HStack(spacing: 4) {
                    Image(systemName: "arrow.turn.down.right")
                        .font(.caption2)
                    Text("Sub")
                        .font(.caption)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.indigo.opacity(0.12))
                .foregroundStyle(.indigo)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .frame(width: 70, alignment: .trailing)
                
                // Status indicator
                Image(systemName: statusIconName)
                    .font(.caption)
                    .foregroundStyle(statusColor)
                    .frame(width: 16)
                
                // Sub-driver title
                Text(driver.title)
                    .font(.subheadline)
                    .foregroundStyle(driver.status == .discarded ? .tertiary : .secondary)
                    .strikethrough(driver.status == .discarded, color: .red)
                
                // Status badge for non-pending
                if driver.status != .pending {
                    Text(driver.status.displayName)
                        .font(.caption2)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(statusColor.opacity(0.1))
                        .foregroundStyle(statusColor)
                        .clipShape(Capsule())
                }
                
                Spacer()
            }
            
            // Logic/reasoning (if provided)
            if let logic = driver.logic, !logic.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "lightbulb")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    
                    Text(logic)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .italic()
                }
                .padding(.leading, 30)
            }
        }
        .padding(.vertical, 4)
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
                // Driver type pill
                HStack(spacing: 4) {
                    Image(systemName: "number")
                        .font(.caption2)
                    Text("Driver")
                        .font(.caption)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.orange.opacity(0.12))
                .foregroundStyle(.orange)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                
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
        .background(Color(nsColor: .windowBackgroundColor))
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
                
                // Sub-driver type pill
                HStack(spacing: 4) {
                    Image(systemName: "arrow.turn.down.right")
                        .font(.caption2)
                    Text("Sub")
                        .font(.caption)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.indigo.opacity(0.12))
                .foregroundStyle(.indigo)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                
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
            // Arrow for subdrivers
            if isSubDriver {
                Text("→")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            // Driver/Sub-driver type pill
            HStack(spacing: 4) {
                Image(systemName: isSubDriver ? "arrow.turn.down.right" : "number")
                    .font(.caption2)
                Text(isSubDriver ? "Sub" : "Driver")
                    .font(.caption)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(isSubDriver ? Color.indigo.opacity(0.12) : Color.orange.opacity(0.12))
            .foregroundStyle(isSubDriver ? .indigo : .orange)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            
            // Status indicator icon
            Image(systemName: driver.status.iconName)
                .font(.caption)
                .foregroundStyle(statusColor)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                // Driver title
                Text(driver.title)
                    .font(.subheadline)
                    .strikethrough(driver.status == .discarded, color: .red)
                    .foregroundStyle(driver.status == .discarded ? .secondary : .primary)
                
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
                
                // Type pill (directly after icon)
                Text(logEntry.entryType.displayName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(typeColor.opacity(0.15))
                    .foregroundStyle(typeColor)
                    .clipShape(Capsule())
                
                Text(logEntry.title)
                    .font(density == .compact ? .subheadline : .headline)
                    .lineLimit(1)
                
                if logEntry.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                
                // Show sentiment badge if linked to driver
                if let sentiment = logEntry.sentiment {
                    sentimentBadge(sentiment)
                }
                
                // Link indicator if log entry has source URL
                if let sourceUrl = logEntry.sourceUrl, !sourceUrl.isEmpty {
                    Image(systemName: "link")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
                
                Spacer()
                
                // Date
                Text(logEntry.occurredAt.formatted(date: .abbreviated, time: density == .compact ? .omitted : .shortened))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            // Driver linkage indicator
            if let driver = logEntry.driver {
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
            
            // Evidence section - show evidence items in timeline
            if !logEntry.sortedEvidence.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(logEntry.sortedEvidence.prefix(density == .compact ? 1 : 3)) { evidence in
                        EvidenceTimelineRow(evidence: evidence, density: density)
                    }
                    if logEntry.evidenceCount > (density == .compact ? 1 : 3) {
                        Text("+\(logEntry.evidenceCount - (density == .compact ? 1 : 3)) more")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .italic()
                    }
                }
                .padding(.top, 4)
            }
            
            // Metadata row (hide in compact mode)
            if density.showMetadataRow {
                HStack(spacing: 12) {
                    // Evidence count (if not shown above)
                    if logEntry.evidenceCount > (density == .compact ? 1 : 3) {
                        Label("\(logEntry.evidenceCount) evidence", systemImage: "link")
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
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: density == .compact ? 8 : 10))
        .overlay(
            RoundedRectangle(cornerRadius: density == .compact ? 8 : 10)
                .stroke(logEntry.driver != nil ? Color.blue.opacity(0.3) : Color(nsColor: .separatorColor).opacity(0.3), lineWidth: 1)
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

// MARK: - Decision Timeline Card

/// Card view for displaying a decision in the timeline
struct DecisionTimelineCard: View {
    let decision: Decision
    var density: DisplayDensity = .comfortable
    let onTap: () -> Void
    
    private var actionColor: Color {
        Color.fromName(decision.actionType.colorName)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: density == .compact ? 4 : 8) {
            // Header row
            HStack {
                // Action icon
                Image(systemName: decision.actionType.iconName)
                    .foregroundStyle(actionColor)
                    .font(density == .compact ? .caption : .body)
                
                // Decision pill (directly after icon)
                Text("Decision")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(actionColor.opacity(0.15))
                    .foregroundStyle(actionColor)
                    .clipShape(Capsule())
                
                Text(decision.actionType.displayName)
                    .font(density == .compact ? .subheadline : .headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(actionColor)
                
                Spacer()
                
                // Date
                Text(decision.decidedAt.formatted(date: .abbreviated, time: density == .compact ? .omitted : .shortened))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            // Rationale preview
            Text(rationalePreview)
                .font(density == .compact ? .caption : .subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(density.bodyPreviewLines)
            
            // Metadata row (hide in compact mode)
            if density.showMetadataRow {
                HStack(spacing: 12) {
                    // Confidence at decision
                    if let confidence = decision.confidenceLevel {
                        Label(confidence.shortLabel, systemImage: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Price
                    if let price = decision.priceAtDecision, !price.isEmpty {
                        Label(price, systemImage: "dollarsign.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Expectations indicator
                    if decision.hasExpectations {
                        Label("Expectations", systemImage: "target")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Exit plan indicator
                    if decision.hasExitPlan {
                        Label("Exit Plan", systemImage: "door.left.hand.open")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(density == .compact ? 10 : 16)
        .background(actionColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: density == .compact ? 8 : 10))
        .overlay(
            RoundedRectangle(cornerRadius: density == .compact ? 8 : 10)
                .stroke(actionColor.opacity(0.25), lineWidth: 1)
        )
        .onTapGesture {
            onTap()
        }
    }
    
    /// Rationale preview text with density-appropriate truncation
    private var rationalePreview: String {
        let text = decision.rationale
        let maxLength = density == .compact ? 80 : (density == .comfortable ? 150 : 300)
        if text.count <= maxLength {
            return text
        }
        return String(text.prefix(maxLength)) + "..."
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
                            Image(systemName: "note.text")
                                .foregroundStyle(.secondary)
                            
                            // Show sentiment badge if linked to driver
                            if let sentiment = logEntry.sentiment {
                                sentimentBadge(sentiment)
                            }
                            
                            // Link indicator if has source URL
                            if let sourceUrl = logEntry.sourceUrl, !sourceUrl.isEmpty {
                                Image(systemName: "link")
                                    .foregroundStyle(.blue)
                            }
                            
                            Spacer()
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

// MARK: - Evidence Timeline Row

/// Compact evidence row for timeline display
struct EvidenceTimelineRow: View {
    let evidence: Evidence
    var density: DisplayDensity = .comfortable
    
    var body: some View {
        HStack(spacing: 6) {
            // Evidence type icon
            Image(systemName: evidence.evidenceType.iconName)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 12)
            
            // Link icon if has URL
            if evidence.urlRaw != nil && !evidence.urlRaw!.isEmpty {
                Image(systemName: "link")
                    .font(.caption2)
                    .foregroundStyle(.blue)
            }
            
            // Driver indicator if linked
            if evidence.driver != nil {
                Image(systemName: "target")
                    .font(.caption2)
                    .foregroundStyle(.blue)
            }
            
            // Title
            Text(evidence.effectiveTitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(evidence.driver != nil ? Color.blue.opacity(0.05) : Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(evidence.driver != nil ? Color.blue.opacity(0.2) : Color.clear, lineWidth: 1)
        )
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
            
            // Show linked driver if evidence is linked to a driver
            if let driver = evidence.driver {
                HStack(spacing: 4) {
                    Image(systemName: "target")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                    Text("Linked to:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(driver.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.blue)
                }
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
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(evidence.driver != nil ? Color.blue.opacity(0.3) : Color(nsColor: .separatorColor).opacity(0.3), lineWidth: 1)
        )
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
