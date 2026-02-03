/**
 ReviewAnalyticsView displays review schedule metrics and upcoming review calendar.
 
 Features:
 - Review adherence metrics (due, overdue, on-time rate)
 - Upcoming reviews calendar/timeline
 - Review outcome history (reinforce/revise/invalidate)
 - Snooze pattern analysis
 */

import SwiftUI
import SwiftData
import Charts

struct ReviewAnalyticsView: View {
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - State
    
    @State private var analytics: ReviewAnalytics?
    @State private var isLoading = true
    @State private var selectedTimeRange: TimeRange = .twoWeeks
    
    enum TimeRange: String, CaseIterable {
        case oneWeek = "7 Days"
        case twoWeeks = "14 Days"
        case oneMonth = "30 Days"
        
        var days: Int {
            switch self {
            case .oneWeek: return 7
            case .twoWeeks: return 14
            case .oneMonth: return 30
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if isLoading {
                    loadingView
                } else if let analytics = analytics {
                    // Header metrics
                    reviewMetricsHeader(analytics)
                    
                    // Upcoming reviews section
                    upcomingReviewsSection(analytics)
                    
                    // Review outcomes chart
                    HStack(alignment: .top, spacing: 20) {
                        reviewOutcomesChart(analytics)
                        reviewAdherenceChart(analytics)
                    }
                    
                    // Days since review distribution
                    daysSinceReviewSection(analytics)
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
            Text("Loading review analytics...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            
            Text("No Review Data")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("Set up review reminders for your research questions to see analytics")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    // MARK: - Review Metrics Header
    
    private func reviewMetricsHeader(_ analytics: ReviewAnalytics) -> some View {
        HStack(spacing: 16) {
            // Adherence gauge
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(analytics.adherenceRate) / 100)
                        .stroke(
                            adherenceColor(for: analytics.adherenceRate),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 0) {
                        Text(String(format: "%.0f%%", analytics.adherenceRate))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                        Text("On Time")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Text("Review Adherence")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Key metrics
            VStack(spacing: 12) {
                HStack(spacing: 20) {
                    metricBox(
                        value: "\(analytics.dueReviews)",
                        label: "Due Now",
                        icon: "clock.fill",
                        color: analytics.dueReviews > 0 ? .orange : .green
                    )
                    
                    metricBox(
                        value: "\(analytics.overdueReviews)",
                        label: "Overdue",
                        icon: "exclamationmark.circle.fill",
                        color: analytics.overdueReviews > 0 ? .red : .green
                    )
                    
                    metricBox(
                        value: "\(analytics.snoozedReviews)",
                        label: "Snoozed",
                        icon: "moon.fill",
                        color: .purple
                    )
                    
                    metricBox(
                        value: "\(analytics.reviewsSoonCount)",
                        label: "Due Soon (3d)",
                        icon: "calendar.badge.clock",
                        color: .blue
                    )
                }
                
                HStack(spacing: 20) {
                    metricBox(
                        value: "\(analytics.enabledReminders)",
                        label: "Active Reminders",
                        icon: "bell.fill",
                        color: .green
                    )
                    
                    metricBox(
                        value: String(format: "%.1f", analytics.averageSnoozeCount),
                        label: "Avg Snoozes",
                        icon: "arrow.clockwise",
                        color: .orange
                    )
                }
            }
            
            Spacer()
        }
        .padding(20)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func metricBox(value: String, label: String, icon: String, color: Color) -> some View {
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
    
    // MARK: - Upcoming Reviews Section
    
    private func upcomingReviewsSection(_ analytics: ReviewAnalytics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Upcoming Reviews")
                    .font(.headline)
                
                Spacer()
                
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            
            let filteredReviews = analytics.upcomingReviews.filter { reminder, _ in
                guard let days = reminder.daysUntilDue else { return false }
                return days <= selectedTimeRange.days
            }
            
            if filteredReviews.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.title)
                        .foregroundStyle(.green)
                    Text("No reviews scheduled in this period")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
            } else {
                // Timeline view
                VStack(spacing: 0) {
                    ForEach(Array(filteredReviews.enumerated()), id: \.offset) { index, item in
                        let (reminder, question) = item
                        reviewTimelineItem(reminder: reminder, question: question, isLast: index == filteredReviews.count - 1)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private func reviewTimelineItem(reminder: ReviewReminder, question: ResearchQuestion, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Timeline indicator
            VStack(spacing: 0) {
                Circle()
                    .fill(urgencyColor(for: reminder))
                    .frame(width: 12, height: 12)
                
                if !isLast {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2)
                        .frame(minHeight: 40)
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
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
                    
                    // Due date badge
                    if let days = reminder.daysUntilDue {
                        Text(dueDateLabel(days: days))
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(urgencyColor(for: reminder).opacity(0.15))
                            .foregroundStyle(urgencyColor(for: reminder))
                            .clipShape(Capsule())
                    }
                }
                
                HStack(spacing: 12) {
                    Label(reminder.cadence.displayName, systemImage: "repeat")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if reminder.isSnoozed {
                        Label("Snoozed", systemImage: "moon.fill")
                            .font(.caption)
                            .foregroundStyle(.purple)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .padding(.horizontal, 8)
    }
    
    // MARK: - Review Outcomes Chart
    
    private func reviewOutcomesChart(_ analytics: ReviewAnalytics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Review Outcomes")
                .font(.headline)
            
            let outcomes = analytics.reviewOutcomes
            let total = outcomes.values.reduce(0, +)
            
            if total == 0 {
                VStack(spacing: 8) {
                    Image(systemName: "chart.pie")
                        .font(.title)
                        .foregroundStyle(.tertiary)
                    Text("No reviews completed yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 150)
            } else {
                let chartData = [
                    OutcomeChartData(outcome: "Reinforce", count: outcomes[.reinforce] ?? 0, color: .green),
                    OutcomeChartData(outcome: "Revise", count: outcomes[.revise] ?? 0, color: .orange),
                    OutcomeChartData(outcome: "Invalidate", count: outcomes[.invalidate] ?? 0, color: .red)
                ].filter { $0.count > 0 }
                
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
                            Text(item.outcome)
                                .font(.caption)
                            Spacer()
                            Text("\(item.count)")
                                .font(.caption)
                                .fontWeight(.medium)
                            Text("(\(Int(Double(item.count) / Double(total) * 100))%)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    // MARK: - Review Adherence Chart
    
    private func reviewAdherenceChart(_ analytics: ReviewAnalytics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Review Status")
                .font(.headline)
            
            let total = analytics.enabledReminders
            let onTime = total - analytics.overdueReviews
            
            if total == 0 {
                VStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.title)
                        .foregroundStyle(.tertiary)
                    Text("No reminders set up")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 150)
            } else {
                // Stacked bar
                VStack(spacing: 8) {
                    GeometryReader { geometry in
                        HStack(spacing: 2) {
                            Rectangle()
                                .fill(Color.green)
                                .frame(width: geometry.size.width * CGFloat(onTime) / CGFloat(total))
                            Rectangle()
                                .fill(Color.red)
                                .frame(width: geometry.size.width * CGFloat(analytics.overdueReviews) / CGFloat(total))
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .frame(height: 24)
                    
                    HStack {
                        HStack(spacing: 4) {
                            Circle().fill(.green).frame(width: 8, height: 8)
                            Text("On Time: \(onTime)")
                                .font(.caption)
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            Circle().fill(.red).frame(width: 8, height: 8)
                            Text("Overdue: \(analytics.overdueReviews)")
                                .font(.caption)
                        }
                    }
                    .foregroundStyle(.secondary)
                }
                .frame(height: 150)
                
                // Cadence breakdown
                Text("By Cadence")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.top, 8)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    // MARK: - Days Since Review Section
    
    private func daysSinceReviewSection(_ analytics: ReviewAnalytics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Days Since Last Review")
                .font(.headline)
            
            let distribution = analytics.daysSinceReviewDistribution
            
            if distribution.isEmpty {
                Text("No review history available")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(24)
            } else {
                // Create histogram buckets
                let buckets = createHistogramBuckets(from: distribution)
                
                Chart(buckets) { bucket in
                    BarMark(
                        x: .value("Days", bucket.label),
                        y: .value("Count", bucket.count)
                    )
                    .foregroundStyle(bucket.color)
                }
                .frame(height: 120)
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel()
                    }
                }
                
                // Summary stats
                HStack(spacing: 24) {
                    if let min = distribution.min() {
                        VStack(alignment: .leading) {
                            Text("\(min)")
                                .font(.title3)
                                .fontWeight(.bold)
                            Text("Min Days")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if !distribution.isEmpty {
                        let avg = distribution.reduce(0, +) / distribution.count
                        VStack(alignment: .leading) {
                            Text("\(avg)")
                                .font(.title3)
                                .fontWeight(.bold)
                            Text("Avg Days")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if let max = distribution.max() {
                        VStack(alignment: .leading) {
                            Text("\(max)")
                                .font(.title3)
                                .fontWeight(.bold)
                            Text("Max Days")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    // MARK: - Helper Methods
    
    private func loadAnalytics() {
        Task {
            let service = AnalyticsService.shared
            let reviewAnalytics = service.computeReviewAnalytics(modelContext: modelContext)
            
            await MainActor.run {
                self.analytics = reviewAnalytics
                self.isLoading = false
            }
        }
    }
    
    private func adherenceColor(for rate: Double) -> Color {
        if rate >= 80 { return .green }
        if rate >= 60 { return .blue }
        if rate >= 40 { return .orange }
        return .red
    }
    
    private func urgencyColor(for reminder: ReviewReminder) -> Color {
        guard let days = reminder.daysUntilDue else { return .gray }
        if days < 0 { return .red }
        if days == 0 { return .orange }
        if days <= 3 { return .yellow }
        return .green
    }
    
    private func dueDateLabel(days: Int) -> String {
        if days < 0 { return "Overdue \(abs(days))d" }
        if days == 0 { return "Today" }
        if days == 1 { return "Tomorrow" }
        return "In \(days) days"
    }
    
    private func createHistogramBuckets(from distribution: [Int]) -> [HistogramBucket] {
        var buckets: [String: Int] = [
            "0-7": 0,
            "8-14": 0,
            "15-30": 0,
            "31-60": 0,
            "60+": 0
        ]
        
        for days in distribution {
            switch days {
            case 0...7: buckets["0-7", default: 0] += 1
            case 8...14: buckets["8-14", default: 0] += 1
            case 15...30: buckets["15-30", default: 0] += 1
            case 31...60: buckets["31-60", default: 0] += 1
            default: buckets["60+", default: 0] += 1
            }
        }
        
        return [
            HistogramBucket(label: "0-7", count: buckets["0-7"] ?? 0, color: .green),
            HistogramBucket(label: "8-14", count: buckets["8-14"] ?? 0, color: .blue),
            HistogramBucket(label: "15-30", count: buckets["15-30"] ?? 0, color: .yellow),
            HistogramBucket(label: "31-60", count: buckets["31-60"] ?? 0, color: .orange),
            HistogramBucket(label: "60+", count: buckets["60+"] ?? 0, color: .red)
        ]
    }
}

// MARK: - Chart Data Types

struct OutcomeChartData: Identifiable {
    let id = UUID()
    let outcome: String
    let count: Int
    let color: Color
}

struct HistogramBucket: Identifiable {
    let id = UUID()
    let label: String
    let count: Int
    let color: Color
}

// MARK: - Preview

#Preview {
    ReviewAnalyticsView()
        .modelContainer(for: [Asset.self, ResearchQuestion.self, ReviewReminder.self, LogEntry.self], inMemory: true)
}

