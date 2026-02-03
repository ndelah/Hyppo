/**
 AnalyticsDashboardView is the main analytics container with tab navigation.
 
 Features:
 - Sidebar navigation for different analytics sections
 - Portfolio Health overview (default)
 - Evidence, Task, Driver, Review analytics
 - Risk Alerts dashboard
 */

import SwiftUI
import SwiftData

/// Analytics section tabs
enum AnalyticsSection: String, CaseIterable, Identifiable {
    case portfolio = "Portfolio Health"
    case evidence = "Evidence"
    case tasks = "Tasks"
    case drivers = "Drivers"
    case reviews = "Reviews"
    case alerts = "Risk Alerts"
    
    var id: String { rawValue }
    
    /// SF Symbol icon for the section
    var iconName: String {
        switch self {
        case .portfolio: return "chart.pie.fill"
        case .evidence: return "doc.text.fill"
        case .tasks: return "checklist"
        case .drivers: return "target"
        case .reviews: return "calendar.badge.clock"
        case .alerts: return "exclamationmark.triangle.fill"
        }
    }
    
    /// Color for the section icon
    var iconColor: Color {
        switch self {
        case .portfolio: return .blue
        case .evidence: return .purple
        case .tasks: return .green
        case .drivers: return .orange
        case .reviews: return .teal
        case .alerts: return .red
        }
    }
    
    /// Brief description of the section
    var description: String {
        switch self {
        case .portfolio: return "Overall health metrics"
        case .evidence: return "Source analysis & freshness"
        case .tasks: return "Completion & backlog"
        case .drivers: return "Validation funnel"
        case .reviews: return "Schedule & adherence"
        case .alerts: return "Proactive warnings"
        }
    }
}

struct AnalyticsDashboardView: View {
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - State
    
    @State private var selectedSection: AnalyticsSection = .portfolio
    @State private var alertCount: Int = 0
    
    // MARK: - Body
    
    var body: some View {
        HSplitView {
            // Sidebar
            sidebarView
                .frame(minWidth: 180, maxWidth: 220)
            
            // Content
            contentView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear(perform: loadAlertCount)
    }
    
    // MARK: - Sidebar View
    
    private var sidebarView: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header
            HStack {
                Image(systemName: "chart.bar.xaxis")
                    .foregroundStyle(.secondary)
                Text("Analytics")
                    .font(.headline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            Divider()
                .padding(.bottom, 8)
            
            // Section buttons
            ForEach(AnalyticsSection.allCases) { section in
                sectionButton(section)
            }
            
            Spacer()
            
            // Footer with refresh hint
            VStack(alignment: .leading, spacing: 4) {
                Divider()
                Text("Data refreshes automatically")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }
        }
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    private func sectionButton(_ section: AnalyticsSection) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedSection = section
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: section.iconName)
                    .font(.subheadline)
                    .foregroundStyle(selectedSection == section ? section.iconColor : .secondary)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 1) {
                    HStack {
                        Text(section.rawValue)
                            .font(.subheadline)
                            .fontWeight(selectedSection == section ? .medium : .regular)
                        
                        // Badge for alerts
                        if section == .alerts && alertCount > 0 {
                            Text("\(alertCount)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(alertCount > 0 ? Color.red : Color.gray)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(section.description)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                selectedSection == section
                    ? section.iconColor.opacity(0.1)
                    : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
    }
    
    // MARK: - Content View
    
    @ViewBuilder
    private var contentView: some View {
        switch selectedSection {
        case .portfolio:
            PortfolioHealthDashboardView()
        case .evidence:
            EvidenceAnalyticsView()
        case .tasks:
            TaskAnalyticsView()
        case .drivers:
            DriverAnalyticsView()
        case .reviews:
            ReviewAnalyticsView()
        case .alerts:
            RiskAlertsDashboardView()
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadAlertCount() {
        Task {
            let alerts = AnalyticsService.shared.generateRiskAlerts(modelContext: modelContext)
            await MainActor.run {
                self.alertCount = alerts.count
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AnalyticsDashboardView()
        .modelContainer(for: [
            Asset.self,
            ResearchQuestion.self,
            Driver.self,
            Evidence.self,
            ResearchTask.self,
            LogEntry.self,
            ReviewReminder.self,
            Tag.self
        ], inMemory: true)
}

