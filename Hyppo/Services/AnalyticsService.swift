/**
 AnalyticsService provides computed metrics and data summaries for the analytics dashboard.
 
 This service aggregates data across all models to compute:
 - Portfolio-level health scores and statistics
 - Time-based activity metrics
 - Evidence analytics (source diversity, sentiment balance, freshness)
 - Driver validation funnel statistics
 - Review adherence and alert conditions
 */

import Foundation
import SwiftData

// MARK: - Portfolio Analytics Summary

/**
 Aggregate statistics for the entire research portfolio.
 */
struct PortfolioAnalytics {
    // Overall counts
    let totalAssets: Int
    let totalResearchQuestions: Int
    let activeQuestions: Int
    let onHoldQuestions: Int
    let invalidatedQuestions: Int
    let archivedQuestions: Int
    
    // Health metrics
    let averageHealthScore: Double
    let averageConfidence: Double
    let totalDrivers: Int
    let totalEvidence: Int
    
    // Alerts
    let overdueReviews: Int
    let blindSpotCount: Int
    let staleResearchCount: Int
    let recentContradictingCount: Int
    
    /// Overall portfolio health based on multiple factors
    var portfolioHealthScore: Int {
        var score = 50
        
        // Factor in average health scores
        score += Int((averageHealthScore - 50) * 0.4)
        
        // Penalize for issues
        let questionCount = max(1, totalResearchQuestions)
        score -= min(20, (overdueReviews * 100) / questionCount / 5)
        score -= min(15, (blindSpotCount * 100) / max(1, totalDrivers) / 5)
        score -= min(10, staleResearchCount * 3)
        
        return max(0, min(100, score))
    }
    
    /// Confidence distribution for chart display
    var confidenceDistribution: [Int: Int] {
        // Returns [confidenceLevel: count]
        [:]  // Populated by the service
    }
    
    /// Status distribution for chart display
    var statusDistribution: [ResearchQuestionStatus: Int] {
        [
            .active: activeQuestions,
            .onHold: onHoldQuestions,
            .invalidated: invalidatedQuestions,
            .archived: archivedQuestions
        ]
    }
}

// MARK: - Evidence Analytics

/**
 Evidence-related metrics and distributions.
 */
struct EvidenceAnalytics {
    // Sentiment breakdown
    let supportingCount: Int
    let contradictingCount: Int
    let neutralCount: Int
    
    // Source type distribution
    let sourceTypeDistribution: [SourceType: Int]
    
    // Evidence type distribution
    let evidenceTypeDistribution: [EvidenceType: Int]
    
    // Domain frequency (top domains)
    let topDomains: [(domain: String, count: Int)]
    
    // Freshness
    let evidenceUnder30Days: Int
    let evidence30To90Days: Int
    let evidenceOver90Days: Int
    
    // Recent contradicting evidence (last 7 days)
    let recentContradicting: [Evidence]
    
    /// Total evidence count
    var totalEvidence: Int {
        supportingCount + contradictingCount + neutralCount
    }
    
    /// Net sentiment balance
    var sentimentBalance: Int {
        supportingCount - contradictingCount
    }
    
    /// Freshness score (0-100, higher is fresher)
    var freshnessScore: Int {
        guard totalEvidence > 0 else { return 50 }
        let freshWeight = Double(evidenceUnder30Days) * 1.0
        let mediumWeight = Double(evidence30To90Days) * 0.5
        let staleWeight = Double(evidenceOver90Days) * 0.0
        let weightedSum = freshWeight + mediumWeight + staleWeight
        return Int((weightedSum / Double(totalEvidence)) * 100)
    }
}

// MARK: - Driver Analytics (Validation Funnel)

/**
 Driver validation funnel statistics.
 */
struct DriverAnalytics {
    let totalDrivers: Int
    let pendingDrivers: Int
    let confirmedDrivers: Int
    let discardedDrivers: Int
    let needsRevisionDrivers: Int
    
    // Evidence coverage
    let driversWithEvidence: Int
    let driversWithBlindSpots: Int
    
    // By research question
    let driversByQuestion: [(question: ResearchQuestion, drivers: [Driver])]
    
    /// Validation progress percentage
    var validationProgress: Double {
        guard totalDrivers > 0 else { return 0 }
        let resolved = confirmedDrivers + discardedDrivers
        return Double(resolved) / Double(totalDrivers) * 100
    }
    
    /// Evidence coverage percentage
    var evidenceCoverage: Double {
        guard totalDrivers > 0 else { return 100 }
        return Double(driversWithEvidence) / Double(totalDrivers) * 100
    }
    
