/**
 DriverOutlineView provides a flat, keyboard-driven outline editor for a 2-level Driver hierarchy.
 
 Features:
 - Flat vertical list - all items at same indentation level
 - Pill indicators show "Driver" vs "Sub" hierarchy (matching task view badge style)
 - Keyboard-first interaction (Todoist-style):
   - Enter: Confirm and create new driver below
   - Up/Down arrows: Navigate between drivers
   - Inline d1/d2: Type "d1" or "d2" anywhere in text, it highlights, then converts on Enter
 - Drag-and-drop reordering
 
 Used within the Research Wizard and Research Question forms.
 */

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Flat Driver Item

/**
 Represents a flattened view of the driver hierarchy for rendering.
 Maps back to the actual driver data via indices.
 */
struct FlatDriverItem: Identifiable {
    let id: UUID
    var driverIndex: Int        // Index in the drivers array
    var subDriverIndex: Int?    // nil if top-level, otherwise index in parent's subDrivers
    var depth: Int              // 0 = driver, 1 = sub-driver
    
    /// Returns true if this is a sub-driver
    var isSubDriver: Bool {
        depth > 0
    }
}

// MARK: - Driver Outline View

struct DriverOutlineView: View {
    @Binding var drivers: [DriverDTO]
    let prompt: String
    
    /// Currently dragged driver ID for visual feedback
    @State private var draggedDriverId: UUID?
    
    /// Focus state for keyboard navigation between driver fields
    @FocusState private var focusedField: DriverRowField?
    
