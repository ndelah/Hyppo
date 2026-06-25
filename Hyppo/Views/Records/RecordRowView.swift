/**
 RecordRowView displays a single research question as a table row.
 
 Shows configurable columns based on ViewConfiguration settings.
 Each column renders the appropriate data type for the research question.
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
    
    // MARK: - Accessibility
    
    @AppStorage("textSizeMultiplier") private var textSizeMultiplier: Double = 1.0
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 0) {
            // Left margin spacer
            Spacer()
                .frame(width: 16)
            
            ForEach(columns) { column in
                // Use responsive width if provided, otherwise fall back to minimum width
                let width = columnWidths?[column] ?? column.minWidth
                
                HStack(spacing: 0) {
                    // Add extra leading padding for left-aligned columns so text doesn't stick to divider
                    columnCell(for: column)
                        .frame(width: width - 16, alignment: column.alignment)
                        .padding(.leading, column.alignment == .leading ? 12 : 8)
                        .padding(.trailing, 8)
                        .padding(.vertical, 10)
                    
                    if column != columns.last {
                        Divider()
                            .frame(height: 24)
                    }
                }
                .frame(width: width)
            }
            
            Spacer(minLength: 0)
        }
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        .contentShape(Rectangle())
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
        case .drivers:
            driversCell
        case .scenarios:
            scenariosCell
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
    
    // MARK: - Cell Views
    
    private var questionCell: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(question.questionText)
                .font(.system(size: 13 * textSizeMultiplier, weight: .medium))
                .lineLimit(2)
            
            if let context = question.context, !context.isEmpty {
                Text(context)
                    .font(.system(size: 11 * textSizeMultiplier))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
    
    private var assetCell: some View {
        Group {
            if let asset = question.asset {
                Text(asset.ticker)
                    .font(.system(size: 13 * textSizeMultiplier, weight: .semibold))
                    .foregroundStyle(.cyan)
            } else {
                Text("—")
                    .font(.system(size: 13 * textSizeMultiplier))
                    .foregroundStyle(.tertiary)
            }
        }
    }
    
    private var statusCell: some View {
        HStack(spacing: 4) {
            Image(systemName: question.status.iconName)
                .font(.system(size: 11 * textSizeMultiplier))
            Text(question.status.displayName)
                .font(.system(size: 11 * textSizeMultiplier, weight: .medium))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.15))
        .foregroundStyle(statusColor)
        .clipShape(Capsule())
    }
    
    private var driversCell: some View {
        let count = question.drivers?.count ?? 0
        return Text("\(count)")
            .font(.system(size: 13 * textSizeMultiplier))
            .foregroundStyle(count > 0 ? .primary : .tertiary)
    }
    
    private var scenariosCell: some View {
        let count = question.scenariosCount
        return Text("\(count)")
            .font(.system(size: 13 * textSizeMultiplier))
            .foregroundStyle(count > 0 ? .primary : .tertiary)
    }
    
    private var logEntriesCell: some View {
        let count = question.logEntriesCount
        return Text("\(count)")
            .font(.system(size: 13 * textSizeMultiplier))
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
                            .font(.system(size: 11 * textSizeMultiplier))
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("\(tags.count - 3) more tags")
                    }
                }
            } else {
                Text("—")
                    .font(.system(size: 11 * textSizeMultiplier))
                    .foregroundStyle(.tertiary)
                    .accessibilityLabel("No tags")
            }
        }
    }
    
    private var createdCell: some View {
        Text(question.createdAt.formatted(date: .abbreviated, time: .omitted))
            .font(.system(size: 11 * textSizeMultiplier))
            .foregroundStyle(.secondary)
    }
    
    private var updatedCell: some View {
        Text(question.updatedAt.formatted(date: .abbreviated, time: .omitted))
            .font(.system(size: 11 * textSizeMultiplier))
            .foregroundStyle(.secondary)
    }
    
    // MARK: - Helpers
    
    private var statusColor: Color {
        switch question.status {
        case .active: return .green
        case .onHold: return .orange
        case .invalidated: return .red
        case .archived: return .gray
        }
    }
    
}

// MARK: - Tag Pill

/// Small tag pill for displaying in table cells
private struct TagPill: View {
    let tag: Tag
    
    @AppStorage("textSizeMultiplier") private var textSizeMultiplier: Double = 1.0
    
    var body: some View {
        Text(tag.name)
            .font(.system(size: 11 * textSizeMultiplier))
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
            return .blue
        }
        return tagColor.color
    }
}

// MARK: - Preview

#Preview {
    let question = ResearchQuestion(
        questionText: "Can AAPL sustain services revenue growth?",
        context: "Services now represent 20% of revenue"
    )
    
    return RecordRowView(
        question: question,
        columns: [.question, .assetName, .status, .updated],
        isSelected: false
    )
    .padding()
}

