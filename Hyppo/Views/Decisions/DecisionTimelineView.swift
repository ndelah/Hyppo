/**
 DecisionTimelineView displays a chronological timeline of decisions for a research question.
 
 Shows all decisions from the investment lifecycle:
 - Pass decisions during watching phase
 - Entry decision (Buy)
 - Position management decisions (Hold, Add, Trim)
 - Exit decision
 - Outcome (if recorded)
 */

import SwiftUI
import SwiftData

/// Timeline view showing all decisions for a research question
struct DecisionTimelineView: View {
    // MARK: - Properties
    
    let researchQuestion: ResearchQuestion
    let onDecisionTapped: ((Decision) -> Void)?
    
    // MARK: - Initialization
    
    init(researchQuestion: ResearchQuestion, onDecisionTapped: ((Decision) -> Void)? = nil) {
        self.researchQuestion = researchQuestion
        self.onDecisionTapped = onDecisionTapped
    }
    
    // MARK: - Computed Properties
    
    private var sortedDecisions: [Decision] {
        researchQuestion.sortedDecisions
    }
    
    private var hasDecisions: Bool {
        !sortedDecisions.isEmpty
    }
    
    private var outcome: Outcome? {
        researchQuestion.outcome
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if hasDecisions {
                ForEach(Array(sortedDecisions.enumerated()), id: \.element.decisionId) { index, decision in
                    DecisionTimelineItem(
                        decision: decision,
                        isFirst: index == 0,
                        isLast: index == sortedDecisions.count - 1 && outcome == nil,
                        onTap: { onDecisionTapped?(decision) }
                    )
                }
                
                // Show outcome at the end if exists
                if let outcome = outcome {
                    OutcomeTimelineItem(outcome: outcome)
                }
            } else {
                emptyState
            }
        }
    }
    
    // MARK: - Subviews
    
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.title2)
                .foregroundStyle(.secondary)
            
            Text("No decisions yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text("Record your first decision to start tracking")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

// MARK: - Decision Timeline Item

/// A single decision item in the timeline
struct DecisionTimelineItem: View {
    let decision: Decision
    let isFirst: Bool
    let isLast: Bool
    let onTap: () -> Void
    
    private var actionColor: Color {
        Color(decision.actionType.colorName)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Timeline connector
            VStack(spacing: 0) {
                // Top connector
                Rectangle()
                    .fill(isFirst ? Color.clear : Color(nsColor: .separatorColor))
                    .frame(width: 2, height: 12)
                
                // Action icon
                ZStack {
                    Circle()
                        .fill(actionColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: decision.actionType.iconName)
                        .font(.system(size: 14))
                        .foregroundStyle(actionColor)
                }
                
                // Bottom connector
                Rectangle()
                    .fill(isLast ? Color.clear : Color(nsColor: .separatorColor))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 32)
            
            // Content
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 6) {
                    // Header with action and date
                    HStack {
                        Text(decision.actionType.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(actionColor)
                        
                        Spacer()
                        
                        Text(formatDate(decision.decidedAt))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Rationale preview
                    Text(decision.rationale)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    
                    // Metadata row
                    HStack(spacing: 12) {
                        if let confidence = decision.confidenceLevel {
                            Label(confidence.shortLabel, systemImage: "star.fill")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        if let price = decision.priceAtDecision, !price.isEmpty {
                            Label(price, systemImage: "dollarsign.circle")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        if decision.hasExpectations {
                            Label("Expectations", systemImage: "target")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        if decision.hasExitPlan {
                            Label("Exit Plan", systemImage: "door.left.hand.open")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .windowBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Outcome Timeline Item

/// The outcome item at the end of the timeline
struct OutcomeTimelineItem: View {
    let outcome: Outcome
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Timeline connector
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color(nsColor: .separatorColor))
                    .frame(width: 2, height: 12)
                
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "flag.checkered")
                        .font(.system(size: 14))
                        .foregroundStyle(.purple)
                }
                
                // No bottom connector - this is always last
                Color.clear
                    .frame(width: 2, height: 12)
            }
            .frame(width: 32)
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                // Header
                HStack {
                    Text("Post-Mortem")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.purple)
                    
                    Spacer()
                    
                    Text(formatDate(outcome.recordedAt))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Result preview
                Text(outcome.actualResult)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                
                // Assessments
                HStack(spacing: 12) {
                    Label(outcome.thesisAssessment.displayName, systemImage: outcome.thesisAssessment.iconName)
                        .font(.caption2)
                        .foregroundStyle(Color(outcome.thesisAssessment.colorName))
                    
                    Label(outcome.timingAssessment.displayName, systemImage: outcome.timingAssessment.iconName)
                        .font(.caption2)
                        .foregroundStyle(Color(outcome.timingAssessment.colorName))
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.purple.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.purple.opacity(0.2), lineWidth: 1)
            )
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Compact Timeline View

/// A more compact version of the timeline for embedding in other views
struct CompactDecisionTimelineView: View {
    let researchQuestion: ResearchQuestion
    
    private var sortedDecisions: [Decision] {
        researchQuestion.sortedDecisions
    }
    
    var body: some View {
        if sortedDecisions.isEmpty {
            Text("No decisions recorded")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            HStack(spacing: 4) {
                ForEach(sortedDecisions) { decision in
                    Image(systemName: decision.actionType.iconName)
                        .font(.caption)
                        .foregroundStyle(Color(decision.actionType.colorName))
                }
                
                if researchQuestion.outcome != nil {
                    Image(systemName: "flag.checkered")
                        .font(.caption)
                        .foregroundStyle(.purple)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("With Decisions") {
    let rq = ResearchQuestion(
        questionText: "Is NVDA a good investment?",
        thesisStatement: "AI demand will continue to drive datacenter growth"
    )
    
    // Add some decisions
    let pass1 = Decision(
        actionType: .pass,
        rationale: "Valuation too stretched, waiting for pullback",
        decidedAt: Date().addingTimeInterval(-86400 * 30),
        confidenceAtDecision: 3
    )
    
    let buy = Decision(
        actionType: .buy,
        rationale: "Pullback provided good entry, drivers confirmed",
        decidedAt: Date().addingTimeInterval(-86400 * 15),
        confidenceAtDecision: 4
    )
    buy.expectedOutcome = "30% upside"
    buy.priceAtDecision = "$125"
    buy.exitPlan = "Sell at $160 or if AI thesis breaks"
    
    let hold = Decision(
        actionType: .hold,
        rationale: "Thesis intact, maintaining position",
        decidedAt: Date().addingTimeInterval(-86400 * 7),
        confidenceAtDecision: 4
    )
    
    rq.decisions = [pass1, buy, hold]
    rq.investmentPhaseRaw = InvestmentPhase.entered.rawValue
    
    return ScrollView {
        DecisionTimelineView(researchQuestion: rq)
            .padding()
    }
    .frame(width: 400, height: 500)
}

#Preview("Empty State") {
    let rq = ResearchQuestion(
        questionText: "Is NVDA a good investment?"
    )
    
    return DecisionTimelineView(researchQuestion: rq)
        .padding()
        .frame(width: 400, height: 200)
}

#Preview("With Outcome") {
    let rq = ResearchQuestion(
        questionText: "Is NVDA a good investment?",
        thesisStatement: "AI demand will continue to drive datacenter growth"
    )
    
    let buy = Decision(
        actionType: .buy,
        rationale: "Drivers confirmed",
        decidedAt: Date().addingTimeInterval(-86400 * 60),
        confidenceAtDecision: 4
    )
    buy.priceAtDecision = "$125"
    
    let exit = Decision(
        actionType: .exit,
        rationale: "Target reached",
        decidedAt: Date().addingTimeInterval(-86400 * 5),
        confidenceAtDecision: 4
    )
    exit.priceAtDecision = "$175"
    
    rq.decisions = [buy, exit]
    
    let outcome = Outcome(
        actualResult: "Thesis played out well, AI demand exceeded expectations",
        thesisAssessment: .correct,
        timingAssessment: .onTime
    )
    outcome.lessonsLearned = "Trust the process when drivers confirm"
    rq.outcome = outcome
    rq.investmentPhaseRaw = InvestmentPhase.postMortem.rawValue
    
    return ScrollView {
        DecisionTimelineView(researchQuestion: rq)
            .padding()
    }
    .frame(width: 400, height: 500)
}