    /// Confirmation rate (of resolved drivers)
    var confirmationRate: Double {
        let resolved = confirmedDrivers + discardedDrivers
        guard resolved > 0 else { return 0 }
        return Double(confirmedDrivers) / Double(resolved) * 100
    }
}

// MARK: - Review Analytics

/**
 Review schedule and adherence metrics.
 */
struct ReviewAnalytics {
    let totalReminders: Int
    let enabledReminders: Int
    let dueReviews: Int
    let overdueReviews: Int
    let snoozedReviews: Int
    
    // Upcoming reviews by day
    let upcomingReviews: [(reminder: ReviewReminder, question: ResearchQuestion)]
    
    // Review history (from log entries)
    let reviewOutcomes: [ReviewOutcome: Int]
    let averageSnoozeCount: Double
    
    // Days since last review distribution
    let daysSinceReviewDistribution: [Int]
    
    /// On-time review rate
    var adherenceRate: Double {
        guard enabledReminders > 0 else { return 100 }
        let onTime = enabledReminders - overdueReviews
        return Double(onTime) / Double(enabledReminders) * 100
    }
    
    /// Questions needing review soon (within 3 days)
    var reviewsSoonCount: Int {
        upcomingReviews.filter { reminder, _ in
            if let days = reminder.daysUntilDue {
                return days >= 0 && days <= 3
            }
            return false
        }.count
    }
}

// MARK: - Risk Alerts

/**
 Risk conditions and alerts.
 */
struct RiskAlert: Identifiable {
    let id = UUID()
    let type: RiskAlertType
    let severity: AlertSeverity
    let title: String
    let description: String
    let relatedQuestion: ResearchQuestion?
    let createdAt: Date
    
    enum RiskAlertType: String {
        case contradictingEvidence = "Contradicting Evidence"
        case staleResearch = "Stale Research"
        case confidenceDrop = "Confidence Drop"
        case blindSpots = "Blind Spots"
        case overdueReview = "Overdue Review"
        case invalidationRisk = "Invalidation Risk"
        case unresolvedDrivers = "Unresolved Drivers"
    }
    
    enum AlertSeverity: Int, Comparable {
        case info = 0
        case warning = 1
        case critical = 2
        
        static func < (lhs: AlertSeverity, rhs: AlertSeverity) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
        
        var colorName: String {
            switch self {
            case .info: return "blue"
            case .warning: return "orange"
            case .critical: return "red"
            }
        }
        
        var iconName: String {
            switch self {
            case .info: return "info.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .critical: return "exclamationmark.octagon.fill"
            }
        }
    }
}

// MARK: - Analytics Service

/**
 Service for computing analytics across the entire data model.
 */
final class AnalyticsService {
    
    // MARK: - Singleton
    
    static let shared = AnalyticsService()
    private init() {}
    
    // MARK: - Portfolio Analytics
    
    /**
     Computes aggregate portfolio statistics.
     
     - Parameter modelContext: The SwiftData model context
     - Returns: Portfolio analytics summary
     */
    func computePortfolioAnalytics(modelContext: ModelContext) -> PortfolioAnalytics {
        // Fetch all data
        let assets = fetchAll(Asset.self, from: modelContext)
        let questions = fetchAll(ResearchQuestion.self, from: modelContext)
        let drivers = fetchAll(Driver.self, from: modelContext)
        let evidence = fetchAll(Evidence.self, from: modelContext)
        let reminders = fetchAll(ReviewReminder.self, from: modelContext)
        
        // Count by status
        let activeQuestions = questions.filter { $0.status == .active }.count
        let onHoldQuestions = questions.filter { $0.status == .onHold }.count
        let invalidatedQuestions = questions.filter { $0.status == .invalidated }.count
        let archivedQuestions = questions.filter { $0.status == .archived }.count
        
        // Calculate average health score
        let healthScores = questions.compactMap { question -> Int? in
            guard let questionDrivers = question.drivers, !questionDrivers.isEmpty else { return nil }
            return ConvictionHealthSummary.from(drivers: questionDrivers).healthScore
        }
        let avgHealth = healthScores.isEmpty ? 50.0 : Double(healthScores.reduce(0, +)) / Double(healthScores.count)
        
        // Calculate average confidence
        let confidences = questions.compactMap { $0.confidenceCurrent }
        let avgConfidence = confidences.isEmpty ? 3.0 : Double(confidences.reduce(0, +)) / Double(confidences.count)
        
        // Count overdue reviews
        let overdueReviews = reminders.filter { $0.isEnabled && $0.isDue && ($0.daysUntilDue ?? 0) < 0 }.count
        
        // Count blind spots
        let topLevelDrivers = drivers.filter { $0.parentDriver == nil }
        let blindSpotCount = topLevelDrivers.filter { $0.hasBlindSpot }.count
        
        // Count stale research (not updated in 30+ days)
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let staleCount = questions.filter { $0.status == .active && $0.updatedAt < thirtyDaysAgo }.count
        
        // Count recent contradicting evidence
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentContradicting = evidence.filter { $0.sentiment == .contradicting && $0.capturedAt > sevenDaysAgo }.count
        
        return PortfolioAnalytics(
            totalAssets: assets.count,
            totalResearchQuestions: questions.count,
            activeQuestions: activeQuestions,
            onHoldQuestions: onHoldQuestions,
            invalidatedQuestions: invalidatedQuestions,
            archivedQuestions: archivedQuestions,
            averageHealthScore: avgHealth,
            averageConfidence: avgConfidence,
            totalDrivers: drivers.count,
            totalEvidence: evidence.count,
            overdueReviews: overdueReviews,
            blindSpotCount: blindSpotCount,
            staleResearchCount: staleCount,
            recentContradictingCount: recentContradicting
        )
    }
    