    /// Computes a flat list of all drivers and sub-drivers for rendering
    /// All items shown at same level visually - hierarchy indicated by pill
    private var flattenedDrivers: [FlatDriverItem] {
        var result: [FlatDriverItem] = []
        for (driverIndex, driver) in drivers.enumerated() {
            // Add the top-level driver
            result.append(FlatDriverItem(
                id: driver.id,
                driverIndex: driverIndex,
                subDriverIndex: nil,
                depth: 0
            ))
            // Always show sub-drivers (flat list, no collapsing)
            for (subIndex, subDriver) in driver.subDrivers.enumerated() {
                result.append(FlatDriverItem(
                    id: subDriver.id,
                    driverIndex: driverIndex,
                    subDriverIndex: subIndex,
                    depth: 1
                ))
            }
        }
        return result
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(prompt)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 4) {
                ForEach(Array(flattenedDrivers.enumerated()), id: \.element.id) { flatIndex, item in
                    driverRow(for: item, flatIndex: flatIndex)
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
    
    // MARK: - Row Builder
    
    @ViewBuilder
    private func driverRow(for item: FlatDriverItem, flatIndex: Int) -> some View {
        let binding = driverBinding(for: item)
        
        DriverRowView(
            driver: binding,
            onDelete: { deleteItem(item) },
            onAddSubDriver: item.isSubDriver ? nil : { addSubDriver(to: item) },
            onMoveUp: canMoveUp(item) ? { moveItemUp(item) } : nil,
            onMoveDown: canMoveDown(item) ? { moveItemDown(item) } : nil,
            onSetDriverType: { shouldBeSubDriver in
                setDriverType(item: item, isSubDriver: shouldBeSubDriver)
            },
            onCreateSibling: { createSiblingBelow(item) },
            onFocusNextDriver: { focusNextItem(after: flatIndex) },
            onFocusPreviousDriver: { focusPreviousItem(before: flatIndex) },
            focusedField: $focusedField
        )
        // No indentation - all items at same level, pill indicator shows hierarchy
        .opacity(draggedDriverId == item.id ? 0.5 : 1.0)
        .modifier(DragDropModifier(
            item: item,
            isSubDriver: item.isSubDriver,
            draggedDriverId: $draggedDriverId,
            onDrop: { droppedId in
                handleDrop(droppedId: droppedId, ontoItem: item)
            }
        ))
    }
    
    /// Returns a binding to the driver for the given flat item
    private func driverBinding(for item: FlatDriverItem) -> Binding<DriverDTO> {
        if let subIndex = item.subDriverIndex {
            return $drivers[item.driverIndex].subDrivers[subIndex]
        } else {
            return $drivers[item.driverIndex]
        }
    }
    
    // MARK: - Focus Navigation
    
    /// Focus the next item's title field
    private func focusNextItem(after flatIndex: Int) {
        let items = flattenedDrivers
        let nextIndex = flatIndex + 1
        if nextIndex < items.count {
            focusedField = .title(items[nextIndex].id)
        } else {
            focusedField = nil
        }
    }
    
    /// Focus the previous item's title field (Shift+Enter navigation)
    private func focusPreviousItem(before flatIndex: Int) {
        let items = flattenedDrivers
        let prevIndex = flatIndex - 1
        if prevIndex >= 0 {
            focusedField = .title(items[prevIndex].id)
        }
    }
    
    // MARK: - Driver/SubDriver Conversion (d1/d2 inline shortcuts)
    
    /// Sets the driver type based on inline d1/d2 shortcut
    /// Simply changes the isSubDriver flag - the pill will update immediately
    private func setDriverType(item: FlatDriverItem, isSubDriver: Bool) {
        withAnimation(.easeInOut(duration: 0.15)) {
            if let subIndex = item.subDriverIndex {
                // It's currently a sub-driver
                drivers[item.driverIndex].subDrivers[subIndex].isSubDriver = isSubDriver
            } else {
                // It's a top-level driver
                drivers[item.driverIndex].isSubDriver = isSubDriver
            }
        }
    }
    
    // MARK: - Sibling Creation
    
    /// Creates a new driver as a sibling below the given item
    private func createSiblingBelow(_ item: FlatDriverItem) {
        let newDriver = DriverDTO(title: "", isSubDriver: item.isSubDriver)
        
        withAnimation(.easeInOut(duration: 0.2)) {
            if item.isSubDriver, let subIndex = item.subDriverIndex {
                // Insert after current sub-driver
                drivers[item.driverIndex].subDrivers.insert(newDriver, at: subIndex + 1)
            } else {
                // Insert after current driver (and all its sub-drivers)
                drivers.insert(newDriver, at: item.driverIndex + 1)
            }
        }
        
        // Focus the new driver's title field
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            focusedField = .title(newDriver.id)
        }
    }
    
    // MARK: - Move Actions
    
    private func canMoveUp(_ item: FlatDriverItem) -> Bool {
        if item.isSubDriver, let subIndex = item.subDriverIndex {
            return subIndex > 0
        } else {
            return item.driverIndex > 0
        }
    }
    
    private func canMoveDown(_ item: FlatDriverItem) -> Bool {
        if item.isSubDriver, let subIndex = item.subDriverIndex {
            return subIndex < drivers[item.driverIndex].subDrivers.count - 1
        } else {
            return item.driverIndex < drivers.count - 1
        }
    }
    
    private func moveItemUp(_ item: FlatDriverItem) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if item.isSubDriver, let subIndex = item.subDriverIndex {
                guard subIndex > 0 else { return }
                drivers[item.driverIndex].subDrivers.swapAt(subIndex, subIndex - 1)
            } else {
                guard item.driverIndex > 0 else { return }
                drivers.swapAt(item.driverIndex, item.driverIndex - 1)
            }
        }
    }
    
    private func moveItemDown(_ item: FlatDriverItem) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if item.isSubDriver, let subIndex = item.subDriverIndex {
                guard subIndex < drivers[item.driverIndex].subDrivers.count - 1 else { return }
                drivers[item.driverIndex].subDrivers.swapAt(subIndex, subIndex + 1)
            } else {
                guard item.driverIndex < drivers.count - 1 else { return }
                drivers.swapAt(item.driverIndex, item.driverIndex + 1)
            }
        }
    }
    
    // MARK: - Delete Actions
    
    private func deleteItem(_ item: FlatDriverItem) {
        _ = withAnimation(.easeInOut(duration: 0.2)) {
            if item.isSubDriver, let subIndex = item.subDriverIndex {
                drivers[item.driverIndex].subDrivers.remove(at: subIndex)
            } else {
                drivers.remove(at: item.driverIndex)
            }
        }
    }
    
    // MARK: - Sub-Driver Actions
    
    private func addSubDriver(to item: FlatDriverItem) {
        guard !item.isSubDriver else { return }
        
        let newSubDriver = DriverDTO(title: "", isSubDriver: true)
        withAnimation(.easeInOut(duration: 0.2)) {
            drivers[item.driverIndex].subDrivers.append(newSubDriver)
            drivers[item.driverIndex].isExpanded = true
        }
        
        // Focus the new sub-driver's title field
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            focusedField = .title(newSubDriver.id)
        }
    }
    
    // MARK: - Drag and Drop
    
    private func handleDrop(droppedId: UUID, ontoItem targetItem: FlatDriverItem) {
        // Find the dropped item
        guard let sourceItem = flattenedDrivers.first(where: { $0.id == droppedId }) else { return }
        guard sourceItem.id != targetItem.id else { return }
        
        // Only support reordering at the same level for now
        if sourceItem.isSubDriver == targetItem.isSubDriver {
            withAnimation(.easeInOut(duration: 0.2)) {
                if sourceItem.isSubDriver {
                    // Both are sub-drivers - only reorder within same parent
                    guard sourceItem.driverIndex == targetItem.driverIndex,
                          let sourceSubIndex = sourceItem.subDriverIndex,
                          let targetSubIndex = targetItem.subDriverIndex else { return }
                    
                    let driver = drivers[sourceItem.driverIndex].subDrivers.remove(at: sourceSubIndex)
                    drivers[targetItem.driverIndex].subDrivers.insert(driver, at: targetSubIndex)
                } else {
                    // Both are top-level drivers
                    let driver = drivers.remove(at: sourceItem.driverIndex)
                    drivers.insert(driver, at: targetItem.driverIndex)
                }
                draggedDriverId = nil
            }
        }
    }
}

