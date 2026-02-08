/**
 DecisionDetailView displays the full details of a single investment decision.
 
 Shows all captured data including:
 - Action type and rationale
 - Research state snapshot at decision time
 - Expectations and exit plan (if applicable)
 - Related outcome (if recorded)
 */

import SwiftUI
import SwiftData

/// Detail view for inspecting a single decision
struct DecisionDetailView: View {
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Properties
    
    let decision: Decision
    
    // MARK: - Computed Properties
    
    private var actionColor: Color {
        Color(decision.actionType.colorName)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    headerSection
                    
                    Divider()
                    
                    // Rationale
                    rationaleSection
                    
                    // Research snapshot
                    snapshotSection
                    
                    // Expectations (if applicable)
                    if decision.hasExpectations {
                        expectationsSection
                    }
                    
                    // Exit plan (if applicable)
                    if decision.hasExitPlan {
                        exitPlanSection
                    }
                    
                    // What would change my mind (for Pass decisions)
                    if let whatWouldChange = decision.whatWouldChangeMyMind, !whatWouldChange.isEmpty {
                        whatWouldChangeSection(whatWouldChange)
                    }
                    
                    // Price (if recorded)
                    if let price = decision.priceAtDecision, !price.isEmpty {
                        priceSection(price)
                    }
                }
                .padding()
            }
            .navigationTitle("Decision Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
    
    // MARK: - Subviews
    
    private var headerSection: some View {
        HStack(spacing: 16) {
            // Action icon
            ZStack {
                Circle()
                    .fill(actionColor.opacity(0.15))
                    .frame(width: 60, height: 60)
                
                Image(systemName: decision.actionType.iconName)
                    .font(.title)
                    .foregroundStyle(actionColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(decision.actionType.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(actionColor)
                
                Text(formatDate(decision.decidedAt))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                // Ticker if available
                if let ticker = decision.researchQuestion?.asset?.ticker {
                    Text(ticker)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            
            Spacer()
        }
    }
    
    private var rationaleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(title: "Rationale", icon: "text.quote")
            
            Text(decision.rationale)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .windowBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private var snapshotSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(title: "Research State at Decision", icon: "camera.fill")
            
            HStack(spacing: 20) {
                snapshotItem(
                    icon: "star.fill",
                    label: "Confidence",
                    value: decision.confidenceLevel?.shortLabel ?? "Not set",
                    color: .yellow
                )
                
                snapshotItem(
                    icon: "checkmark.circle.fill",
                    label: "Confirmed",
                    value: "\(decision.driversConfirmedCount)",
                    color: .green
                )
                
                snapshotItem(
                    icon: "circle.dashed",
                    label: "Under Review",
                    value: "\(decision.driversPendingCount)",
                    color: .gray
                )
                
                snapshotItem(
                    icon: "xmark.circle.fill",
                    label: "Discarded",
                    value: "\(decision.driversDiscardedCount)",
                    color: .red
                )
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private func snapshotItem(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var expectationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(title: "Expectations", icon: "target")
            
            VStack(alignment: .leading, spacing: 12) {
                if let outcome = decision.expectedOutcome {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Expected Outcome")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(outcome)
                            .font(.subheadline)
                    }
                }
                
                if let timeframe = decision.expectedTimeframe {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Expected Timeframe")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(timeframe)
                            .font(.subheadline)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.green.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private var exitPlanSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(title: "Exit Plan", icon: "door.left.hand.open")
            
            Text(decision.exitPlan ?? "")
                .font(.subheadline)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private func whatWouldChangeSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(title: "What Would Change My Mind", icon: "arrow.triangle.2.circlepath")
            
            Text(text)
                .font(.subheadline)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private func priceSection(_ price: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(title: "Price at Decision", icon: "dollarsign.circle")
            
            Text(price)
                .font(.title2)
                .fontWeight(.semibold)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .windowBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    // MARK: - Helper Views
    
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .foregroundStyle(.secondary)
    }
    
    // MARK: - Helpers
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    let decision = Decision(
        actionType: .buy,
        rationale: "Drivers confirmed, valuation reasonable after pullback, AI demand thesis validated by Q4 earnings",
        confidenceAtDecision: 4,
        driversConfirmedCount: 3,
        driversPendingCount: 1,
        driversDiscardedCount: 0
    )
    decision.expectedOutcome = "30% upside over 12 months as AI revenue accelerates"
    decision.expectedTimeframe = "12 months"
    decision.priceAtDecision = "$125.00"
    decision.exitPlan = "Sell 50% at $160, remainder at $180. Stop loss at $100. Exit if AI demand thesis breaks."
    
    return DecisionDetailView(decision: decision)
}

