/**
 RiskAlertsDashboardView displays proactive risk alerts and warnings.
 
 Features:
 - Alert cards organized by severity (Critical/Warning/Info)
 - Alert type breakdown
 - Quick actions for common remediation
 - Historical alert trends (if data available)
 */

import SwiftUI
import SwiftData
import Charts

struct RiskAlertsDashboardView: View {
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - State
    
    @State private var alerts: [RiskAlert] = []
    @State private var isLoading = true
    @State private var selectedSeverity: RiskAlert.AlertSeverity? = nil
    @State private var selectedType: RiskAlert.RiskAlertType? = nil
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if isLoading {
                    loadingView
                } else if alerts.isEmpty {
                    allClearView
                } else {
                    // Summary header
                    alertSummaryHeader
                    
                    // Filters
                    filterBar
                    
                    // Alert type breakdown
                    HStack(alignment: .top, spacing: 20) {
                        alertTypesChart
                        severityBreakdownChart
                    }
                    
                    // Alert list
                    alertListSection
                }
            }
            .padding(20)
        }
        .background(Color.surface)
        .onAppear(perform: loadAlerts)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Scanning for risks...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - All Clear View
    
    private var allClearView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.statusActive)
            
            Text("All Clear!")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("No risk alerts detected. Your research portfolio is in good shape.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            // Quick stats
            HStack(spacing: 24) {
                VStack {
                    Image(systemName: "doc.text.fill")
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                    Text("Research Active")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                VStack {
                    Image(systemName: "clock.fill")
                        .font(.title2)
                        .foregroundStyle(Color.statusActive)
                    Text("Reviews On Time")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                VStack {
                    Image(systemName: "eye.fill")
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                    Text("No Blind Spots")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    // MARK: - Alert Summary Header
    
    private var alertSummaryHeader: some View {
        HStack(spacing: 16) {
            // Alert icon based on highest severity
            let highestSeverity = alerts.map { $0.severity }.max() ?? .info
            
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(severityColor(highestSeverity).opacity(0.15))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: highestSeverity.iconName)
                        .font(.system(size: 36))
                        .foregroundStyle(severityColor(highestSeverity))
                }
                
                Text(severityLabel(highestSeverity))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(severityColor(highestSeverity))
            }
            
            // Summary counts
            VStack(alignment: .leading, spacing: 12) {
                Text("Risk Alerts")
                    .font(.headline)
                
                HStack(spacing: 20) {
                    severityCount(severity: .critical, count: alertCount(for: .critical))
                    severityCount(severity: .warning, count: alertCount(for: .warning))
                    severityCount(severity: .info, count: alertCount(for: .info))
                }
                
                Text("\(alerts.count) total alert\(alerts.count == 1 ? "" : "s") requiring attention")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Refresh button
            Button(action: loadAlerts) {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
        }
        .padding(20)
        .background(severityColor(alerts.map { $0.severity }.max() ?? .info).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func severityCount(severity: RiskAlert.AlertSeverity, count: Int) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(severityColor(severity))
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 0) {
                Text("\(count)")
                    .font(.title3)
                    .fontWeight(.bold)
                Text(severity == .critical ? "Critical" : severity == .warning ? "Warning" : "Info")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Filter Bar
    
    private var filterBar: some View {
        HStack(spacing: 12) {
            Text("Filter:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            // Severity filter
            Menu {
                Button("All Severities") {
                    selectedSeverity = nil
                }
                Divider()
                ForEach([RiskAlert.AlertSeverity.critical, .warning, .info], id: \.self) { severity in
                    Button {
                        selectedSeverity = severity
                    } label: {
                        Label(
                            severity == .critical ? "Critical" : severity == .warning ? "Warning" : "Info",
                            systemImage: severity.iconName
                        )
                    }
                }
            } label: {
                HStack {
                    if let selected = selectedSeverity {
                        Circle()
                            .fill(severityColor(selected))
                            .frame(width: 8, height: 8)
                        Text(selected == .critical ? "Critical" : selected == .warning ? "Warning" : "Info")
                    } else {
                        Text("All Severities")
                    }
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .font(.subheadline)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            
            // Type filter
            Menu {
                Button("All Types") {
                    selectedType = nil
                }
                Divider()
                ForEach(uniqueAlertTypes, id: \.self) { type in
                    Button(type.rawValue) {
                        selectedType = type
                    }
                }
            } label: {
                HStack {
                    Text(selectedType?.rawValue ?? "All Types")
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .font(.subheadline)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Clear filters
            if selectedSeverity != nil || selectedType != nil {
                Button("Clear Filters") {
                    selectedSeverity = nil
                    selectedType = nil
                }
                .font(.subheadline)
            }
        }
    }
    
    private var uniqueAlertTypes: [RiskAlert.RiskAlertType] {
        Array(Set(alerts.map { $0.type })).sorted { $0.rawValue < $1.rawValue }
    }
    
    // MARK: - Alert Types Chart
    
    private var alertTypesChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Alert Types")
                .font(.headline)
            
            let typeData = Dictionary(grouping: alerts, by: { $0.type })
                .map { AlertTypeChartData(type: $0.key.rawValue, count: $0.value.count) }
                .sorted { $0.count > $1.count }
            
            Chart(typeData) { item in
                BarMark(
                    x: .value("Count", item.count),
                    y: .value("Type", item.type)
                )
                .foregroundStyle(Color.statusOnHold.gradient)
                .annotation(position: .trailing) {
                    Text("\(item.count)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .chartXAxis(.hidden)
            .frame(height: CGFloat(typeData.count * 30 + 20))
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    // MARK: - Severity Breakdown Chart
    
    private var severityBreakdownChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Severity Breakdown")
                .font(.headline)
            
            let criticalCount = alertCount(for: .critical)
            let warningCount = alertCount(for: .warning)
            let infoCount = alertCount(for: .info)
            
            let chartData = [
                SeverityChartData(severity: "Critical", count: criticalCount, color: Color.statusInvalidated),
                SeverityChartData(severity: "Warning", count: warningCount, color: Color.statusOnHold),
                SeverityChartData(severity: "Info", count: infoCount, color: Color.accentColor)
            ].filter { $0.count > 0 }
            
            if chartData.isEmpty {
                Text("No alerts")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
            } else {
                Chart(chartData) { item in
                    SectorMark(
                        angle: .value("Count", item.count),
                        innerRadius: .ratio(0.6),
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
                            Text(item.severity)
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
    
    // MARK: - Alert List Section
    
    private var alertListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Active Alerts")
                    .font(.headline)
                
                Spacer()
                
                Text("\(filteredAlerts.count) alert\(filteredAlerts.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            if filteredAlerts.isEmpty {
                Text("No alerts match the current filters")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(24)
            } else {
                VStack(spacing: 8) {
                    ForEach(filteredAlerts) { alert in
                        alertCard(alert)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private var filteredAlerts: [RiskAlert] {
        alerts.filter { alert in
            let matchesSeverity = selectedSeverity == nil || alert.severity == selectedSeverity
            let matchesType = selectedType == nil || alert.type == selectedType
            return matchesSeverity && matchesType
        }
    }
    
    private func alertCard(_ alert: RiskAlert) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Severity indicator
            VStack {
                Image(systemName: alert.severity.iconName)
                    .font(.title2)
                    .foregroundStyle(severityColor(alert.severity))
            }
            .frame(width: 32)
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(alert.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    // Alert type badge
                    Text(alert.type.rawValue)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.statusArchived.opacity(0.15))
                        .clipShape(Capsule())
                }
                
                Text(alert.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                
                // Related question
                if let question = alert.relatedQuestion {
                    HStack(spacing: 6) {
                        if let asset = question.asset {
                            Text(asset.ticker)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.accentColor.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        
                        Text(question.questionText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .padding(.top, 2)
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(severityColor(alert.severity).opacity(0.05))
        .overlay(
            Rectangle()
                .fill(severityColor(alert.severity))
                .frame(width: 4),
            alignment: .leading
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - Helper Methods
    
    private func loadAlerts() {
        isLoading = true
        Task {
            let service = AnalyticsService.shared
            let riskAlerts = service.generateRiskAlerts(modelContext: modelContext)
            
            await MainActor.run {
                self.alerts = riskAlerts
                self.isLoading = false
            }
        }
    }
    
    private func alertCount(for severity: RiskAlert.AlertSeverity) -> Int {
        alerts.filter { $0.severity == severity }.count
    }
    
    private func severityColor(_ severity: RiskAlert.AlertSeverity) -> Color {
        switch severity {
        case .critical: return .statusInvalidated
        case .warning: return .statusOnHold
        case .info: return Color.accentColor
        }
    }
    
    private func severityLabel(_ severity: RiskAlert.AlertSeverity) -> String {
        switch severity {
        case .critical: return "Critical Alerts"
        case .warning: return "Warnings Active"
        case .info: return "Info Available"
        }
    }
}

// MARK: - Chart Data Types

struct AlertTypeChartData: Identifiable {
    let id = UUID()
    let type: String
    let count: Int
}

struct SeverityChartData: Identifiable {
    let id = UUID()
    let severity: String
    let count: Int
    let color: Color
}

// MARK: - Preview

#Preview {
    RiskAlertsDashboardView()
        .modelContainer(for: [Asset.self, ResearchQuestion.self, Driver.self, Evidence.self, ReviewReminder.self], inMemory: true)
}

