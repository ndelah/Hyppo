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
    
    // MARK: - Accessibility
    
    @AppStorage("textSizeMultiplier") private var textSizeMultiplier: Double = 1.0
    
    // MARK: - Layout Constants
    
    /// Fixed card height for consistent grid layout
    private var cardHeight: CGFloat {
        isCompact ? 140 : 180
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 8 : 12) {
            // Header with asset and status
            headerRow
            
            // Question text (truncated with ellipsis)
            Text(question.questionText)
                .font(.system(size: (isCompact ? 13 : 15) * textSizeMultiplier, weight: .medium))
                .lineLimit(isCompact ? 2 : 3)
                .truncationMode(.tail)
            
            // Context preview (if not compact, truncated)
            if !isCompact, let context = question.context, !context.isEmpty {
                Text(context)
                    .font(.system(size: 12 * textSizeMultiplier))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .truncationMode(.tail)
            }
            
            Spacer(minLength: 0)
            
            // Metrics row
            metricsRow
            
            // Footer with date
            footerRow
        }
        .padding(isCompact ? 12 : 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: cardHeight)
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
                    .font(.system(size: 11 * textSizeMultiplier, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.cyan.opacity(0.15))
                    .foregroundStyle(.cyan)
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
                .font(.system(size: 11 * textSizeMultiplier))
            if !isCompact {
                Text(question.status.displayName)
                    .font(.system(size: 11 * textSizeMultiplier, weight: .medium))
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
                            .frame(width: 8 * textSizeMultiplier, height: 8 * textSizeMultiplier)
                            .accessibilityLabel("Tag: \(tag.name)")
                    }
                    if tags.count > 2 {
                        Text("+\(tags.count - 2)")
                            .font(.system(size: 11 * textSizeMultiplier))
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("\(tags.count - 2) more tags")
                    }
                }
            }
            
            Spacer()
            
            // Last updated
            Text(question.updatedAt.formatted(date: .abbreviated, time: .omitted))
                .font(.system(size: 11 * textSizeMultiplier))
                .foregroundStyle(.tertiary)
                .accessibilityLabel("Last updated \(question.updatedAt.formatted(date: .long, time: .omitted))")
        }
    }
    
    // MARK: - Helpers
    
    private var cardBackground: Color {
        Color(nsColor: .windowBackgroundColor)
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
    
    @AppStorage("textSizeMultiplier") private var textSizeMultiplier: Double = 1.0
    
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 11 * textSizeMultiplier))
            Text(text)
                .font(.system(size: 11 * textSizeMultiplier, weight: .medium))
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

