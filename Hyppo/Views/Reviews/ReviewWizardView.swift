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
    case .reinforce: return .statusActive
    case .revise: return .statusOnHold
    case .invalidate: return .statusInvalidated
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
    /// The revised title entered inline when driver is marked as needing revision
    var revisedTitle: String = ""
    
    init(driver: Driver) {
        self.id = driver.driverId
        self.title = driver.title
        self.currentStatus = driver.status
        // Default to current status, or pending (under review) if not yet resolved
        self.newStatus = driver.status
    }
    
    /// Whether the user has provided a non-empty revised title
    var hasRevision: Bool {
        let trimmed = revisedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed != title
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
    
    // Decision state (required)
    @State private var selectedAction: DecisionAction
    @State private var decisionRationale: String = ""
    @State private var expectedTargetDate: Date? = nil
    @State private var priceAtDecision: String = ""
    @State private var exitPlan: String = ""
    @State private var whatWouldChangeMyMind: String = ""
    
    
    // MARK: - Wizard Steps
    
    enum WizardStep: Int, CaseIterable {
        case overview = 0
        case drivers = 1
        case outcome = 2
        case decision = 3
        case summary = 4
        
        var title: String {
            switch self {
            case .overview: return "Review Overview"
            case .drivers: return "Check Key Drivers"
            case .outcome: return "Select Outcome"
            case .decision: return "Record Decision"
            case .summary: return "Review Summary"
            }
        }
        
        var iconName: String {
            switch self {
            case .overview: return "doc.text.magnifyingglass"
            case .drivers: return "arrow.up.forward"
            case .outcome: return "questionmark.circle"
            case .decision: return "checkmark.circle.fill"
            case .summary: return "checkmark.circle"
            }
        }
    }
    
    // MARK: - Initialization
    
    init(researchQuestion: ResearchQuestion, onComplete: @escaping () -> Void) {
        self.researchQuestion = researchQuestion
        self.onComplete = onComplete
        
        // Initialize decision action to first valid action for current phase
        let validActions = researchQuestion.validDecisionActions
        _selectedAction = State(initialValue: validActions.first ?? .pass)
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
                            .fill(step.rawValue < currentStep.rawValue ? Color.accentColor : Color.statusArchived.opacity(0.3))
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
        .background(Color.surface)
    }
    
    private func stepIndicator(for step: WizardStep) -> some View {
        let isCompleted = step.rawValue < currentStep.rawValue
        let isCurrent = step == currentStep
        
        return VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.accentColor : (isCurrent ? Color.accentColor.opacity(0.2) : Color.statusArchived.opacity(0.2)))
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
        case .decision:
            decisionStep
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
                    .foregroundStyle(Color.statusActive)
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
                    reviewProcessItem(number: 3, text: "Record your decision based on the review")
                    reviewProcessItem(number: 4, text: "Review summary and complete")
                }
            }
            
            // Quick stats
            HStack(spacing: 24) {
                statBox(title: "Reviews", value: "\(researchQuestion.reviewLogsCount)", icon: "magnifyingglass")
                statBox(title: "Assumptions", value: "\(researchQuestion.drivers?.count ?? 0)", icon: "target")
                statBox(title: "Logs", value: "\(researchQuestion.logEntriesCount)", icon: "note.text")
                statBox(title: "Decisions", value: "\(researchQuestion.decisionsCount)", icon: "checkmark.circle")
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
        .background(Color.surface)
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
                    .foregroundStyle(Color.statusActive)
            }
            if discardedCount > 0 {
                Label("\(discardedCount) discarded", systemImage: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(Color.statusInvalidated)
            }
            if revisionCount > 0 {
                Label("\(revisionCount) needs revision", systemImage: "exclamationmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(Color.statusOnHold)
            }
            if pendingCount > 0 {
                Label("\(pendingCount) under review", systemImage: "circle.dashed")
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
                            .background(newConfidence == level ? Color.accentColor : Color.surface)
                            .foregroundStyle(newConfidence == level ? .white : (newConfidence >= level ? Color.confidenceMedium : .primary))
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
                let revisionCount = driverAssessments.filter { $0.newStatus == .needsRevision }.count
                let pendingCount = driverAssessments.filter { $0.newStatus == .pending }.count
                summaryRow(
                    label: "Assumptions",
                    value: driverAssessments.isEmpty
                        ? "No assumptions defined"
                        : "\(confirmedCount) confirmed, \(discardedCount) discarded, \(revisionCount) revised, \(pendingCount) under review",
                    isWarning: discardedCount > 0 || revisionCount > 0
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
                
                // Decision action
                summaryRow(
                    label: "Decision",
                    value: selectedAction.displayName,
                    isWarning: false
                )
            }
            
            Divider()
            
            // Decision rationale preview
            VStack(alignment: .leading, spacing: 8) {
                Text("Decision Rationale Preview")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(decisionRationale)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
        }
    }
    
    // MARK: - Decision Step
    
    private var decisionStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Record Your Decision")
                .font(.headline)
            
            Text("Based on your review, what action are you taking?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            // Action selection
            VStack(spacing: 12) {
                ForEach(researchQuestion.validDecisionActions, id: \.self) { action in
                    DecisionActionButton(
                        action: action,
                        isSelected: selectedAction == action,
                        onSelect: { selectedAction = action }
                    )
                }
            }
            
            Divider()
            
            // Decision rationale (required)
            VStack(alignment: .leading, spacing: 8) {
                Text("Rationale *")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                TextEditor(text: $decisionRationale)
                    .font(.body)
                    .frame(height: 100)
                    .padding(8)
                    .background(Color.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(decisionRationale.isEmpty ? Color.statusInvalidated.opacity(0.5) : Color.appBorder, lineWidth: 1)
                    )
                
                Text("Explain why you're making this decision based on your review.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            // Conditional fields based on action
            if selectedAction == .buy || selectedAction == .add {
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Expectations")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Target Date")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        DatePicker(
                            "",
                            selection: expectedTargetDateBinding,
                            displayedComponents: [.date]
                        )
                        .labelsHidden()
                        
                        HStack {
                            Text("Shown on your timeline as a reminder.")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                            
                            Spacer()
                            
                            if expectedTargetDate != nil {
                                Button("Clear Date") {
                                    expectedTargetDate = nil
                                }
                                .font(.caption2)
                            }
                        }
                    }
                }
            }
            
            if selectedAction == .buy || selectedAction == .add {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Exit Plan")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    if let currentExitPlan, !currentExitPlan.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current plan")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            
                            Text(currentExitPlan)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    
                    TextEditor(text: $exitPlan)
                        .font(.body)
                        .frame(height: 60)
                        .padding(8)
                        .background(Color.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.appBorder, lineWidth: 1)
                        )
                    
                    Text("Leave blank to keep the current plan. Update when commitments change.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            
            if selectedAction == .pass {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("What Would Change Your Mind?")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    TextEditor(text: $whatWouldChangeMyMind)
                        .font(.body)
                        .frame(height: 60)
                        .padding(8)
                        .background(Color.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.appBorder, lineWidth: 1)
                        )
                }
            }
            
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
                    completeReview()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            } else if currentStep == .decision {
                Button("Next") {
                    // Validate decision rationale before proceeding
                    if !decisionRationale.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        withAnimation {
                            currentStep = .summary
                        }
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(decisionRationale.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
        .background(Color.surface)
    }
    
    // MARK: - Helpers
    
    private func initializeAssessments() {
        driverAssessments = (researchQuestion.drivers ?? []).map { DriverAssessment(driver: $0) }
        newConfidence = researchQuestion.confidenceCurrent ?? 3
    }
    
    /// Color for the research question status
    private var statusColor: Color {
        Color.forStatus(researchQuestion.status)
    }
    
    /// Most recent exit plan on record (used as the current plan)
    private var currentExitPlan: String? {
        researchQuestion.sortedDecisions.last { decision in
            guard let plan = decision.exitPlan else { return false }
            return !plan.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }?.exitPlan
    }
    
    /// Binding that allows a DatePicker to write to an optional date
    private var expectedTargetDateBinding: Binding<Date> {
        Binding(
            get: { expectedTargetDate ?? Date() },
            set: { expectedTargetDate = $0 }
        )
    }
    
    private func generateDecisionRationale() -> String {
        var rationale = decisionRationale
        
        // Add review context to rationale
        rationale += "\n\n## Review Context\n"
        rationale += "**Outcome:** \(selectedOutcome.displayName)\n\n"
        
        // Drivers assessment summary
        if !driverAssessments.isEmpty {
            let confirmedCount = driverAssessments.filter { $0.newStatus == .confirmed }.count
            let discardedCount = driverAssessments.filter { $0.newStatus == .discarded }.count
            rationale += "**Assumptions:** \(confirmedCount) confirmed, \(discardedCount) discarded\n\n"
        }
        
        // Confidence change
        let oldConfidence = researchQuestion.confidenceCurrent ?? 3
        if newConfidence != oldConfidence {
            rationale += "**Confidence:** \(oldConfidence)/5 → \(newConfidence)/5\n\n"
        }
        
        return rationale
    }
    
    private func completeReview() {
        // Create Decision (not a Review log entry)
        let decision = Decision(
            actionType: selectedAction,
            rationale: generateDecisionRationale(),
            decidedAt: Date(),
            confidenceAtDecision: newConfidence
        )
        
        // Set price if provided
        if !priceAtDecision.isEmpty {
            decision.priceAtDecision = priceAtDecision
        }
        
        // Set expectations if provided
        if let expectedTargetDate {
            decision.expectedTargetDate = expectedTargetDate
        }
        
        // Set exit plan if provided
        if !exitPlan.isEmpty {
            decision.exitPlan = exitPlan
        }
        
        // Set "what would change my mind" if provided
        if !whatWouldChangeMyMind.isEmpty {
            decision.whatWouldChangeMyMind = whatWouldChangeMyMind
        }
        
        // Capture snapshot of driver counts from assessments (before updating)
        let confirmedCount = driverAssessments.filter { $0.newStatus == .confirmed }.count
        let discardedCount = driverAssessments.filter { $0.newStatus == .discarded }.count
        let pendingCount = driverAssessments.filter { $0.newStatus == .pending }.count
        
        decision.driversConfirmedCount = confirmedCount
        decision.driversDiscardedCount = discardedCount
        decision.driversPendingCount = pendingCount
        
        decision.researchQuestion = researchQuestion
        
        modelContext.insert(decision)
        
        // Update driver statuses based on assessments
        updateDriverStatuses()
        
        // Update research question
        researchQuestion.confidenceCurrent = newConfidence
        researchQuestion.lastReviewedAt = Date()
        
        // Update status based on outcome
        if selectedOutcome == .invalidate {
            _ = researchQuestion.updateStatus(.invalidated)
        }
        
        // Update investment phase based on decision action
        switch selectedAction {
        case .buy:
            if researchQuestion.investmentPhase == .watching {
                researchQuestion.investmentPhase = .entered
            }
        case .exit, .abandon:
            researchQuestion.investmentPhase = .exited
        default:
            break
        }
        
        // Update review reminder if exists
        if let reminder = researchQuestion.reviewReminder {
            reminder.completeReview()
        }
        
        onComplete()
        dismiss()
    }
    
    /// Updates driver statuses based on the assessments made during review.
    /// For drivers marked as needing revision with an inline revised title,
    /// applies the title change and resets status to pending (under review).
    private func updateDriverStatuses() {
        guard let drivers = researchQuestion.drivers else { return }
        
        for assessment in driverAssessments {
            if let driver = drivers.first(where: { $0.driverId == assessment.id }) {
                if assessment.newStatus == .needsRevision && assessment.hasRevision {
                    // User revised the driver inline — apply the new title and reset to pending
                    driver.title = assessment.revisedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                    driver.status = .pending
                    driver.updatedAt = Date()
                } else {
                    driver.status = assessment.newStatus
                }
            }
        }
    }
}

// MARK: - Driver Assessment Card

private struct DriverAssessmentCard: View {
    @Binding var assessment: DriverAssessment
    
    /// Color for the current status
    private var statusColor: Color {
        Color.forDriverStatus(assessment.newStatus)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row with title
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
            
            // Inline revision field (only when needs revision)
            if assessment.newStatus == .needsRevision {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Revised assumption:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    TextField("Enter revised assumption...", text: $assessment.revisedTitle, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .font(.caption)
                }
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
        Color.forDriverStatus(status)
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
            .background(isSelected ? statusColor : Color.surface)
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
            .background(isSelected ? reviewOutcomeColor(outcome).opacity(0.1) : Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? reviewOutcomeColor(outcome) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}


// MARK: - Decision Action Button

private struct DecisionActionButton: View {
    let action: DecisionAction
    let isSelected: Bool
    let onSelect: () -> Void
    
    private var actionColor: Color {
        Color.fromName(action.colorName)
    }
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: action.iconName)
                    .font(.title2)
                    .foregroundStyle(actionColor)
                    .frame(width: 40)
                
                Text(action.displayName)
                    .font(.headline)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(actionColor)
                }
            }
            .padding()
            .background(isSelected ? actionColor.opacity(0.1) : Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? actionColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    let question = ResearchQuestion(
        questionText: "Can AAPL sustain services revenue growth?",
        thesisStatement: "Company will see 20% revenue growth driven by new product launches."
    )
    
    return ReviewWizardView(researchQuestion: question) { }
        .modelContainer(for: [ResearchQuestion.self, LogEntry.self, Tag.self, Driver.self, Decision.self], inMemory: true)
}
