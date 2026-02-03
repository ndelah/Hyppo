/**
 RecordCardView displays a research question as a card.
 
 Used in both Kanban view (column cards) and Card Grid view.
 Provides a compact visual summary of the research question.
 */

import SwiftUI
import SwiftData

/// Card view for a research question record
struct RecordCardView: View {
    // MARK: - Properties
    
    let question: ResearchQuestion
    let isSelected: Bool
    var isCompact: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 8 : 12) {
            // Header with asset and status
            headerRow
            
            // Question text
            Text(question.questionText)
                .font(isCompact ? .subheadline : .headline)
                .fontWeight(.medium)
                .lineLimit(isCompact ? 2 : 3)
                .fixedSize(horizontal: false, vertical: true)
            
            // Context preview (if not compact)
            if !isCompact, let context = question.context, !context.isEmpty {
                Text(context)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            // Metrics row
            metricsRow
            
            // Footer with date
            footerRow
        }
        .padding(isCompact ? 12 : 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: isCompact ? 10 : 12))
        .overlay(
            RoundedRectangle(cornerRadius: isCompact ? 10 : 12)
                .stroke(isSelected ? Color.accentColor : Color(nsColor: .separatorColor), lineWidth: isSelected ? 2 : 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Subviews
    
    private var headerRow: some View {
        HStack {
            // Asset ticker badge
            if let asset = question.asset {
                Text(asset.ticker)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.15))
                    .foregroundStyle(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            
            Spacer()
            
            // Status badge
            statusBadge
        }
    }
    
    private var statusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: question.status.iconName)
                .font(.caption)
            if !isCompact {
                Text(question.status.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
        .padding(.horizontal, isCompact ? 6 : 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.15))
        .foregroundStyle(statusColor)
        .clipShape(Capsule())
        .accessibilityLabel("Status: \(question.status.displayName)")
    }
    
    private var metricsRow: some View {
        HStack(spacing: isCompact ? 8 : 16) {
            // Confidence
            if let confidence = question.confidence {
                MetricBadge(
                    icon: "gauge",
                    text: confidence.shortLabel,
                    color: confidenceColor(for: confidence),
                    isCompact: isCompact
                )
            }
            
            // Drivers count
            let driverCount = question.drivers?.count ?? 0
            if driverCount > 0 {
                MetricBadge(
                    icon: "target",
                    text: "\(driverCount)",
                    color: .purple,
                    isCompact: isCompact
                )
            }
            
            // Log entries count
            let logCount = question.logEntriesCount
            if logCount > 0 {
                MetricBadge(
                    icon: "note.text",
                    text: "\(logCount)",
                    color: .orange,
                    isCompact: isCompact
                )
            }
            
            Spacer()
        }
    }
    
    private var footerRow: some View {
        HStack {
            // Tags (show first 2)
            if let tags = question.tags, !tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(tags.prefix(2)) { tag in
                        Circle()
                            .fill(tagColor(for: tag))
                            .frame(width: 8, height: 8)
                            .accessibilityLabel("Tag: \(tag.name)")
                    }
                    if tags.count > 2 {
                        Text("+\(tags.count - 2)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("\(tags.count - 2) more tags")
                    }
                }
            }
            
            Spacer()
            
            // Last updated
            Text(question.updatedAt.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundStyle(.tertiary)
                .accessibilityLabel("Last updated \(question.updatedAt.formatted(date: .long, time: .omitted))")
        }
    }
    
    // MARK: - Helpers
    
    private var cardBackground: Color {
        Color(nsColor: .controlBackgroundColor)
    }
    
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
    
    private func tagColor(for tag: Tag) -> Color {
        guard let colorName = tag.colorName,
              let tagColor = TagColor(rawValue: colorName) else {
            return .blue
        }
        return tagColor.color
    }
}

// MARK: - Metric Badge

/// Small badge showing an icon and value
private struct MetricBadge: View {
    let icon: String
    let text: String
    let color: Color
    var isCompact: Bool = false
    
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundStyle(color)
    }
}

// MARK: - Preview

#Preview("Default Card") {
    let question = ResearchQuestion(
        questionText: "Can AAPL sustain services revenue growth at 15%+ annually?",
        context: "Services now represent 20% of revenue and growing",
        confidence: 4
    )
    
    return RecordCardView(question: question, isSelected: false)
        .frame(width: 300)
        .padding()
}

#Preview("Compact Card") {
    let question = ResearchQuestion(
        questionText: "Will AI demand drive semiconductor growth?",
        context: "Data center spending accelerating",
        confidence: 3
    )
    
    return RecordCardView(question: question, isSelected: true, isCompact: true)
        .frame(width: 250)
        .padding()
}

