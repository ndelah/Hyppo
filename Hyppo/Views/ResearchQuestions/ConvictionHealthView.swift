/**
 ConvictionHealthView displays a dashboard showing evidence balance and conviction health
 for a research question.
 
 Features:
 - Overall conviction meter with health score
 - Per-driver evidence breakdown table with status indicators (including blind spots)
 - Recent contradicting evidence highlights
 - Compact mode for embedding in review wizard
 */

import SwiftUI

// MARK: - Conviction Health Summary

/**
 Computed summary of evidence health across all drivers.
 */
struct ConvictionHealthSummary {
    let totalSupporting: Int
    let totalContradicting: Int
    let totalNeutral: Int
    let driversWithBlindSpots: [Driver]
    let totalDrivers: Int
    let recentContradictingEvidence: [Evidence]
    
    /// Overall sentiment balance
    var overallBalance: Int {
        totalSupporting - totalContradicting
    }
    
    /// Number of drivers with blind spots
    var blindSpotCount: Int {
        driversWithBlindSpots.count
    }
    
    /// Percentage of drivers with blind spots
    var blindSpotPercentage: Double {
        guard totalDrivers > 0 else { return 0 }
        return Double(blindSpotCount) / Double(totalDrivers) * 100
    }
    
    /// Overall health rating (0-100)
    var healthScore: Int {
        guard totalDrivers > 0 else { return 50 }
        
        var score = 50 // Start neutral
        
        // Adjust for evidence balance
        let balanceRatio = totalSupporting + totalContradicting > 0
            ? Double(totalSupporting - totalContradicting) / Double(totalSupporting + totalContradicting)
            : 0
        score += Int(balanceRatio * 30)
        
        // Penalize for blind spots
        score -= Int(blindSpotPercentage * 0.3)
        
        // Bonus for having evidence on all drivers
        if blindSpotCount == 0 && totalDrivers > 0 {
            score += 10
        }
        
        return max(0, min(100, score))
    }
    
    /// Health status based on score
    var healthStatus: HealthStatus {
        if healthScore >= 70 { return .strong }
        if healthScore >= 50 { return .moderate }
        if healthScore >= 30 { return .weak }
        return .critical
    }
    
    enum HealthStatus {
        case strong, moderate, weak, critical
        
        var label: String {
            switch self {
            case .strong: return "Strong"
            case .moderate: return "Moderate"
            case .weak: return "Weak"
            case .critical: return "Critical"
            }
        }
        
        var color: Color {
            switch self {
            case .strong: return .green
            case .moderate: return .blue
            case .weak: return .orange
            case .critical: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .strong: return "heart.fill"
            case .moderate: return "heart"
            case .weak: return "heart.slash"
            case .critical: return "exclamationmark.heart"
            }
        }
    }
    
    /// Creates a summary from an array of drivers
    static func from(drivers: [Driver]) -> ConvictionHealthSummary {
        var supporting = 0
        var contradicting = 0
        var neutral = 0
        var blindSpotDrivers: [Driver] = []
        var recentContradicting: [Evidence] = []
        
        let topLevelDrivers = drivers.filter { $0.parentDriver == nil }
        
        func processDriver(_ driver: Driver, isTopLevel: Bool) {
            if let evidence = driver.evidence {
                for item in evidence {
                    switch item.sentiment {
                    case .supporting: supporting += 1
                    case .contradicting:
                        contradicting += 1
                        // Track recent contradicting evidence (last 7 days)
                        if item.capturedAt > Date().addingTimeInterval(-7 * 24 * 60 * 60) {
                            recentContradicting.append(item)
                        }
                    case .neutral: neutral += 1
                    }
                }
            }
            
            // Only track blind spots for top-level drivers (or if sub-driver has no evidence)
            if driver.hasBlindSpot && isTopLevel {
                blindSpotDrivers.append(driver)
            }
            
            // Process sub-drivers
            if let subs = driver.subDrivers {
                for sub in subs {
                    processDriver(sub, isTopLevel: false)
                }
            }
        }
        
        for driver in topLevelDrivers {
            processDriver(driver, isTopLevel: true)
        }
        
        return ConvictionHealthSummary(
            totalSupporting: supporting,
            totalContradicting: contradicting,
            totalNeutral: neutral,
            driversWithBlindSpots: blindSpotDrivers,
            totalDrivers: topLevelDrivers.count,
            recentContradictingEvidence: recentContradicting.sorted { $0.capturedAt > $1.capturedAt }
        )
    }
}

// MARK: - Conviction Health View

struct ConvictionHealthView: View {
    let drivers: [Driver]
    
