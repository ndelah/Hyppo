/**
 DecisionAnalyticsView provides analytics and calibration metrics for investment decisions.
 
 Displays key metrics to help users understand their decision-making effectiveness:
 - Decision accuracy (% correct/partial/wrong)
 - Timing calibration (% early/onTime/late)
 - Action distribution (how often you pass vs buy vs exit)
 - Confidence calibration (were high-confidence decisions better?)
 */

import SwiftUI
import SwiftData

/// Analytics dashboard for investment decisions
struct DecisionAnalyticsView: View {
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Queries
    
    @Query private var allDecisions: [Decision]
    @Query private var allOutcomes: [Outcome]
    @Query(filter: #Predicate<ResearchQuestion> { rq in
        rq.investmentPhaseRaw == "PostMortem"
    }) private var completedTheses: [ResearchQuestion]
    
    // MARK: - Computed Properties
    
    /// Total decisions made
    private var totalDecisions: Int {
        allDecisions.count
    }
    
    /// Total completed theses (with outcomes)
    private var totalCompletedTheses: Int {
        completedTheses.count
    }
    
    /// Outcomes grouped by thesis assessment
    private var thesisAssessmentCounts: [ThesisAssessment: Int] {
        var counts: [ThesisAssessment: Int] = [:]
        for outcome in allOutcomes {
            counts[outcome.thesisAssessment, default: 0] += 1
        }
        return counts
    }
    
    /// Outcomes grouped by timing assessment
    private var timingAssessmentCounts: [TimingAssessment: Int] {
        var counts: [TimingAssessment: Int] = [:]
        for outcome in allOutcomes {
            counts[outcome.timingAssessment, default: 0] += 1
        }
        return counts
    }
    
    /// Decisions grouped by action type
    private var actionTypeCounts: [DecisionAction: Int] {
        var counts: [DecisionAction: Int] = [:]
        for decision in allDecisions {
            counts[decision.actionType, default: 0] += 1
        }
        return counts
    }
    
    /// Thesis accuracy percentage
    private var thesisAccuracyPercentage: Double? {
        let total = allOutcomes.count
        guard total > 0 else { return nil }
        let correct = thesisAssessmentCounts[.correct, default: 0]
        let partial = thesisAssessmentCounts[.partial, default: 0]
        // Count correct as 1, partial as 0.5
        return Double(correct * 100 + partial * 50) / Double(total)
    }
    
    /// Timing accuracy percentage
    private var timingAccuracyPercentage: Double? {
        let applicable = allOutcomes.filter { $0.timingAssessment != .notApplicable }
        guard !applicable.isEmpty else { return nil }
        let onTime = applicable.filter { $0.timingAssessment == .onTime }.count
        return Double(onTime * 100) / Double(applicable.count)
    }
    
    /// Buy decisions
    private var buyDecisionsCount: Int {
        actionTypeCounts[.buy, default: 0]
    }
    
    /// Pass decisions
    private var passDecisionsCount: Int {
        actionTypeCounts[.pass, default: 0]
    }
    
    /// Pass to Buy ratio
    private var passToBuyRatio: Double? {
        guard buyDecisionsCount > 0 else { return nil }
        return Double(passDecisionsCount) / Double(buyDecisionsCount)
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                headerSection
                
                if totalDecisions == 0 {
                    emptyState
                } else {
                    // Summary metrics
                    summaryMetricsSection
                    
                    // Thesis accuracy breakdown
                    if !allOutcomes.isEmpty {
                        thesisAccuracySection
                    }
                    
                    // Timing calibration breakdown
                    if !allOutcomes.isEmpty {
                        timingCalibrationSection
                    }
                    
                    // Action distribution
                    actionDistributionSection
                    
                    // Calibration insights
                    if totalCompletedTheses >= 3 {
                        calibrationInsightsSection
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Subviews
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Decision Analytics")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Track your decision-making effectiveness over time")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            
            Text("No decisions recorded yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text("Start recording investment decisions to track your accuracy and calibration over time.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    private var summaryMetricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Summary")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                metricCard(
                    title: "Total Decisions",
                    value: "\(totalDecisions)",
                    icon: "checkmark.circle",
                    color: Color.accentColor
                )
                
                metricCard(
                    title: "Completed Theses",
                    value: "\(totalCompletedTheses)",
                    icon: "flag.checkered",
                    color: Color.accentColor
                )
                
                if let accuracy = thesisAccuracyPercentage {
                    metricCard(
                        title: "Thesis Accuracy",
                        value: String(format: "%.0f%%", accuracy),
                        icon: "target",
                        color: accuracyColor(accuracy)
                    )
                }
                
                if let timing = timingAccuracyPercentage {
                    metricCard(
                        title: "Timing Accuracy",
                        value: String(format: "%.0f%%", timing),
                        icon: "clock",
                        color: accuracyColor(timing)
                    )
                }
            }
        }
    }
    
    private func metricCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }
            
            HStack {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
            }
            
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding()
        .background(color.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var thesisAccuracySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Thesis Accuracy")
                .font(.headline)
            
            HStack(spacing: 16) {
                ForEach(ThesisAssessment.allCases) { assessment in
                    let count = thesisAssessmentCounts[assessment, default: 0]
                    assessmentBar(
                        label: assessment.displayName,
                        count: count,
                        total: allOutcomes.count,
                        color: Color.fromName(assessment.colorName),
                        icon: assessment.iconName
                    )
                }
            }
            .padding()
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var timingCalibrationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timing Calibration")
                .font(.headline)
            
            HStack(spacing: 16) {
                ForEach(TimingAssessment.allCases) { assessment in
                    let count = timingAssessmentCounts[assessment, default: 0]
                    assessmentBar(
                        label: assessment.displayName,
                        count: count,
                        total: allOutcomes.count,
                        color: Color.fromName(assessment.colorName),
                        icon: assessment.iconName
                    )
                }
            }
            .padding()
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func assessmentBar(label: String, count: Int, total: Int, color: Color, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text("\(count)")
                .font(.title3)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            // Percentage bar
            GeometryReader { geometry in
                let percentage = total > 0 ? CGFloat(count) / CGFloat(total) : 0
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geometry.size.width * percentage)
                }
            }
            .frame(height: 4)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var actionDistributionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Action Distribution")
                .font(.headline)
            
            HStack(spacing: 12) {
                ForEach(DecisionAction.allCases) { action in
                    let count = actionTypeCounts[action, default: 0]
                    if count > 0 {
                        actionBadge(action: action, count: count)
                    }
                }
            }
            
            // Pass to Buy ratio
            if let ratio = passToBuyRatio {
                HStack {
                    Text("Pass-to-Buy Ratio:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(String(format: "%.1f:1", ratio))
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Text("(Higher = more selective)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func actionBadge(action: DecisionAction, count: Int) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: action.iconName)
                Text("\(count)")
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.fromName(action.colorName).opacity(0.15))
            .foregroundStyle(Color.fromName(action.colorName))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Text(action.displayName)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
    
    private var calibrationInsightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Calibration Insights")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                // Generate insights based on data
                ForEach(generateInsights(), id: \.self) { insight in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(Color.confidenceMedium)
                        Text(insight)
                            .font(.subheadline)
                    }
                }
            }
            .padding()
            .background(Color.confidenceMedium.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Helpers
    
    private func accuracyColor(_ percentage: Double) -> Color {
        if percentage >= 70 {
            return .statusActive
        } else if percentage >= 50 {
            return .statusOnHold
        } else {
            return .statusInvalidated
        }
    }
    
    private func generateInsights() -> [String] {
        var insights: [String] = []
        
        // Thesis accuracy insight
        if let accuracy = thesisAccuracyPercentage {
            if accuracy >= 70 {
                insights.append("Your thesis accuracy is strong at \(Int(accuracy))%. Your research process is working well.")
            } else if accuracy >= 50 {
                insights.append("Your thesis accuracy is moderate at \(Int(accuracy))%. Consider being more rigorous with driver validation.")
            } else {
                insights.append("Your thesis accuracy is below 50%. Review your driver identification process.")
            }
        }
        
        // Timing insight
        let earlyCount = timingAssessmentCounts[.early, default: 0]
        let lateCount = timingAssessmentCounts[.late, default: 0]
        if earlyCount > lateCount * 2 {
            insights.append("You tend to act early. Consider waiting for more driver confirmation before entering.")
        } else if lateCount > earlyCount * 2 {
            insights.append("You tend to act late. Consider being more decisive when your drivers confirm.")
        }
        
        // Selectivity insight
        if let ratio = passToBuyRatio {
            if ratio > 5 {
                insights.append("You're highly selective (pass:buy ratio \(String(format: "%.1f", ratio)):1). Ensure you're not missing opportunities.")
            } else if ratio < 1 {
                insights.append("You rarely pass on opportunities. Consider being more selective with your entries.")
            }
        }
        
        // Add a default if no specific insights
        if insights.isEmpty {
            insights.append("Keep recording decisions to build more calibration data.")
        }
        
        return insights
    }
}

// MARK: - Preview

#Preview {
    DecisionAnalyticsView()
        .modelContainer(for: [
            Decision.self,
            Outcome.self,
            ResearchQuestion.self
        ], inMemory: true)
        .frame(width: 800, height: 600)
}