    // MARK: - Confidence Distribution
    
    /**
     Computes confidence level distribution across research questions.
     
     - Parameter modelContext: The SwiftData model context
     - Returns: Dictionary mapping confidence level (1-5) to count
     */
    func computeConfidenceDistribution(modelContext: ModelContext) -> [Int: Int] {
        let questions = fetchAll(ResearchQuestion.self, from: modelContext)
        var distribution: [Int: Int] = [1: 0, 2: 0, 3: 0, 4: 0, 5: 0]
        
        for question in questions {
            if let confidence = question.confidenceCurrent {
                distribution[confidence, default: 0] += 1
            }
        }
        
        return distribution
    }
    
    // MARK: - Evidence Analytics
    
    /**
     Computes evidence-related metrics.
     
     - Parameter modelContext: The SwiftData model context
     - Returns: Evidence analytics summary
     */
    func computeEvidenceAnalytics(modelContext: ModelContext) -> EvidenceAnalytics {
        let evidence = fetchAll(Evidence.self, from: modelContext)
        
        // Sentiment counts
        let supporting = evidence.filter { $0.sentiment == .supporting }.count
        let contradicting = evidence.filter { $0.sentiment == .contradicting }.count
        let neutral = evidence.filter { $0.sentiment == .neutral }.count
        
        // Source type distribution
        var sourceTypeDist: [SourceType: Int] = [:]
        for item in evidence {
            sourceTypeDist[item.sourceType, default: 0] += 1
        }
        
        // Evidence type distribution
        var evidenceTypeDist: [EvidenceType: Int] = [:]
        for item in evidence {
            evidenceTypeDist[item.evidenceType, default: 0] += 1
        }
        
        // Domain frequency
        var domainCounts: [String: Int] = [:]
        for item in evidence {
            if let domain = item.domain {
                domainCounts[domain, default: 0] += 1
            }
        }
        let topDomains = domainCounts.sorted { $0.value > $1.value }.prefix(10).map { ($0.key, $0.value) }
        
        // Freshness breakdown
        let now = Date()
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
        let ninetyDaysAgo = Calendar.current.date(byAdding: .day, value: -90, to: now) ?? now
        
        let under30 = evidence.filter { $0.capturedAt > thirtyDaysAgo }.count
        let between30And90 = evidence.filter { $0.capturedAt <= thirtyDaysAgo && $0.capturedAt > ninetyDaysAgo }.count
        let over90 = evidence.filter { $0.capturedAt <= ninetyDaysAgo }.count
        
        // Recent contradicting
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        let recentContradicting = evidence.filter { $0.sentiment == .contradicting && $0.capturedAt > sevenDaysAgo }
        
        return EvidenceAnalytics(
            supportingCount: supporting,
            contradictingCount: contradicting,
            neutralCount: neutral,
            sourceTypeDistribution: sourceTypeDist,
            evidenceTypeDistribution: evidenceTypeDist,
            topDomains: topDomains,
            evidenceUnder30Days: under30,
            evidence30To90Days: between30And90,
            evidenceOver90Days: over90,
            recentContradicting: recentContradicting
        )
    }
    
    // MARK: - Driver Analytics
    