// MARK: - Drag Drop Modifier

/// Modifier to add drag and drop support to driver rows
struct DragDropModifier: ViewModifier {
    let item: FlatDriverItem
    let isSubDriver: Bool
    @Binding var draggedDriverId: UUID?
    let onDrop: (UUID) -> Void
    
    func body(content: Content) -> some View {
        content
            .draggable(item.id.uuidString) {
                HStack(spacing: 8) {
                    Image(systemName: "line.3.horizontal")
                        .foregroundStyle(.secondary)
                    Text("Driver")
                        .lineLimit(1)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(nsColor: .windowBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(radius: 4)
                .onAppear { draggedDriverId = item.id }
            }
            .dropDestination(for: String.self) { items, _ in
                guard let droppedIdString = items.first,
                      let droppedId = UUID(uuidString: droppedIdString) else {
                    return false
                }
                onDrop(droppedId)
                return true
            } isTargeted: { _ in }
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
}

// MARK: - Driver Row View

struct DriverRowView: View {
    @Binding var driver: DriverDTO
    let onDelete: () -> Void
    let onAddSubDriver: (() -> Void)?
    var onMoveUp: (() -> Void)?
    var onMoveDown: (() -> Void)?
    
    /// Callback for changing driver type (from d1/d2 inline shortcut)
    var onSetDriverType: ((Bool) -> Void)?  // true = sub-driver, false = driver
    /// Callback for Enter - create sibling below
    var onCreateSibling: (() -> Void)?
    
    /// Callback to focus the next driver's title field (down arrow)
    var onFocusNextDriver: (() -> Void)?
    /// Callback to focus the previous driver's title field (up arrow)
    var onFocusPreviousDriver: (() -> Void)?
    
    /// Focus state binding from parent for coordinated keyboard navigation
    var focusedField: FocusState<DriverRowField?>.Binding?
    
    @State private var isHovering = false
    
    /// Detected shortcut in the text (d1 or d2)
    private var detectedShortcut: DriverShortcut? {
        DriverShortcut.detect(in: driver.title)
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Drag handle (visible on hover)
            Image(systemName: "line.3.horizontal")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .opacity(isHovering ? 1.0 : 0.0)
                .frame(width: 16)
            
            // Pill indicator for Driver vs Sub-driver (matching task view style)
            // Uses driver.isSubDriver from binding so it updates when d1/d2 is processed
            hierarchyPill
            
            // Title field with inline shortcut highlighting
            titleFieldWithHighlighting
            
            // Delete button (visible on hover)
            Button {
                onDelete()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .opacity(isHovering ? 1.0 : 0.0)
            .help("Delete")
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovering ? Color(nsColor: .quaternarySystemFill) : Color.clear)
        )
        .onHover { hovering in
            isHovering = hovering
        }
    }
    
    // MARK: - Hierarchy Pill (Task View Style)
    
    /// Pill indicator matching the task view badge style
    /// Uses driver.isSubDriver so it updates when d1/d2 shortcut is processed
    private var hierarchyPill: some View {
        HStack(spacing: 4) {
            Image(systemName: driver.isSubDriver ? "arrow.turn.down.right" : "number")
                .font(.caption2)
            Text(driver.isSubDriver ? "Sub" : "Driver")
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(driver.isSubDriver ? Color.indigo.opacity(0.12) : Color.orange.opacity(0.12))
        .foregroundStyle(driver.isSubDriver ? .indigo : .orange)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .animation(.easeInOut(duration: 0.15), value: driver.isSubDriver)
    }
    
    // MARK: - Title Field with Inline Shortcut Highlighting
    
    @ViewBuilder
    private var titleFieldWithHighlighting: some View {
        ZStack(alignment: .leading) {
            // Highlighted text overlay (shows d1/d2 with background)
            if let shortcut = detectedShortcut {
                highlightedTextView(shortcut: shortcut)
                    .allowsHitTesting(false)
            }
            
            // Actual text field (transparent text when shortcut detected to show highlight)
            if let focusBinding = focusedField {
                TextField("Assumption...", text: $driver.title)
                    .textFieldStyle(.plain)
                    .foregroundStyle(detectedShortcut != nil ? .clear : .primary)
                    .focused(focusBinding, equals: .title(driver.id))
                    .onKeyPress(.return, phases: .down) { _ in
                        // Enter: process shortcut if present, then create sibling
                        processShortcutAndSubmit()
                        return .handled
                    }
                    .onKeyPress(.downArrow, phases: .down) { _ in
                        onFocusNextDriver?()
                        return .handled
                    }
                    .onKeyPress(.upArrow, phases: .down) { _ in
                        onFocusPreviousDriver?()
                        return .handled
                    }
            } else {
                TextField("Assumption...", text: $driver.title)
                    .textFieldStyle(.plain)
            }
        }
    }
    
    /// Creates the highlighted text view showing d1/d2 with colored background
    private func highlightedTextView(shortcut: DriverShortcut) -> some View {
        HStack(spacing: 0) {
            // Text before the shortcut
            if !shortcut.textBefore.isEmpty {
                Text(shortcut.textBefore)
            }
            
            // The shortcut itself with highlight
            Text(shortcut.shortcutText)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(shortcut.isSubDriver ? Color.indigo.opacity(0.25) : Color.orange.opacity(0.25))
                .foregroundStyle(shortcut.isSubDriver ? .indigo : .orange)
                .clipShape(RoundedRectangle(cornerRadius: 3))
            
            // Text after the shortcut
            if !shortcut.textAfter.isEmpty {
                Text(shortcut.textAfter)
            }
        }
        .font(.body)
    }
    
    /// Process any detected shortcut and submit the driver
    private func processShortcutAndSubmit() {
        if let shortcut = detectedShortcut {
            // Remove the shortcut from the title first
            driver.title = shortcut.cleanedText
            // Set the driver type based on shortcut (d1 = Driver, d2 = Sub-driver)
            // This directly changes the current item's type - the pill will update
            onSetDriverType?(shortcut.isSubDriver)
        }
        // Create sibling below
        onCreateSibling?()
    }
}

// MARK: - Driver Shortcut Detection

/// Represents a detected d1/d2 shortcut in text
struct DriverShortcut {
    let shortcutText: String      // "d1" or "d2"
    let isSubDriver: Bool         // true for d2, false for d1
    let range: Range<String.Index>
    let textBefore: String
    let textAfter: String
    
    /// The text with the shortcut removed
    var cleanedText: String {
        (textBefore + textAfter).trimmingCharacters(in: .whitespaces)
    }
    
    /// Detects d1 or d2 in the given text (case insensitive)
    static func detect(in text: String) -> DriverShortcut? {
        let lowercased = text.lowercased()
        
        // Look for d1 or d2 (with word boundaries - space or start/end)
        for pattern in ["d1", "d2"] {
            if let range = lowercased.range(of: pattern) {
                // Check if it's at a word boundary (space before or start of string)
                let indexBefore = range.lowerBound
                let isAtStart = indexBefore == lowercased.startIndex
                let hasSpaceBefore = !isAtStart && lowercased[lowercased.index(before: indexBefore)] == " "
                
                // Check if there's space after or end of string
                let indexAfter = range.upperBound
                let isAtEnd = indexAfter == lowercased.endIndex
                let hasSpaceAfter = !isAtEnd && lowercased[indexAfter] == " "
                
                if isAtStart || hasSpaceBefore || isAtEnd || hasSpaceAfter {
                    // Convert range to original text indices
                    let originalRange = text.index(text.startIndex, offsetBy: lowercased.distance(from: lowercased.startIndex, to: range.lowerBound))..<text.index(text.startIndex, offsetBy: lowercased.distance(from: lowercased.startIndex, to: range.upperBound))
                    
                    let before = String(text[..<originalRange.lowerBound])
                    let after = String(text[originalRange.upperBound...])
                    
                    return DriverShortcut(
                        shortcutText: String(text[originalRange]),
                        isSubDriver: pattern == "d2",
                        range: originalRange,
                        textBefore: before,
                        textAfter: after
                    )
                }
            }
        }
        return nil
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
                subDrivers: [
                    DriverDTO(title: "Training compute demand", isSubDriver: true),
                    DriverDTO(title: "Inference workloads expand", isSubDriver: true)
                ]
            ),
            DriverDTO(title: "NVIDIA maintains hardware lead"),
            DriverDTO(title: "Software moat (CUDA) defensible")
        ]
        
        var body: some View {
            DriverOutlineView(
                drivers: $drivers,
                prompt: "What assumptions must be true?"
            )
            .padding()
            .frame(width: 600, height: 400)
        }
    }
    
    return PreviewWrapper()
}
