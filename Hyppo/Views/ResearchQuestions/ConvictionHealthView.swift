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
    let driverEvidenceCounts: [Int]
    let recentSupportingCount: Int
    let recentContradictingCount: Int
    let recentWindowSize: Int
    
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

    /**
     Number of top-level drivers with at least one evidence item.
     
     - Returns: Count of drivers with evidence.
     */
    var driversWithEvidenceCount: Int {
        driverEvidenceCounts.filter { $0 > 0 }.count
    }

    /**
     Ratio of drivers with evidence relative to total drivers.
     
     - Returns: Coverage ratio between 0 and 1.
     */
    var driverCoverageRatio: Double {
        guard totalDrivers > 0 else { return 0 }
        return Double(driversWithEvidenceCount) / Double(totalDrivers)
    }

    /**
     Total evidence count across all top-level drivers.
     
     - Returns: Total evidence items counted.
     */
    var totalEvidenceCount: Int {
        driverEvidenceCounts.reduce(0, +)
    }

    /**
     Share of evidence concentrated in the most-evidenced driver.
     
     - Returns: Concentration ratio between 0 and 1.
     */
    var driverConcentrationRatio: Double {
        guard totalEvidenceCount > 0 else { return 0 }
        return Double(driverEvidenceCounts.max() ?? 0) / Double(totalEvidenceCount)
    }

    /**
     Human-readable coverage text for driver evidence distribution.
     
     - Returns: A short coverage summary string.
     */
    var coverageDetailText: String {
        guard totalEvidenceCount > 0 else { return "No evidence yet" }
        if driverConcentrationRatio >= 0.6 {
            return "Evidence concentrated in 1 driver"
        }
        if driverCoverageRatio < 0.5 {
            return "Coverage is narrow"
        }
        return "Evidence spread across drivers"
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

    /**
     Ratio of recent evidence balance over the rolling window.
     
     - Returns: Balance ratio between -1 and 1.
     */
    var recentBalanceRatio: Double {
        let total = recentSupportingCount + recentContradictingCount
        guard total > 0 else { return 0 }
        return Double(recentSupportingCount - recentContradictingCount) / Double(total)
    }

    /**
     Trend direction based on recent evidence balance.
     
     - Returns: Trend direction (improving/degrading/flat).
     */
    var trendDirection: TrendDirection {
        if recentBalanceRatio >= 0.2 { return .improving }
        if recentBalanceRatio <= -0.2 { return .degrading }
        return .flat
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
            case .strong: return .statusActive
            case .moderate: return Color.accentColor
            case .weak: return .statusOnHold
            case .critical: return .statusInvalidated
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

    enum TrendDirection {
        case improving, degrading, flat
        
        var label: String {
            switch self {
            case .improving: return "Improving"
            case .degrading: return "Degrading"
            case .flat: return "Flat"
            }
        }
        
        var icon: String {
            switch self {
            case .improving: return "arrow.up.right"
            case .degrading: return "arrow.down.right"
            case .flat: return "arrow.right"
            }
        }
        
        var color: Color {
            switch self {
            case .improving: return .statusActive
            case .degrading: return .statusInvalidated
            case .flat: return .statusArchived
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
        var driverEvidenceCountById: [UUID: Int] = [:]
        var allEvidence: [Evidence] = []
        let recentWindowSize = 10
        
        let topLevelDrivers = drivers.filter { $0.parentDriver == nil }
        
        for driver in topLevelDrivers {
            driverEvidenceCountById[driver.driverId] = 0
        }
        
        func processDriver(_ driver: Driver, rootDriverId: UUID, isTopLevel: Bool) {
            if let evidence = driver.evidence {
                for item in evidence {
                    allEvidence.append(item)
                    driverEvidenceCountById[rootDriverId, default: 0] += 1
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
                    processDriver(sub, rootDriverId: rootDriverId, isTopLevel: false)
                }
            }
        }
        
        for driver in topLevelDrivers {
            processDriver(driver, rootDriverId: driver.driverId, isTopLevel: true)
        }
        
        let recentEvidence = allEvidence
            .sorted { $0.capturedAt > $1.capturedAt }
            .prefix(recentWindowSize)
        
        var recentSupportingCount = 0
        var recentContradictingCount = 0
        for item in recentEvidence {
            switch item.sentiment {
            case .supporting: recentSupportingCount += 1
            case .contradicting: recentContradictingCount += 1
            case .neutral: break
            }
        }
        
        return ConvictionHealthSummary(
            totalSupporting: supporting,
            totalContradicting: contradicting,
            totalNeutral: neutral,
            driversWithBlindSpots: blindSpotDrivers,
            totalDrivers: topLevelDrivers.count,
            recentContradictingEvidence: recentContradicting.sorted { $0.capturedAt > $1.capturedAt },
            driverEvidenceCounts: driverEvidenceCountById.values.map { $0 },
            recentSupportingCount: recentSupportingCount,
            recentContradictingCount: recentContradictingCount,
            recentWindowSize: recentWindowSize
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
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Conviction Health")
                    .font(.headline)
                
                Spacer()
                
                // Overall health badge + trend
                HStack(spacing: 8) {
                    healthStatusBadge
                    trendBadge
                }
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

    /**
     Trend chip showing whether recent evidence is improving or degrading.
     
     - Returns: A view representing the trend direction.
     */
    private var trendBadge: some View {
        let trend = summary.trendDirection
        
        return HStack(spacing: 4) {
            Image(systemName: trend.icon)
            Text(trend.label)
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(trend.color.opacity(0.12))
        .foregroundStyle(trend.color)
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Recent trend: \(trend.label)")
    }
    
    private var evidenceSummaryBar: some View {
        return HStack(alignment: .top, spacing: 16) {
            balanceBarSection
            coverageBarSection
        }
    }

    /**
     Evidence balance bar showing supporting/neutral/contradicting mix.
     
     - Returns: A view representing sentiment balance.
     */
    private var balanceBarSection: some View {
        let total = summary.totalSupporting + summary.totalContradicting + summary.totalNeutral
        
        return VStack(alignment: .leading, spacing: 6) {
            Text("Evidence Balance")
                .font(.caption)
                .fontWeight(.semibold)
            
            GeometryReader { geometry in
                HStack(spacing: 2) {
                    if summary.totalSupporting > 0 {
                        Rectangle()
                            .fill(Color.statusActive)
                            .frame(width: max(4, geometry.size.width * CGFloat(summary.totalSupporting) / CGFloat(max(1, total))))
                    }
                    if summary.totalNeutral > 0 {
                        Rectangle()
                            .fill(Color.statusArchived.opacity(0.4))
                            .frame(width: max(4, geometry.size.width * CGFloat(summary.totalNeutral) / CGFloat(max(1, total))))
                    }
                    if summary.totalContradicting > 0 {
                        Rectangle()
                            .fill(Color.statusInvalidated)
                            .frame(width: max(4, geometry.size.width * CGFloat(summary.totalContradicting) / CGFloat(max(1, total))))
                    }
                    if total == 0 {
                        Rectangle()
                            .fill(Color.statusArchived.opacity(0.2))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .frame(height: 8)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Evidence balance: \(summary.totalSupporting) supporting, \(summary.totalNeutral) neutral, \(summary.totalContradicting) contradicting")
            
            HStack(spacing: 16) {
                evidenceLegendItem(count: summary.totalSupporting, label: "Supporting", color: Color.statusActive)
                evidenceLegendItem(count: summary.totalNeutral, label: "Neutral", color: Color.statusArchived)
                evidenceLegendItem(count: summary.totalContradicting, label: "Contradicting", color: Color.statusInvalidated)
            }
            .font(.caption)
        }
    }

    /**
     Driver coverage bar showing how widely evidence is distributed.
     
     - Returns: A view representing driver coverage and concentration.
     */
    private var coverageBarSection: some View {
        return VStack(alignment: .leading, spacing: 6) {
            Text("Driver Coverage")
                .font(.caption)
                .fontWeight(.semibold)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.statusArchived.opacity(0.2))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.accentColor.opacity(0.8))
                        .frame(width: geometry.size.width * CGFloat(summary.driverCoverageRatio))
                }
            }
            .frame(height: 8)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(summary.driversWithEvidenceCount) of \(summary.totalDrivers) drivers have evidence")
            
            HStack(spacing: 12) {
                Text("\(summary.driversWithEvidenceCount) of \(summary.totalDrivers) drivers have evidence")
                    .foregroundStyle(.secondary)
                
                if summary.blindSpotCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "eye.slash.fill")
                            .foregroundStyle(Color.statusOnHold)
                        Text("\(summary.blindSpotCount) blind spot\(summary.blindSpotCount == 1 ? "" : "s")")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(summary.blindSpotCount) assumption\(summary.blindSpotCount == 1 ? "" : "s") without evidence")
                }
                
                Spacer()
                
                Text(summary.coverageDetailText)
                    .foregroundStyle(.secondary)
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
                    .strikethrough(driver.status == .discarded, color: Color.statusInvalidated)
                    .foregroundStyle(driver.status == .discarded ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("\(driver.directEvidenceCount)")
                    .font(.caption)
                    .frame(width: 50)
                
                let balance = driver.totalEvidenceBalance
                let balanceColor: Color = balance > 0 ? .statusActive : (balance < 0 ? .statusInvalidated : .secondary)
                Text(balance > 0 ? "+\(balance)" : "\(balance)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(balanceColor)
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
                            .strikethrough(sub.status == .discarded, color: Color.statusInvalidated)
                            .foregroundStyle(sub.status == .discarded ? .tertiary : .secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("\(sub.directEvidenceCount)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .frame(width: 50)
                        
                        let balance = sub.totalEvidenceBalance
                        let subBalanceColor: Color = balance > 0 ? .statusActive : (balance < 0 ? .statusInvalidated : .secondary)
                        Text(balance > 0 ? "+\(balance)" : "\(balance)")
                            .font(.caption2)
                            .foregroundStyle(subBalanceColor.opacity(balance != 0 ? 0.8 : 1.0))
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
                    .foregroundStyle(Color.statusInvalidated)
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
                            .foregroundStyle(Color.statusInvalidated)
                        
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
        .background(Color.statusInvalidated.opacity(0.05))
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
                        .foregroundStyle(Color.statusOnHold)
                    
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
                .background(Color.statusOnHold.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            
            // Recent contradicting count
            if !summary.recentContradictingEvidence.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.statusInvalidated)
                    Text("\(summary.recentContradictingEvidence.count) new contradicting evidence this week")
                        .font(.caption)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.statusInvalidated.opacity(0.1))
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
                badge("Blind Spot", color: Color.statusOnHold, icon: "eye.slash")
            } else if balance > 0 {
                badge("Supported", color: Color.statusActive, icon: "checkmark.circle")
            } else if balance < 0 {
                badge("Challenged", color: Color.statusInvalidated, icon: "exclamationmark.circle")
            } else {
                badge("Neutral", color: Color.statusArchived, icon: "circle")
            }
        }
    }
    
    // MARK: - Validation Status Badge (Review-based)
    
    /// Badge showing validation status from reviews (Confirmed/Discarded/Needs Revision/Under Review)
    private func validationBadge(for driver: Driver) -> some View {
        let status = driver.status
        
        return Group {
            switch status {
            case .confirmed:
                badge("Confirmed", color: Color.statusActive, icon: "checkmark.seal.fill")
            case .discarded:
                badge("Discarded", color: Color.statusInvalidated, icon: "xmark.seal.fill")
            case .needsRevision:
                badge("Revision", color: Color.statusOnHold, icon: "exclamationmark.circle.fill")
            case .pending:
                badge("Under Review", color: Color.statusArchived, icon: "circle.dashed")
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
