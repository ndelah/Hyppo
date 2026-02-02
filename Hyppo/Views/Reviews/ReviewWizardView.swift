/**
 ReviewWizardView provides a guided review workflow for research questions.
 
 Walks the user through reviewing key drivers and deciding on an outcome
 (reinforce/revise/invalidate). Generates a structured review log entry
 upon completion.
 */

import SwiftUI
import SwiftData

// MARK: - ReviewOutcome Helpers

/// Helper functions for ReviewOutcome UI display in the wizard
func reviewOutcomeDescription(_ outcome: ReviewOutcome) -> String {
    switch outcome {
    case .reinforce:
        return "Thesis remains valid. Strengthen conviction based on evidence."
    case .revise:
        return "Thesis needs updates. Some assumptions have changed."
    case .invalidate:
        return "Thesis is no longer valid. An invalidation rule was triggered."
    }
}

func reviewOutcomeFilledIcon(_ outcome: ReviewOutcome) -> String {
    switch outcome {
    case .reinforce: return "checkmark.seal.fill"
    case .revise: return "pencil.circle.fill"
    case .invalidate: return "xmark.seal.fill"
    }
}

func reviewOutcomeColor(_ outcome: ReviewOutcome) -> Color {
    switch outcome {
    case .reinforce: return .green
    case .revise: return .orange
    case .invalidate: return .red
    }
}

func reviewOutcomeResearchQuestionStatus(_ outcome: ReviewOutcome) -> ResearchQuestionStatus? {
    switch outcome {
    case .reinforce: return nil
    case .revise: return nil
    case .invalidate: return .invalidated
    }
}

// MARK: - Driver Assessment

/// Tracks assessment of each key driver during review
struct DriverAssessment: Identifiable {
    let id: UUID
    let title: String
    let currentStatus: DriverStatus
    var newStatus: DriverStatus
    var notes: String = ""
    
    init(driver: Driver) {
        self.id = driver.driverId
        self.title = driver.title
        self.currentStatus = driver.status
        // Default to current status, or pending if not yet resolved
        self.newStatus = driver.status
    }
    
    /// Whether the driver is being marked as confirmed
    var isConfirmed: Bool {
        newStatus == .confirmed
    }
    
    /// Whether the driver is being marked as discarded
    var isDiscarded: Bool {
        newStatus == .discarded
    }
    
    /// Whether the status changed from the original
    var statusChanged: Bool {
        newStatus != currentStatus
    }
}

// MARK: - Review Wizard View

struct ReviewWizardView: View {
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Properties
    
    let researchQuestion: ResearchQuestion
    let onComplete: () -> Void
    
    // MARK: - State
    
    @State private var currentStep: WizardStep = .overview
    @State private var driverAssessments: [DriverAssessment] = []
    @State private var selectedOutcome: ReviewOutcome = .reinforce
    @State private var newConfidence: Int = 3
    @State private var overallNotes: String = ""
    @State private var showingConfirmation = false
    
    // Conclusion state (shown when all drivers resolved)
    @State private var conclusionText: String = ""
    @State private var shouldArchiveAfterConclusion = false
    
    // Revision prompt state
    @State private var showingRevisionPrompt = false
    @State private var driversNeedingRevision: [DriverAssessment] = []
    
    // MARK: - Wizard Steps
    
    enum WizardStep: Int, CaseIterable {
        case overview = 0
        case drivers = 1
        case outcome = 2
        case summary = 3
        
        var title: String {
            switch self {
            case .overview: return "Review Overview"
            case .drivers: return "Check Key Drivers"
            case .outcome: return "Select Outcome"
            case .summary: return "Review Summary"
            }
        }
        
        var iconName: String {
            switch self {
            case .overview: return "doc.text.magnifyingglass"
            case .drivers: return "arrow.up.forward"
            case .outcome: return "questionmark.circle"
            case .summary: return "checkmark.circle"
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            progressBar
            
            Divider()
            
            // Step content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    stepContent
                }
                .padding(24)
            }
            
            Divider()
            
