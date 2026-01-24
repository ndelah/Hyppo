/**
 ReviewWizardView provides a guided review workflow for scenarios.
 
 Walks the user through reviewing key drivers, checking invalidation rules,
 and deciding on an outcome (reinforce/revise/invalidate). Generates a
 structured review log entry upon completion.
 */

import SwiftUI
import SwiftData

// MARK: - ReviewOutcome Helpers

/// Helper functions for ReviewOutcome UI display in the wizard
func reviewOutcomeDescription(_ outcome: ReviewOutcome) -> String {
    switch outcome {
    case .reinforce:
        return "Scenario remains valid. Strengthen conviction based on evidence."
    case .revise:
        return "Scenario needs updates. Some assumptions have changed."
    case .invalidate:
        return "Scenario is no longer valid. An invalidation rule was triggered."
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

func reviewOutcomeScenarioStatus(_ outcome: ReviewOutcome) -> ScenarioStatus? {
    switch outcome {
    case .reinforce: return nil
    case .revise: return nil
    case .invalidate: return .invalidated
    }
}

// MARK: - Driver Assessment

/// Tracks assessment of each key driver
struct DriverAssessment: Identifiable {
    let id = UUID()
    let driver: String
    var isStillValid: Bool = true
    var notes: String = ""
}

// MARK: - Rule Check

/// Tracks check of each invalidation rule
struct RuleCheck: Identifiable {
    let id = UUID()
    let rule: String
    var isTriggered: Bool = false
    var notes: String = ""
}

// MARK: - Review Wizard View

struct ReviewWizardView: View {
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Properties
    
    let scenario: Scenario
    let onComplete: () -> Void
    
    // MARK: - State
    
    @State private var currentStep: WizardStep = .overview
    @State private var driverAssessments: [DriverAssessment] = []
    @State private var ruleChecks: [RuleCheck] = []
    @State private var selectedOutcome: ReviewOutcome = .reinforce
    @State private var newConfidence: Int = 3
    @State private var overallNotes: String = ""
    @State private var showingConfirmation = false
    
    // MARK: - Wizard Steps
    
    enum WizardStep: Int, CaseIterable {
        case overview = 0
        case drivers = 1
        case rules = 2
        case outcome = 3
        case summary = 4
        
        var title: String {
            switch self {
            case .overview: return "Review Overview"
            case .drivers: return "Check Key Drivers"
            case .rules: return "Check Invalidation Rules"
            case .outcome: return "Select Outcome"
            case .summary: return "Review Summary"
            }
        }
        
        var iconName: String {
            switch self {
            case .overview: return "doc.text.magnifyingglass"
            case .drivers: return "arrow.up.forward"
            case .rules: return "xmark.circle"
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
        .frame(width: 600, height: 550)
        .onAppear {
            initializeAssessments()
        }
        .alert("Complete Review", isPresented: $showingConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Complete") {
                completeReview()
            }
        } message: {
            Text("This will create a review log entry and update the scenario. Continue?")
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
        case .rules:
            rulesStep
        case .outcome:
            outcomeStep
        case .summary:
            summaryStep
        }
    }
    
    // MARK: - Overview Step
    
    private var overviewStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Scenario info
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: scenario.scenarioType.iconName)
                            .foregroundStyle(scenarioTypeColor)
                        Text(scenario.title)
                            .font(.headline)
                        Spacer()
                        Text(scenario.status.displayName)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(scenarioStatusColor.opacity(0.15))
                            .foregroundStyle(scenarioStatusColor)
                            .clipShape(Capsule())
                    }
                    
                    Text(scenario.scenarioStatement)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    if let lastReview = scenario.lastReviewedAt {
                        Text("Last reviewed: \(lastReview.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    } else {
                        Text("Never reviewed")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(8)
            }
            
            // Review process explanation
            VStack(alignment: .leading, spacing: 12) {
                Text("Review Process")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 8) {
                    reviewProcessItem(number: 1, text: "Check if each key driver is still valid")
                    reviewProcessItem(number: 2, text: "Verify if any invalidation rules have triggered")
                    reviewProcessItem(number: 3, text: "Decide on an outcome: Reinforce, Revise, or Invalidate")
                    reviewProcessItem(number: 4, text: "Add notes and confirm your review")
                }
            }
            
            // Quick stats
            HStack(spacing: 24) {
                statBox(title: "Key Drivers", value: "\(scenario.keyDrivers.count)", icon: "arrow.up.forward")
                statBox(title: "Invalidation Rules", value: "\(scenario.invalidationRules.count)", icon: "xmark.circle")
                statBox(title: "Log Entries", value: "\(scenario.logEntriesCount)", icon: "note.text")
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
            Text("For each key driver, assess whether it remains valid:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            ForEach($driverAssessments) { $assessment in
                DriverAssessmentCard(assessment: $assessment)
            }
            
            // Summary
            let validCount = driverAssessments.filter { $0.isStillValid }.count
            HStack {
                Spacer()
                Text("\(validCount) of \(driverAssessments.count) drivers still valid")
                    .font(.caption)
                    .foregroundStyle(validCount == driverAssessments.count ? .green : .orange)
            }
        }
    }
    
    // MARK: - Rules Step
    
    private var rulesStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Check if any invalidation rules have been triggered:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            ForEach($ruleChecks) { $check in
                RuleCheckCard(ruleCheck: $check)
            }
            
            // Summary
            let triggeredCount = ruleChecks.filter { $0.isTriggered }.count
            HStack {
                Spacer()
                if triggeredCount > 0 {
                    Label("\(triggeredCount) rule(s) triggered!", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                } else {
                    Label("No rules triggered", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
        }
    }
    
    // MARK: - Outcome Step
    
    private var outcomeStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Auto-suggestion based on assessments
            if let suggestion = suggestedOutcome {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                    Text("Based on your assessment, we suggest: **\(suggestion.displayName)**")
                        .font(.subheadline)
                }
                .padding()
                .background(Color.yellow.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
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
                            Text("\(level)")
                                .font(.headline)
                                .frame(width: 44, height: 44)
                                .background(newConfidence == level ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
                                .foregroundStyle(newConfidence == level ? .white : .primary)
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
                let invalidDrivers = driverAssessments.filter { !$0.isStillValid }
                summaryRow(
                    label: "Drivers",
                    value: invalidDrivers.isEmpty
                        ? "All \(driverAssessments.count) drivers valid"
                        : "\(invalidDrivers.count) of \(driverAssessments.count) no longer valid",
                    isWarning: !invalidDrivers.isEmpty
                )
                
                // Rules summary
                let triggeredRules = ruleChecks.filter { $0.isTriggered }
                summaryRow(
                    label: "Invalidation Rules",
                    value: triggeredRules.isEmpty
                        ? "No rules triggered"
                        : "\(triggeredRules.count) rule(s) triggered",
                    isWarning: !triggeredRules.isEmpty
                )
                
                // Confidence
                summaryRow(
                    label: "Confidence",
                    value: "\(scenario.confidenceCurrent ?? 3) → \(newConfidence)",
                    isWarning: newConfidence < (scenario.confidenceCurrent ?? 3)
                )
                
                // Status change (if invalidating)
                if selectedOutcome == .invalidate {
                    summaryRow(
                        label: "Status Change",
                        value: "\(scenario.status.displayName) → Invalidated",
                        isWarning: true
                    )
                }
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
        driverAssessments = scenario.keyDrivers.map { DriverAssessment(driver: $0) }
        ruleChecks = scenario.invalidationRules.map { RuleCheck(rule: $0) }
        newConfidence = scenario.confidenceCurrent ?? 3
    }
    
    private var suggestedOutcome: ReviewOutcome? {
        let hasTriggeredRules = ruleChecks.contains { $0.isTriggered }
        let invalidDriverCount = driverAssessments.filter { !$0.isStillValid }.count
        
        if hasTriggeredRules {
            return .invalidate
        } else if invalidDriverCount > 0 {
            return .revise
        } else {
            return .reinforce
        }
    }
    
    /// Color for the scenario type
    private var scenarioTypeColor: Color {
        switch scenario.scenarioType {
        case .bull: return .green
        case .bear: return .red
        case .base: return .blue
        case .custom: return .purple
        }
    }
    
    /// Color for the scenario status
    private var scenarioStatusColor: Color {
        switch scenario.status {
        case .active: return .green
        case .onHold: return .orange
        case .invalidated: return .red
        case .archived: return .gray
        }
    }
    
    private func generateLogBody() -> String {
        var body = "## Review Outcome: \(selectedOutcome.displayName)\n\n"
        
        // Drivers assessment
        body += "### Key Drivers Assessment\n"
        for assessment in driverAssessments {
            let status = assessment.isStillValid ? "✅" : "❌"
            body += "- \(status) \(assessment.driver)\n"
            if !assessment.notes.isEmpty {
                body += "  - Note: \(assessment.notes)\n"
            }
        }
        body += "\n"
        
        // Rules check
        body += "### Invalidation Rules Check\n"
        for check in ruleChecks {
            let status = check.isTriggered ? "⚠️ TRIGGERED" : "✓ Not triggered"
            body += "- \(status): \(check.rule)\n"
            if !check.notes.isEmpty {
                body += "  - Note: \(check.notes)\n"
            }
        }
        body += "\n"
        
        // Confidence
        let oldConfidence = scenario.confidenceCurrent ?? 3
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
        logEntry.scenario = scenario
        modelContext.insert(logEntry)
        
        // Update scenario
        scenario.confidenceCurrent = newConfidence
        scenario.lastReviewedAt = Date()
        
        // Update status if invalidating
        if selectedOutcome == .invalidate {
            _ = scenario.updateStatus(.invalidated)
        }
        
        // Update review reminder if exists
        if let reminder = scenario.reviewReminder {
            reminder.completeReview()
        }
        
        onComplete()
        dismiss()
    }
}

// MARK: - Driver Assessment Card

private struct DriverAssessmentCard: View {
    @Binding var assessment: DriverAssessment
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button {
                    assessment.isStillValid.toggle()
                } label: {
                    Image(systemName: assessment.isStillValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(assessment.isStillValid ? .green : .red)
                }
                .buttonStyle(.plain)
                
                Text(assessment.driver)
                    .font(.subheadline)
                
                Spacer()
                
                Button {
                    withAnimation { isExpanded.toggle() }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            if isExpanded {
                TextField("Add notes...", text: $assessment.notes, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Rule Check Card

private struct RuleCheckCard: View {
    @Binding var ruleCheck: RuleCheck
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button {
                    ruleCheck.isTriggered.toggle()
                } label: {
                    Image(systemName: ruleCheck.isTriggered ? "exclamationmark.triangle.fill" : "checkmark.shield.fill")
                        .font(.title2)
                        .foregroundStyle(ruleCheck.isTriggered ? .red : .green)
                }
                .buttonStyle(.plain)
                
                Text(ruleCheck.rule)
                    .font(.subheadline)
                    .foregroundStyle(ruleCheck.isTriggered ? .red : .primary)
                
                Spacer()
                
                Button {
                    withAnimation { isExpanded.toggle() }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            if isExpanded {
                TextField("Add notes...", text: $ruleCheck.notes, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
            }
        }
        .padding()
        .background(ruleCheck.isTriggered ? Color.red.opacity(0.1) : Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
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

// MARK: - Preview

#Preview {
    let scenario = Scenario(
        scenarioType: .bull,
        title: "Revenue Growth Acceleration",
        scenarioStatement: "Company will see 20% revenue growth driven by new product launches.",
        keyDrivers: ["New product adoption", "Market expansion", "Pricing power"],
        invalidationRules: ["Revenue growth falls below 10%", "Market share loss > 5%"]
    )
    
    return ReviewWizardView(scenario: scenario) { }
        .modelContainer(for: [Scenario.self, LogEntry.self, Tag.self], inMemory: true)
}

