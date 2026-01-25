/**
 ResearchWizardView provides a guided 3-step wizard for creating research questions
 following the McKinsey Mind framework.
 
 Steps:
 1. Frame the Problem - Define question, hypothesis, and core assumptions (2+ required)
 2. Design the Analysis - Add validation questions, data sources, thresholds, and kill criteria
 3. Review & Save - Confirm the structured research plan before saving
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
    @State private var questionText: String = ""
    @State private var thesisStatement: String = ""
    @State private var drivers: [DriverDTO] = [
        DriverDTO(title: ""),
        DriverDTO(title: "")
    ]
    
    // Step 2: Design the Analysis
    @State private var killCriteria: [KillCriteriaDTO] = [
        KillCriteriaDTO(condition: "")
    ]
    @State private var selectedDriverIndex: Int = 0
    
    // MARK: - Initialization
    
    init(asset: Asset, existingQuestion: ResearchQuestion? = nil, onSave: @escaping (ResearchQuestion) -> Void) {
        self.asset = asset
        self.existingQuestion = existingQuestion
        self.onSave = onSave
        
        // Pre-populate if editing
        if let question = existingQuestion {
            _questionText = State(initialValue: question.questionText)
            _thesisStatement = State(initialValue: question.thesisStatement ?? "")
            
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
            if dtos.count >= 2 {
                _drivers = State(initialValue: dtos)
            }
            
            let kcDtos = (question.killCriteria ?? []).map { KillCriteriaDTO(condition: $0.condition, threshold: $0.threshold ?? "", dataSource: $0.dataSource ?? "") }
            if !kcDtos.isEmpty {
                _killCriteria = State(initialValue: kcDtos)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isStep1Valid: Bool {
        let trimmedQuestion = questionText.trimmingCharacters(in: .whitespacesAndNewlines)
        let validDrivers = drivers.filter { !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return !trimmedQuestion.isEmpty && validDrivers.count >= 2
    }
    
    private var isStep2Valid: Bool {
        let validKillCriteria = killCriteria.filter { !$0.condition.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return validKillCriteria.count >= 1
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
                    case 2: designStep
                    case 3: reviewStep
                    default: EmptyView()
                    }
                }
                .padding(32)
            }
            
            Divider()
            
            // Footer
            footerView
        }
        .frame(width: 750, height: 650)
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
                
                Text("Step \(currentStep) of 3")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Step Indicators
            HStack(spacing: 0) {
                stepIndicator(step: 1, title: "Frame", icon: "lightbulb")
                stepConnector(completed: currentStep > 1)
                stepIndicator(step: 2, title: "Design", icon: "hammer")
                stepConnector(completed: currentStep > 2)
                stepIndicator(step: 3, title: "Review", icon: "checkmark.circle")
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
                
                Text("Define the core research question, your hypothesis, and the key assumptions that must be true.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Research Question
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Research Question")
                        .font(.headline)
                    Text("*")
                        .foregroundStyle(.red)
                }
                
                TextField("e.g., Can NVIDIA maintain 80%+ data center GPU market share through 2027?", text: $questionText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(2...4)
            }
            
            // Thesis Statement
            VStack(alignment: .leading, spacing: 8) {
                Text("Hypothesis (Thesis Statement)")
                    .font(.headline)
                
                Text("What must be true for this investment to work?")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                TextEditor(text: $thesisStatement)
                    .frame(minHeight: 80, maxHeight: 120)
                    .padding(8)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(nsColor: .separatorColor)))
            }
            
            // Key Assumptions (Drivers)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Key Assumptions")
                        .font(.headline)
                    Text("*")
                        .foregroundStyle(.red)
                    Text("(minimum 2)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                DriverOutlineView(
                    drivers: $drivers,
                    prompt: "What assumptions must be true for this hypothesis to hold?"
                )
                
                // Validation hint
                let validCount = validDriversForDesign.count
                if validCount < 2 {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Add at least \(2 - validCount) more assumption\(validCount == 1 ? "" : "s") to proceed.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("\(validCount) assumptions defined")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }
            }
        }
    }
    
    // MARK: - Step 2: Design the Analysis
    
    private var designStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "2.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                    Text("Design the Analysis")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Text("Define how you'll validate each assumption and what would prove you wrong.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Research Plan per Driver
            VStack(alignment: .leading, spacing: 16) {
                Text("Research Plan by Assumption")
                    .font(.headline)
                
                if validDriversForDesign.isEmpty {
                    Text("No assumptions defined yet.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } else {
                    // Driver selector tabs
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(validDriversForDesign.enumerated()), id: \.element.id) { index, driver in
                                Button {
                                    selectedDriverIndex = index
                                } label: {
                                    Text(driver.title.isEmpty ? "Assumption \(index + 1)" : driver.title)
                                        .font(.caption)
                                        .lineLimit(1)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedDriverIndex == index ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
                                        .foregroundStyle(selectedDriverIndex == index ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Selected driver details
                    if selectedDriverIndex < validDriversForDesign.count {
                        let driverIndex = drivers.firstIndex(where: { $0.id == validDriversForDesign[selectedDriverIndex].id })!
                        
                        VStack(alignment: .leading, spacing: 16) {
                            // Validation Question
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Validation Question")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("What specific question needs to be answered?")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                TextField("e.g., What is the YoY growth rate of AI training compute demand?", text: $drivers[driverIndex].validationQuestion)
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
                                SourceTypePicker(selectedSources: $drivers[driverIndex].dataSources)
                            }
                            
                            // Proof Threshold
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Proof Threshold")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("What specific data would validate or invalidate this assumption?")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                TextField("e.g., Revenue growth > 20% YoY validates; < 10% invalidates", text: $drivers[driverIndex].proofThreshold)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                        .padding()
                        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            
            Divider()
            
            // Kill Criteria
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Kill Criteria")
                        .font(.headline)
                    Text("*")
                        .foregroundStyle(.red)
                    Text("(minimum 1)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text("Define upfront what would prove you wrong and force an exit.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                VStack(spacing: 12) {
                    ForEach(killCriteria.indices, id: \.self) { index in
                        killCriteriaRow(index: index)
                    }
                }
                
                Button {
                    killCriteria.append(KillCriteriaDTO(condition: ""))
                } label: {
                    Label("Add Kill Criteria", systemImage: "plus.circle")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
                
                // Validation hint
                let validCount = killCriteria.filter { !$0.condition.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
                if validCount < 1 {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Define at least 1 kill criteria to ensure falsifiability.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }
            }
        }
    }
    
    private func killCriteriaRow(index: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "xmark.octagon.fill")
                    .foregroundStyle(.red.opacity(0.7))
                    .frame(width: 20)
                
                TextField("e.g., If Gross Margin drops below 60%", text: $killCriteria[index].condition)
                    .textFieldStyle(.roundedBorder)
                
                Button {
                    if killCriteria.count > 1 {
                        killCriteria.remove(at: index)
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(killCriteria.count > 1 ? .red : .gray)
                }
                .buttonStyle(.plain)
                .disabled(killCriteria.count <= 1)
            }
            
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Text("Threshold:")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    TextField("60%", text: $killCriteria[index].threshold)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
                
                HStack(spacing: 4) {
                    Text("Monitor via:")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    TextField("10-Q filings", text: $killCriteria[index].dataSource)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 120)
                }
            }
            .padding(.leading, 28)
        }
        .padding(12)
        .background(Color.red.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red.opacity(0.1)))
    }
    
    // MARK: - Step 3: Review & Save
    
    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "3.circle.fill")
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
                // Question & Thesis
                VStack(alignment: .leading, spacing: 12) {
                    reviewSection(icon: "questionmark.circle.fill", title: "Research Question", color: .blue) {
                        Text(questionText)
                            .font(.subheadline)
                    }
                    
                    if !thesisStatement.isEmpty {
                        reviewSection(icon: "lightbulb.fill", title: "Hypothesis", color: .yellow) {
                            Text(thesisStatement)
                                .font(.subheadline)
                        }
                    }
                }
                
                Divider()
                
                // Assumptions
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
                
                // Kill Criteria
                let validKillCriteria = killCriteria.filter { !$0.condition.isEmpty }
                reviewSection(icon: "xmark.octagon.fill", title: "Kill Criteria (\(validKillCriteria.count))", color: .red) {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(validKillCriteria) { criteria in
                            HStack(alignment: .top, spacing: 8) {
                                Circle()
                                    .fill(Color.red.opacity(0.6))
                                    .frame(width: 6, height: 6)
                                    .padding(.top, 5)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(criteria.condition)
                                        .font(.subheadline)
                                    
                                    if !criteria.threshold.isEmpty || !criteria.dataSource.isEmpty {
                                        HStack(spacing: 8) {
                                            if !criteria.threshold.isEmpty {
                                                Text("@ \(criteria.threshold)")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            if !criteria.dataSource.isEmpty {
                                                Text("via \(criteria.dataSource)")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                }
                            }
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
                checklistItem(passed: !questionText.isEmpty, text: "Research question defined")
                checklistItem(passed: validDriversForDesign.count >= 2, text: "2+ assumptions")
                checklistItem(passed: killCriteria.filter { !$0.condition.isEmpty }.count >= 1, text: "Kill criteria set")
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
            
            if currentStep < 3 {
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
            if questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                validationMessage = "Please enter a research question."
                showValidationError = true
                return false
            }
            if validDriversForDesign.count < 2 {
                validationMessage = "Please define at least 2 key assumptions."
                showValidationError = true
                return false
            }
            return true
            
        case 2:
            let validKC = killCriteria.filter { !$0.condition.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            if validKC.isEmpty {
                validationMessage = "Please define at least 1 kill criteria to ensure your thesis is falsifiable."
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
        
        if let existing = existingQuestion {
            // Update existing
            existing.update(
                questionText: questionText,
                context: nil,
                thesisStatement: thesisStatement.isEmpty ? nil : thesisStatement,
                confidence: nil,
                priority: nil
            )
            
            // Clear existing drivers and kill criteria
            existing.drivers?.forEach { modelContext.delete($0) }
            existing.killCriteria?.forEach { modelContext.delete($0) }
            
            rq = existing
        } else {
            // Create new
            rq = ResearchQuestion(
                questionText: questionText,
                thesisStatement: thesisStatement.isEmpty ? nil : thesisStatement
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
        
        // Save kill criteria
        for kc in killCriteria {
            let trimmedCondition = kc.condition.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedCondition.isEmpty {
                let criteria = KillCriteria(
                    condition: trimmedCondition,
                    threshold: kc.threshold.isEmpty ? nil : kc.threshold,
                    dataSource: kc.dataSource.isEmpty ? nil : kc.dataSource
                )
                criteria.researchQuestion = rq
            }
        }
        
        onSave(rq)
        dismiss()
    }
}

// MARK: - Supporting Types

/**
 Data Transfer Object for Kill Criteria to simplify form state management.
 */
struct KillCriteriaDTO: Identifiable {
    let id = UUID()
    var condition: String
    var threshold: String = ""
    var dataSource: String = ""
}

// MARK: - Preview

#Preview("New Research") {
    let asset = Asset(ticker: "NVDA", name: "NVIDIA Corporation")
    return ResearchWizardView(asset: asset) { _ in }
}