            // Navigation buttons
            navigationBar
        }
        .frame(width: 600, height: 850)
        .onAppear {
            initializeAssessments()
        }
        .alert("Complete Review", isPresented: $showingConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Complete") {
                completeReview()
            }
        } message: {
            Text("This will create a review log entry and update the research question. Continue?")
        }
        .sheet(isPresented: $showingRevisionPrompt) {
            RevisionPromptSheet(
                driversNeedingRevision: driversNeedingRevision,
                researchQuestion: researchQuestion,
                onDismiss: {
                    showingRevisionPrompt = false
                    onComplete()
                    dismiss()
                }
            )
        }
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        VStack(spacing: 12) {
            // Step indicators
            HStack(spacing: 0) {
                ForEach(WizardStep.allCases, id: \.rawValue) { step in
                    stepIndicator(for: step)
                    
                    if step != WizardStep.allCases.last {
                        Rectangle()
                            .fill(step.rawValue < currentStep.rawValue ? Color.accentColor : Color.gray.opacity(0.3))
                            .frame(height: 2)
                    }
                }
            }
            .padding(.horizontal)
            
            // Current step title
            Text(currentStep.title)
                .font(.headline)
        }
        .padding(.vertical, 16)
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    private func stepIndicator(for step: WizardStep) -> some View {
        let isCompleted = step.rawValue < currentStep.rawValue
        let isCurrent = step == currentStep
        
        return VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.accentColor : (isCurrent ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.2)))
                    .frame(width: 32, height: 32)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                } else {
                    Image(systemName: step.iconName)
                        .font(.caption)
                        .foregroundStyle(isCurrent ? Color.accentColor : .secondary)
                }
            }
            
            Text(step.title)
                .font(.caption2)
                .foregroundStyle(isCurrent ? .primary : .secondary)
                .lineLimit(1)
                .frame(width: 80)
        }
    }
    
    // MARK: - Step Content
    
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .overview:
            overviewStep
        case .drivers:
            driversStep
        case .outcome:
            outcomeStep
        case .summary:
            summaryStep
        }
    }
    
    // MARK: - Overview Step
    
    private var overviewStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Research question info (shown above conviction health)
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text(researchQuestion.questionText)
                    .font(.headline)
                    .lineLimit(2)
                Spacer()
                Text(researchQuestion.status.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.15))
                    .foregroundStyle(statusColor)
                    .clipShape(Capsule())
            }
            
            if let thesis = researchQuestion.thesisStatement, !thesis.isEmpty {
                Text(thesis)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            if let lastReview = researchQuestion.lastReviewedAt {
                Text("Last reviewed: \(lastReview.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                Text("Never reviewed")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            // Conviction Health Dashboard (compact version for overview)
            ConvictionHealthView(drivers: researchQuestion.drivers ?? [], isCompact: true)
            
            // Review process explanation
            VStack(alignment: .leading, spacing: 12) {
                Text("Review Process")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 8) {
                    reviewProcessItem(number: 1, text: "Check if each key driver is still valid")
                    reviewProcessItem(number: 2, text: "Decide on an outcome: Reinforce, Revise, or Invalidate")
                    reviewProcessItem(number: 3, text: "Add notes and confirm your review")
                }
            }
            
            // Quick stats
            HStack(spacing: 24) {
                statBox(title: "Assumptions", value: "\(researchQuestion.drivers?.count ?? 0)", icon: "target")
                statBox(title: "Log Entries", value: "\(researchQuestion.logEntriesCount)", icon: "note.text")
            }
        }
    }
    
    private func reviewProcessItem(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption.bold())
                .frame(width: 20, height: 20)
                .background(Color.accentColor.opacity(0.15))
                .foregroundStyle(Color.accentColor)
                .clipShape(Circle())
            
            Text(text)
                .font(.subheadline)
        }
    }
    
    private func statBox(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - Drivers Step
    
    private var driversStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("For each assumption, assess its current status:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            if driverAssessments.isEmpty {
                Text("No assumptions defined for this research question.")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .padding()
            } else {
                ForEach($driverAssessments) { $assessment in
                    DriverAssessmentCard(assessment: $assessment)
                }
                
                // Summary
                driverAssessmentSummary
            }
        }
    }
    
    /// Summary of driver assessments
    private var driverAssessmentSummary: some View {
        let confirmedCount = driverAssessments.filter { $0.newStatus == .confirmed }.count
        let discardedCount = driverAssessments.filter { $0.newStatus == .discarded }.count
        let revisionCount = driverAssessments.filter { $0.newStatus == .needsRevision }.count
        let pendingCount = driverAssessments.filter { $0.newStatus == .pending }.count
        
        return HStack(spacing: 16) {
            Spacer()
            if confirmedCount > 0 {
                Label("\(confirmedCount) confirmed", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
            if discardedCount > 0 {
                Label("\(discardedCount) discarded", systemImage: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            if revisionCount > 0 {
                Label("\(revisionCount) needs revision", systemImage: "exclamationmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            if pendingCount > 0 {
                Label("\(pendingCount) pending", systemImage: "circle.dashed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Outcome Step
    
    private var outcomeStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Select Review Outcome")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            // Outcome selection
            ForEach(ReviewOutcome.allCases) { outcome in
                OutcomeSelectionCard(
                    outcome: outcome,
                    isSelected: selectedOutcome == outcome,
                    onSelect: { selectedOutcome = outcome }
                )
            }
            
            Divider()
            
            // Confidence adjustment
            VStack(alignment: .leading, spacing: 8) {
                Text("Update Confidence Level")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 12) {
                    ForEach(1...5, id: \.self) { level in
                        Button {
                            newConfidence = level
                        } label: {
                            VStack(spacing: 2) {
                                Image(systemName: newConfidence >= level ? "star.fill" : "star")
                                    .font(.title2)
                                Text("\(level)")
                                    .font(.caption2)
                            }
                            .frame(width: 44, height: 44)
                            .background(newConfidence == level ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
                            .foregroundStyle(newConfidence == level ? .white : (newConfidence >= level ? .orange : .primary))
                            .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Spacer()
                    
                    if let level = ConfidenceLevel(rawValue: newConfidence) {
                        Text(level.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Divider()
            
            // Overall notes
            VStack(alignment: .leading, spacing: 8) {
                Text("Additional Notes")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                TextEditor(text: $overallNotes)
                    .font(.body)
                    .frame(height: 80)
                    .padding(8)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                    )
            }
        }
    }
    
    // MARK: - Summary Step
    
    private var summaryStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Outcome badge
            HStack {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: reviewOutcomeFilledIcon(selectedOutcome))
                        .font(.largeTitle)
                        .foregroundStyle(reviewOutcomeColor(selectedOutcome))
                    Text(selectedOutcome.displayName)
                        .font(.title2.bold())
                        .foregroundStyle(reviewOutcomeColor(selectedOutcome))
                    Text(reviewOutcomeDescription(selectedOutcome))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                Spacer()
            }
            .padding()
            .background(reviewOutcomeColor(selectedOutcome).opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Divider()
            
            // Summary details
            VStack(alignment: .leading, spacing: 12) {
                Text("Review Summary")
                    .font(.headline)
                
                // Drivers summary
                let confirmedCount = driverAssessments.filter { $0.newStatus == .confirmed }.count
                let discardedCount = driverAssessments.filter { $0.newStatus == .discarded }.count
                summaryRow(
                    label: "Assumptions",
                    value: driverAssessments.isEmpty
                        ? "No assumptions defined"
                        : "\(confirmedCount) confirmed, \(discardedCount) discarded",
                    isWarning: discardedCount > 0
                )
                
                // Confidence
                summaryRow(
                    label: "Confidence",
                    value: "\(researchQuestion.confidenceCurrent ?? 3) → \(newConfidence)",
                    isWarning: newConfidence < (researchQuestion.confidenceCurrent ?? 3)
                )
                
                // Status change (if invalidating)
                if selectedOutcome == .invalidate {
                    summaryRow(
                        label: "Status Change",
                        value: "\(researchQuestion.status.displayName) → Invalidated",
                        isWarning: true
                    )
                }
            }
            
            // Research Completion Section (shown when all drivers resolved)
            if willAllDriversBeResolved {
                researchCompletionSection
            }
            
            // Generated log preview
            VStack(alignment: .leading, spacing: 8) {
                Text("Log Entry Preview")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(generateLogBody())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    
    // MARK: - Research Completion Section
    
    /// Section shown when all drivers have been resolved
    private var researchCompletionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Completion banner
            HStack(spacing: 12) {
                Image(systemName: "flag.checkered")
                    .font(.title2)
                    .foregroundStyle(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Research Complete")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("All assumptions have been tested. Consider forming a conclusion.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            // Conclusion input
            VStack(alignment: .leading, spacing: 8) {
                Text("Conclusion (Optional)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                TextEditor(text: $conclusionText)
                    .font(.body)
                    .frame(height: 80)
                    .padding(8)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                    )
                
                Text("Summarize your findings and investment decision.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            // Archive option
            Toggle(isOn: $shouldArchiveAfterConclusion) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Archive Research Question")
                        .font(.subheadline)
                    Text("Mark this research as complete and archive it")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .toggleStyle(.switch)
            
            Divider()
        }
    }
    
    private func summaryRow(label: String, value: String, isWarning: Bool) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundStyle(isWarning ? .orange : .primary)
        }
        .font(.subheadline)
    }
    
    // MARK: - Navigation Bar
    
    private var navigationBar: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)
            
            Spacer()
            
            if currentStep != .overview {
                Button("Back") {
                    withAnimation {
                        currentStep = WizardStep(rawValue: currentStep.rawValue - 1) ?? .overview
                    }
                }
            }
            
            if currentStep == .summary {
                Button("Complete Review") {
                    showingConfirmation = true
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            } else {
                Button("Next") {
                    withAnimation {
                        currentStep = WizardStep(rawValue: currentStep.rawValue + 1) ?? .summary
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    // MARK: - Helpers
    
    private func initializeAssessments() {
        driverAssessments = (researchQuestion.drivers ?? []).map { DriverAssessment(driver: $0) }
        newConfidence = researchQuestion.confidenceCurrent ?? 3
    }
    
    /// Color for the research question status
    private var statusColor: Color {
        switch researchQuestion.status {
        case .active: return .green
        case .onHold: return .orange
        case .invalidated: return .red
        case .archived: return .gray
        }
    }
    
    /// Returns true if all drivers will be resolved (non-pending) after this review
    private var willAllDriversBeResolved: Bool {
        guard !driverAssessments.isEmpty else { return false }
        return driverAssessments.allSatisfy { $0.newStatus != .pending }
    }
    
    private func generateLogBody() -> String {
        var body = "## Review Outcome: \(selectedOutcome.displayName)\n\n"
        
        // Drivers assessment
        if !driverAssessments.isEmpty {
            body += "### Assumptions Assessment\n"
            for assessment in driverAssessments {
                let statusIcon: String
                switch assessment.newStatus {
                case .confirmed: statusIcon = "✅"
                case .discarded: statusIcon = "❌"
                case .needsRevision: statusIcon = "⚠️"
                case .pending: statusIcon = "⏳"
                }
                body += "- \(statusIcon) \(assessment.title) (\(assessment.newStatus.displayName))\n"
                if !assessment.notes.isEmpty {
                    body += "  - Note: \(assessment.notes)\n"
                }
            }
            body += "\n"
        }
        
        // Confidence
        let oldConfidence = researchQuestion.confidenceCurrent ?? 3
        if newConfidence != oldConfidence {
            body += "### Confidence Update\n"
            body += "Changed from \(oldConfidence)/5 to \(newConfidence)/5\n\n"
        }
        
        // Additional notes
        if !overallNotes.isEmpty {
            body += "### Additional Notes\n"
            body += overallNotes + "\n"
        }
        
        return body
    }
    
    private func completeReview() {
        // Create structured review log entry
        let logTitle = "Review: \(selectedOutcome.displayName)"
        let logEntry = LogEntry(
            title: logTitle,
            body: generateLogBody(),
            entryType: .review,
            confidence: newConfidence,
            occurredAt: Date(),
            isSystemGenerated: false
        )
        logEntry.researchQuestion = researchQuestion
        modelContext.insert(logEntry)
        
        // Update driver statuses based on assessments
        updateDriverStatuses()
        
        // Update research question
        researchQuestion.confidenceCurrent = newConfidence
        researchQuestion.lastReviewedAt = Date()
        
        // Handle conclusion if provided
        if !conclusionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            researchQuestion.conclusion = conclusionText
        }
        
        // Update status based on outcome or archive choice
        if selectedOutcome == .invalidate {
            _ = researchQuestion.updateStatus(.invalidated)
        } else if shouldArchiveAfterConclusion && willAllDriversBeResolved {
            _ = researchQuestion.updateStatus(.archived)
        }
        
        // Update review reminder if exists
        if let reminder = researchQuestion.reviewReminder {
            reminder.completeReview()
        }
        
        // Check if any drivers need revision and prompt user
        let revisionNeeded = driverAssessments.filter { $0.newStatus == .needsRevision }
        if !revisionNeeded.isEmpty {
            driversNeedingRevision = revisionNeeded
            showingRevisionPrompt = true
        } else {
            onComplete()
            dismiss()
        }
    }
    
    /// Updates driver statuses based on the assessments made during review
    private func updateDriverStatuses() {
        guard let drivers = researchQuestion.drivers else { return }
        
        for assessment in driverAssessments {
            if let driver = drivers.first(where: { $0.driverId == assessment.id }) {
                driver.status = assessment.newStatus
            }
        }
    }
}

// MARK: - Driver Assessment Card

private struct DriverAssessmentCard: View {
    @Binding var assessment: DriverAssessment
    @State private var isExpanded = false
    
    /// Color for the current status
    private var statusColor: Color {
        switch assessment.newStatus {
        case .confirmed: return .green
        case .discarded: return .red
        case .needsRevision: return .orange
        case .pending: return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row with title and expand button
            HStack {
                Image(systemName: assessment.newStatus.iconName)
                    .font(.title2)
                    .foregroundStyle(statusColor)
                
                Text(assessment.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                // Show previous status if it was already resolved
                if assessment.currentStatus != .pending {
                    Text("was: \(assessment.currentStatus.displayName)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                
                Button {
                    withAnimation { isExpanded.toggle() }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            // Status picker buttons
            HStack(spacing: 8) {
                ForEach([DriverStatus.confirmed, .needsRevision, .discarded, .pending], id: \.self) { status in
                    StatusButton(
                        status: status,
                        isSelected: assessment.newStatus == status,
                        action: { assessment.newStatus = status }
                    )
                }
            }
            
            // Expandable notes
            if isExpanded {
                TextField("Add notes...", text: $assessment.notes, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
            }
        }
        .padding()
        .background(statusColor.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(statusColor.opacity(0.3), lineWidth: 1)
        )
    }
}

/// Button for selecting a driver status
private struct StatusButton: View {
    let status: DriverStatus
    let isSelected: Bool
    let action: () -> Void
    
    private var statusColor: Color {
        switch status {
        case .confirmed: return .green
        case .discarded: return .red
        case .needsRevision: return .orange
        case .pending: return .gray
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: status.iconName)
                    .font(.caption)
                Text(status.displayName)
                    .font(.caption2)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(isSelected ? statusColor : Color(nsColor: .controlBackgroundColor))
            .foregroundStyle(isSelected ? .white : .secondary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.secondary.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Outcome Selection Card

private struct OutcomeSelectionCard: View {
    let outcome: ReviewOutcome
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                Image(systemName: reviewOutcomeFilledIcon(outcome))
                    .font(.title2)
                    .foregroundStyle(reviewOutcomeColor(outcome))
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(outcome.displayName)
                        .font(.headline)
                    Text(reviewOutcomeDescription(outcome))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding()
            .background(isSelected ? reviewOutcomeColor(outcome).opacity(0.1) : Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? reviewOutcomeColor(outcome) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Revision Prompt Sheet

/// Sheet displayed when drivers are marked as needing revision
private struct RevisionPromptSheet: View {
    let driversNeedingRevision: [DriverAssessment]
    let researchQuestion: ResearchQuestion
    let onDismiss: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    @State private var editedTitles: [UUID: String] = [:]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.orange)
                
                Text("Revise Assumptions")
                    .font(.title2.bold())
                
                Text("\(driversNeedingRevision.count) assumption\(driversNeedingRevision.count == 1 ? "" : "s") need revision based on your review.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.orange.opacity(0.1))
            
            Divider()
            
            // Driver edit list
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(driversNeedingRevision) { assessment in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current:")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            
                            Text(assessment.title)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .strikethrough()
                            
                            Text("Revised:")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .padding(.top, 4)
                            
                            TextField("Enter revised assumption...", text: binding(for: assessment.id, defaultValue: assessment.title))
                                .textFieldStyle(.roundedBorder)
                            
                            if !assessment.notes.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "note.text")
                                        .font(.caption2)
                                    Text("Note: \(assessment.notes)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Action buttons
            HStack {
                Button("Skip for Now") {
                    onDismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Save Changes") {
                    saveRevisions()
                    onDismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(!hasChanges)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .frame(width: 500, height: 500)
        .onAppear {
            // Initialize with current titles
            for assessment in driversNeedingRevision {
                editedTitles[assessment.id] = assessment.title
            }
        }
    }
    
    private func binding(for id: UUID, defaultValue: String) -> Binding<String> {
        Binding(
            get: { editedTitles[id] ?? defaultValue },
            set: { editedTitles[id] = $0 }
        )
    }
    
    private var hasChanges: Bool {
        for assessment in driversNeedingRevision {
            if let edited = editedTitles[assessment.id],
               edited != assessment.title,
               !edited.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return true
            }
        }
        return false
    }
    
    private func saveRevisions() {
        guard let drivers = researchQuestion.drivers else { return }
        
        for assessment in driversNeedingRevision {
            if let edited = editedTitles[assessment.id],
               edited != assessment.title,
               !edited.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               let driver = drivers.first(where: { $0.driverId == assessment.id }) {
                driver.title = edited.trimmingCharacters(in: .whitespacesAndNewlines)
                driver.updatedAt = Date()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let question = ResearchQuestion(
        questionText: "Can AAPL sustain services revenue growth?",
        thesisStatement: "Company will see 20% revenue growth driven by new product launches."
    )
    
    return ReviewWizardView(researchQuestion: question) { }
        .modelContainer(for: [ResearchQuestion.self, LogEntry.self, Tag.self, Driver.self], inMemory: true)
}