    /**
     Computes driver validation funnel statistics.
     
     - Parameter modelContext: The SwiftData model context
     - Returns: Driver analytics summary
     */
    func computeDriverAnalytics(modelContext: ModelContext) -> DriverAnalytics {
        let drivers = fetchAll(Driver.self, from: modelContext)
        let questions = fetchAll(ResearchQuestion.self, from: modelContext)
        
        // Filter to top-level drivers only for funnel stats
        let topLevel = drivers.filter { $0.parentDriver == nil }
        
        let pending = topLevel.filter { $0.status == .pending }.count
        let confirmed = topLevel.filter { $0.status == .confirmed }.count
        let discarded = topLevel.filter { $0.status == .discarded }.count
        let needsRevision = topLevel.filter { $0.status == .needsRevision }.count
        
        // Evidence coverage
        let withEvidence = topLevel.filter { !$0.hasBlindSpot }.count
        let withBlindSpots = topLevel.filter { $0.hasBlindSpot }.count
        
        // Drivers by question
        var driversByQuestion: [(ResearchQuestion, [Driver])] = []
        for question in questions.filter({ $0.status == .active }) {
            if let questionDrivers = question.drivers, !questionDrivers.isEmpty {
                driversByQuestion.append((question, questionDrivers))
            }
        }
        
        return DriverAnalytics(
            totalDrivers: topLevel.count,
            pendingDrivers: pending,
            confirmedDrivers: confirmed,
            discardedDrivers: discarded,
            needsRevisionDrivers: needsRevision,
            driversWithEvidence: withEvidence,
            driversWithBlindSpots: withBlindSpots,
            driversByQuestion: driversByQuestion
        )
    }
    
    // MARK: - Review Analytics
    
    /**
     Computes review schedule and adherence metrics.
     
     - Parameter modelContext: The SwiftData model context
     - Returns: Review analytics summary
     */
    func computeReviewAnalytics(modelContext: ModelContext) -> ReviewAnalytics {
        let reminders = fetchAll(ReviewReminder.self, from: modelContext)
        let logEntries = fetchAll(LogEntry.self, from: modelContext)
        
        let enabled = reminders.filter { $0.isEnabled }
        let due = enabled.filter { $0.isDue }
        let overdue = enabled.filter { ($0.daysUntilDue ?? 0) < 0 }
        let snoozed = enabled.filter { $0.isSnoozed }
        
        // Upcoming reviews (next 14 days)
        var upcoming: [(ReviewReminder, ResearchQuestion)] = []
        for reminder in enabled {
            if let days = reminder.daysUntilDue, days >= 0 && days <= 14,
               let question = reminder.researchQuestion {
                upcoming.append((reminder, question))
            }
        }
        upcoming.sort { ($0.0.daysUntilDue ?? 0) < ($1.0.daysUntilDue ?? 0) }
        
        // Review outcomes from log entries
        let reviewLogs = logEntries.filter { $0.entryType == .review && $0.isSystemGenerated }
        var outcomes: [ReviewOutcome: Int] = [.reinforce: 0, .revise: 0, .invalidate: 0]
        for log in reviewLogs {
            if log.title.contains("Reinforce") {
                outcomes[.reinforce, default: 0] += 1
            } else if log.title.contains("Revise") {
                outcomes[.revise, default: 0] += 1
            } else if log.title.contains("Invalidate") {
                outcomes[.invalidate, default: 0] += 1
            }
        }
        
        // Average snooze count
        let totalSnoozes = reminders.reduce(0) { $0 + $1.snoozeCount }
        let avgSnooze = reminders.isEmpty ? 0.0 : Double(totalSnoozes) / Double(reminders.count)
        
        // Days since last review distribution
        var daysSinceReview: [Int] = []
        for reminder in enabled {
            if let question = reminder.researchQuestion,
               let lastReview = question.lastReviewedAt {
                let days = Calendar.current.dateComponents([.day], from: lastReview, to: Date()).day ?? 0
                daysSinceReview.append(days)
            }
        }
        
        return ReviewAnalytics(
            totalReminders: reminders.count,
            enabledReminders: enabled.count,
            dueReviews: due.count,
            overdueReviews: overdue.count,
            snoozedReviews: snoozed.count,
            upcomingReviews: upcoming,
            reviewOutcomes: outcomes,
            averageSnoozeCount: avgSnooze,
            daysSinceReviewDistribution: daysSinceReview
        )
    }
    
    // MARK: - Risk Alerts
    
