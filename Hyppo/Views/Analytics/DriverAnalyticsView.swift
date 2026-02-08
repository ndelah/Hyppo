/**
 DriverAnalyticsView displays driver/assumption validation funnel analytics.
 
 Features:
 - Validation funnel visualization (Under Review → Confirmed/Discarded)
 - Evidence coverage metrics
 - Blind spot analysis
 - Confirmation bias detection
 - Driver status by research question
 */

import SwiftUI
import SwiftData
import Charts

struct DriverAnalyticsView: View {
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - State
    
    @State private var analytics: DriverAnalytics?
    @State private var isLoading = true
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if isLoading {
                    loadingView
                } else if let analytics = analytics {
                    // Header metrics
                    driverMetricsHeader(analytics)
                    
                    // Funnel and coverage charts
                    HStack(alignment: .top, spacing: 20) {
                        validationFunnelChart(analytics)
                        evidenceCoverageChart(analytics)
                    }
                    
                    // Status distribution chart
                    statusDistributionChart(analytics)
                    
                    // Drivers by research question
                    driversByQuestionSection(analytics)
                    
                    // Confirmation bias warning
                    if shouldShowBiasWarning(analytics) {
                        confirmationBiasWarning(analytics)
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
            Text("Loading driver analytics...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "target")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            
            Text("No Driver Data")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("Add assumptions/drivers to your research questions to see analytics")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    // MARK: - Driver Metrics Header
    
    private func driverMetricsHeader(_ analytics: DriverAnalytics) -> some View {
        HStack(spacing: 16) {
            // Validation progress gauge
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(analytics.validationProgress) / 100)
                        .stroke(
                            validationColor(for: analytics.validationProgress),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 0) {
                        Text(String(format: "%.0f%%", analytics.validationProgress))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(validationColor(for: analytics.validationProgress))
                        Text("Validated")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Text("Validation Progress")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Key metrics
            VStack(spacing: 12) {
                HStack(spacing: 20) {
                    metricCard(
                        value: "\(analytics.totalDrivers)",
                        label: "Total Drivers",
                        icon: "target",
                        color: .blue
                    )
                    
                    metricCard(
                        value: "\(analytics.pendingDrivers)",
                        label: "Under Review",
                        icon: "circle.dashed",
                        color: .gray
                    )
                    
                    metricCard(
                        value: "\(analytics.confirmedDrivers)",
                        label: "Confirmed",
                        icon: "checkmark.seal.fill",
                        color: .green
                    )
                    
                    metricCard(
                        value: "\(analytics.discardedDrivers)",
                        label: "Discarded",
                        icon: "xmark.seal.fill",
                        color: .red
                    )
                }
                
                HStack(spacing: 20) {
                    metricCard(
                        value: "\(analytics.needsRevisionDrivers)",
                        label: "Needs Revision",
                        icon: "exclamationmark.circle.fill",
                        color: .orange
                    )
                    
                    metricCard(
                        value: String(format: "%.0f%%", analytics.evidenceCoverage),
                        label: "Evidence Coverage",
                        icon: "doc.text.fill",
                        color: analytics.evidenceCoverage >= 70 ? .green : .orange
                    )
                    
                    metricCard(
                        value: "\(analytics.driversWithBlindSpots)",
                        label: "Blind Spots",
                        icon: "eye.slash.fill",
                        color: analytics.driversWithBlindSpots > 0 ? .orange : .green
                    )
                }
            }
            
            Spacer()
        }
        .padding(20)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func metricCard(value: String, label: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - Validation Funnel Chart
    
    private func validationFunnelChart(_ analytics: DriverAnalytics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Validation Funnel")
                .font(.headline)
            
            if analytics.totalDrivers == 0 {
                emptyChartPlaceholder
            } else {
                VStack(spacing: 8) {
                    // Funnel visualization
                    funnelBar(
                        label: "Total",
                        count: analytics.totalDrivers,
                        maxCount: analytics.totalDrivers,
                        color: .blue
                    )
                    
                    funnelBar(
                        label: "Tested",
                        count: analytics.totalDrivers - analytics.pendingDrivers,
                        maxCount: analytics.totalDrivers,
                        color: .purple
                    )
                    
                    funnelBar(
                        label: "Confirmed",
                        count: analytics.confirmedDrivers,
                        maxCount: analytics.totalDrivers,
                        color: .green
                    )
                    
                    funnelBar(
                        label: "Discarded",
                        count: analytics.discardedDrivers,
                        maxCount: analytics.totalDrivers,
                        color: .red
                    )
                }
                .frame(height: 180)
                
                // Conversion rates
                VStack(alignment: .leading, spacing: 4) {
                    if analytics.totalDrivers > analytics.pendingDrivers {
                        let testedCount = analytics.totalDrivers - analytics.pendingDrivers
                        HStack {
                            Text("Testing Rate:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.0f%%", Double(testedCount) / Double(analytics.totalDrivers) * 100))
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                    
                    HStack {
                        Text("Confirmation Rate:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.0f%%", analytics.confirmationRate))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.green)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private func funnelBar(label: String, count: Int, maxCount: Int, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .frame(width: 70, alignment: .leading)
            
            GeometryReader { geometry in
                let width = maxCount > 0 ? geometry.size.width * CGFloat(count) / CGFloat(maxCount) : 0
                
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                    
                    Rectangle()
                        .fill(color.gradient)
                        .frame(width: max(4, width))
                }
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .frame(height: 24)
            
            Text("\(count)")
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 30, alignment: .trailing)
        }
    }
    
    // MARK: - Evidence Coverage Chart
    
    private func evidenceCoverageChart(_ analytics: DriverAnalytics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Evidence Coverage")
                    .font(.headline)
                
                Spacer()
                
                Text(String(format: "%.0f%%", analytics.evidenceCoverage))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(analytics.evidenceCoverage >= 70 ? .green : .orange)
            }
            
            if analytics.totalDrivers == 0 {
                emptyChartPlaceholder
            } else {
                let chartData = [
                    CoverageChartData(category: "With Evidence", count: analytics.driversWithEvidence, color: .green),
                    CoverageChartData(category: "Blind Spots", count: analytics.driversWithBlindSpots, color: .orange)
                ]
                
                Chart(chartData) { item in
                    SectorMark(
                        angle: .value("Count", item.count),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(item.color)
                }
                .frame(height: 150)
                
                // Legend
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(chartData) { item in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 10, height: 10)
                            Text(item.category)
                                .font(.caption)
                            Spacer()
                            Text("\(item.count)")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
                
                // Warning if blind spots exist
                if analytics.driversWithBlindSpots > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "eye.slash.fill")
                            .foregroundStyle(.orange)
                        Text("\(analytics.driversWithBlindSpots) driver\(analytics.driversWithBlindSpots == 1 ? "" : "s") need evidence")
                            .font(.caption)
                    }
                    .padding(8)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    // MARK: - Status Distribution Chart
    
    private func statusDistributionChart(_ analytics: DriverAnalytics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Driver Status Distribution")
                .font(.headline)
            
            if analytics.totalDrivers == 0 {
                Text("No drivers to display")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(24)
            } else {
                let chartData = [
                    DriverStatusChartData(status: "Under Review", count: analytics.pendingDrivers, color: .gray),
                    DriverStatusChartData(status: "Confirmed", count: analytics.confirmedDrivers, color: .green),
                    DriverStatusChartData(status: "Discarded", count: analytics.discardedDrivers, color: .red),
                    DriverStatusChartData(status: "Needs Revision", count: analytics.needsRevisionDrivers, color: .orange)
                ].filter { $0.count > 0 }
                
                Chart(chartData) { item in
                    BarMark(
                        x: .value("Status", item.status),
                        y: .value("Count", item.count)
                    )
                    .foregroundStyle(item.color)
                    .annotation(position: .top) {
                        Text("\(item.count)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel()
                    }
                }
                .frame(height: 150)
            }
        }
        .padding(16)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    // MARK: - Drivers by Question Section
    
    private func driversByQuestionSection(_ analytics: DriverAnalytics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Drivers by Research Question")
                .font(.headline)
            
            if analytics.driversByQuestion.isEmpty {
                Text("No research questions with drivers")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(24)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(analytics.driversByQuestion.prefix(6).enumerated()), id: \.offset) { index, item in
                        let (question, drivers) = item
                        driverQuestionRow(question: question, drivers: drivers)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private func driverQuestionRow(question: ResearchQuestion, drivers: [Driver]) -> some View {
        let topLevel = drivers.filter { $0.parentDriver == nil }
        let confirmed = topLevel.filter { $0.status == .confirmed }.count
        let discarded = topLevel.filter { $0.status == .discarded }.count
        let pending = topLevel.filter { $0.status == .pending }.count
        let needsRevision = topLevel.filter { $0.status == .needsRevision }.count
        let blindSpots = topLevel.filter { $0.hasBlindSpot }.count
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let asset = question.asset {
                    Text(asset.ticker)
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.1))
                        .clipShape(Capsule())
                }
                
                Text(question.questionText)
                    .font(.subheadline)
                    .lineLimit(1)
                
                Spacer()
                
                Text("\(topLevel.count) drivers")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Status badges
            HStack(spacing: 8) {
                if confirmed > 0 {
                    statusBadge(count: confirmed, label: "Confirmed", color: .green, icon: "checkmark.seal.fill")
                }
                if discarded > 0 {
                    statusBadge(count: discarded, label: "Discarded", color: .red, icon: "xmark.seal.fill")
                }
                if pending > 0 {
                    statusBadge(count: pending, label: "Under Review", color: .gray, icon: "circle.dashed")
                }
                if needsRevision > 0 {
                    statusBadge(count: needsRevision, label: "Revision", color: .orange, icon: "exclamationmark.circle.fill")
                }
                if blindSpots > 0 {
                    statusBadge(count: blindSpots, label: "Blind Spots", color: .yellow, icon: "eye.slash")
                }
                
                Spacer()
            }
        }
        .padding(12)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func statusBadge(count: Int, label: String, color: Color, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text("\(count)")
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
        .help(label)
    }
    
    // MARK: - Confirmation Bias Warning
    
    private func confirmationBiasWarning(_ analytics: DriverAnalytics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("Potential Confirmation Bias")
                    .font(.headline)
            }
            
            Text("Your confirmation rate is very high (\(String(format: "%.0f%%", analytics.confirmationRate))). Consider actively seeking contradicting evidence to stress-test your assumptions.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 8) {
                Label("Confirmed", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                Text("\(analytics.confirmedDrivers)")
                    .fontWeight(.bold)
                
                Text("vs")
                    .foregroundStyle(.tertiary)
                
                Label("Discarded", systemImage: "xmark.seal.fill")
                    .foregroundStyle(.red)
                Text("\(analytics.discardedDrivers)")
                    .fontWeight(.bold)
            }
            .font(.caption)
            .padding(8)
            .background(Color(nsColor: .windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    // MARK: - Empty Chart Placeholder
    
    private var emptyChartPlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar")
                .font(.title)
                .foregroundStyle(.tertiary)
            Text("No data available")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
    }
    
    // MARK: - Helper Methods
    
    private func loadAnalytics() {
        Task {
            let service = AnalyticsService.shared
            let driverAnalytics = service.computeDriverAnalytics(modelContext: modelContext)
            
            await MainActor.run {
                self.analytics = driverAnalytics
                self.isLoading = false
            }
        }
    }
    
    private func validationColor(for progress: Double) -> Color {
        if progress >= 75 { return .green }
        if progress >= 50 { return .blue }
        if progress >= 25 { return .orange }
        return .gray
    }
    
    private func shouldShowBiasWarning(_ analytics: DriverAnalytics) -> Bool {
        let resolved = analytics.confirmedDrivers + analytics.discardedDrivers
        // Show warning if >80% confirmed with at least 5 resolved drivers
        return resolved >= 5 && analytics.confirmationRate > 80
    }
}

// MARK: - Chart Data Types

struct CoverageChartData: Identifiable {
    let id = UUID()
    let category: String
    let count: Int
    let color: Color
}

struct DriverStatusChartData: Identifiable {
    let id = UUID()
    let status: String
    let count: Int
    let color: Color
}

// MARK: - Preview

#Preview {
    DriverAnalyticsView()
        .modelContainer(for: [Asset.self, ResearchQuestion.self, Driver.self, Evidence.self], inMemory: true)
}

