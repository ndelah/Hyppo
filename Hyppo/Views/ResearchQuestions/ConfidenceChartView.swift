/**
 ConfidenceChartView displays a step chart showing confidence evolution over time
 with decision markers to visualize whether actions aligned with conviction.
 
 The chart shows:
 - Confidence level over time (step chart, not smooth)
 - Decision markers at decision points
 - Current confidence level
 */

import SwiftUI
import SwiftData
import Charts

/// Data point for confidence chart
struct ConfidenceDataPoint: Identifiable {
    var id: UUID
    var date: Date
    var value: Int
    var source: String  // "review", "decision", "initial"
    
    init(date: Date, value: Int, source: String) {
        self.id = UUID()
        self.date = date
        self.value = value
        self.source = source
    }
}

/// Decision marker for the chart
struct DecisionMarker: Identifiable {
    var id: UUID
    var date: Date
    var confidence: Int
    var actionType: DecisionAction
    
    init(decision: Decision) {
        self.id = decision.decisionId
        self.date = decision.decidedAt
        self.confidence = decision.confidenceAtDecision ?? 3
        self.actionType = decision.actionType
    }
}

/// Chart view showing confidence evolution with decision markers
struct ConfidenceChartView: View {
    // MARK: - Properties
    
    let researchQuestion: ResearchQuestion
    
    // MARK: - Computed Properties
    
    /// Confidence data points from reviews and decisions
    private var confidenceDataPoints: [ConfidenceDataPoint] {
        var points: [ConfidenceDataPoint] = []
        
        // Add initial confidence if set at creation
        if let initialConfidence = researchQuestion.confidenceCurrent {
            points.append(ConfidenceDataPoint(
                date: researchQuestion.createdAt,
                value: initialConfidence,
                source: "initial"
            ))
        }
        
        // Add confidence from review log entries
        if let logEntries = researchQuestion.logEntries {
            for entry in logEntries {
                if entry.entryType == .review,
                   let confidence = entry.confidence {
                    points.append(ConfidenceDataPoint(
                        date: entry.occurredAt,
                        value: confidence,
                        source: "review"
                    ))
                }
            }
        }
        
        // Add confidence snapshots from decisions
        if let decisions = researchQuestion.decisions {
            for decision in decisions {
                if let confidence = decision.confidenceAtDecision {
                    points.append(ConfidenceDataPoint(
                        date: decision.decidedAt,
                        value: confidence,
                        source: "decision"
                    ))
                }
            }
        }
        
        // Sort by date
        return points.sorted { $0.date < $1.date }
    }
    
    /// Decision markers for the chart
    private var decisionMarkers: [DecisionMarker] {
        guard let decisions = researchQuestion.decisions else { return [] }
        return decisions.map { DecisionMarker(decision: $0) }
    }
    
    /// Current confidence value
    private var currentConfidence: Int? {
        researchQuestion.confidenceCurrent
    }
    
    /// Whether we have any data to show
    private var hasData: Bool {
        !confidenceDataPoints.isEmpty || !decisionMarkers.isEmpty
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Confidence Over Time")
                    .font(.headline)
                
                Spacer()
                
                if let current = currentConfidence {
                    HStack(spacing: 4) {
                        Text("Current:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(ConfidenceLevel(rawValue: current)?.shortLabel ?? "\(current)/5")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
            }
            
            if !hasData {
                // Empty state
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title2)
                        .foregroundStyle(.tertiary)
                    Text("No confidence data yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Confidence will appear after reviews or decisions")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 150)
            } else {
                // Chart
                Chart {
                    // Step chart for confidence evolution
                    if !confidenceDataPoints.isEmpty {
                        ForEach(confidenceDataPoints) { point in
                            LineMark(
                                x: .value("Date", point.date, unit: .day),
                                y: .value("Confidence", point.value)
                            )
                            .interpolationMethod(.stepEnd)
                            .foregroundStyle(.blue)
                            .lineStyle(StrokeStyle(lineWidth: 2))
                        }
                    }
                    
                    // Decision markers as points
                    ForEach(decisionMarkers) { marker in
                        PointMark(
                            x: .value("Date", marker.date, unit: .day),
                            y: .value("Confidence", marker.confidence)
                        )
                        .symbol {
                            Circle()
                                .fill(Color.fromName(marker.actionType.colorName))
                                .frame(width: 10, height: 10)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                        .frame(width: 10, height: 10)
                                )
                        }
                        .foregroundStyle(Color.fromName(marker.actionType.colorName))
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: [1, 2, 3, 4, 5]) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text("\(intValue)")
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartYScale(domain: 0.5...5.5)
                .frame(height: 200)
                
                // Legend
                if !decisionMarkers.isEmpty {
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                            Text("Confidence")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        ForEach(Array(Set(decisionMarkers.map { $0.actionType })), id: \.self) { action in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.fromName(action.colorName))
                                    .frame(width: 8, height: 8)
                                Text(action.displayName)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor).opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview("With Data") {
    let rq = ResearchQuestion(
        questionText: "Is NVDA a good investment?",
        thesisStatement: "AI demand will continue to drive datacenter growth",
        confidence: 3
    )
    
    // Add some review log entries with confidence
    let review1 = LogEntry(
        title: "Review: Reinforce",
        body: "Thesis intact",
        entryType: .review,
        confidence: 4,
        occurredAt: Date().addingTimeInterval(-86400 * 30)
    )
    review1.researchQuestion = rq
    
    let review2 = LogEntry(
        title: "Review: Revise",
        body: "Some drivers need updating",
        entryType: .review,
        confidence: 3,
        occurredAt: Date().addingTimeInterval(-86400 * 15)
    )
    review2.researchQuestion = rq
    
    // Add decisions
    let buy = Decision(
        actionType: .buy,
        rationale: "Drivers confirmed",
        decidedAt: Date().addingTimeInterval(-86400 * 10),
        confidenceAtDecision: 4
    )
    buy.researchQuestion = rq
    
    let hold = Decision(
        actionType: .hold,
        rationale: "Maintaining position",
        decidedAt: Date().addingTimeInterval(-86400 * 5),
        confidenceAtDecision: 4
    )
    hold.researchQuestion = rq
    
    rq.logEntries = [review1, review2]
    rq.decisions = [buy, hold]
    rq.confidenceCurrent = 4
    
    return ConfidenceChartView(researchQuestion: rq)
        .padding()
        .frame(width: 600)
}

#Preview("Empty State") {
    let rq = ResearchQuestion(
        questionText: "Is NVDA a good investment?"
    )
    
    return ConfidenceChartView(researchQuestion: rq)
        .padding()
        .frame(width: 600)
}

