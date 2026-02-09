/**
 RecordRowView displays a single research question as a table row.
 
 Features:
 - Clickable question title to navigate to detail view
 - Inline asset picker (Notion-style popover)
 - Inline status picker
 - Inline confidence picker
 - Changes are logged automatically
 */

import SwiftUI
import SwiftData

/// Table row view for a research question record
struct RecordRowView: View {
    // MARK: - Properties
    
    let question: ResearchQuestion
    let columns: [RecordColumn]
    var columnWidths: [RecordColumn: CGFloat]?
    let isSelected: Bool
    
    /// Whether the row's checkbox is checked
    var isChecked: Bool = false
    
    /// Width of the checkbox column (should match header)
    var checkboxColumnWidth: CGFloat = 40
    
    /// Callback when the checkbox is toggled. The Bool indicates if Shift was held.
    var onToggleSelection: ((Bool) -> Void)?
    
    /// Callback when the question title is clicked (navigate to detail)
    var onQuestionTap: (() -> Void)?
    
    /// Callback when asset is changed (oldAsset, newAsset)
    var onAssetChange: ((Asset?, Asset?) -> Void)?
    
    /// Callback when status is changed (oldStatus, newStatus)
    var onStatusChange: ((ResearchQuestionStatus, ResearchQuestionStatus) -> Void)?
    
    /// Callback when confidence is changed (oldConfidence, newConfidence)
    var onConfidenceChange: ((ConfidenceLevel?, ConfidenceLevel?) -> Void)?
    
    /// Available assets for the asset picker
    var availableAssets: [Asset] = []
    
    // MARK: - Bulk Edit Properties
    
    /// Whether multiple rows are selected (enables bulk edit mode)
    var hasMultipleSelection: Bool = false
    
    /// Callback when asset cell is clicked for bulk edit (only called when hasMultipleSelection is true)
    var onBulkAssetEdit: (() -> Void)?
    
    /// Callback when status cell is clicked for bulk edit (only called when hasMultipleSelection is true)
    var onBulkStatusEdit: (() -> Void)?
    
    /// Callback when confidence cell is clicked for bulk edit (only called when hasMultipleSelection is true)
    var onBulkConfidenceEdit: (() -> Void)?
    
    // MARK: - State
    
    @State private var showingAssetPopover = false
    @State private var showingStatusPopover = false
    @State private var showingConfidencePopover = false
    
    // MARK: - Accessibility
    
