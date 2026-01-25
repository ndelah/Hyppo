/**
 DriverOutlineView provides a collapsible outline editor for a 2-level Driver hierarchy.
 
 Features:
 - Add/edit/delete drivers and sub-drivers inline
 - Drag-and-drop reordering for top-level drivers
 - Expand/collapse controls for sub-drivers
 - Research plan details (validation question, data sources, thresholds)
 
 Used within the Research Wizard and Research Question forms.
 */

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Driver Outline View

struct DriverOutlineView: View {
    @Binding var drivers: [DriverDTO]
    let prompt: String
    
    /// Currently dragged driver ID for visual feedback
    @State private var draggedDriverId: UUID?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(prompt)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 4) {
                ForEach(Array(drivers.enumerated()), id: \.element.id) { index, driver in
                    VStack(spacing: 0) {
                        // Main driver row with drag support
                        DriverRowView(
                            driver: Binding(
                                get: { drivers[index] },
                                set: { drivers[index] = $0 }
                            ),
                            onDelete: { drivers.remove(at: index) },
                            onAddSubDriver: {
                                drivers[index].subDrivers.append(DriverDTO(title: "", isSubDriver: true))
                                drivers[index].isExpanded = true
                            },
                            onMoveUp: index > 0 ? { moveDriver(from: index, to: index - 1) } : nil,
                            onMoveDown: index < drivers.count - 1 ? { moveDriver(from: index, to: index + 1) } : nil
                        )
                        .opacity(draggedDriverId == driver.id ? 0.5 : 1.0)
                        .draggable(driver.id.uuidString) {
                            // Drag preview
                            HStack(spacing: 8) {
                                Image(systemName: "line.3.horizontal")
                                    .foregroundStyle(.secondary)
                                Text(driver.title.isEmpty ? "Assumption \(index + 1)" : driver.title)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow(radius: 4)
                            .onAppear { draggedDriverId = driver.id }
                        }
                        .dropDestination(for: String.self) { items, _ in
                            guard let droppedIdString = items.first,
                                  let droppedId = UUID(uuidString: droppedIdString),
                                  let fromIndex = drivers.firstIndex(where: { $0.id == droppedId }),
                                  fromIndex != index else {
                                return false
                            }
                            moveDriver(from: fromIndex, to: index)
                            return true
                        } isTargeted: { isTargeted in
                            // Visual feedback handled by opacity
                        }
                        
                        // Sub-drivers
                        if driver.isExpanded {
                            ForEach(Array(drivers[index].subDrivers.enumerated()), id: \.element.id) { subIndex, subDriver in
                                DriverRowView(
                                    driver: Binding(
                                        get: { drivers[index].subDrivers[subIndex] },
                                        set: { drivers[index].subDrivers[subIndex] = $0 }
                                    ),
                                    onDelete: { drivers[index].subDrivers.remove(at: subIndex) },
                                    onAddSubDriver: nil,
                                    onMoveUp: subIndex > 0 ? { moveSubDriver(parentIndex: index, from: subIndex, to: subIndex - 1) } : nil,
                                    onMoveDown: subIndex < drivers[index].subDrivers.count - 1 ? { moveSubDriver(parentIndex: index, from: subIndex, to: subIndex + 1) } : nil,
                                    isSubDriver: true
                                )
                                .padding(.leading, 24)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                    }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: drivers.map { $0.id })
            .onDrop(of: [.text], isTargeted: nil) { _ in
                draggedDriverId = nil
                return false
            }
            
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    drivers.append(DriverDTO(title: ""))
                }
            } label: {
                Label("Add Assumption", systemImage: "plus.circle")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.blue)
            .padding(.top, 4)
        }
    }
    
    // MARK: - Reordering Actions
    
    private func moveDriver(from source: Int, to destination: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            let driver = drivers.remove(at: source)
            drivers.insert(driver, at: destination)
            draggedDriverId = nil
        }
    }
    
    private func moveSubDriver(parentIndex: Int, from source: Int, to destination: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            let subDriver = drivers[parentIndex].subDrivers.remove(at: source)
            drivers[parentIndex].subDrivers.insert(subDriver, at: destination)
        }
    }
}

// MARK: - Driver DTO

/**
 Data Transfer Object for Driver to simplify form state management.
 Supports 2-level hierarchy with sub-drivers.
 */
struct DriverDTO: Identifiable, Equatable {
    let id: UUID
    var title: String
    var description: String = ""
    var validationQuestion: String = ""
    var dataSources: [String] = []
    var proofThreshold: String = ""
    var subDrivers: [DriverDTO] = []
    var isExpanded: Bool = false
    var isSubDriver: Bool = false
    var showDetails: Bool = false
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        validationQuestion: String = "",
        dataSources: [String] = [],
        proofThreshold: String = "",
        subDrivers: [DriverDTO] = [],
        isExpanded: Bool = false,
        isSubDriver: Bool = false,
        showDetails: Bool = false
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.validationQuestion = validationQuestion
        self.dataSources = dataSources
        self.proofThreshold = proofThreshold
        self.subDrivers = subDrivers
        self.isExpanded = isExpanded
        self.isSubDriver = isSubDriver
        self.showDetails = showDetails
    }
    
    static func == (lhs: DriverDTO, rhs: DriverDTO) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Driver Row View

