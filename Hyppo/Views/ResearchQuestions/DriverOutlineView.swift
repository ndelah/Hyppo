import SwiftUI

/**
 A collapsible outline editor for a 2-level Driver hierarchy.
 Used within the Research Wizard and Research Question forms.
 */
struct DriverOutlineView: View {
    @Binding var drivers: [DriverDTO]
    let prompt: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(prompt)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                ForEach(drivers.indices, id: \.self) { index in
                    DriverRowView(
                        driver: $drivers[index],
                        onDelete: { drivers.remove(at: index) },
                        onAddSubDriver: {
                            drivers[index].subDrivers.append(DriverDTO(title: "", isSubDriver: true))
                            drivers[index].isExpanded = true
                        }
                    )
                    
                    if drivers[index].isExpanded {
                        ForEach(drivers[index].subDrivers.indices, id: \.self) { subIndex in
                            DriverRowView(
                                driver: $drivers[index].subDrivers[subIndex],
                                onDelete: { drivers[index].subDrivers.remove(at: subIndex) },
                                onAddSubDriver: nil,
                                isSubDriver: true
                            )
                            .padding(.leading, 24)
                        }
                    }
                }
            }
            
            Button {
                drivers.append(DriverDTO(title: ""))
            } label: {
                Label("Add Assumption", systemImage: "plus.circle")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.blue)
            .padding(.top, 4)
        }
    }
}

/**
 Data Transfer Object for Driver to simplify form state management.
 */
struct DriverDTO: Identifiable {
    let id = UUID()
    var title: String
    var description: String = ""
    var validationQuestion: String = ""
    var dataSources: [String] = []
    var proofThreshold: String = ""
    var subDrivers: [DriverDTO] = []
    var isExpanded: Bool = false
    var isSubDriver: Bool = false
    var showDetails: Bool = false
}

struct DriverRowView: View {
    @Binding var driver: DriverDTO
    let onDelete: () -> Void
    let onAddSubDriver: (() -> Void)?
    var isSubDriver: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                if !isSubDriver {
                    Button {
                        driver.isExpanded.toggle()
                    } label: {
                        Image(systemName: "chevron.right")
                            .rotationEffect(.degrees(driver.isExpanded ? 90 : 0))
                            .foregroundStyle(.secondary)
                            .frame(width: 12)
                    }
                    .buttonStyle(.plain)
                    .opacity(driver.subDrivers.isEmpty ? 0.3 : 1.0)
                } else {
                    Image(systemName: "arrow.turn.down.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.leading, 4)
                }
                
                TextField(isSubDriver ? "Sub-assumption..." : "Main assumption...", text: $driver.title)
                    .textFieldStyle(.roundedBorder)
                
                Button {
                    driver.showDetails.toggle()
                } label: {
                    Image(systemName: "doc.text.magnifyingglass")
                        .foregroundStyle(driver.showDetails ? .blue : .secondary)
                }
                .buttonStyle(.plain)
                .help("Edit Research Plan")
                
                if let onAddSubDriver = onAddSubDriver {
                    Button {
                        onAddSubDriver()
                    } label: {
                        Image(systemName: "plus.square.dashed")
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                    .help("Add Sub-assumption")
                }
                
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
            
            if driver.showDetails {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Validation Question")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        TextField("What question validates this?", text: $driver.validationQuestion)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Proof Threshold")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        TextField("What would prove this true/false?", text: $driver.proofThreshold)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Data Sources")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        SourceTypePicker(selectedSources: $driver.dataSources)
                    }
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.top, 8)
                .padding(.leading, isSubDriver ? 24 : 20)
            }
        }
    }
}

struct SourceTypePicker: View {
    @Binding var selectedSources: [String]
    
    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(SourceType.allCases) { type in
                Toggle(isOn: Binding(
                    get: { selectedSources.contains(type.rawValue) },
                    set: { isOn in
                        if isOn {
                            selectedSources.append(type.rawValue)
                        } else {
                            selectedSources.removeAll { $0 == type.rawValue }
                        }
                    }
                )) {
                    Label(type.displayName, systemImage: type.iconName)
                        .font(.caption2)
                }
                .toggleStyle(.button)
            }
        }
    }
}

/**
 Simple flow layout for tags/toggles.
 */
struct FlowLayout: Layout {
    var spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        _ = layout(proposal: proposal, subviews: subviews, bounds: bounds)
    }
    
    private func layout(proposal: ProposedViewSize, subviews: Subviews, bounds: CGRect? = nil) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var currentX: CGFloat = bounds?.minX ?? 0
        var currentY: CGFloat = bounds?.minY ?? 0
        var lineHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        var positions: [CGPoint] = []
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth {
                currentX = bounds?.minX ?? 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            if let _ = bounds {
                positions.append(CGPoint(x: currentX + size.width / 2, y: currentY + size.height / 2))
                subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            }
            
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            totalWidth = max(totalWidth, currentX)
            totalHeight = max(totalHeight, currentY + lineHeight)
        }
        
        return (CGSize(width: totalWidth, height: totalHeight), positions)
    }
}

