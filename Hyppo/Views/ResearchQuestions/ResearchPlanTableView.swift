import SwiftUI

/**
 A flat table view of the Driver hierarchy, mimicking a McKinsey work plan.
 */
struct ResearchPlanTableView: View {
    let drivers: [Driver]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 0) {
                headerCell("Assumption", width: 200)
                headerCell("Validation Question", width: 250)
                headerCell("Data Sources", width: 150)
                headerCell("Proof Threshold", width: 150)
                headerCell("Evidence", width: 80)
            }
            .background(Color(nsColor: .headerColor))
            
            Divider()
            
            // Rows
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(drivers.sorted(by: { $0.position < $1.position })) { driver in
                        if driver.parentDriver == nil {
                            driverRow(driver, isSub: false)
                            
                            if let subs = driver.subDrivers?.sorted(by: { $0.position < $1.position }) {
                                ForEach(subs) { sub in
                                    driverRow(sub, isSub: true)
                                }
                            }
                        }
                    }
                }
            }
        }
        .border(Color(nsColor: .separatorColor))
    }
    
    private func headerCell(_ title: String, width: CGFloat) -> some View {
        Text(title)
            .font(.caption)
            .fontWeight(.bold)
            .padding(8)
            .frame(width: width, alignment: .leading)
    }
    
    private func driverRow(_ driver: Driver, isSub: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text(isSub ? "  → \(driver.title)" : driver.title)
                    .font(.subheadline)
                    .padding(8)
                    .frame(width: 200, alignment: .leading)
                
                Text(driver.validationQuestion ?? "-")
                    .font(.caption)
                    .padding(8)
                    .frame(width: 250, alignment: .leading)
                
                Text(driver.dataSources?.joined(separator: ", ") ?? "-")
                    .font(.caption)
                    .padding(8)
                    .frame(width: 150, alignment: .leading)
                
                Text(driver.proofThreshold ?? "-")
                    .font(.caption)
                    .padding(8)
                    .frame(width: 150, alignment: .leading)
                
                HStack {
                    Text("\(driver.directEvidenceCount)")
                    if driver.hasBlindSpot {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                }
                .font(.caption)
                .padding(8)
                .frame(width: 80, alignment: .center)
            }
            Divider()
        }
        .background(isSub ? Color(nsColor: .controlBackgroundColor).opacity(0.3) : Color.clear)
    }
}

