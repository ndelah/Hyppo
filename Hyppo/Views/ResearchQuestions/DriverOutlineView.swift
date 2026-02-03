/**
 DriverOutlineView provides a collapsible outline editor for a 2-level Driver hierarchy.
 
 Features:
 - Add/edit/delete drivers and sub-drivers inline
 - Drag-and-drop reordering for top-level drivers
 - Expand/collapse controls for sub-drivers
 
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
    
    /// Focus state for keyboard navigation between driver fields
    @FocusState private var focusedField: DriverRowField?
    
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
                            onMoveDown: index < drivers.count - 1 ? { moveDriverDown(at: index) } : nil,
                            onFocusNextDriver: { focusNextDriver(after: index) },
                            onFocusPreviousDriver: { focusPreviousDriver(before: index) },
                            focusedField: $focusedField
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
                            .background(Color(nsColor: .windowBackgroundColor))
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
                        
                        // Sub-drivers (only show if parent is expanded for sub-drivers)
                        if drivers[index].isExpanded {
                            ForEach(Array(drivers[index].subDrivers.enumerated()), id: \.element.id) { subIndex, subDriver in
                                DriverRowView(
                                    driver: $drivers[index].subDrivers[subIndex],
                                    onDelete: { deleteSubDriver(parentIndex: index, subIndex: subIndex) },
                                    onAddSubDriver: nil,
                                    onMoveUp: subIndex > 0 ? { moveSubDriverUp(parentIndex: index, subIndex: subIndex) } : nil,
                                    onMoveDown: subIndex < drivers[index].subDrivers.count - 1 ? { moveSubDriverDown(parentIndex: index, subIndex: subIndex) } : nil,
                                    isSubDriver: true,
                                    onFocusNextDriver: { focusNextSubDriver(parentIndex: index, afterSubIndex: subIndex) },
                                    onFocusPreviousDriver: { focusPreviousSubDriver(parentIndex: index, beforeSubIndex: subIndex) },
                                    focusedField: $focusedField
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
                let newDriver = DriverDTO(title: "")
                drivers.append(newDriver)
                // Focus the new driver's title field
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    focusedField = .title(newDriver.id)
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
    
    // MARK: - Focus Navigation
    
    /// Focus the next driver's title field after completing the current driver's logic
    private func focusNextDriver(after index: Int) {
        let nextIndex = index + 1
        if nextIndex < drivers.count {
            focusedField = .title(drivers[nextIndex].id)
        } else {
            // No next driver, clear focus
            focusedField = nil
        }
    }
    
    /// Focus the previous driver's logic field
    private func focusPreviousDriver(before index: Int) {
        let prevIndex = index - 1
        if prevIndex >= 0 {
            focusedField = .logic(drivers[prevIndex].id)
        }
    }
    
    /// Focus the next sub-driver's title or the next main driver if no more sub-drivers
    private func focusNextSubDriver(parentIndex: Int, afterSubIndex: Int) {
        let nextSubIndex = afterSubIndex + 1
        if nextSubIndex < drivers[parentIndex].subDrivers.count {
            focusedField = .title(drivers[parentIndex].subDrivers[nextSubIndex].id)
        } else {
            // Move to next main driver
            focusNextDriver(after: parentIndex)
        }
    }
    
    /// Focus the previous sub-driver's logic or the parent driver's logic
    private func focusPreviousSubDriver(parentIndex: Int, beforeSubIndex: Int) {
        let prevSubIndex = beforeSubIndex - 1
        if prevSubIndex >= 0 {
            focusedField = .logic(drivers[parentIndex].subDrivers[prevSubIndex].id)
        } else {
            // Move to parent driver's logic
            focusedField = .logic(drivers[parentIndex].id)
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
    var logic: String = ""
    var subDrivers: [DriverDTO] = []
    var isExpanded: Bool = false
    var isSubDriver: Bool = false
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        logic: String = "",
        subDrivers: [DriverDTO] = [],
        isExpanded: Bool = false,
        isSubDriver: Bool = false
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.logic = logic
        self.subDrivers = subDrivers
        self.isExpanded = isExpanded
        self.isSubDriver = isSubDriver
    }
}

// MARK: - Driver Row Focus Field

/// Enum to track which field is focused in a driver row
enum DriverRowField: Hashable {
    case title(UUID)
    case logic(UUID)
}

// MARK: - Driver Row View

struct DriverRowView: View {
    @Binding var driver: DriverDTO
    let onDelete: () -> Void
    let onAddSubDriver: (() -> Void)?
    var onMoveUp: (() -> Void)?
    var onMoveDown: (() -> Void)?
    var isSubDriver: Bool = false
    
    /// Callback to focus the next driver's title field (for Enter key navigation)
    var onFocusNextDriver: (() -> Void)?
    /// Callback to focus the previous driver's logic field (for Shift+Tab navigation)
    var onFocusPreviousDriver: (() -> Void)?
    
    /// Focus state binding from parent for coordinated keyboard navigation
    var focusedField: FocusState<DriverRowField?>.Binding?
    
    @State private var isHovering = false
    @State private var isLogicExpanded = false
    
    /// Whether the logic section should be visible (expanded or has content)
    private var showLogicField: Bool {
        isLogicExpanded || !driver.logic.isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main row with title
            HStack(spacing: 8) {
                // Expand/collapse for logic field
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isLogicExpanded.toggle()
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(showLogicField ? 90 : 0))
                        .foregroundStyle(.secondary)
                        .frame(width: 12)
                        .animation(.easeInOut(duration: 0.2), value: showLogicField)
                }
                .buttonStyle(.borderless)
                .help("Expand to add logic")
                
                // Sub-driver indicator
                if isSubDriver {
                    Image(systemName: "arrow.turn.down.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                
                // Drag handle (visible on hover for non-sub-drivers)
                if !isSubDriver {
                    Image(systemName: "line.3.horizontal")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .opacity(isHovering ? 1.0 : 0.0)
                        .frame(width: 16)
                }
                
                // Title field with focus and keyboard handling
                titleField
                
                // Logic indicator when collapsed but has content
                if !showLogicField && !driver.logic.isEmpty {
                    Image(systemName: "text.alignleft")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                        .help("Has logic defined")
                }
                
                // Action buttons grouped tightly
                HStack(spacing: 4) {
                    // Move up/down buttons
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
            
            // Expandable logic field
            if showLogicField {
                logicField
                    .padding(.leading, isSubDriver ? 36 : 28)
                    .padding(.trailing, 4)
                    .padding(.bottom, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    // MARK: - Title Field
    
    @ViewBuilder
    private var titleField: some View {
        if let focusBinding = focusedField {
            TextField(isSubDriver ? "Sub-assumption..." : "Main assumption...", text: $driver.title)
                .textFieldStyle(.roundedBorder)
                .focused(focusBinding, equals: .title(driver.id))
                .onSubmit {
                    // Enter key: expand and focus logic field
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isLogicExpanded = true
                    }
                    focusBinding.wrappedValue = .logic(driver.id)
                }
        } else {
            TextField(isSubDriver ? "Sub-assumption..." : "Main assumption...", text: $driver.title)
                .textFieldStyle(.roundedBorder)
        }
    }
    
    // MARK: - Logic Field
    
    @ViewBuilder
    private var logicField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Logic")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            
            if let focusBinding = focusedField {
                TextField("Why must this be true?", text: $driver.logic, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                    .focused(focusBinding, equals: .logic(driver.id))
                    .onSubmit {
                        // Enter key: collapse and move to next driver
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isLogicExpanded = false
                        }
                        onFocusNextDriver?()
                    }
            } else {
                TextField("Why must this be true?", text: $driver.logic, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Expands the logic field and requests focus
    func expandAndFocusLogic() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isLogicExpanded = true
        }
        focusedField?.wrappedValue = .logic(driver.id)
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
                .background(isSelected ? Color.accentColor : Color(nsColor: .windowBackgroundColor))
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
            DriverDTO(
                title: "AI demand continues growing",
                logic: "Enterprise AI adoption is accelerating, with major cloud providers reporting 50%+ growth in AI workloads.",
                subDrivers: [
                    DriverDTO(title: "Training compute demand", logic: "Foundation model training requires exponentially more compute each generation.", isSubDriver: true),
                    DriverDTO(title: "Inference workloads expand", logic: "As models deploy to production, inference demand scales with users.", isSubDriver: true)
                ]
            ),
            DriverDTO(title: "NVIDIA maintains hardware lead", logic: "H100/B100 architecture provides 3x performance advantage over competitors."),
            DriverDTO(title: "Software moat (CUDA) defensible")
        ]
        
        var body: some View {
            DriverOutlineView(
                drivers: $drivers,
                prompt: "What assumptions must be true?"
            )
            .padding()
            .frame(width: 600, height: 500)
        }
    }
    
    return PreviewWrapper()
}
