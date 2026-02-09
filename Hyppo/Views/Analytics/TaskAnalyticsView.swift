/**
 TaskAnalyticsView displays task-related analytics.
 
 Features:
 - Task completion metrics and rates
 - Inbox health indicator
 - Stale tasks warning
 - Completion time statistics
 - Task backlog by research question
 - Burndown visualization
 */

import SwiftUI
import SwiftData
import Charts

struct TaskAnalyticsView: View {
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - State
    
    @State private var analytics: TaskAnalytics?
    @State private var timeAnalytics: TimeAnalytics?
    @State private var isLoading = true
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if isLoading {
                    loadingView
                } else if let analytics = analytics {
                    // Header metrics
                    taskMetricsHeader(analytics)
                    
                    // Completion chart and stats
                    HStack(alignment: .top, spacing: 20) {
                        completionRateChart(analytics)
                        completionTimeStats(analytics)
                    }
                    
                    // Tasks by week chart
                    if let timeAnalytics = timeAnalytics {
                        tasksCompletedChart(timeAnalytics)
                    }
                    
                    // Task backlog by question
                    taskBacklogSection(analytics)
                    
                    // Stale tasks warning
                    if analytics.staleTasks > 0 {
                        staleTasksWarning(analytics)
                    }
                } else {
                    emptyStateView
                }
            }
            .padding(20)
        }
        .background(Color.surface)
        .onAppear(perform: loadAnalytics)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading task analytics...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checklist")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            
            Text("No Task Data")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("Start adding tasks to your research to see analytics")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    // MARK: - Task Metrics Header
    
    private func taskMetricsHeader(_ analytics: TaskAnalytics) -> some View {
        HStack(spacing: 16) {
            // Completion rate gauge
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(Color.statusArchived.opacity(0.2), lineWidth: 10)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(analytics.completionRate) / 100)
                        .stroke(
                            completionColor(for: analytics.completionRate),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 0) {
                        Text(String(format: "%.0f%%", analytics.completionRate))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(completionColor(for: analytics.completionRate))
                        Text("Done")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Text("Completion Rate")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Key metrics
            VStack(spacing: 12) {
                HStack(spacing: 20) {
                    metricCard(
                        value: "\(analytics.totalTasks)",
                        label: "Total Tasks",
                        icon: "checklist",
                        color: Color.accentColor
                    )
                    
                    metricCard(
                        value: "\(analytics.completedTasks)",
                        label: "Completed",
                        icon: "checkmark.circle.fill",
                        color: Color.statusActive
                    )
                    
                    metricCard(
                        value: "\(analytics.openTasks)",
                        label: "Open",
                        icon: "circle",
                        color: Color.statusOnHold
                    )
                    
                    metricCard(
                        value: "\(analytics.inboxTasks)",
                        label: "Inbox",
                        icon: "tray.fill",
                        color: analytics.inboxTasks > 5 ? Color.statusOnHold : .blue
                    )
                }
                
                HStack(spacing: 20) {
                    metricCard(
                        value: "\(analytics.staleTasks)",
                        label: "Stale (>30d)",
                        icon: "clock.badge.exclamationmark",
                        color: analytics.staleTasks > 0 ? Color.statusInvalidated : .green
                    )
                }
            }
            
            Spacer()
        }
        .padding(20)
        .background(Color.surface)
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
    
    // MARK: - Completion Rate Chart
    
    private func completionRateChart(_ analytics: TaskAnalytics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Task Status")
                .font(.headline)
            
            if analytics.totalTasks == 0 {
                emptyChartPlaceholder
            } else {
                let chartData = [
                    TaskStatusChartData(status: "Completed", count: analytics.completedTasks, color: Color.statusActive),
                    TaskStatusChartData(status: "Open", count: analytics.openTasks - analytics.staleTasks, color: Color.accentColor),
                    TaskStatusChartData(status: "Stale", count: analytics.staleTasks, color: Color.statusInvalidated),
                    TaskStatusChartData(status: "Inbox", count: analytics.inboxTasks, color: Color.accentColor)
                ].filter { $0.count > 0 }
                
                Chart(chartData) { item in
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
                .frame(height: 180)
                
                // Legend
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(chartData) { item in
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
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    // MARK: - Completion Time Stats
    
    private func completionTimeStats(_ analytics: TaskAnalytics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Completion Time")
                .font(.headline)
            
            if analytics.completedTasks == 0 {
                VStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.title)
                        .foregroundStyle(.tertiary)
                    Text("No completed tasks yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 180)
            } else {
                VStack(spacing: 16) {
                    // Average
                    if let avg = analytics.averageCompletionDays {
                        statRow(
                            label: "Average",
                            value: String(format: "%.1f days", avg),
                            icon: "chart.line.uptrend.xyaxis",
                            color: Color.accentColor
                        )
                    }
                    
                    // Fastest
                    if let fastest = analytics.fastestCompletionDays {
                        statRow(
                            label: "Fastest",
                            value: "\(fastest) \(fastest == 1 ? "day" : "days")",
                            icon: "hare.fill",
                            color: Color.statusActive
                        )
                    }
                    
                    // Slowest
                    if let slowest = analytics.slowestCompletionDays {
                        statRow(
                            label: "Slowest",
                            value: "\(slowest) \(slowest == 1 ? "day" : "days")",
                            icon: "tortoise.fill",
                            color: Color.statusOnHold
                        )
                    }
                }
                .frame(height: 180)
                
                // Insight
                if let avg = analytics.averageCompletionDays {
                    HStack(spacing: 6) {
                        Image(systemName: avg <= 7 ? "checkmark.circle.fill" : "info.circle.fill")
                            .foregroundStyle(avg <= 7 ? Color.statusActive : .blue)
                        Text(completionTimeInsight(avg))
                            .font(.caption)
                    }
                    .padding(8)
                    .background((avg <= 7 ? Color.statusActive : Color.accentColor).opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private func statRow(label: String, value: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
    
    // MARK: - Tasks Completed Chart
    
    private func tasksCompletedChart(_ timeAnalytics: TimeAnalytics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tasks Completed by Week")
                .font(.headline)
            
            if timeAnalytics.tasksCompletedByWeek.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar")
                        .font(.title)
                        .foregroundStyle(.tertiary)
                    Text("No completion data in the last 90 days")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 150)
            } else {
                Chart(timeAnalytics.tasksCompletedByWeek) { dataPoint in
                    BarMark(
                        x: .value("Week", dataPoint.label),
                        y: .value("Count", dataPoint.count)
                    )
                    .foregroundStyle(Color.statusActive.gradient)
                    .annotation(position: .top) {
                        if dataPoint.count > 0 {
                            Text("\(dataPoint.count)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel(orientation: .verticalReversed)
                    }
                }
                .frame(height: 150)
                
                // Summary
                let total = timeAnalytics.tasksCompletedByWeek.reduce(0) { $0 + $1.count }
                let weeks = timeAnalytics.tasksCompletedByWeek.count
                if weeks > 0 {
                    HStack {
                        Text("\(total) tasks completed in \(weeks) weeks")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text("Avg: \(String(format: "%.1f", Double(total) / Double(weeks)))/week")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    // MARK: - Task Backlog Section
    
    private func taskBacklogSection(_ analytics: TaskAnalytics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Task Backlog by Research Question")
                .font(.headline)
            
            if analytics.tasksByQuestion.isEmpty {
                Text("No tasks assigned to research questions")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(24)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(analytics.tasksByQuestion.prefix(8).enumerated()), id: \.offset) { index, item in
                        let (question, total, completed) = item
                        taskBacklogRow(question: question, total: total, completed: completed, rank: index + 1)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private func taskBacklogRow(question: ResearchQuestion, total: Int, completed: Int, rank: Int) -> some View {
        HStack(spacing: 12) {
            Text("\(rank).")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .frame(width: 20)
            
            // Asset ticker badge
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
            
            // Progress bar
            let progress = total > 0 ? Double(completed) / Double(total) : 0
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.statusArchived.opacity(0.2))
                    
                    Rectangle()
                        .fill(progress >= 1 ? Color.statusActive : Color.accentColor)
                        .frame(width: geometry.size.width * CGFloat(progress))
                }
                .clipShape(RoundedRectangle(cornerRadius: 3))
            }
            .frame(width: 60, height: 8)
            
            Text("\(completed)/\(total)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(completed == total ? Color.statusActive : .primary)
                .frame(width: 40, alignment: .trailing)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
    
    // MARK: - Stale Tasks Warning
    
    private func staleTasksWarning(_ analytics: TaskAnalytics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.statusInvalidated)
                Text("Stale Tasks Warning")
                    .font(.headline)
            }
            
            Text("\(analytics.staleTasks) task\(analytics.staleTasks == 1 ? "" : "s") have been open for over 30 days. Consider reviewing or archiving them.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 12) {
                Button("Review Tasks") {
                    // Would navigate to tasks list
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.statusInvalidated.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    // MARK: - Empty Chart Placeholder
    
    private var emptyChartPlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.pie")
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
            let taskAnalytics = service.computeTaskAnalytics(modelContext: modelContext)
            let timeAnal = service.computeTimeAnalytics(modelContext: modelContext)
            
            await MainActor.run {
                self.analytics = taskAnalytics
                self.timeAnalytics = timeAnal
                self.isLoading = false
            }
        }
    }
    
    private func completionColor(for rate: Double) -> Color {
        if rate >= 75 { return Color.statusActive }
        if rate >= 50 { return Color.accentColor }
        if rate >= 25 { return Color.statusOnHold }
        return .statusInvalidated
    }
    
    private func completionTimeInsight(_ avgDays: Double) -> String {
        if avgDays <= 1 { return "Excellent! Tasks are completed very quickly" }
        if avgDays <= 3 { return "Good pace - tasks are moving efficiently" }
        if avgDays <= 7 { return "Tasks complete within a week on average" }
        if avgDays <= 14 { return "Consider breaking down larger tasks" }
        return "Tasks are taking longer than expected"
    }
}

// MARK: - Chart Data Types

struct TaskStatusChartData: Identifiable {
    let id = UUID()
    let status: String
    let count: Int
    let color: Color
}

// MARK: - Preview

#Preview {
    TaskAnalyticsView()
        .modelContainer(for: [Asset.self, ResearchQuestion.self, Driver.self, ResearchTask.self], inMemory: true)
}