struct DriverRowView: View {
    @Binding var driver: DriverDTO
    let onDelete: () -> Void
    let onAddSubDriver: (() -> Void)?
    var onMoveUp: (() -> Void)?
    var onMoveDown: (() -> Void)?
    var isSubDriver: Bool = false
    
    @State private var isHovering = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                // Expand/collapse or sub-driver indicator
                if !isSubDriver {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            driver.isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .rotationEffect(.degrees(driver.isExpanded ? 90 : 0))
                            .foregroundStyle(.secondary)
                            .frame(width: 12)
                    }
                    .buttonStyle(.plain)
                    .opacity(driver.subDrivers.isEmpty ? 0.3 : 1.0)
                } else {
                    Image(systemName: "arrow.turn.down.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.leading, 4)
                }
                
                // Drag handle (visible on hover for non-sub-drivers)
                if !isSubDriver {
                    Image(systemName: "line.3.horizontal")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .opacity(isHovering ? 1.0 : 0.0)
                        .frame(width: 16)
                }
                
                // Title field
                TextField(isSubDriver ? "Sub-assumption..." : "Main assumption...", text: $driver.title)
                    .textFieldStyle(.roundedBorder)
                
                // Research plan button
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        driver.showDetails.toggle()
                    }
                } label: {
                    Image(systemName: "doc.text.magnifyingglass")
                        .foregroundStyle(driver.showDetails ? .blue : .secondary)
                }
                .buttonStyle(.plain)
                .help("Edit Research Plan")
                
                // Move up/down buttons (visible on hover)
                if isHovering {
                    HStack(spacing: 2) {
                        if let onMoveUp = onMoveUp {
                            Button {
                                onMoveUp()
                            } label: {
                                Image(systemName: "chevron.up")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("Move up")
                        }
                        
                        if let onMoveDown = onMoveDown {
                            Button {
                                onMoveDown()
                            } label: {
                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("Move down")
                        }
                    }
                    .frame(width: 32)
                }
                
                // Add sub-driver button
                if let onAddSubDriver = onAddSubDriver {
                    Button {
                        onAddSubDriver()
                    } label: {
                        Image(systemName: "plus.square.dashed")
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                    .help("Add Sub-assumption")
                }
                
                // Delete button
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        onDelete()
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 4)
            .onHover { hovering in
                isHovering = hovering
            }
            
            // Research plan details
            if driver.showDetails {
                researchPlanDetails
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    private var researchPlanDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Validation Question
            VStack(alignment: .leading, spacing: 4) {
                Text("Validation Question")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                TextField("What question validates this assumption?", text: $driver.validationQuestion)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Proof Threshold
            VStack(alignment: .leading, spacing: 4) {
                Text("Proof Threshold")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                TextField("What data would prove this true/false?", text: $driver.proofThreshold)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Data Sources
            VStack(alignment: .leading, spacing: 4) {
                Text("Data Sources")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                SourceTypePicker(selectedSources: $driver.dataSources)
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.top, 8)
        .padding(.leading, isSubDriver ? 24 : 20)
    }
}

// MARK: - Source Type Picker

struct SourceTypePicker: View {
    @Binding var selectedSources: [String]
    
    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(SourceType.allCases) { type in
                Toggle(isOn: Binding(
                    get: { selectedSources.contains(type.rawValue) },
                    set: { isOn in
                        if isOn {
                            selectedSources.append(type.rawValue)
                        } else {
                            selectedSources.removeAll { $0 == type.rawValue }
                        }
                    }
                )) {
                    Label(type.displayName, systemImage: type.iconName)
                        .font(.caption2)
                }
                .toggleStyle(.button)
            }
        }
    }
}

// MARK: - Preview

#Preview("Driver Outline") {
    struct PreviewWrapper: View {
        @State private var drivers: [DriverDTO] = [
            DriverDTO(title: "AI demand continues growing", subDrivers: [
                DriverDTO(title: "Training compute demand", isSubDriver: true),
                DriverDTO(title: "Inference workloads expand", isSubDriver: true)
            ]),
            DriverDTO(title: "NVIDIA maintains hardware lead"),
            DriverDTO(title: "Software moat (CUDA) defensible")
        ]
        
        var body: some View {
            DriverOutlineView(
                drivers: $drivers,
                prompt: "What assumptions must be true?"
            )
            .padding()
            .frame(width: 500)
        }
    }
    
    return PreviewWrapper()
}
