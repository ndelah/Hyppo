/**
 DecisionFormView provides a form for recording investment decisions.
 
 The form is phase-aware and adapts its available actions based on
 the current investment phase of the research question:
 - Watching phase: Pass, Buy, Abandon
 - Entered phase: Hold, Add, Trim, Exit
 
 Fields shown depend on the selected action type.
 */

import SwiftUI
import SwiftData

/// Form for creating a new decision
struct DecisionFormView: View {
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Properties
    
    let researchQuestion: ResearchQuestion
    let onSave: (Decision) -> Void
    let onExitWithOutcome: (() -> Void)?
    
    // MARK: - State
    
    @State private var selectedAction: DecisionAction
    @State private var rationale: String = ""
    @State private var expectedTargetDate: Date? = nil
    @State private var priceAtDecision: String = ""
    @State private var exitPlan: String = ""
    @State private var whatWouldChangeMyMind: String = ""
    @State private var decidedAt: Date = Date()
    
    @State private var validationErrors: [String] = []
    @State private var showExitConfirmation: Bool = false
    
    // MARK: - Initialization
    
    init(
        researchQuestion: ResearchQuestion,
        onSave: @escaping (Decision) -> Void,
        onExitWithOutcome: (() -> Void)? = nil
    ) {
        self.researchQuestion = researchQuestion
        self.onSave = onSave
        self.onExitWithOutcome = onExitWithOutcome
        
        // Default to first valid action for current phase
        let validActions = researchQuestion.investmentPhase.validActions
        _selectedAction = State(initialValue: validActions.first ?? .pass)
    }
    
    // MARK: - Computed Properties
    
    /// Valid actions for current phase
    private var validActions: [DecisionAction] {
        researchQuestion.validDecisionActions
    }
    
    /// Whether the form is valid
    private var isValid: Bool {
        !rationale.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Title based on phase
    private var formTitle: String {
        switch researchQuestion.investmentPhase {
        case .watching:
            return "Record Decision"
        case .entered:
            return "Position Decision"
        default:
            return "Record Decision"
        }
    }
    
    /// Whether to show expectations section
    private var showExpectations: Bool {
        selectedAction == .buy || selectedAction == .add
    }
    
    /// Whether to show exit plan section
    private var showExitPlan: Bool {
        selectedAction == .buy || selectedAction == .add
    }
    
    /// Whether to show "what would change my mind" section
    private var showWhatWouldChange: Bool {
        selectedAction == .pass
    }
    
    /// Whether this is an exit/abandon action
    private var isTerminalAction: Bool {
        selectedAction == .exit || selectedAction == .abandon
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
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Form content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Research context
                    researchContextSection
                    
                    // Action picker
                    actionPickerSection
                    
                    // Rationale (always required)
                    rationaleSection
                    
                    // Action-specific fields
                    if showExpectations {
                        expectationsSection
                    }
                    
                    if showExitPlan {
                        exitPlanSection
                    }
                    
                    if showWhatWouldChange {
                        whatWouldChangeSection
                    }
                    
                    // Price at decision (optional)
                    if selectedAction == .buy || selectedAction == .add || selectedAction == .trim || selectedAction == .exit {
                        priceSection
                    }
                    
                    // Decision timestamp
                    timestampSection
                    
                    // Driver snapshot preview
                    driverSnapshotSection
                    
                    // Validation errors
                    if !validationErrors.isEmpty {
                        validationErrorsView
                    }
                    
                    // Terminal action warning
                    if isTerminalAction {
                        terminalActionWarning
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Footer with buttons
            footerView
        }
        .frame(width: 550, height: 600)
        .alert("Record Outcome", isPresented: $showExitConfirmation) {
            Button("Record Now") {
                saveAndPromptOutcome()
            }
            Button("Skip for Now", role: .cancel) {
                save()
            }
        } message: {
            Text("After exiting, you'll need to record the outcome to complete this thesis. Would you like to do that now?")
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(formTitle)
                    .font(.headline)
                
                HStack(spacing: 4) {
                    Image(systemName: researchQuestion.investmentPhase.iconName)
                        .foregroundStyle(Color(researchQuestion.investmentPhase.colorName))
                    Text(researchQuestion.investmentPhase.displayName)
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
    
    private var researchContextSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Thesis")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(researchQuestion.questionText)
                .font(.subheadline)
                .lineLimit(2)
            
            if let thesis = researchQuestion.thesisStatement, !thesis.isEmpty {
                Text(thesis)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var actionPickerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Action")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 8) {
                ForEach(validActions) { action in
                    actionButton(action)
                }
            }
        }
    }
    
    private func actionButton(_ action: DecisionAction) -> some View {
        let actionColor = Color.fromName(action.colorName)
        
        return Button {
            selectedAction = action
        } label: {
            HStack(spacing: 4) {
                Image(systemName: action.iconName)
                Text(action.displayName)
            }
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                selectedAction == action
                    ? actionColor.opacity(0.2)
                    : Color.surface
            )
            .foregroundStyle(
                selectedAction == action
                    ? actionColor
                    : .primary
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        selectedAction == action
                            ? actionColor
                            : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private var rationaleSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(rationaleLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            TextEditor(text: $rationale)
                .font(.body)
                .frame(minHeight: 80)
                .padding(4)
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.appBorder, lineWidth: 1)
                )
            
            Text(rationaleHint)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
    
    private var rationaleLabel: String {
        switch selectedAction {
        case .pass:
            return "Why are you passing? (Required)"
        case .buy:
            return "Why buy now? (Required)"
        case .add:
            return "Why add to position? (Required)"
        case .trim:
            return "Why trim position? (Required)"
        case .hold:
            return "Why hold? (Required)"
        case .exit:
            return "Why exit now? (Required)"
        case .abandon:
            return "Why abandon this thesis? (Required)"
        }
    }
    
    private var rationaleHint: String {
        switch selectedAction {
        case .pass:
            return "What conditions aren't met yet?"
        case .buy:
            return "Which drivers have been confirmed? What's the catalyst?"
        case .add:
            return "What new evidence supports increasing your position?"
        case .trim:
            return "What changed to warrant reducing exposure?"
        case .hold:
            return "What supports maintaining your current position?"
        case .exit:
            return "Did the thesis play out, or has something invalidated it?"
        case .abandon:
            return "What made you decide to stop pursuing this thesis?"
        }
    }
    
    private var expectationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Expectations")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Target date")
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
        .padding()
        .background(Color.statusActive.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var exitPlanSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Exit Plan")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if let currentExitPlan, !currentExitPlan.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current plan")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    
                    Text(currentExitPlan)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            
            TextEditor(text: $exitPlan)
                .font(.body)
                .frame(minHeight: 60)
                .padding(4)
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.appBorder, lineWidth: 1)
                )
            
