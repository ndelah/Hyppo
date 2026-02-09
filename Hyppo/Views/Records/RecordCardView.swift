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
        isCompact ? 150 : 200
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 10 : 14) {
            // Header with asset and status
            headerRow
            
            // Question text (truncated with ellipsis)
            Text(question.questionText)
                .font(.system(size: (isCompact ? 14 : 16) * textSizeMultiplier, weight: .medium))
                .lineLimit(isCompact ? 2 : 3)
                .truncationMode(.tail)
            
            // Context preview (if not compact, truncated)
            if !isCompact, let context = question.context, !context.isEmpty {
                Text(context)
                    .font(.system(size: 13 * textSizeMultiplier))
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
        .padding(isCompact ? 14 : 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: cardHeight)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: isCompact ? 10 : 12))
        .overlay(
            RoundedRectangle(cornerRadius: isCompact ? 10 : 12)
                .stroke(isSelected ? Color.accentColor : Color.appBorder, lineWidth: isSelected ? 2 : 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Subviews
    
    private var headerRow: some View {
        HStack {
            // Asset ticker badge
            if let asset = question.asset {
                Text(asset.ticker)
                    .font(.system(size: 12 * textSizeMultiplier, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.assetBackgroundColor)
                    .foregroundStyle(Color.assetColor)
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
                .font(.system(size: 12 * textSizeMultiplier))
            if !isCompact {
                Text(question.status.displayName)
                    .font(.system(size: 12 * textSizeMultiplier, weight: .medium))
            }
        }
        .padding(.horizontal, isCompact ? 8 : 10)
        .padding(.vertical, 5)
        .background(statusColor.opacity(0.15))
        .foregroundStyle(statusColor)
        .clipShape(Capsule())
        .accessibilityLabel("Status: \(question.status.displayName)")
    }
    
    private var metricsRow: some View {
        HStack(spacing: isCompact ? 10 : 18) {
            // Confidence
            if let confidence = question.confidence {
                MetricBadge(
                    icon: "gauge",
                    text: confidence.displayName,
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
                    color: Color.statusOnHold,
                    isCompact: isCompact
                )
            }
            
            Spacer()
        }
    }
    
    private var footerRow: some View {
        HStack {
            // Labels (show first 2)
            let labels = question.effectiveLabels
            if !labels.isEmpty {
                HStack(spacing: 5) {
                    ForEach(labels.prefix(2)) { tag in
                        Circle()
                            .fill(tagColor(for: tag))
                            .frame(width: 9 * textSizeMultiplier, height: 9 * textSizeMultiplier)
                            .accessibilityLabel("Label: \(tag.name)")
                    }
                    if labels.count > 2 {
                        Text("+\(labels.count - 2)")
                            .font(.system(size: 12 * textSizeMultiplier))
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("\(labels.count - 2) more labels")
                    }
                }
            }
            
            Spacer()
            
            // Last updated
            Text(question.updatedAt.formatted(date: .abbreviated, time: .omitted))
                .font(.system(size: 12 * textSizeMultiplier))
                .foregroundStyle(.tertiary)
                .accessibilityLabel("Last updated \(question.updatedAt.formatted(date: .long, time: .omitted))")
        }
    }
    
    // MARK: - Helpers
    
    private var cardBackground: Color {
        Color.surface
    }
    
    private var statusColor: Color {
        Color.forStatus(question.status)
    }
    
    private func confidenceColor(for confidence: ConfidenceLevel) -> Color {
        Color.forConfidence(confidence)
    }
    
    private func tagColor(for tag: Tag) -> Color {
        guard let colorName = tag.colorName,
              let tagColor = TagColor(rawValue: colorName) else {
            return Color.accentColor
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
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12 * textSizeMultiplier))
            Text(text)
                .font(.system(size: 12 * textSizeMultiplier, weight: .medium))
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

