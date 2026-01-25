import SwiftUI

/**
 Dashboard showing evidence balance and conviction health for a research question.
 */
struct ConvictionHealthView: View {
    let drivers: [Driver]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Conviction Health")
                .font(.headline)
            
            VStack(spacing: 12) {
                // Summary Header
                HStack {
                    Text("Assumption")
                        .font(.caption)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Direct")
                        .font(.caption)
                        .fontWeight(.bold)
                        .frame(width: 60)
                    Text("Balance")
                        .font(.caption)
                        .fontWeight(.bold)
                        .frame(width: 60)
                    Text("Status")
                        .font(.caption)
                        .fontWeight(.bold)
                        .frame(width: 100)
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                
                Divider()
                
                ForEach(drivers.filter { $0.parentDriver == nil }.sorted(by: { $0.position < $1.position })) { driver in
                    healthRow(driver)
                }
            }
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func healthRow(_ driver: Driver) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(driver.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("\(driver.directEvidenceCount)")
                    .font(.caption)
                    .frame(width: 60)
                
                let balance = driver.totalEvidenceBalance
                Text(balance > 0 ? "+\(balance)" : "\(balance)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(balance > 0 ? .green : (balance < 0 ? .red : .secondary))
                    .frame(width: 60)
                
                statusBadge(for: driver)
                    .frame(width: 100)
            }
            .padding(.horizontal, 8)
            
            if let subs = driver.subDrivers, !subs.isEmpty {
                ForEach(subs.sorted(by: { $0.position < $1.position })) { sub in
                    HStack {
                        Text("  → \(sub.title)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("\(sub.directEvidenceCount)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .frame(width: 60)
                        
                        let balance = sub.totalEvidenceBalance
                        Text(balance > 0 ? "+\(balance)" : "\(balance)")
                            .font(.caption2)
                            .foregroundStyle(balance > 0 ? .green.opacity(0.8) : (balance < 0 ? .red.opacity(0.8) : .secondary))
                            .frame(width: 60)
                        
                        statusBadge(for: sub, isSmall: true)
                            .frame(width: 100)
                    }
                    .padding(.horizontal, 8)
                }
            }
            
            Divider()
                .padding(.vertical, 4)
        }
    }
    
    private func statusBadge(for driver: Driver, isSmall: Bool = false) -> some View {
        let balance = driver.totalEvidenceBalance
        let hasBlindSpot = driver.hasBlindSpot
        
        return Group {
            if hasBlindSpot {
                badge("Blind Spot", color: .orange, icon: "eye.slash", isSmall: isSmall)
            } else if balance > 0 {
                badge("Supported", color: .green, icon: "checkmark.circle", isSmall: isSmall)
            } else if balance < 0 {
                badge("Challenged", color: .red, icon: "exclamationmark.circle", isSmall: isSmall)
            } else {
                badge("Neutral", color: .gray, icon: "circle", isSmall: isSmall)
            }
        }
    }
    
    private func badge(_ text: String, color: Color, icon: String, isSmall: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text)
        }
        .font(isSmall ? .system(size: 9, weight: .bold) : .caption2.bold())
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.1))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }
}

