/**
 ResearchPlanTableView displays a flat table view of the Driver hierarchy,
 mimicking a McKinsey-style work plan.
 
 Features:
 - Tabular view with columns for Assumption, Validation Question, Data Sources, Proof Threshold, Evidence
 - Inline editing of cells
 - Blind spot indicators for drivers with no evidence
 - Sub-driver indentation
 */

import SwiftUI
import SwiftData

struct ResearchPlanTableView: View {
    let drivers: [Driver]
    
    /// Track which cell is being edited
    @State private var editingCell: EditingCell?
    
    /// Temporary edit values
    @State private var editValue: String = ""
    @State private var editSources: [String] = []
    
    /// Environment for saving changes
    @Environment(\.modelContext) private var modelContext
    
    private struct EditingCell: Equatable {
        let driverId: UUID
        let field: EditField
    }
    
    private enum EditField {
        case validationQuestion
        case proofThreshold
        case dataSources
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            headerRow
            
            Divider()
            
            // Rows
            if sortedTopLevelDrivers.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(sortedTopLevelDrivers) { driver in
                            driverRow(driver, isSub: false)
                            
                            if let subs = driver.subDrivers?.sorted(by: { $0.position < $1.position }) {
                                ForEach(subs) { sub in
                                    driverRow(sub, isSub: true)
                                }
                            }
                        }
                    }
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        )
    }
    
    // MARK: - Computed Properties
    
    private var sortedTopLevelDrivers: [Driver] {
        drivers.filter { $0.parentDriver == nil }.sorted { $0.position < $1.position }
    }
    
    // MARK: - Header Row
    
    private var headerRow: some View {
        HStack(spacing: 0) {
            headerCell("Assumption", width: 180)
            headerCell("Validation Question", width: 200)
            headerCell("Data Sources", width: 140)
            headerCell("Proof Threshold", width: 160)
            headerCell("Evidence", width: 80, alignment: .center)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    private func headerCell(_ title: String, width: CGFloat, alignment: Alignment = .leading) -> some View {
        Text(title)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
            .frame(width: width, alignment: alignment)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "tablecells")
                .font(.title)
                .foregroundStyle(.tertiary)
            Text("No assumptions defined")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Add assumptions to see the research plan")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Driver Row
    
    private func driverRow(_ driver: Driver, isSub: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // Assumption column
                assumptionCell(driver, isSub: isSub)
                
                // Validation Question column (editable)
                editableTextCell(
                    value: driver.validationQuestion ?? "",
                    placeholder: "Click to add...",
                    width: 200,
                    driverId: driver.driverId,
                    field: .validationQuestion,
                    onSave: { newValue in
                        driver.validationQuestion = newValue.isEmpty ? nil : newValue
                        driver.updatedAt = Date()
                    }
                )
                
                // Data Sources column (editable)
                dataSourcesCell(driver)
                
                // Proof Threshold column (editable)
                editableTextCell(
                    value: driver.proofThreshold ?? "",
                    placeholder: "Click to add...",
                    width: 160,
                    driverId: driver.driverId,
                    field: .proofThreshold,
                    onSave: { newValue in
                        driver.proofThreshold = newValue.isEmpty ? nil : newValue
                        driver.updatedAt = Date()
                    }
                )
                
                // Evidence column
                evidenceCell(driver)
            }
            
            Divider()
        }
        .background(isSub ? Color(nsColor: .controlBackgroundColor).opacity(0.3) : Color.clear)
    }
    
    // MARK: - Cell Views
    
    private func assumptionCell(_ driver: Driver, isSub: Bool) -> some View {
        HStack(spacing: 6) {
            if isSub {
                Text("→")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            Text(driver.title)
                .font(isSub ? .caption : .subheadline)
                .fontWeight(isSub ? .regular : .medium)
                .lineLimit(2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .padding(.leading, isSub ? 16 : 0)
        .frame(width: 180, alignment: .leading)
    }
    
    private func editableTextCell(
        value: String,
        placeholder: String,
        width: CGFloat,
        driverId: UUID,
        field: EditField,
        onSave: @escaping (String) -> Void
    ) -> some View {
        let isEditing = editingCell == EditingCell(driverId: driverId, field: field)
        
        return Group {
            if isEditing {
                TextField(placeholder, text: $editValue)
                    .textFieldStyle(.plain)
                    .font(.caption)
                    .padding(4)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .onSubmit {
                        onSave(editValue)
                        editingCell = nil
                    }
                    .onExitCommand {
                        editingCell = nil
                    }
            } else {
                Text(value.isEmpty ? placeholder : value)
                    .font(.caption)
                    .foregroundStyle(value.isEmpty ? .tertiary : .secondary)
                    .lineLimit(2)
                    .onTapGesture {
                        editValue = value
                        editingCell = EditingCell(driverId: driverId, field: field)
                    }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .frame(width: width, alignment: .leading)
        .contentShape(Rectangle())
    }
    
    private func dataSourcesCell(_ driver: Driver) -> some View {
        let sources = driver.dataSources ?? []
        let isEditing = editingCell == EditingCell(driverId: driver.driverId, field: .dataSources)
        
        return Group {
            if isEditing {
                // Source picker popover
                VStack(alignment: .leading, spacing: 4) {
                    FlowLayout(spacing: 4) {
                        ForEach(SourceType.allCases) { type in
                            Toggle(isOn: Binding(
                                get: { editSources.contains(type.rawValue) },
                                set: { isOn in
                                    if isOn {
                                        editSources.append(type.rawValue)
                                    } else {
                                        editSources.removeAll { $0 == type.rawValue }
                                    }
                                }
                            )) {
                                Text(type.displayName)
                                    .font(.caption2)
                            }
                            .toggleStyle(.button)
                            .controlSize(.mini)
                        }
                    }
                    
                    HStack {
                        Spacer()
                        Button("Done") {
                            driver.dataSources = editSources.isEmpty ? nil : editSources
                            driver.updatedAt = Date()
                            editingCell = nil
                        }
                        .font(.caption)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.mini)
                    }
                }
                .padding(8)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .shadow(radius: 4)
            } else {
                Group {
                    if sources.isEmpty {
                        Text("Click to add...")
                            .foregroundStyle(.tertiary)
                    } else {
                        Text(sources.joined(separator: ", "))
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.caption)
                .lineLimit(2)
                .onTapGesture {
                    editSources = sources
                    editingCell = EditingCell(driverId: driver.driverId, field: .dataSources)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .frame(width: 140, alignment: .leading)
        .contentShape(Rectangle())
    }
    
    private func evidenceCell(_ driver: Driver) -> some View {
        HStack(spacing: 4) {
            let count = driver.directEvidenceCount
            let balance = driver.totalEvidenceBalance
            
            // Count
            Text("\(count)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(count > 0 ? .primary : .tertiary)
            
            // Balance indicator
            if count > 0 {
                Text(balance > 0 ? "+\(balance)" : "\(balance)")
                    .font(.caption2)
                    .foregroundStyle(balance > 0 ? .green : (balance < 0 ? .red : .secondary))
            }
            
            // Blind spot warning
            if driver.hasBlindSpot {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                    .help("No evidence collected (blind spot)")
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .frame(width: 80, alignment: .center)
    }
}

// MARK: - Preview

#Preview("Research Plan Table") {
    // Create sample drivers for preview
    let container = try! ModelContainer(for: Driver.self, ResearchQuestion.self, Evidence.self, configurations: .init(isStoredInMemoryOnly: true))
    
    let rq = ResearchQuestion(questionText: "Test Question")
    
    let driver1 = Driver(title: "AI demand continues growing", position: 0)
    driver1.validationQuestion = "What is the YoY growth of AI training compute?"
    driver1.dataSources = ["Earnings Call", "Industry Report"]
    driver1.proofThreshold = "> 50% YoY growth"
    driver1.researchQuestion = rq
    
    let driver2 = Driver(title: "NVIDIA maintains hardware lead", position: 1)
    driver2.researchQuestion = rq
    
    let sub1 = Driver(title: "H100 performance gap", position: 0, parentDriver: driver1)
    sub1.researchQuestion = rq
    
    container.mainContext.insert(rq)
    container.mainContext.insert(driver1)
    container.mainContext.insert(driver2)
    container.mainContext.insert(sub1)
    
    return ResearchPlanTableView(drivers: [driver1, driver2])
        .frame(height: 300)
        .padding()
        .modelContainer(container)
}
