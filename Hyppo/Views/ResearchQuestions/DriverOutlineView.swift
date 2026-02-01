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
                            driver: $drivers[index],
                            onDelete: { deleteDriver(at: index) },
                            onAddSubDriver: { addSubDriver(at: index) },
                            onMoveUp: index > 0 ? { moveDriverUp(at: index) } : nil,
                            onMoveDown: index < drivers.count - 1 ? { moveDriverDown(at: index) } : nil
                        )
                        .opacity(draggedDriverId == driver.id ? 0.5 : 1.0)
                        .draggable(driver.id.uuidString) {
                            // Drag preview
                            HStack(spacing: 8) {
                                Image(systemName: "line.3.horizontal")
                                    .foregroundStyle(.secondary)
                                Text(driver.title.isEmpty ? "Assumption" : driver.title)
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
                        } isTargeted: { _ in
                            // Visual feedback handled by opacity
                        }
                        
                        // Sub-drivers (only show if expanded)
                        if drivers[index].isExpanded {
                            ForEach(Array(drivers[index].subDrivers.enumerated()), id: \.element.id) { subIndex, _ in
                                DriverRowView(
                                    driver: $drivers[index].subDrivers[subIndex],
                                    onDelete: { deleteSubDriver(parentIndex: index, subIndex: subIndex) },
                                    onAddSubDriver: nil,
                                    onMoveUp: subIndex > 0 ? { moveSubDriverUp(parentIndex: index, subIndex: subIndex) } : nil,
                                    onMoveDown: subIndex < drivers[index].subDrivers.count - 1 ? { moveSubDriverDown(parentIndex: index, subIndex: subIndex) } : nil,
                                    isSubDriver: true
                                )
                                .padding(.leading, 24)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                    }
                }
            }
            .onDrop(of: [.text], isTargeted: nil) { _ in
                draggedDriverId = nil
                return false
            }
            
            Button {
                drivers.append(DriverDTO(title: ""))
            } label: {
                Label("Add Assumption", systemImage: "plus.circle")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.blue)
            .padding(.top, 4)
        }
    }
    
    // MARK: - Actions
    
    private func deleteDriver(at index: Int) {
        guard index < drivers.count else { return }
        _ = withAnimation(.easeInOut(duration: 0.2)) {
            drivers.remove(at: index)
        }
    }
    
    private func deleteSubDriver(parentIndex: Int, subIndex: Int) {
        guard parentIndex < drivers.count,
              subIndex < drivers[parentIndex].subDrivers.count else { return }
        _ = withAnimation(.easeInOut(duration: 0.2)) {
            drivers[parentIndex].subDrivers.remove(at: subIndex)
        }
    }
    
    private func addSubDriver(at parentIndex: Int) {
        guard parentIndex < drivers.count else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            drivers[parentIndex].subDrivers.append(DriverDTO(title: "", isSubDriver: true))
            drivers[parentIndex].isExpanded = true
        }
    }
    
    private func moveDriverUp(at index: Int) {
        guard index > 0, index < drivers.count else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            drivers.swapAt(index, index - 1)
        }
    }
    
    private func moveDriverDown(at index: Int) {
        guard index < drivers.count - 1 else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            drivers.swapAt(index, index + 1)
        }
    }
    
    private func moveSubDriverUp(parentIndex: Int, subIndex: Int) {
        guard parentIndex < drivers.count,
              subIndex > 0,
              subIndex < drivers[parentIndex].subDrivers.count else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            drivers[parentIndex].subDrivers.swapAt(subIndex, subIndex - 1)
        }
    }
    
    private func moveSubDriverDown(parentIndex: Int, subIndex: Int) {
        guard parentIndex < drivers.count,
              subIndex < drivers[parentIndex].subDrivers.count - 1 else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            drivers[parentIndex].subDrivers.swapAt(subIndex, subIndex + 1)
        }
    }
    
    private func moveDriver(from source: Int, to destination: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            let driver = drivers.remove(at: source)
            drivers.insert(driver, at: destination)
            draggedDriverId = nil
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
                        driver.isExpanded.toggle()
                    } label: {
                        Image(systemName: "chevron.right")
                            .rotationEffect(.degrees(driver.isExpanded ? 90 : 0))
                            .foregroundStyle(.secondary)
                            .frame(width: 12)
                            .animation(.easeInOut(duration: 0.2), value: driver.isExpanded)
                    }
                    .buttonStyle(.borderless)
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
                
                // Title field - direct binding to driver.title
                TextField(isSubDriver ? "Sub-assumption..." : "Main assumption...", text: $driver.title)
                    .textFieldStyle(.roundedBorder)
                
                // Action buttons grouped tightly
                HStack(spacing: 4) {
                    // Research plan button
                    Button {
                        driver.showDetails.toggle()
                    } label: {
                        Image(systemName: "doc.text.magnifyingglass")
                            .foregroundStyle(driver.showDetails ? .blue : .secondary)
                    }
                    .buttonStyle(.borderless)
                    .help("Edit Research Plan")
                    
                    // Move up/down buttons (visible on hover, but always reserve space to prevent layout jitter)
                    HStack(spacing: 0) {
                        Button {
                            onMoveUp?()
                        } label: {
                            Image(systemName: "chevron.up")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.borderless)
                        .help("Move up")
                        .disabled(onMoveUp == nil)
                        .opacity(isHovering && onMoveUp != nil ? 1.0 : 0.0)
                        
                        Button {
                            onMoveDown?()
                        } label: {
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.borderless)
                        .help("Move down")
                        .disabled(onMoveDown == nil)
                        .opacity(isHovering && onMoveDown != nil ? 1.0 : 0.0)
                    }
                    .frame(width: 24)
                    
                    // Add sub-driver button
                    if let onAddSubDriver = onAddSubDriver {
                        Button {
                            onAddSubDriver()
                        } label: {
                            Image(systemName: "plus.square.dashed")
                                .foregroundStyle(.blue)
                        }
                        .buttonStyle(.borderless)
                        .help("Add Sub-assumption")
                    }
                    
                    // Delete button
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(.vertical, 4)
            .onHover { hovering in
                isHovering = hovering
            }
            
            // Research plan details
            if driver.showDetails {
                ResearchPlanDetailsView(driver: $driver, isSubDriver: isSubDriver)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: driver.showDetails)
    }
}

// MARK: - Research Plan Details View

/**
 Separate view for research plan details to ensure proper state observation.
 */
struct ResearchPlanDetailsView: View {
    @Binding var driver: DriverDTO
    let isSubDriver: Bool
    
    var body: some View {
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

/**
 A picker for selecting data source types with visual toggle buttons.
 */
struct SourceTypePicker: View {
    @Binding var selectedSources: [String]
    
    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(SourceType.allCases) { type in
                SourceTypeChip(
                    type: type,
                    isSelected: selectedSources.contains(type.rawValue),
                    onTap: {
                        if selectedSources.contains(type.rawValue) {
                            selectedSources.removeAll { $0 == type.rawValue }
                        } else {
                            selectedSources.append(type.rawValue)
                        }
                    }
                )
            }
        }
    }
}

/**
 Individual source type chip button.
 */
struct SourceTypeChip: View {
    let type: SourceType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Label(type.displayName, systemImage: type.iconName)
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isSelected ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? Color.accentColor : Color(nsColor: .separatorColor), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
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
