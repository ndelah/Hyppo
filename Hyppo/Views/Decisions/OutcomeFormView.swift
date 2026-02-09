/**
 OutcomeFormView provides a form for recording the outcome of an investment thesis.
 
 This form is required after Exit or Abandon decisions to complete the thesis lifecycle
 and transition to PostMortem phase. It captures:
 - What actually happened
 - Thesis accuracy assessment
 - Timing accuracy assessment
 - Lessons learned
 */

import SwiftUI
import SwiftData

/// Form for recording the outcome of a thesis
struct OutcomeFormView: View {
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Properties
    
    let researchQuestion: ResearchQuestion
    let onSave: (Outcome) -> Void
    
    // MARK: - State
    
    @State private var actualResult: String = ""
    @State private var actualTimeframe: String = ""
    @State private var exitPrice: String = ""
    @State private var thesisAssessment: ThesisAssessment = .inconclusive
    @State private var timingAssessment: TimingAssessment = .notApplicable
    @State private var lessonsLearned: String = ""
    @State private var whatWouldIDoDifferently: String = ""
    @State private var recordedAt: Date = Date()
    
    @State private var validationErrors: [String] = []
    
    // MARK: - Computed Properties
    
    /// Whether the form is valid
    private var isValid: Bool {
        !actualResult.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Whether this is an abandoned thesis (vs exited)
    private var isAbandoned: Bool {
        researchQuestion.investmentPhase == .abandoned
    }
    
    /// Title based on whether abandoned or exited
    private var formTitle: String {
        isAbandoned ? "Record Abandonment Outcome" : "Record Exit Outcome"
    }
    
    /// Entry decision for context
    private var entryDecision: Decision? {
        researchQuestion.entryDecision
    }
    
    /// Exit decision for context
    private var exitDecision: Decision? {
        researchQuestion.exitDecision
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Form content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Context section
                    contextSection
                    
                    // What actually happened
                    actualResultSection
                    
                    // Assessments (only for exited positions)
                    if !isAbandoned {
                        assessmentSection
                    }
                    
                    // Timeframe and price
                    if !isAbandoned {
                        quantitativeSection
                    }
                    
                    // Reflection
                    reflectionSection
                    
                    // Timestamp
                    timestampSection
                    
                    // Validation errors
                    if !validationErrors.isEmpty {
                        validationErrorsView
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Footer with buttons
            footerView
        }
        .frame(width: 550, height: 600)
        .onAppear {
            // Pre-populate timing assessment based on context
            if isAbandoned {
                timingAssessment = .notApplicable
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(formTitle)
                    .font(.headline)
                
                HStack(spacing: 4) {
                    Image(systemName: isAbandoned ? "xmark.circle" : "arrow.uturn.down.circle")
                        .foregroundStyle(isAbandoned ? Color.statusInvalidated : Color.statusOnHold)
                    Text(isAbandoned ? "Thesis Abandoned" : "Position Exited")
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }
            
            Spacer()
            
            // Ticker badge if available
            if let asset = researchQuestion.asset {
                Text(asset.ticker)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .padding()
    }
    
    private var contextSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Thesis
            VStack(alignment: .leading, spacing: 4) {
                Text("Thesis")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(researchQuestion.questionText)
                    .font(.subheadline)
            }
            
            // Entry details (if position was entered)
            if let entry = entryDecision {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Entry")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        let formatter = DateFormatter()
                        let _ = formatter.dateStyle = .medium
                        
                        Text(formatter.string(from: entry.decidedAt))
                        
                        if let price = entry.priceAtDecision {
                            Text("@")
                                .foregroundStyle(.secondary)
                            Text(price)
                        }
                        
                        if let confidence = entry.confidenceLevel {
                            Spacer()
                            Text(confidence.shortLabel)
                        }
                    }
                    .font(.subheadline)
                }
                
                // Expected target date
                if let targetDate = entry.expectedTargetDate {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Target Date")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(targetDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else if let expected = entry.expectedOutcome {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Expected Outcome (Legacy)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(expected)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Exit/Abandon details
            if let exitOrAbandon = isAbandoned
                ? researchQuestion.decisions?.first(where: { $0.actionType == .abandon })
                : exitDecision {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isAbandoned ? "Abandon Reason" : "Exit Reason")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(exitOrAbandon.rationale)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var actualResultSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(isAbandoned ? "What happened? Why did you abandon? (Required)" : "What actually happened? (Required)")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            TextEditor(text: $actualResult)
                .font(.body)
                .frame(minHeight: 100)
                .padding(4)
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.appBorder, lineWidth: 1)
                )
            
            Text(isAbandoned
                 ? "Describe why you stopped pursuing this thesis"
                 : "Describe the outcome - did the thesis play out? What changed?")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
    
    private var assessmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Assessments")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            // Thesis assessment
            VStack(alignment: .leading, spacing: 8) {
                Text("Was your thesis correct?")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 8) {
                    ForEach(ThesisAssessment.allCases) { assessment in
                        assessmentButton(
                            assessment: assessment,
                            isSelected: thesisAssessment == assessment,
                            icon: assessment.iconName,
                            label: assessment.displayName,
                            color: assessment.colorName
                        ) {
                            thesisAssessment = assessment
                        }
                    }
                }
            }
            
            // Timing assessment
            VStack(alignment: .leading, spacing: 8) {
                Text("Was your timing correct?")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 8) {
                    ForEach(TimingAssessment.allCases) { assessment in
                        assessmentButton(
                            assessment: assessment,
                            isSelected: timingAssessment == assessment,
                            icon: assessment.iconName,
                            label: assessment.displayName,
                            color: assessment.colorName
                        ) {
                            timingAssessment = assessment
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.accentColor.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func assessmentButton<T: Identifiable>(
        assessment: T,
        isSelected: Bool,
        icon: String,
        label: String,
        color: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                Text(label)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                isSelected
                    ? Color(color).opacity(0.2)
                    : Color.surface
            )
            .foregroundStyle(
                isSelected
                    ? Color(color)
                    : .primary
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isSelected ? Color(color) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private var quantitativeSection: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Actual Timeframe (Optional)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                TextField("e.g., 8 months", text: $actualTimeframe)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Exit Price (Optional)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                TextField("e.g., $185.50", text: $exitPrice)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
    
    private var reflectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reflection")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("What did you learn? (Optional but recommended)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                TextEditor(text: $lessonsLearned)
                    .font(.body)
                    .frame(minHeight: 60)
                    .padding(4)
                    .background(Color.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.appBorder, lineWidth: 1)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("What would you do differently? (Optional)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                TextField("", text: $whatWouldIDoDifferently)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .padding()
        .background(Color.purple.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var timestampSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Recorded Date")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            DatePicker(
                "",
                selection: $recordedAt,
                displayedComponents: [.date, .hourAndMinute]
            )
            .labelsHidden()
        }
    }
    
    private var validationErrorsView: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(validationErrors, id: \.self) { error in
                Label(error, systemImage: "exclamationmark.circle")
                    .foregroundStyle(Color.statusInvalidated)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color.statusInvalidated.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var footerView: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.escape, modifiers: [])
            
            Spacer()
            
            Text("Recording outcome will complete this thesis")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Button("Record Outcome") {
                save()
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .buttonStyle(.borderedProminent)
            .disabled(!isValid)
        }
        .padding()
    }
    
    // MARK: - Actions
    
    private func validate() -> Bool {
        validationErrors = []
        
        if actualResult.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors.append("Actual result description is required")
        }
        
        return validationErrors.isEmpty
    }
    
    private func save() {
        guard validate() else { return }
        
        let outcome = Outcome(
            actualResult: actualResult,
            thesisAssessment: thesisAssessment,
            timingAssessment: timingAssessment,
            recordedAt: recordedAt
        )
        
        // Set optional fields
        if !actualTimeframe.isEmpty {
            outcome.actualTimeframe = actualTimeframe
        }
        if !exitPrice.isEmpty {
            outcome.exitPrice = exitPrice
        }
        if !lessonsLearned.isEmpty {
            outcome.lessonsLearned = lessonsLearned
        }
        if !whatWouldIDoDifferently.isEmpty {
            outcome.whatWouldIDoDifferently = whatWouldIDoDifferently
        }
        
        onSave(outcome)
        dismiss()
    }
}

// MARK: - Preview

#Preview("Exited Position") {
    let rq = ResearchQuestion(
        questionText: "Is NVDA a good investment?",
        thesisStatement: "AI demand will continue to drive datacenter growth"
    )
    rq.investmentPhaseRaw = InvestmentPhase.exited.rawValue
    
    // Add a buy decision
    let buyDecision = Decision(
        actionType: .buy,
        rationale: "Drivers confirmed, valuation reasonable",
        confidenceAtDecision: 4,
        driversConfirmedCount: 3,
        driversPendingCount: 1
    )
    buyDecision.expectedTargetDate = Calendar.current.date(byAdding: .month, value: 9, to: Date())
    buyDecision.priceAtDecision = "$125.00"
    rq.decisions = [buyDecision]
    
    return OutcomeFormView(researchQuestion: rq) { _ in }
}

#Preview("Abandoned Thesis") {
    let rq = ResearchQuestion(
        questionText: "Is NVDA a good investment?",
        thesisStatement: "AI demand will continue to drive datacenter growth"
    )
    rq.investmentPhaseRaw = InvestmentPhase.abandoned.rawValue
    
    return OutcomeFormView(researchQuestion: rq) { _ in }
}

