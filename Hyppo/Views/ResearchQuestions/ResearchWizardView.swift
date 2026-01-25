import SwiftUI
import SwiftData

/**
 A 5-step guided wizard for creating a research question following the McKinsey framework.
 Steps: Frame -> Design (Drivers) -> Design (Kill Criteria) -> Review
 */
struct ResearchWizardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let asset: Asset
    let onSave: (ResearchQuestion) -> Void
    
    @State private var currentStep = 1
    
    // Step 1: Frame
    @State private var questionText: String = ""
    @State private var thesisStatement: String = ""
    
    // Step 2: Design - Drivers
    @State private var drivers: [DriverDTO] = [
        DriverDTO(title: ""),
        DriverDTO(title: "")
    ]
    
    // Step 3: Design - Kill Criteria
    @State private var killCriteria: [KillCriteriaDTO] = [
        KillCriteriaDTO(condition: "")
    ]
    
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
                    case 2: driversStep
                    case 3: killCriteriaStep
                    case 4: reviewStep
                    default: EmptyView()
                    }
                }
                .padding(32)
            }
            
            Divider()
            
            // Footer
            footerView
        }
        .frame(width: 700, height: 600)
    }
    
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Research Wizard")
                    .font(.headline)
                Spacer()
                Text("Step \(currentStep) of 4")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Progress Bar
            ProgressView(value: Double(currentStep), total: 4)
                .progressViewStyle(.linear)
        }
        .padding()
    }
    
    private var frameStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("1. Frame the Problem")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Define the core question and your initial hypothesis.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Research Question")
                    .font(.headline)
                TextField("e.g., Can NVIDIA maintain its 80%+ market share in AI data centers through 2027?", text: $questionText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(2...4)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Hypothesis (Thesis Statement)")
                    .font(.headline)
                Text("What must be true for this investment to work?")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $thesisStatement)
                    .frame(height: 100)
                    .padding(4)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(nsColor: .separatorColor)))
            }
        }
    }
    
    private var driversStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("2. Design the Analysis: Assumptions")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Identify the key drivers that support your hypothesis.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            DriverOutlineView(
                drivers: $drivers,
                prompt: "What assumptions must be true for the hypothesis to hold?"
            )
            
            if drivers.count < 2 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("McKinsey recommends at least 2-3 core assumptions.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
        }
    }
    
    private var killCriteriaStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("3. Design the Analysis: Kill Criteria")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Define upfront what would prove you wrong.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("What specific data would force you to exit?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                ForEach(killCriteria.indices, id: \.self) { index in
                    HStack {
                        TextField("e.g., If Gross Margin drops below 60%", text: $killCriteria[index].condition)
                            .textFieldStyle(.roundedBorder)
                        
                        Button {
                            killCriteria.remove(at: index)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
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
            }
            
            if killCriteria.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Defining at least one kill criteria ensures falsifiability.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
        }
    }
    
    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("4. Review Research Plan")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Confirm your structured hypothesis before starting data collection.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                ReviewItemView(label: "Question", value: questionText)
                ReviewItemView(label: "Hypothesis", value: thesisStatement)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Assumptions")
                        .font(.headline)
                    ForEach(drivers) { driver in
                        Text("• \(driver.title)")
                            .font(.subheadline)
                        ForEach(driver.subDrivers) { sub in
                            Text("  - \(sub.title)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Kill Criteria")
                        .font(.headline)
                    ForEach(killCriteria) { criteria in
                        Text("• \(criteria.condition)")
                            .font(.subheadline)
                    }
                }
            }
        }
    }
    
    private var footerView: some View {
        HStack {
            Button("Cancel") { dismiss() }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            if currentStep > 1 {
                Button("Back") { currentStep -= 1 }
            }
            
            if currentStep < 4 {
                Button("Next") { currentStep += 1 }
                    .buttonStyle(.borderedProminent)
                    .disabled(currentStep == 1 && questionText.isEmpty)
            } else {
                Button("Save Research Plan") { save() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
    
    private func save() {
        let rq = ResearchQuestion(
            questionText: questionText,
            thesisStatement: thesisStatement
        )
        rq.asset = asset
        
        // Save drivers and sub-drivers
        for (index, d) in drivers.enumerated() {
            if !d.title.isEmpty {
                let driver = Driver(
                    title: d.title,
                    position: index,
                    validationQuestion: d.validationQuestion,
                    dataSources: d.dataSources,
                    proofThreshold: d.proofThreshold
                )
                driver.researchQuestion = rq
                
                for (subIndex, sd) in d.subDrivers.enumerated() {
                    if !sd.title.isEmpty {
                        let subDriver = Driver(
                            title: sd.title,
                            position: subIndex,
                            validationQuestion: sd.validationQuestion,
                            dataSources: sd.dataSources,
                            proofThreshold: sd.proofThreshold,
                            parentDriver: driver
                        )
                        subDriver.researchQuestion = rq
                    }
                }
            }
        }
        
        // Save kill criteria
        for kc in killCriteria {
            if !kc.condition.isEmpty {
                let criteria = KillCriteria(
                    condition: kc.condition
                )
                criteria.researchQuestion = rq
            }
        }
        
        onSave(rq)
        dismiss()
    }
}

struct KillCriteriaDTO: Identifiable {
    let id = UUID()
    var condition: String
}

struct ReviewItemView: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.headline)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