    @AppStorage("textSizeMultiplier") private var textSizeMultiplier: Double = 1.0
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 0) {
            // Left margin spacer
            Spacer()
                .frame(width: 16)
            
            // Selection checkbox
            if let onToggle = onToggleSelection {
                Button {
                    // Detect if Shift is held for range selection
                    let shiftHeld = NSEvent.modifierFlags.contains(.shift)
                    onToggle(shiftHeld)
                } label: {
                    Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                        .font(.system(size: 16))
                        .foregroundStyle(isChecked ? Color.accentColor : .secondary)
                }
                .buttonStyle(.plain)
                .frame(width: checkboxColumnWidth)
                .padding(.vertical, 14)
            }
            
            ForEach(columns) { column in
                // Use responsive width if provided, otherwise fall back to minimum width
                let width = columnWidths?[column] ?? column.minWidth
                
                HStack(spacing: 0) {
                    // Add extra leading padding for left-aligned columns so text doesn't stick to divider
                    columnCell(for: column)
                        .frame(width: width - 16, alignment: column.alignment)
                        .padding(.leading, column.alignment == .leading ? 12 : 8)
                        .padding(.trailing, 8)
                        .padding(.vertical, 14)
                    
                    if column != columns.last {
                        Divider()
                            .frame(height: 28)
                    }
                }
                .frame(width: width)
            }
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipped()
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
    }
    
    // MARK: - Column Cell
    
    @ViewBuilder
    private func columnCell(for column: RecordColumn) -> some View {
        switch column {
        case .question:
            questionCell
        case .assetName:
            assetCell
        case .status:
            statusCell
        case .confidence:
            confidenceCell
        case .drivers:
            driversCell
        case .logEntries:
            logEntriesCell
        case .tags:
            tagsCell
        case .created:
            createdCell
        case .updated:
            updatedCell
        }
    }
    
    // MARK: - Question Cell (Clickable for Navigation)
    
    private var questionCell: some View {
        Button {
            onQuestionTap?()
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(question.questionText)
                    .font(.system(size: 14 * textSizeMultiplier, weight: .medium))
                    .lineLimit(2)
                    .foregroundStyle(.primary)
                
                if let context = question.context, !context.isEmpty {
                    Text(context)
                        .font(.system(size: 12 * textSizeMultiplier))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
    
    // MARK: - Asset Cell (Inline Picker / Bulk Edit)
    
    private var assetCell: some View {
        Button {
            if hasMultipleSelection {
                // Trigger bulk edit callback for all selected rows
                onBulkAssetEdit?()
            } else {
                showingAssetPopover = true
            }
        } label: {
            Group {
                if let asset = question.asset {
                    Text(asset.ticker)
                        .font(.system(size: 14 * textSizeMultiplier, weight: .semibold))
                        .foregroundStyle(Color.assetColor)
                } else {
                    Text("—")
                        .font(.system(size: 14 * textSizeMultiplier))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(hasMultipleSelection && isChecked ? Color.accentColor.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
        .popover(isPresented: $showingAssetPopover, arrowEdge: .bottom) {
            AssetPickerPopover(
                selectedAsset: question.asset,
                availableAssets: availableAssets,
                onSelect: { newAsset in
                    let oldAsset = question.asset
                    if oldAsset?.assetId != newAsset?.assetId {
                        onAssetChange?(oldAsset, newAsset)
                    }
                    showingAssetPopover = false
                }
            )
        }
    }
    
    // MARK: - Status Cell (Inline Picker / Bulk Edit)
    
    private var statusCell: some View {
        Button {
            if hasMultipleSelection {
                // Trigger bulk edit callback for all selected rows
                onBulkStatusEdit?()
            } else {
                showingStatusPopover = true
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: question.status.iconName)
                    .font(.system(size: 12 * textSizeMultiplier))
                Text(question.status.displayName)
                    .font(.system(size: 12 * textSizeMultiplier, weight: .medium))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(hasMultipleSelection && isChecked ? 0.25 : 0.15))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
        .popover(isPresented: $showingStatusPopover, arrowEdge: .bottom) {
            StatusPickerPopover(
                currentStatus: question.status,
                onSelect: { newStatus in
                    let oldStatus = question.status
                    if oldStatus != newStatus {
                        onStatusChange?(oldStatus, newStatus)
                    }
                    showingStatusPopover = false
                }
            )
        }
    }
    
    // MARK: - Confidence Cell (Inline Picker / Bulk Edit)
    
    private var confidenceCell: some View {
        Button {
            if hasMultipleSelection {
                // Trigger bulk edit callback for all selected rows
                onBulkConfidenceEdit?()
            } else {
                showingConfidencePopover = true
            }
        } label: {
            Group {
                if let confidence = question.confidence {
                    Text(confidence.shortLabel)
                        .font(.system(size: 12 * textSizeMultiplier))
                        .foregroundStyle(confidenceColor(for: confidence))
                } else {
                    Text("—")
                        .font(.system(size: 12 * textSizeMultiplier))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(hasMultipleSelection && isChecked ? Color.accentColor.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
        .popover(isPresented: $showingConfidencePopover, arrowEdge: .bottom) {
            ConfidencePickerPopover(
                currentConfidence: question.confidence,
                onSelect: { newConfidence in
                    let oldConfidence = question.confidence
                    if oldConfidence != newConfidence {
                        onConfidenceChange?(oldConfidence, newConfidence)
                    }
                    showingConfidencePopover = false
                }
            )
        }
    }
    
    // MARK: - Other Cells (Read-Only)
    
    private var driversCell: some View {
        let count = question.drivers?.count ?? 0
        return Text("\(count)")
            .font(.system(size: 14 * textSizeMultiplier))
            .foregroundStyle(count > 0 ? .primary : .tertiary)
    }
    
    private var logEntriesCell: some View {
        let count = question.logEntriesCount
        return Text("\(count)")
            .font(.system(size: 14 * textSizeMultiplier))
            .foregroundStyle(count > 0 ? .primary : .tertiary)
    }
    
    private var tagsCell: some View {
        Group {
            if let tags = question.tags, !tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(tags.prefix(3)) { tag in
                        TagPill(tag: tag)
                    }
                    if tags.count > 3 {
                        Text("+\(tags.count - 3)")
                            .font(.system(size: 12 * textSizeMultiplier))
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("\(tags.count - 3) more tags")
                    }
                }
            } else {
                Text("—")
                    .font(.system(size: 12 * textSizeMultiplier))
                    .foregroundStyle(.tertiary)
                    .accessibilityLabel("No tags")
            }
        }
    }
    
    private var createdCell: some View {
        Text(question.createdAt.formatted(date: .abbreviated, time: .omitted))
            .font(.system(size: 12 * textSizeMultiplier))
            .foregroundStyle(.secondary)
    }
    
    private var updatedCell: some View {
        Text(question.updatedAt.formatted(date: .abbreviated, time: .omitted))
            .font(.system(size: 12 * textSizeMultiplier))
            .foregroundStyle(.secondary)
    }
    
    // MARK: - Helpers
    
    private var statusColor: Color {
        Color.forStatus(question.status)
    }
    
    private func confidenceColor(for confidence: ConfidenceLevel) -> Color {
        Color.forConfidence(confidence)
    }
    
}

// MARK: - Asset Picker Popover

/// Notion-style asset picker popover
private struct AssetPickerPopover: View {
    let selectedAsset: Asset?
    let availableAssets: [Asset]
    let onSelect: (Asset?) -> Void
    
    @State private var searchText = ""
    
    private var filteredAssets: [Asset] {
        if searchText.isEmpty {
            return availableAssets
        }
        return availableAssets.filter { asset in
            asset.ticker.localizedCaseInsensitiveContains(searchText) ||
            asset.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search assets...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(10)
            
            Divider()
            
            // Asset list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    // "None" option
                    Button {
                        onSelect(nil)
                    } label: {
                        HStack {
                            Text("None")
                                .foregroundStyle(.secondary)
                            Spacer()
                            if selectedAsset == nil {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .background(Color.surface.opacity(0.5))
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    ForEach(filteredAssets) { asset in
                        Button {
                            onSelect(asset)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(asset.ticker)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color.assetColor)
                                    Text(asset.name)
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                if selectedAsset?.assetId == asset.assetId {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxHeight: 250)
        }
        .frame(width: 220)
    }
}

// MARK: - Status Picker Popover

/// Status picker popover with all available statuses
private struct StatusPickerPopover: View {
    let currentStatus: ResearchQuestionStatus
    let onSelect: (ResearchQuestionStatus) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Status")
                .font(.headline)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            
            Divider()
            
            VStack(spacing: 0) {
                ForEach(ResearchQuestionStatus.allCases) { status in
                    Button {
                        onSelect(status)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: status.iconName)
                                .font(.system(size: 14))
                                .foregroundStyle(statusColor(for: status))
                                .frame(width: 20)
                            
                            Text(status.displayName)
                                .font(.system(size: 13))
                            
                            Spacer()
                            
                            if currentStatus == status {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
        .frame(width: 180)
    }
    
    private func statusColor(for status: ResearchQuestionStatus) -> Color {
        Color.forStatus(status)
    }
}

// MARK: - Confidence Picker Popover

/// Confidence level picker popover
private struct ConfidencePickerPopover: View {
    let currentConfidence: ConfidenceLevel?
    let onSelect: (ConfidenceLevel?) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Confidence")
                .font(.headline)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            
            Divider()
            
            VStack(spacing: 0) {
                // "None" option
                Button {
                    onSelect(nil)
                } label: {
                    HStack {
                        Text("None")
                            .foregroundStyle(.secondary)
                        Spacer()
                        if currentConfidence == nil {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                Divider()
                    .padding(.vertical, 4)
                
                ForEach(ConfidenceLevel.allCases) { level in
                    Button {
                        onSelect(level)
                    } label: {
                        HStack(spacing: 8) {
                            Text(level.shortLabel)
                                .font(.system(size: 12))
                                .foregroundStyle(confidenceColor(for: level))
                                .frame(width: 80, alignment: .leading)
                            
                            Text(level.displayName)
                                .font(.system(size: 13))
                            
                            Spacer()
                            
                            if currentConfidence == level {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
        .frame(width: 220)
    }
    
    private func confidenceColor(for level: ConfidenceLevel) -> Color {
        Color.forConfidence(level)
    }
}

// MARK: - Tag Pill

/// Small tag pill for displaying in table cells
private struct TagPill: View {
    let tag: Tag
    
    @AppStorage("textSizeMultiplier") private var textSizeMultiplier: Double = 1.0
    
    var body: some View {
        Text(tag.name)
            .font(.system(size: 12 * textSizeMultiplier))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(tagColor.opacity(0.2))
            .foregroundStyle(tagColor)
            .clipShape(Capsule())
            .accessibilityLabel("Tag: \(tag.name)")
    }
    
    private var tagColor: Color {
        guard let colorName = tag.colorName,
              let tagColor = TagColor(rawValue: colorName) else {
            return Color.accentColor
        }
        return tagColor.color
    }
}

// MARK: - Preview

#Preview {
    let question = ResearchQuestion(
        questionText: "Can AAPL sustain services revenue growth?",
        context: "Services now represent 20% of revenue",
        confidence: 4
    )
    
    return RecordRowView(
        question: question,
        columns: [.question, .assetName, .status, .confidence, .updated],
        isSelected: false,
        onQuestionTap: { print("Question tapped") },
        onAssetChange: { old, new in print("Asset: \(old?.ticker ?? "nil") -> \(new?.ticker ?? "nil")") },
        onStatusChange: { old, new in print("Status: \(old) -> \(new)") },
        onConfidenceChange: { old, new in print("Confidence: \(String(describing: old)) -> \(String(describing: new))") }
    )
    .padding()
}
