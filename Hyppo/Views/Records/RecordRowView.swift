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
    let isSelected: Bool
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(columns) { column in
                columnCell(for: column)
                    .frame(width: column.suggestedWidth, alignment: alignment(for: column))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 10)
                
                if column != columns.last {
                    Divider()
                        .frame(height: 24)
                }
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
        case .confidence:
            confidenceCell
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
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)
            
            if let context = question.context, !context.isEmpty {
                Text(context)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
    
    private var assetCell: some View {
        Group {
            if let asset = question.asset {
                Text(asset.ticker)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
            } else {
                Text("—")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
        }
    }
    
    private var statusCell: some View {
        HStack(spacing: 4) {
            Image(systemName: question.status.iconName)
                .font(.caption)
            Text(question.status.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.15))
        .foregroundStyle(statusColor)
        .clipShape(Capsule())
    }
    
    private var confidenceCell: some View {
        Group {
            if let confidence = question.confidence {
                HStack(spacing: 4) {
                    Image(systemName: "gauge")
                        .font(.caption)
                    Text(confidence.shortLabel)
                        .font(.caption)
                }
                .foregroundStyle(confidenceColor(for: confidence))
            } else {
                Text("—")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
    
    private var driversCell: some View {
        let count = question.drivers?.count ?? 0
        return Text("\(count)")
            .font(.subheadline)
            .foregroundStyle(count > 0 ? .primary : .tertiary)
    }
    
    private var scenariosCell: some View {
        let count = question.scenariosCount
        return Text("\(count)")
            .font(.subheadline)
            .foregroundStyle(count > 0 ? .primary : .tertiary)
    }
    
    private var logEntriesCell: some View {
        let count = question.logEntriesCount
        return Text("\(count)")
            .font(.subheadline)
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
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Text("—")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
    
    private var createdCell: some View {
        Text(question.createdAt.formatted(date: .abbreviated, time: .omitted))
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    
    private var updatedCell: some View {
        Text(question.updatedAt.formatted(date: .abbreviated, time: .omitted))
            .font(.caption)
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
    
    private func confidenceColor(for confidence: ConfidenceLevel) -> Color {
        switch confidence {
        case .veryLow: return .red
        case .low: return .orange
        case .medium: return .yellow
        case .high: return .green
        case .veryHigh: return .blue
        }
    }
    
    private func alignment(for column: RecordColumn) -> Alignment {
        switch column {
        case .question, .tags:
            return .leading
        case .drivers, .scenarios, .logEntries:
            return .center
        case .assetName, .status, .confidence, .created, .updated:
            return .leading
        }
    }
}

// MARK: - Tag Pill

/// Small tag pill for displaying in table cells
private struct TagPill: View {
    let tag: Tag
    
    var body: some View {
        Text(tag.name)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(tagColor.opacity(0.2))
            .foregroundStyle(tagColor)
            .clipShape(Capsule())
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
        context: "Services now represent 20% of revenue",
        confidence: 4
    )
    
    return RecordRowView(
        question: question,
        columns: [.question, .assetName, .status, .confidence, .updated],
        isSelected: false
    )
    .padding()
}