    /// Optional flag to show compact version (for review wizard)
    var isCompact: Bool = false
    
    /// Computed health summary
    private var summary: ConvictionHealthSummary {
        ConvictionHealthSummary.from(drivers: drivers)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 12 : 16) {
            // Header with overall meter
            headerSection
            
            if !isCompact {
                // Detailed driver breakdown
                driverBreakdownSection
                
                // Recent contradicting evidence
                if !summary.recentContradictingEvidence.isEmpty {
                    recentContradictingSection
                }
            } else {
                // Compact summary for review wizard
                compactSummarySection
                
                // Compact alerts
                if summary.blindSpotCount > 0 || !summary.recentContradictingEvidence.isEmpty {
                    compactAlertsSection
                }
            }
        }
        .padding(isCompact ? 12 : 16)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Conviction Health")
                    .font(.headline)
                
                Spacer()
                
                // Overall health badge
                healthStatusBadge
            }
            
            // Evidence summary bar
            evidenceSummaryBar
        }
    }
    
    private var healthStatusBadge: some View {
        let status = summary.healthStatus
        
        return HStack(spacing: 6) {
            Image(systemName: status.icon)
            Text("\(summary.healthScore)")
                .fontWeight(.bold)
            Text(status.label)
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(status.color.opacity(0.15))
        .foregroundStyle(status.color)
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Health score \(summary.healthScore) out of 100, status: \(status.label)")
    }
    
    private var evidenceSummaryBar: some View {
        let total = summary.totalSupporting + summary.totalContradicting + summary.totalNeutral
        
        return VStack(alignment: .leading, spacing: 6) {
            // Progress bar
            GeometryReader { geometry in
                HStack(spacing: 2) {
                    if summary.totalSupporting > 0 {
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: max(4, geometry.size.width * CGFloat(summary.totalSupporting) / CGFloat(max(1, total))))
                    }
                    if summary.totalNeutral > 0 {
                        Rectangle()
                            .fill(Color.gray.opacity(0.4))
                            .frame(width: max(4, geometry.size.width * CGFloat(summary.totalNeutral) / CGFloat(max(1, total))))
                    }
                    if summary.totalContradicting > 0 {
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: max(4, geometry.size.width * CGFloat(summary.totalContradicting) / CGFloat(max(1, total))))
                    }
                    if total == 0 {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .frame(height: 8)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Evidence balance: \(summary.totalSupporting) supporting, \(summary.totalNeutral) neutral, \(summary.totalContradicting) contradicting")
            
            // Legend
            HStack(spacing: 16) {
                evidenceLegendItem(count: summary.totalSupporting, label: "Supporting", color: .green)
                evidenceLegendItem(count: summary.totalNeutral, label: "Neutral", color: .gray)
                evidenceLegendItem(count: summary.totalContradicting, label: "Contradicting", color: .red)
                
                // Blind spots indicator (only show if there are blind spots)
                if summary.blindSpotCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "eye.slash.fill")
                            .foregroundStyle(.orange)
                        Text("\(summary.blindSpotCount) blind spot\(summary.blindSpotCount == 1 ? "" : "s")")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(summary.blindSpotCount) assumption\(summary.blindSpotCount == 1 ? "" : "s") without evidence")
                }
            }
            .font(.caption)
        }
    }
    
    private func evidenceLegendItem(count: Int, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text("\(count) \(label)")
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Driver Breakdown Section
    
    private var driverBreakdownSection: some View {
        VStack(spacing: 12) {
            // Table Header
            HStack {
                Text("Assumption")
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Evidence")
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(width: 50)
                Text("Balance")
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(width: 50)
                Text("Data")
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(width: 80)
                Text("Validation")
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(width: 90)
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            
            Divider()
            
            // Driver rows
            ForEach(drivers.filter { $0.parentDriver == nil }.sorted(by: { $0.position < $1.position })) { driver in
                healthRow(driver)
            }
        }
    }
    
    private func healthRow(_ driver: Driver) -> some View {
        VStack(spacing: 8) {
            HStack {
                // Driver title with strikethrough if discarded
                Text(driver.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .strikethrough(driver.status == .discarded, color: .red)
                    .foregroundStyle(driver.status == .discarded ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("\(driver.directEvidenceCount)")
                    .font(.caption)
                    .frame(width: 50)
                
                let balance = driver.totalEvidenceBalance
                Text(balance > 0 ? "+\(balance)" : "\(balance)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(balance > 0 ? .green : (balance < 0 ? .red : .secondary))
                    .frame(width: 50)
                
                // Evidence-based status (Data column)
                evidenceStatusBadge(for: driver)
                    .frame(width: 80)
                
                // Validation status from review
                validationBadge(for: driver)
                    .frame(width: 90)
            }
            .padding(.horizontal, 8)
            
            // Sub-drivers
            if let subs = driver.subDrivers, !subs.isEmpty {
                ForEach(subs.sorted(by: { $0.position < $1.position })) { sub in
                    HStack {
                        Text("  → \(sub.title)")
                            .font(.caption)
                            .strikethrough(sub.status == .discarded, color: .red)
                            .foregroundStyle(sub.status == .discarded ? .tertiary : .secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("\(sub.directEvidenceCount)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .frame(width: 50)
                        
                        let balance = sub.totalEvidenceBalance
                        Text(balance > 0 ? "+\(balance)" : "\(balance)")
                            .font(.caption2)
                            .foregroundStyle(balance > 0 ? .green.opacity(0.8) : (balance < 0 ? .red.opacity(0.8) : .secondary))
                            .frame(width: 50)
                        
                        evidenceStatusBadge(for: sub)
                            .frame(width: 80)
                        
                        validationBadge(for: sub)
                            .frame(width: 90)
                    }
                    .padding(.horizontal, 8)
                }
            }
            
            Divider()
                .padding(.vertical, 4)
        }
    }
    
    // MARK: - Recent Contradicting Section
    
    private var recentContradictingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text("Recent Contradicting Evidence")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("(last 7 days)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            VStack(spacing: 6) {
                ForEach(summary.recentContradictingEvidence.prefix(5)) { evidence in
                    HStack {
                        Image(systemName: "minus.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                        
                        Text(evidence.effectiveTitle)
                            .font(.caption)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if let driver = evidence.driver {
                            Text(driver.title)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                                .frame(maxWidth: 100)
                        }
                        
                        Text(evidence.capturedAt, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(12)
        .background(Color.red.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - Compact Summary Section
    
    private var compactSummarySection: some View {
        EmptyView()
    }
    
    // MARK: - Compact Alerts Section
    
    private var compactAlertsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Blind spots summary
            if summary.blindSpotCount > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "eye.slash.fill")
                        .foregroundStyle(.orange)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(summary.blindSpotCount) assumption\(summary.blindSpotCount == 1 ? "" : "s") need evidence")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Text(summary.driversWithBlindSpots.prefix(2).map { $0.title }.joined(separator: ", "))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            
            // Recent contradicting count
            if !summary.recentContradictingEvidence.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text("\(summary.recentContradictingEvidence.count) new contradicting evidence this week")
                        .font(.caption)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
    }
    
    // MARK: - Evidence Status Badge (Data-based)
    
    /// Badge showing evidence-based status (Supported/Challenged/Blind Spot/Neutral)
    private func evidenceStatusBadge(for driver: Driver) -> some View {
        let balance = driver.totalEvidenceBalance
        let hasBlindSpot = driver.hasBlindSpot
        
        return Group {
            if hasBlindSpot {
                badge("Blind Spot", color: .orange, icon: "eye.slash")
            } else if balance > 0 {
                badge("Supported", color: .green, icon: "checkmark.circle")
            } else if balance < 0 {
                badge("Challenged", color: .red, icon: "exclamationmark.circle")
            } else {
                badge("Neutral", color: .gray, icon: "circle")
            }
        }
    }
    
    // MARK: - Validation Status Badge (Review-based)
    
    /// Badge showing validation status from reviews (Confirmed/Discarded/Needs Revision/Pending)
    private func validationBadge(for driver: Driver) -> some View {
        let status = driver.status
        
        return Group {
            switch status {
            case .confirmed:
                badge("Confirmed", color: .green, icon: "checkmark.seal.fill")
            case .discarded:
                badge("Discarded", color: .red, icon: "xmark.seal.fill")
            case .needsRevision:
                badge("Revision", color: .orange, icon: "exclamationmark.circle.fill")
            case .pending:
                badge("Pending", color: .gray, icon: "circle.dashed")
            }
        }
    }
    
    private func badge(_ text: String, color: Color, icon: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
            Text(text)
                .lineLimit(1)
        }
        .font(.caption.bold())
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(color.opacity(0.1))
        .foregroundStyle(color)
        .clipShape(Capsule())
        .fixedSize()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
    }
}

// MARK: - Preview

#Preview("Full View - With Blind Spots") {
    ConvictionHealthView(drivers: [])
        .padding()
}

#Preview("Compact View") {
    ConvictionHealthView(drivers: [], isCompact: true)
        .padding()
}
