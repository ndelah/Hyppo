/**
 EvidenceAnalyticsView displays evidence-related analytics.
 
 Features:
 - Sentiment balance breakdown (supporting/neutral/contradicting)
 - Source type distribution chart
 - Evidence type distribution
 - Top domains/sources
 - Evidence freshness analysis
 - Recent contradicting evidence alerts
 */

import SwiftUI
import SwiftData
import Charts

struct EvidenceAnalyticsView: View {
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - State
    
    @State private var analytics: EvidenceAnalytics?
    @State private var isLoading = true
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if isLoading {
                    loadingView
                } else if let analytics = analytics {
                    // Header metrics
                    evidenceMetricsHeader(analytics)
                    
                    // Charts row 1
                    HStack(alignment: .top, spacing: 20) {
                        sentimentBreakdownChart(analytics)
                        freshnessChart(analytics)
                    }
                    
                    // Charts row 2
                    HStack(alignment: .top, spacing: 20) {
                        sourceTypeChart(analytics)
                        evidenceTypeChart(analytics)
                    }
                    
                    // Top domains
                    topDomainsSection(analytics)
                    
                    // Recent contradicting evidence
                    if !analytics.recentContradicting.isEmpty {
                        recentContradictingSection(analytics)
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
            Text("Loading evidence analytics...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            
            Text("No Evidence Data")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("Start adding evidence to your research to see analytics")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    // MARK: - Evidence Metrics Header
    
    private func evidenceMetricsHeader(_ analytics: EvidenceAnalytics) -> some View {
        HStack(spacing: 16) {
            // Sentiment balance gauge
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                        .frame(width: 100, height: 100)
                    
                    // Balance indicator
                    let normalizedBalance = min(1, max(-1, Double(analytics.sentimentBalance) / Double(max(1, analytics.totalEvidence))))
                    let progress = (normalizedBalance + 1) / 2  // Convert -1..1 to 0..1
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(
                            balanceColor(for: analytics.sentimentBalance),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 0) {
                        Text(analytics.sentimentBalance >= 0 ? "+\(analytics.sentimentBalance)" : "\(analytics.sentimentBalance)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(balanceColor(for: analytics.sentimentBalance))
                        Text("Balance")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Text("Net Sentiment")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Key metrics
            VStack(spacing: 12) {
                HStack(spacing: 20) {
                    metricCard(
                        value: "\(analytics.totalEvidence)",
                        label: "Total Evidence",
                        icon: "doc.text.fill",
                        color: .blue
                    )
                    
                    metricCard(
                        value: "\(analytics.supportingCount)",
                        label: "Supporting",
                        icon: "plus.circle.fill",
                        color: .green
                    )
                    
                    metricCard(
                        value: "\(analytics.contradictingCount)",
                        label: "Contradicting",
                        icon: "minus.circle.fill",
                        color: .red
                    )
                    
                    metricCard(
                        value: "\(analytics.neutralCount)",
                        label: "Neutral",
                        icon: "circle",
                        color: .gray
                    )
                }
                
                HStack(spacing: 20) {
                    metricCard(
                        value: "\(analytics.freshnessScore)",
                        label: "Freshness Score",
                        icon: "clock.fill",
                        color: freshnessColor(for: analytics.freshnessScore)
                    )
                    
                    metricCard(
                        value: "\(analytics.recentContradicting.count)",
                        label: "Contradicting (7d)",
                        icon: "exclamationmark.triangle.fill",
                        color: analytics.recentContradicting.isEmpty ? .green : .orange
                    )
                }
            }
            
            Spacer()
        }
        .padding(20)
        .background(Color(nsColor: .controlBackgroundColor))
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
    
    // MARK: - Sentiment Breakdown Chart
    
    private func sentimentBreakdownChart(_ analytics: EvidenceAnalytics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sentiment Breakdown")
                .font(.headline)
            
            if analytics.totalEvidence == 0 {
                emptyChartPlaceholder
            } else {
                let chartData = [
                    SentimentChartData(sentiment: "Supporting", count: analytics.supportingCount, color: .green),
                    SentimentChartData(sentiment: "Neutral", count: analytics.neutralCount, color: .gray),
                    SentimentChartData(sentiment: "Contradicting", count: analytics.contradictingCount, color: .red)
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
                            Text(item.sentiment)
                                .font(.caption)
                            Spacer()
                            Text("\(item.count)")
                                .font(.caption)
                                .fontWeight(.medium)
                            Text("(\(percentage(item.count, of: analytics.totalEvidence))%)")
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
    
    // MARK: - Freshness Chart
    
    private func freshnessChart(_ analytics: EvidenceAnalytics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Evidence Freshness")
                    .font(.headline)
                
                Spacer()
                
                Text("Score: \(analytics.freshnessScore)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(freshnessColor(for: analytics.freshnessScore))
            }
            
            if analytics.totalEvidence == 0 {
                emptyChartPlaceholder
            } else {
                let chartData = [
                    FreshnessChartData(range: "< 30 days", count: analytics.evidenceUnder30Days, color: .green),
                    FreshnessChartData(range: "30-90 days", count: analytics.evidence30To90Days, color: .yellow),
                    FreshnessChartData(range: "> 90 days", count: analytics.evidenceOver90Days, color: .red)
                ]
                
                // Stacked bar
                VStack(spacing: 8) {
                    GeometryReader { geometry in
                        HStack(spacing: 2) {
                            ForEach(chartData) { item in
                                if item.count > 0 {
                                    Rectangle()
                                        .fill(item.color)
                                        .frame(width: geometry.size.width * CGFloat(item.count) / CGFloat(analytics.totalEvidence))
                                }
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .frame(height: 24)
                    
                    // Legend
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(chartData) { item in
                            HStack(spacing: 8) {
                                Rectangle()
                                    .fill(item.color)
                                    .frame(width: 16, height: 8)
                                    .clipShape(RoundedRectangle(cornerRadius: 2))
                                Text(item.range)
                                    .font(.caption)
                                Spacer()
                                Text("\(item.count)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
                .frame(height: 180)
                
                // Freshness recommendation
                if analytics.evidenceOver90Days > analytics.totalEvidence / 2 {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Over half your evidence is older than 90 days")
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
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    // MARK: - Source Type Chart
    
    private func sourceTypeChart(_ analytics: EvidenceAnalytics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Source Types")
                .font(.headline)
            
            if analytics.sourceTypeDistribution.isEmpty {
                emptyChartPlaceholder
            } else {
                let sortedSources = analytics.sourceTypeDistribution
                    .sorted { $0.value > $1.value }
                    .prefix(8)
                    .map { SourceTypeChartData(type: $0.key.displayName, count: $0.value) }
                
                Chart(sortedSources) { item in
                    BarMark(
                        x: .value("Count", item.count),
                        y: .value("Source", item.type)
                    )
                    .foregroundStyle(.blue.gradient)
                    .annotation(position: .trailing) {
                        Text("\(item.count)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .chartXAxis(.hidden)
                .frame(height: 200)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    // MARK: - Evidence Type Chart
    
    private func evidenceTypeChart(_ analytics: EvidenceAnalytics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Evidence Types")
                .font(.headline)
            
            if analytics.evidenceTypeDistribution.isEmpty {
                emptyChartPlaceholder
            } else {
                let chartData = analytics.evidenceTypeDistribution
                    .map { EvidenceTypeChartData(type: $0.key, count: $0.value) }
                    .sorted { $0.count > $1.count }
                
                Chart(chartData) { item in
                    BarMark(
                        x: .value("Count", item.count),
                        y: .value("Type", item.type.displayName)
                    )
                    .foregroundStyle(evidenceTypeColor(item.type))
                    .annotation(position: .trailing) {
                        Text("\(item.count)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .chartXAxis(.hidden)
                .frame(height: 180)
                
                // Icons legend
                HStack(spacing: 12) {
                    ForEach(chartData.prefix(5)) { item in
                        HStack(spacing: 4) {
                            Image(systemName: item.type.iconName)
                                .font(.caption)
                                .foregroundStyle(evidenceTypeColor(item.type))
                            Text(item.type.displayName)
                                .font(.caption2)
                        }
                    }
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    // MARK: - Top Domains Section
    
    private func topDomainsSection(_ analytics: EvidenceAnalytics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Top Sources by Domain")
                    .font(.headline)
                
                Spacer()
                
                Text("\(analytics.topDomains.count) unique domains")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if analytics.topDomains.isEmpty {
                Text("No URL-based evidence added yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(24)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(Array(analytics.topDomains.prefix(10).enumerated()), id: \.offset) { index, item in
                        HStack {
                            Text("\(index + 1).")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .frame(width: 20)
                            
                            Text(item.domain)
                                .font(.subheadline)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text("\(item.count)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.accentColor.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    // MARK: - Recent Contradicting Section
    
    private func recentContradictingSection(_ analytics: EvidenceAnalytics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text("Recent Contradicting Evidence")
                    .font(.headline)
                
                Spacer()
                
                Text("Last 7 days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            VStack(spacing: 8) {
                ForEach(analytics.recentContradicting.prefix(5)) { evidence in
                    HStack {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.red)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(evidence.effectiveTitle)
                                .font(.subheadline)
                                .lineLimit(1)
                            
                            HStack(spacing: 8) {
                                if let driver = evidence.driver {
                                    Text(driver.title)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                
                                Text(evidence.capturedAt, style: .relative)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        
                        Spacer()
                        
                        Text(evidence.sourceType.displayName)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.1))
                            .foregroundStyle(.red)
                            .clipShape(Capsule())
                    }
                    .padding(10)
                    .background(Color.red.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor))
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
        .frame(height: 150)
    }
    
    // MARK: - Helper Methods
    
    private func loadAnalytics() {
        Task {
            let service = AnalyticsService.shared
            let evidenceAnalytics = service.computeEvidenceAnalytics(modelContext: modelContext)
            
            await MainActor.run {
                self.analytics = evidenceAnalytics
                self.isLoading = false
            }
        }
    }
    
    private func balanceColor(for balance: Int) -> Color {
        if balance > 0 { return .green }
        if balance < 0 { return .red }
        return .gray
    }
    
    private func freshnessColor(for score: Int) -> Color {
        if score >= 70 { return .green }
        if score >= 40 { return .yellow }
        return .red
    }
    
    private func evidenceTypeColor(_ type: EvidenceType) -> Color {
        switch type {
        case .article: return .blue
        case .filing: return .purple
        case .kpi: return .green
        case .quote: return .orange
        case .note: return .gray
        }
    }
    
    private func percentage(_ value: Int, of total: Int) -> Int {
        guard total > 0 else { return 0 }
        return Int(Double(value) / Double(total) * 100)
    }
}

// MARK: - Chart Data Types

struct SentimentChartData: Identifiable {
    let id = UUID()
    let sentiment: String
    let count: Int
    let color: Color
}

struct FreshnessChartData: Identifiable {
    let id = UUID()
    let range: String
    let count: Int
    let color: Color
}

struct SourceTypeChartData: Identifiable {
    let id = UUID()
    let type: String
    let count: Int
}

struct EvidenceTypeChartData: Identifiable {
    let id = UUID()
    let type: EvidenceType
    let count: Int
}

// MARK: - Preview

#Preview {
    EvidenceAnalyticsView()
        .modelContainer(for: [Asset.self, ResearchQuestion.self, Driver.self, Evidence.self], inMemory: true)
}

