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
    
    let asset: Asset
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
    /// Priority level for the research question (1-5 scale)
    @State private var priority: Int? = nil
    
    // MARK: - Initialization
    
    init(asset: Asset, existingQuestion: ResearchQuestion? = nil, onSave: @escaping (ResearchQuestion) -> Void) {
        self.asset = asset
        self.existingQuestion = existingQuestion
        self.onSave = onSave
        
        // Pre-populate if editing
        if let question = existingQuestion {
            // Use thesisStatement if available, otherwise fall back to questionText for backwards compat
            _investmentThesis = State(initialValue: question.thesisStatement ?? question.questionText)
            _whyThisMatters = State(initialValue: question.context ?? "")
            _confidence = State(initialValue: question.confidenceCurrent)
            _priority = State(initialValue: question.priority)
            
            let dtos = (question.drivers ?? []).filter { $0.parentDriver == nil }.map { d in
                DriverDTO(
                    title: d.title,
                    description: d.driverDescription ?? "",
                    validationQuestion: d.validationQuestion ?? "",
                    dataSources: d.dataSources ?? [],
                    proofThreshold: d.proofThreshold ?? "",
                    subDrivers: (d.subDrivers ?? []).map { sd in
                        DriverDTO(
                            title: sd.title,
                            description: sd.driverDescription ?? "",
                            validationQuestion: sd.validationQuestion ?? "",
                            dataSources: sd.dataSources ?? [],
                            proofThreshold: sd.proofThreshold ?? "",
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
                    Text("Creating research for \(asset.ticker)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
            
            // Confidence & Priority
            HStack(spacing: 24) {
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
                
                Spacer()
                
                // Priority
                VStack(alignment: .leading, spacing: 8) {
                    Text("Priority")
                        .font(.headline)
                    
                    Picker("Priority", selection: $priority) {
                        Text("None").tag(nil as Int?)
                        ForEach(1...5, id: \.self) { level in
                            Text("\(level)/5").tag(level as Int?)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 220)
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
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(validDriversForDesign.enumerated()), id: \.element.id) { index, driver in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(index + 1). \(driver.title)")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    if !driver.validationQuestion.isEmpty {
                                        HStack(alignment: .top, spacing: 4) {
                                            Text("Q:")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            Text(driver.validationQuestion)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    
                                    if !driver.proofThreshold.isEmpty {
                                        HStack(alignment: .top, spacing: 4) {
                                            Text("Threshold:")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            Text(driver.proofThreshold)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    
                                    // Sub-drivers
                                    ForEach(driver.subDrivers.filter { !$0.title.isEmpty }) { sub in
                                        Text("  → \(sub.title)")
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    
                    Divider()
                }
                
                // Confidence & Priority
                HStack(spacing: 24) {
                    if let conf = confidence, let level = ConfidenceLevel(rawValue: conf) {
                        reviewSection(icon: "star.fill", title: "Confidence", color: .orange) {
                            Text(level.displayName)
                                .font(.subheadline)
                        }
                    }
                    
                    if let pri = priority {
                        reviewSection(icon: "flag.fill", title: "Priority", color: .purple) {
                            Text("\(pri)/5")
                                .font(.subheadline)
                        }
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
    
    private var readinessChecklist: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Readiness Checklist")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack(spacing: 12) {
                checklistItem(passed: !investmentThesis.isEmpty, text: "Investment thesis defined")
                checklistItem(passed: !validDriversForDesign.isEmpty, text: "Assumptions added")
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
                confidence: confidence,
                priority: priority
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
                confidence: confidence,
                priority: priority
            )
            rq.asset = asset
        }
        
        // Save drivers and sub-drivers
        for (index, d) in drivers.enumerated() {
            let trimmedTitle = d.title.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedTitle.isEmpty {
                let driver = Driver(
                    title: trimmedTitle,
                    driverDescription: d.description.isEmpty ? nil : d.description,
                    position: index,
                    validationQuestion: d.validationQuestion.isEmpty ? nil : d.validationQuestion,
                    dataSources: d.dataSources.isEmpty ? nil : d.dataSources,
                    proofThreshold: d.proofThreshold.isEmpty ? nil : d.proofThreshold
                )
                driver.researchQuestion = rq
                
                for (subIndex, sd) in d.subDrivers.enumerated() {
                    let trimmedSubTitle = sd.title.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmedSubTitle.isEmpty {
                        let subDriver = Driver(
                            title: trimmedSubTitle,
                            driverDescription: sd.description.isEmpty ? nil : sd.description,
                            position: subIndex,
                            validationQuestion: sd.validationQuestion.isEmpty ? nil : sd.validationQuestion,
                            dataSources: sd.dataSources.isEmpty ? nil : sd.dataSources,
                            proofThreshold: sd.proofThreshold.isEmpty ? nil : sd.proofThreshold,
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

// MARK: - Supporting Types

/**
 Extracted view for editing a selected driver's research plan details.
 Using a separate view helps avoid binding/index issues with inline closures.
 */
struct SelectedDriverEditView: View {
    @Binding var driver: DriverDTO
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Validation Question
            VStack(alignment: .leading, spacing: 6) {
                Text("Validation Question")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("What specific question needs to be answered?")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                TextField("e.g., What is the YoY growth rate of AI training compute demand?", text: $driver.validationQuestion)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Data Sources
            VStack(alignment: .leading, spacing: 6) {
                Text("Data Sources")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("Where will you find the data?")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                SourceTypePicker(selectedSources: $driver.dataSources)
            }
            
            // Proof Threshold
            VStack(alignment: .leading, spacing: 6) {
                Text("Proof Threshold")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("What specific data would validate or invalidate this assumption?")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                TextField("e.g., Revenue growth > 20% YoY validates; < 10% invalidates", text: $driver.proofThreshold)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview("New Research") {
    let asset = Asset(ticker: "NVDA", name: "NVIDIA Corporation")
    return ResearchWizardView(asset: asset) { _ in }
}
