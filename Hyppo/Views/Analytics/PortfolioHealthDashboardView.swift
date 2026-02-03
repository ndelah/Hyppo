/**
 PortfolioHealthDashboardView displays aggregate portfolio health metrics.
 
 Features:
 - Overall portfolio health score gauge
 - Status distribution breakdown (Active/On Hold/Invalidated/Archived)
 - Confidence distribution chart
 - Key metrics summary cards
 - Asset coverage visualization
 */

import SwiftUI
import SwiftData
import Charts

struct PortfolioHealthDashboardView: View {
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - State
    
    @State private var analytics: PortfolioAnalytics?
    @State private var confidenceDistribution: [Int: Int] = [:]
    @State private var isLoading = true
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if isLoading {
                    loadingView
                } else if let analytics = analytics {
                    // Header with overall health
                    healthScoreHeader(analytics)
                    
                    // Key metrics row
                    keyMetricsRow(analytics)
                    
                    // Charts section
                    HStack(alignment: .top, spacing: 20) {
                        // Status distribution
                        statusDistributionChart(analytics)
                        
                        // Confidence distribution
                        confidenceDistributionChart
                    }
                    
                    // Alerts summary
                    if analytics.overdueReviews > 0 || analytics.blindSpotCount > 0 || analytics.staleResearchCount > 0 {
                        alertsSummary(analytics)
                    }
                } else {
                    emptyStateView
                }
            }
            .padding(20)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear(perform: loadAnalytics)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading analytics...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            
            Text("No Data Available")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("Start adding research questions to see your portfolio analytics")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    // MARK: - Health Score Header
    
    private func healthScoreHeader(_ analytics: PortfolioAnalytics) -> some View {
        HStack(spacing: 24) {
            // Health score gauge
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(analytics.portfolioHealthScore) / 100)
                        .stroke(
                            healthColor(for: analytics.portfolioHealthScore),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 2) {
                        Text("\(analytics.portfolioHealthScore)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(healthColor(for: analytics.portfolioHealthScore))
                        Text("Health")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Text(healthLabel(for: analytics.portfolioHealthScore))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(healthColor(for: analytics.portfolioHealthScore))
            }
            
            // Summary stats
            VStack(alignment: .leading, spacing: 12) {
                Text("Portfolio Overview")
                    .font(.headline)
                
                HStack(spacing: 24) {
                    summaryStatItem(
                        value: "\(analytics.totalResearchQuestions)",
                        label: "Research Questions",
                        icon: "doc.text",
                        color: .blue
                    )
                    
                    summaryStatItem(
                        value: "\(analytics.totalAssets)",
                        label: "Assets",
                        icon: "building.2",
                        color: .purple
                    )
                    
                    summaryStatItem(
                        value: String(format: "%.1f", analytics.averageConfidence),
                        label: "Avg Confidence",
                        icon: "gauge",
                        color: .orange
                    )
                    
                    summaryStatItem(
                        value: String(format: "%.0f", analytics.averageHealthScore),
                        label: "Avg Health",
                        icon: "heart",
                        color: .green
                    )
                }
            }
            
            Spacer()
        }
        .padding(20)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func summaryStatItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Key Metrics Row
    
    private func keyMetricsRow(_ analytics: PortfolioAnalytics) -> some View {
        HStack(spacing: 16) {
            metricCard(
                title: "Evidence",
                value: "\(analytics.totalEvidence)",
                subtitle: "\(analytics.recentContradictingCount) contradicting (7d)",
                icon: "doc.badge.plus",
                color: .blue
            )
            
            metricCard(
                title: "Tasks",
                value: "\(analytics.completedTasks)/\(analytics.totalTasks)",
                subtitle: taskCompletionSubtitle(analytics),
                icon: "checklist",
                color: .green
            )
            
            metricCard(
                title: "Drivers",
                value: "\(analytics.totalDrivers)",
                subtitle: "\(analytics.blindSpotCount) blind spots",
                icon: "target",
                color: .purple
            )
            
            metricCard(
                title: "Reviews",
                value: "\(analytics.overdueReviews)",
                subtitle: "overdue",
                icon: "clock.badge.exclamationmark",
                color: analytics.overdueReviews > 0 ? .orange : .green
            )
        }
    }
    
    private func taskCompletionSubtitle(_ analytics: PortfolioAnalytics) -> String {
        guard analytics.totalTasks > 0 else { return "no tasks" }
        let rate = Double(analytics.completedTasks) / Double(analytics.totalTasks) * 100
        return String(format: "%.0f%% complete", rate)
    }
    
    private func metricCard(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    // MARK: - Status Distribution Chart
    
    private func statusDistributionChart(_ analytics: PortfolioAnalytics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Status Distribution")
                .font(.headline)
            
            let statusData = [
                StatusChartData(status: "Active", count: analytics.activeQuestions, color: .green),
                StatusChartData(status: "On Hold", count: analytics.onHoldQuestions, color: .orange),
                StatusChartData(status: "Invalidated", count: analytics.invalidatedQuestions, color: .red),
                StatusChartData(status: "Archived", count: analytics.archivedQuestions, color: .gray)
            ].filter { $0.count > 0 }
            
            if statusData.isEmpty {
                Text("No research questions")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(height: 150)
            } else {
                Chart(statusData) { item in
                    SectorMark(
                        angle: .value("Count", item.count),
                        innerRadius: .ratio(0.6),
                        angularInset: 2
                    )
                    .foregroundStyle(item.color)
                    .annotation(position: .overlay) {
                        if item.count > 0 {
                            Text("\(item.count)")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                        }
                    }
                }
                .chartLegend(position: .bottom, spacing: 16)
                .frame(height: 180)
            }
            
            // Legend
            VStack(alignment: .leading, spacing: 6) {
                ForEach(statusData) { item in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(item.color)
                            .frame(width: 10, height: 10)
                        Text(item.status)
                            .font(.caption)
                        Spacer()
                        Text("\(item.count)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    // MARK: - Confidence Distribution Chart
    
    private var confidenceDistributionChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Confidence Distribution")
                .font(.headline)
            
            let chartData = (1...5).map { level in
                ConfidenceChartData(level: level, count: confidenceDistribution[level] ?? 0)
            }
            
            let hasData = chartData.contains { $0.count > 0 }
            
            if !hasData {
                Text("No confidence data")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(height: 150)
            } else {
                Chart(chartData) { item in
                    BarMark(
                        x: .value("Level", item.levelLabel),
                        y: .value("Count", item.count)
                    )
                    .foregroundStyle(confidenceColor(for: item.level))
                    .annotation(position: .top) {
                        if item.count > 0 {
                            Text("\(item.count)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisValueLabel()
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .frame(height: 180)
            }
            
            // Legend
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { level in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(confidenceColor(for: level))
                            .frame(width: 8, height: 8)
                        Text(ConfidenceLevel(rawValue: level)?.displayName ?? "")
                            .font(.caption2)
                    }
                }
            }
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    // MARK: - Alerts Summary
    
    private func alertsSummary(_ analytics: PortfolioAnalytics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("Attention Needed")
                    .font(.headline)
            }
            
            HStack(spacing: 16) {
                if analytics.overdueReviews > 0 {
                    alertItem(
                        count: analytics.overdueReviews,
                        label: "Overdue Reviews",
                        icon: "clock.badge.exclamationmark",
                        color: .orange
                    )
                }
                
                if analytics.blindSpotCount > 0 {
                    alertItem(
                        count: analytics.blindSpotCount,
                        label: "Blind Spots",
                        icon: "eye.slash",
                        color: .yellow
                    )
                }
                
                if analytics.staleResearchCount > 0 {
                    alertItem(
                        count: analytics.staleResearchCount,
                        label: "Stale Research",
                        icon: "hourglass",
                        color: .gray
                    )
                }
                
                if analytics.recentContradictingCount > 0 {
                    alertItem(
                        count: analytics.recentContradictingCount,
                        label: "New Contradicting (7d)",
                        icon: "minus.circle.fill",
                        color: .red
                    )
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private func alertItem(count: Int, label: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(count)")
                    .font(.title3)
                    .fontWeight(.bold)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - Helper Methods
    
    private func loadAnalytics() {
        Task {
            let service = AnalyticsService.shared
            let portfolioAnalytics = service.computePortfolioAnalytics(modelContext: modelContext)
            let confDist = service.computeConfidenceDistribution(modelContext: modelContext)
            
            await MainActor.run {
                self.analytics = portfolioAnalytics
                self.confidenceDistribution = confDist
                self.isLoading = false
            }
        }
    }
    
    private func healthColor(for score: Int) -> Color {
        if score >= 70 { return .green }
        if score >= 50 { return .blue }
        if score >= 30 { return .orange }
        return .red
    }
    
    private func healthLabel(for score: Int) -> String {
        if score >= 70 { return "Strong" }
        if score >= 50 { return "Moderate" }
        if score >= 30 { return "Weak" }
        return "Critical"
    }
    
    private func confidenceColor(for level: Int) -> Color {
        switch level {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .blue
        case 5: return .green
        default: return .gray
        }
    }
}

// MARK: - Chart Data Types

struct StatusChartData: Identifiable {
    let id = UUID()
    let status: String
    let count: Int
    let color: Color
}

struct ConfidenceChartData: Identifiable {
    let id = UUID()
    let level: Int
    let count: Int
    
    var levelLabel: String {
        ConfidenceLevel(rawValue: level)?.displayName ?? "\(level)"
    }
}

// MARK: - Preview

#Preview {
    PortfolioHealthDashboardView()
        .modelContainer(for: [Asset.self, ResearchQuestion.self, Driver.self, Evidence.self, ResearchTask.self, ReviewReminder.self], inMemory: true)
}

