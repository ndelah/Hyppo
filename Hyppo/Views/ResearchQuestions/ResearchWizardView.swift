/**
 ResearchWizardView provides a guided 2-step wizard for creating research
 following the McKinsey Mind framework.
 
 Steps:
 1. Frame the Problem - Define investment thesis, context, and key assumptions
 2. Review & Save - Confirm the structured research plan before saving
 */

import SwiftUI
import SwiftData

struct ResearchWizardView: View {
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Properties
    
    let asset: Asset?
    let existingQuestion: ResearchQuestion?
    let onSave: (ResearchQuestion) -> Void
    
    // MARK: - State
    
    @State private var currentStep = 1
    @State private var showValidationError = false
    @State private var validationMessage = ""
    
    // Step 1: Frame the Problem
    /// Investment Thesis - the core belief being tested (maps to questionText for model compatibility)
    @State private var investmentThesis: String = ""
    /// Why This Matters - background context for the research
    @State private var whyThisMatters: String = ""
    @State private var drivers: [DriverDTO] = [
        DriverDTO(title: "")
    ]
    
    @State private var selectedDriverId: UUID?
    
    /// Confidence level for the research question (1-5 scale)
    @State private var confidence: Int? = nil
    
    // MARK: - Initialization
    
    init(asset: Asset?, existingQuestion: ResearchQuestion? = nil, onSave: @escaping (ResearchQuestion) -> Void) {
        self.asset = asset ?? existingQuestion?.asset
        self.existingQuestion = existingQuestion
        self.onSave = onSave
        
        // Pre-populate if editing
        if let question = existingQuestion {
            // Use thesisStatement if available, otherwise fall back to questionText for backwards compat
            _investmentThesis = State(initialValue: question.thesisStatement ?? question.questionText)
            _whyThisMatters = State(initialValue: question.context ?? "")
            _confidence = State(initialValue: question.confidenceCurrent)
            
            let dtos = (question.drivers ?? []).filter { $0.parentDriver == nil }.map { d in
                DriverDTO(
                    title: d.title,
                    description: d.driverDescription ?? "",
                    logic: d.logic ?? "",
                    subDrivers: (d.subDrivers ?? []).map { sd in
                        DriverDTO(
                            title: sd.title,
                            description: sd.driverDescription ?? "",
                            logic: sd.logic ?? "",
                            isSubDriver: true
                        )
                    }
                )
            }
            if !dtos.isEmpty {
                _drivers = State(initialValue: dtos)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isStep1Valid: Bool {
        let trimmedThesis = investmentThesis.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedThesis.isEmpty
    }
    
    private var validDriversForDesign: [DriverDTO] {
        drivers.filter { !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Progress
            headerView
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    switch currentStep {
                    case 1: frameStep
                    case 2: reviewStep
                    default: EmptyView()
                    }
                }
                .padding(32)
            }
            
            Divider()
            
            // Footer
            footerView
        }
        .frame(width: 750, height: 800)
        .alert("Validation Required", isPresented: $showValidationError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(validationMessage)
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Research Wizard")
                        .font(.headline)
                    if let asset = asset {
                        Text("Creating research for \(asset.ticker)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Creating new research question")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Text("Step \(currentStep) of 2")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Step Indicators
            HStack(spacing: 0) {
                stepIndicator(step: 1, title: "Frame", icon: "lightbulb")
                stepConnector(completed: currentStep > 1)
                stepIndicator(step: 2, title: "Review", icon: "checkmark.circle")
            }
        }
        .padding()
    }
    
    private func stepIndicator(step: Int, title: String, icon: String) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(step <= currentStep ? Color.accentColor : Color(nsColor: .separatorColor))
                    .frame(width: 36, height: 36)
                
                if step < currentStep {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                } else {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(step == currentStep ? .white : .secondary)
                }
            }
            
            Text(title)
                .font(.caption2)
                .fontWeight(step == currentStep ? .semibold : .regular)
                .foregroundStyle(step <= currentStep ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func stepConnector(completed: Bool) -> some View {
        Rectangle()
            .fill(completed ? Color.accentColor : Color(nsColor: .separatorColor))
            .frame(height: 2)
            .frame(maxWidth: 60)
    }
    
    // MARK: - Step 1: Frame the Problem
    
    private var frameStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "1.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                    Text("Frame the Problem")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Text("Define your investment thesis, why it matters, and the key assumptions that must be true.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Investment Thesis
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Investment Thesis")
                        .font(.headline)
                    Text("*")
                        .foregroundStyle(.red)
                }
                
                Text("What must be true for this investment to work?")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                TextEditor(text: $investmentThesis)
                    .frame(minHeight: 80, maxHeight: 120)
                    .padding(8)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(nsColor: .separatorColor)))
            }
            
            // Why This Matters
            VStack(alignment: .leading, spacing: 8) {
                Text("Why This Matters")
                    .font(.headline)
                
                Text("What makes this worth investigating? What's the background?")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                TextEditor(text: $whyThisMatters)
                    .frame(minHeight: 60, maxHeight: 100)
                    .padding(8)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(nsColor: .separatorColor)))
            }
            
            // Key Assumptions (Drivers)
            VStack(alignment: .leading, spacing: 8) {
                Text("Key Assumptions")
                    .font(.headline)
                
                DriverOutlineView(
                    drivers: $drivers,
                    prompt: "What assumptions must be true for this thesis to hold?"
                )
                
                // Status hint
                let validCount = validDriversForDesign.count
                if validCount > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("\(validCount) assumption\(validCount == 1 ? "" : "s") defined")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }
            }
            
            // Confidence Level
            VStack(alignment: .leading, spacing: 8) {
                Text("Confidence Level")
                    .font(.headline)
                
                HStack(spacing: 8) {
                    ForEach(ConfidenceLevel.allCases, id: \.rawValue) { level in
                        Button {
                            if confidence == level.rawValue {
                                confidence = nil
                            } else {
                                confidence = level.rawValue
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: (confidence ?? 0) >= level.rawValue ? "star.fill" : "star")
                                    .font(.body)
                                Text(level.displayName)
                                    .font(.caption2)
                            }
                            .frame(width: 60, height: 44)
                            .background(confidence == level.rawValue ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
                            .foregroundStyle(confidence == level.rawValue ? .white : ((confidence ?? 0) >= level.rawValue ? .orange : .primary))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    // MARK: - Step 2: Review & Save
    
    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "2.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                    Text("Review Research Plan")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Text("Confirm your structured hypothesis before starting data collection.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Summary Card
            VStack(alignment: .leading, spacing: 20) {
                // Thesis & Context
                VStack(alignment: .leading, spacing: 12) {
                    reviewSection(icon: "lightbulb.fill", title: "Investment Thesis", color: .blue) {
                        Text(investmentThesis)
                            .font(.subheadline)
                    }
                    
                    if !whyThisMatters.isEmpty {
                        reviewSection(icon: "info.circle.fill", title: "Why This Matters", color: .secondary) {
                            Text(whyThisMatters)
                                .font(.subheadline)
                        }
                    }
                }
                
                Divider()
                
                // Assumptions
                if !validDriversForDesign.isEmpty {
                    reviewSection(icon: "target", title: "Key Assumptions (\(validDriversForDesign.count))", color: .green) {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(validDriversForDesign.enumerated()), id: \.element.id) { index, driver in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(index + 1). \(driver.title)")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    // Logic if defined
                                    if !driver.logic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        Text(driver.logic)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .padding(.leading, 12)
                                    }
                                    
                                    // Sub-drivers
                                    ForEach(driver.subDrivers.filter { !$0.title.isEmpty }) { sub in
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("  → \(sub.title)")
                                                .font(.caption)
                                                .foregroundStyle(.tertiary)
                                            
                                            // Sub-driver logic if defined
                                            if !sub.logic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                                Text(sub.logic)
                                                    .font(.caption2)
                                                    .foregroundStyle(.quaternary)
                                                    .padding(.leading, 24)
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    
                    Divider()
                }
                
                // Confidence
                if let conf = confidence, let level = ConfidenceLevel(rawValue: conf) {
                    reviewSection(icon: "star.fill", title: "Confidence", color: .orange) {
                        Text(level.displayName)
                            .font(.subheadline)
                    }
                }
                
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Readiness check
            readinessChecklist
        }
    }
    
    private func reviewSection<Content: View>(icon: String, title: String, color: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.headline)
            }
            
            content()
                .padding(.leading, 28)
        }
    }
    
    /// Count of drivers that have logic defined
    private var driversWithLogicCount: Int {
        validDriversForDesign.filter { !$0.logic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }
    
    private var readinessChecklist: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Readiness Checklist")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack(spacing: 12) {
                checklistItem(passed: !investmentThesis.isEmpty, text: "Investment thesis defined")
                checklistItem(passed: !validDriversForDesign.isEmpty, text: "Assumptions added")
                checklistItem(passed: driversWithLogicCount > 0, text: "Logic defined (\(driversWithLogicCount)/\(validDriversForDesign.count))")
                checklistItem(passed: confidence != nil, text: "Confidence set")
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func checklistItem(passed: Bool, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: passed ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(passed ? .green : .secondary)
            Text(text)
                .font(.caption)
                .foregroundStyle(passed ? .primary : .secondary)
        }
    }
    
    // MARK: - Footer
    
    private var footerView: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            
            Spacer()
            
            if currentStep > 1 {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        currentStep -= 1
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
            }
            
            if currentStep < 2 {
                Button {
                    if validateCurrentStep() {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            currentStep += 1
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button {
                    save()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                        Text("Save Research Plan")
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
    
    // MARK: - Validation
    
    private func validateCurrentStep() -> Bool {
        switch currentStep {
        case 1:
            if investmentThesis.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                validationMessage = "Please enter your investment thesis."
                showValidationError = true
                return false
            }
            return true
            
        default:
            return true
        }
    }
    
    // MARK: - Save
    
    private func save() {
        let rq: ResearchQuestion
        let trimmedThesis = investmentThesis.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContext = whyThisMatters.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let existing = existingQuestion {
            // Update existing
            // Note: thesis maps to both questionText (for backwards compat/title) and thesisStatement
            existing.update(
                questionText: trimmedThesis,
                context: trimmedContext.isEmpty ? nil : trimmedContext,
                thesisStatement: trimmedThesis,
                confidence: confidence
            )
            
            // Clear existing drivers
            existing.drivers?.forEach { modelContext.delete($0) }
            
            rq = existing
        } else {
            // Create new
            // Note: thesis maps to both questionText (for backwards compat/title) and thesisStatement
            rq = ResearchQuestion(
                questionText: trimmedThesis,
                context: trimmedContext.isEmpty ? nil : trimmedContext,
                thesisStatement: trimmedThesis,
                confidence: confidence
            )
            if let asset = asset {
                rq.asset = asset
            }
        }
        
        // Save drivers and sub-drivers
        for (index, d) in drivers.enumerated() {
            let trimmedTitle = d.title.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedTitle.isEmpty {
                let trimmedLogic = d.logic.trimmingCharacters(in: .whitespacesAndNewlines)
                let driver = Driver(
                    title: trimmedTitle,
                    driverDescription: d.description.isEmpty ? nil : d.description,
                    logic: trimmedLogic.isEmpty ? nil : trimmedLogic,
                    position: index
                )
                driver.researchQuestion = rq
                
                for (subIndex, sd) in d.subDrivers.enumerated() {
                    let trimmedSubTitle = sd.title.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmedSubTitle.isEmpty {
                        let trimmedSubLogic = sd.logic.trimmingCharacters(in: .whitespacesAndNewlines)
                        let subDriver = Driver(
                            title: trimmedSubTitle,
                            driverDescription: sd.description.isEmpty ? nil : sd.description,
                            logic: trimmedSubLogic.isEmpty ? nil : trimmedSubLogic,
                            position: subIndex,
                            parentDriver: driver
                        )
                        subDriver.researchQuestion = rq
                    }
                }
            }
        }
        
        onSave(rq)
        dismiss()
    }
}

// MARK: - Preview

#Preview("New Research") {
    let asset = Asset(ticker: "NVDA", name: "NVIDIA Corporation")
    return ResearchWizardView(asset: asset) { _ in }
}