    /**
     Generates risk alerts based on current data state.
     
     - Parameter modelContext: The SwiftData model context
     - Returns: Array of risk alerts sorted by severity
     */
    func generateRiskAlerts(modelContext: ModelContext) -> [RiskAlert] {
        var alerts: [RiskAlert] = []
        
        let questions = fetchAll(ResearchQuestion.self, from: modelContext)
        let reminders = fetchAll(ReviewReminder.self, from: modelContext)
        
        let now = Date()
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
        
        // Check each active research question
        for question in questions.filter({ $0.status == .active }) {
            
            // 1. Recent contradicting evidence surge
            if let drivers = question.drivers {
                let allEvidence = drivers.flatMap { $0.evidence ?? [] }
                let recentContradicting = allEvidence.filter { $0.sentiment == .contradicting && $0.capturedAt > sevenDaysAgo }
                if recentContradicting.count >= 2 {
                    alerts.append(RiskAlert(
                        type: .contradictingEvidence,
                        severity: .warning,
                        title: "Contradicting Evidence Surge",
                        description: "\(recentContradicting.count) contradicting evidence items added in the last 7 days",
                        relatedQuestion: question,
                        createdAt: now
                    ))
                }
            }
            
            // 2. Stale research
            if question.updatedAt < thirtyDaysAgo {
                let daysSinceUpdate = Calendar.current.dateComponents([.day], from: question.updatedAt, to: now).day ?? 0
                alerts.append(RiskAlert(
                    type: .staleResearch,
                    severity: daysSinceUpdate > 60 ? .warning : .info,
                    title: "Stale Research",
                    description: "No updates in \(daysSinceUpdate) days",
                    relatedQuestion: question,
                    createdAt: now
                ))
            }
            
            // 3. Blind spots > 50%
            if let drivers = question.drivers {
                let topLevel = drivers.filter { $0.parentDriver == nil }
                let blindSpots = topLevel.filter { $0.hasBlindSpot }.count
                if topLevel.count > 0 && Double(blindSpots) / Double(topLevel.count) > 0.5 {
                    alerts.append(RiskAlert(
                        type: .blindSpots,
                        severity: .warning,
                        title: "Blind Spot Warning",
                        description: "\(blindSpots) of \(topLevel.count) assumptions have no evidence",
                        relatedQuestion: question,
                        createdAt: now
                    ))
                }
            }
            
            // 4. Low health score
            if let drivers = question.drivers, !drivers.isEmpty {
                let healthScore = ConvictionHealthSummary.from(drivers: drivers).healthScore
                if healthScore < 30 {
                    alerts.append(RiskAlert(
                        type: .invalidationRisk,
                        severity: .critical,
                        title: "Invalidation Risk",
                        description: "Health score is critically low (\(healthScore)/100)",
                        relatedQuestion: question,
                        createdAt: now
                    ))
                }
            }
            
            // 5. Unresolved drivers (> 3 pending for > 14 days)
            if let drivers = question.drivers {
                let pendingDrivers = drivers.filter { $0.status == .pending && $0.parentDriver == nil }
                let fourteenDaysAgo = Calendar.current.date(byAdding: .day, value: -14, to: now) ?? now
                let oldPending = pendingDrivers.filter { $0.createdAt < fourteenDaysAgo }
                if oldPending.count >= 3 {
                    alerts.append(RiskAlert(
                        type: .unresolvedDrivers,
                        severity: .info,
                        title: "Unresolved Assumptions",
                        description: "\(oldPending.count) assumptions pending for over 2 weeks",
                        relatedQuestion: question,
                        createdAt: now
                    ))
                }
            }
        }
        
        // 6. Overdue reviews
        for reminder in reminders.filter({ $0.isEnabled }) {
            if let days = reminder.daysUntilDue, days < -7,
               let question = reminder.researchQuestion {
                alerts.append(RiskAlert(
                    type: .overdueReview,
                    severity: days < -14 ? .warning : .info,
                    title: "Overdue Review",
                    description: "Review overdue by \(abs(days)) days",
                    relatedQuestion: question,
                    createdAt: now
                ))
            }
        }
        
        // Sort by severity (critical first) then by date
        return alerts.sorted { 
            if $0.severity != $1.severity {
                return $0.severity > $1.severity
            }
            return $0.createdAt > $1.createdAt
        }
    }
    
    // MARK: - Helper Methods
    
    /**
     Fetches all instances of a model type.
     */
    private func fetchAll<T: PersistentModel>(_ type: T.Type, from modelContext: ModelContext) -> [T] {
        let descriptor = FetchDescriptor<T>()
        return (try? modelContext.fetch(descriptor)) ?? []
    }
}