            Text("Leave blank to keep the current plan. Update when commitments change.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
    
    private var whatWouldChangeSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("What would make you enter? (Optional)")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            TextField("e.g., valuation below 25x, confirmed channel checks", text: $whatWouldChangeMyMind)
                .textFieldStyle(.roundedBorder)
            
            Text("Document what would need to change for you to buy")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
    
    private var priceSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(selectedAction == .exit ? "Exit Price (Optional)" : "Price (Optional)")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            TextField("e.g., $150.25", text: $priceAtDecision)
                .textFieldStyle(.roundedBorder)
                .frame(width: 150)
        }
    }
    
    private var timestampSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Decision Date")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            DatePicker(
                "",
                selection: $decidedAt,
                displayedComponents: [.date, .hourAndMinute]
            )
            .labelsHidden()
        }
    }
    
    private var driverSnapshotSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Research Snapshot (Auto-captured)")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 16) {
                snapshotItem(
                    icon: "star.fill",
                    label: "Confidence",
                    value: researchQuestion.confidence?.shortLabel ?? "Not set",
                    color: Color.confidenceMedium
                )
                
                snapshotItem(
                    icon: "checkmark.circle.fill",
                    label: "Confirmed",
                    value: "\(researchQuestion.confirmedDriversCount)",
                    color: Color.statusActive
                )
                
                snapshotItem(
                    icon: "circle.dashed",
                    label: "Under Review",
                    value: "\(researchQuestion.pendingDriversCount)",
                    color: Color.statusArchived
                )
                
                snapshotItem(
                    icon: "xmark.circle.fill",
                    label: "Discarded",
                    value: "\(researchQuestion.discardedDriversCount)",
                    color: Color.statusInvalidated
                )
            }
        }
        .padding()
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func snapshotItem(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(value)
                .fontWeight(.medium)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
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
    
    private var terminalActionWarning: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.statusOnHold)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(selectedAction == .exit ? "Exiting Position" : "Abandoning Thesis")
                    .fontWeight(.medium)
                
                Text(selectedAction == .exit
                     ? "You'll need to record the outcome after this decision."
                     : "This will close the thesis. You'll need to record why you abandoned it.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.statusOnHold.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var footerView: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.escape, modifiers: [])
            
            Spacer()
            
            Button("Record Decision") {
                if isTerminalAction {
                    showExitConfirmation = true
                } else {
                    save()
                }
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
        
        if rationale.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors.append("Rationale is required")
        }
        
        return validationErrors.isEmpty
    }
    
    private func save() {
        guard validate() else { return }
        
        // Create decision with snapshot
        let decision = Decision.create(
            actionType: selectedAction,
            rationale: rationale,
            from: researchQuestion
        )
        
        decision.decidedAt = decidedAt
        
        // Set optional fields
        if let expectedTargetDate {
            decision.expectedTargetDate = expectedTargetDate
        }
        if !priceAtDecision.isEmpty {
            decision.priceAtDecision = priceAtDecision
        }
        if !exitPlan.isEmpty {
            decision.exitPlan = exitPlan
        }
        if !whatWouldChangeMyMind.isEmpty {
            decision.whatWouldChangeMyMind = whatWouldChangeMyMind
        }
        
        onSave(decision)
        dismiss()
    }
    
    private func saveAndPromptOutcome() {
        guard validate() else { return }
        
        // Create decision with snapshot
        let decision = Decision.create(
            actionType: selectedAction,
            rationale: rationale,
            from: researchQuestion
        )
        
        decision.decidedAt = decidedAt
        
        if !priceAtDecision.isEmpty {
            decision.priceAtDecision = priceAtDecision
        }
        
        onSave(decision)
        dismiss()
        
        // Trigger outcome form
        onExitWithOutcome?()
    }
}

// MARK: - Preview

#Preview("Watching Phase") {
    let rq = ResearchQuestion(
        questionText: "Is NVDA a good investment?",
        thesisStatement: "AI demand will continue to drive datacenter growth"
    )
    rq.confidenceCurrent = 4
    
    return DecisionFormView(researchQuestion: rq) { _ in }
}

#Preview("Entered Phase") {
    let rq = ResearchQuestion(
        questionText: "Is NVDA a good investment?",
        thesisStatement: "AI demand will continue to drive datacenter growth"
    )
    rq.investmentPhaseRaw = InvestmentPhase.entered.rawValue
    rq.confidenceCurrent = 4
    
    return DecisionFormView(researchQuestion: rq) { _ in }
}

