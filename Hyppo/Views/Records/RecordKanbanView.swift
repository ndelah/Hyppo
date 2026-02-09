/**
 RecordKanbanView displays research questions in a Kanban board layout.
 
 Supports dynamic grouping by various properties:
 - Status (default): Active, On Hold, Invalidated, Archived
 - Asset: Grouped by ticker
 - Confidence: Grouped by confidence level
 - Tags: Grouped by tag name
 - Created/Updated Date: Grouped by month
 
 Features:
 - Drag and drop cards between columns (for status grouping)
 - Click card to navigate to detail view
 - Centered layout with full width distribution
 */

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// Kanban board view for research question records
struct RecordKanbanView: View {
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Properties
    
    let questions: [ResearchQuestion]
    @Binding var navigationPath: NavigationPath
    @Bindable var config: ViewConfiguration
    
    // MARK: - State
    
    @State private var draggingQuestion: ResearchQuestion?
    @State private var targetColumnId: String?
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(alignment: .top, spacing: 16) {
                    ForEach(groupedColumns, id: \.id) { column in
                        kanbanColumn(for: column)
                    }
                }
                .padding()
                .frame(minWidth: geometry.size.width)
            }
        }
    }
    
    // MARK: - Grouped Columns
    
    /// Represents a kanban column with a grouping key and questions
    struct KanbanColumn: Identifiable {
        let id: String
        let title: String
        let icon: String
        let color: Color
        let questions: [ResearchQuestion]
        let status: ResearchQuestionStatus? // Only for status grouping (enables drag-drop)
    }
    
    /// Generates columns based on the current groupBy setting
    private var groupedColumns: [KanbanColumn] {
        switch config.groupByColumn {
        case .none, .status:
            return statusGroupedColumns
        case .asset:
            return assetGroupedColumns
        case .confidence:
            return confidenceGroupedColumns
        case .tags:
            return tagGroupedColumns
        case .createdDate:
            return dateGroupedColumns(keyPath: \.createdAt, label: "Created")
        case .updatedDate:
            return dateGroupedColumns(keyPath: \.updatedAt, label: "Updated")
        }
    }
    
    private var statusGroupedColumns: [KanbanColumn] {
        ResearchQuestionStatus.allCases.map { status in
            KanbanColumn(
                id: status.rawValue,
                title: status.displayName,
                icon: status.iconName,
                color: statusColor(for: status),
                questions: questions.filter { $0.status == status }.sorted { $0.updatedAt > $1.updatedAt },
                status: status
            )
        }
    }
    
    private var assetGroupedColumns: [KanbanColumn] {
        // Group by asset, with "No Asset" for questions without one
        var groups: [String: [ResearchQuestion]] = [:]
        var noAssetQuestions: [ResearchQuestion] = []
        
        for question in questions {
            if let asset = question.asset {
                let key = asset.ticker
                groups[key, default: []].append(question)
            } else {
                noAssetQuestions.append(question)
            }
        }
        
        var columns = groups.keys.sorted().map { ticker in
            KanbanColumn(
                id: ticker,
                title: ticker,
                icon: "building.2",
                color: Color.accentColor,
                questions: groups[ticker]!.sorted { $0.updatedAt > $1.updatedAt },
                status: nil
            )
        }
        
        if !noAssetQuestions.isEmpty {
            columns.append(KanbanColumn(
                id: "_no_asset",
                title: "No Asset",
                icon: "folder",
                color: Color.statusArchived,
                questions: noAssetQuestions.sorted { $0.updatedAt > $1.updatedAt },
                status: nil
            ))
        }
        
        return columns
    }
    
    private var confidenceGroupedColumns: [KanbanColumn] {
        ConfidenceLevel.allCases.map { level in
            KanbanColumn(
                id: "confidence_\(level.rawValue)",
                title: level.displayName,
                icon: "gauge",
                color: confidenceColor(for: level),
                questions: questions.filter { $0.confidenceCurrent == level.rawValue }.sorted { $0.updatedAt > $1.updatedAt },
                status: nil
            )
        } + [
            KanbanColumn(
                id: "confidence_none",
                title: "Not Set",
                icon: "gauge",
                color: Color.statusArchived,
                questions: questions.filter { $0.confidenceCurrent == nil }.sorted { $0.updatedAt > $1.updatedAt },
                status: nil
            )
        ]
    }
    
    private var tagGroupedColumns: [KanbanColumn] {
        // Collect all unique tags
        var tagQuestions: [String: (tag: Tag, questions: [ResearchQuestion])] = [:]
        var untaggedQuestions: [ResearchQuestion] = []
        
        for question in questions {
            if let tags = question.tags, !tags.isEmpty {
                for tag in tags {
                    if tagQuestions[tag.tagId.uuidString] == nil {
                        tagQuestions[tag.tagId.uuidString] = (tag: tag, questions: [])
                    }
                    tagQuestions[tag.tagId.uuidString]?.questions.append(question)
                }
            } else {
                untaggedQuestions.append(question)
            }
        }
        
        var columns = tagQuestions.values.sorted { $0.tag.name < $1.tag.name }.map { item in
            KanbanColumn(
                id: item.tag.tagId.uuidString,
                title: item.tag.name,
                icon: "tag",
                color: tagColor(for: item.tag),
                questions: item.questions.sorted { $0.updatedAt > $1.updatedAt },
                status: nil
            )
        }
        
        if !untaggedQuestions.isEmpty {
            columns.append(KanbanColumn(
                id: "_untagged",
                title: "Untagged",
                icon: "tag.slash",
                color: Color.statusArchived,
                questions: untaggedQuestions.sorted { $0.updatedAt > $1.updatedAt },
                status: nil
            ))
        }
        
        return columns
    }
    
    private func dateGroupedColumns(keyPath: KeyPath<ResearchQuestion, Date>, label: String) -> [KanbanColumn] {
        // Group by month
        let calendar = Calendar.current
        var groups: [String: (date: Date, questions: [ResearchQuestion])] = [:]
        
        for question in questions {
            let date = question[keyPath: keyPath]
            let components = calendar.dateComponents([.year, .month], from: date)
            let key = "\(components.year!)-\(String(format: "%02d", components.month!))"
            
            if groups[key] == nil {
                groups[key] = (date: calendar.date(from: components)!, questions: [])
            }
            groups[key]?.questions.append(question)
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM yyyy"
        
        return groups.keys.sorted().reversed().map { key in
            let item = groups[key]!
            return KanbanColumn(
                id: key,
                title: dateFormatter.string(from: item.date),
                icon: "calendar",
                color: .purple,
                questions: item.questions.sorted { $0.updatedAt > $1.updatedAt },
                status: nil
            )
        }
    }
    
    // MARK: - Kanban Column
    
    private func kanbanColumn(for column: KanbanColumn) -> some View {
        let isDropTarget = targetColumnId == column.id && column.status != nil
        let dropStatus = column.status
        
        return VStack(alignment: .leading, spacing: 12) {
            // Column header
            columnHeader(column: column)
            
            // Column content with drop zone
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    ForEach(column.questions) { question in
                        kanbanCard(for: question, allowDrag: column.status != nil)
                    }
                    
                    if column.questions.isEmpty {
                        emptyColumnPlaceholder(isTargeted: isDropTarget)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 12)
            }
        }
        .frame(width: 280)
        .background(isDropTarget ? column.color.opacity(0.15) : columnBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isDropTarget ? column.color : Color.clear, lineWidth: 2)
        )
        .animation(.easeInOut(duration: 0.2), value: isDropTarget)
        .modifier(DropTargetModifier(
            columnId: column.id,
            status: dropStatus,
            targetColumnId: $targetColumnId,
            draggingQuestion: $draggingQuestion
        ))
    }
    
    // MARK: - Kanban Card
    
    private func kanbanCard(for question: ResearchQuestion, allowDrag: Bool) -> some View {
        RecordCardView(
            question: question,
            isSelected: draggingQuestion == question,
            isCompact: true
        )
        .opacity(draggingQuestion == question ? 0.5 : 1.0)
        .if(allowDrag) { view in
            view.onDrag {
                self.draggingQuestion = question
                return NSItemProvider(object: question.questionId.uuidString as NSString)
            }
        }
        .onTapGesture {
            navigationPath.append(question)
        }
        .contextMenu {
            contextMenu(for: question)
        }
    }
    
    // MARK: - Column Header
    
    private func columnHeader(column: KanbanColumn) -> some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: column.icon)
                    .font(.subheadline)
                    .foregroundStyle(column.color)
                
                Text(column.title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            Text("\(column.questions.count)")
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.surface)
                .clipShape(Capsule())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(column.color.opacity(0.1))
    }
    
    // MARK: - Empty State
    
    private func emptyColumnPlaceholder(isTargeted: Bool) -> some View {
        VStack(spacing: 8) {
            Image(systemName: isTargeted ? "arrow.down.circle.fill" : "tray")
                .font(.title2)
                .foregroundStyle(isTargeted ? Color.accentColor : Color.statusArchived.opacity(0.5))
            
            Text(isTargeted ? "Drop here" : "No questions")
                .font(.caption)
                .foregroundStyle(isTargeted ? Color.accentColor : Color.statusArchived.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(isTargeted ? Color.appAccentSubtle : Color.appBorder.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(style: StrokeStyle(lineWidth: 2, dash: isTargeted ? [] : [6, 4]))
                .foregroundStyle(isTargeted ? Color.accentColor : Color.appBorder.opacity(0.3))
        )
        .animation(.easeInOut(duration: 0.2), value: isTargeted)
    }
    
    // MARK: - Context Menu
    
    @ViewBuilder
    private func contextMenu(for question: ResearchQuestion) -> some View {
        Button {
            navigationPath.append(question)
        } label: {
            Label("View Details", systemImage: "eye")
        }
        
        Divider()
        
        Menu("Move to") {
            ForEach(ResearchQuestionStatus.allCases) { status in
                if question.status != status {
                    Button {
                        withAnimation {
                            question.status = status
                        }
                    } label: {
                        Label(status.displayName, systemImage: status.iconName)
                    }
                }
            }
        }
    }
    
    // MARK: - Styling
    
    private var columnBackground: Color {
        Color.surface
    }
    
    private func statusColor(for status: ResearchQuestionStatus) -> Color {
        Color.forStatus(status)
    }
    
    private func confidenceColor(for level: ConfidenceLevel) -> Color {
        Color.forConfidence(level)
    }
    
    private func tagColor(for tag: Tag) -> Color {
        guard let colorName = tag.colorName,
              let color = TagColor(rawValue: colorName) else {
            return Color.accentColor
        }
        return color.color
    }
}

// MARK: - Conditional View Modifier

extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Drop Target Modifier

/// Modifier to handle drop targeting for kanban columns
private struct DropTargetModifier: ViewModifier {
    let columnId: String
    let status: ResearchQuestionStatus?
    @Binding var targetColumnId: String?
    @Binding var draggingQuestion: ResearchQuestion?
    
    func body(content: Content) -> some View {
        if let status = status {
            content.onDrop(of: [.text], delegate: KanbanDropDelegate(
                columnId: columnId,
                targetStatus: status,
                currentTargetColumnId: $targetColumnId,
                draggingQuestion: $draggingQuestion
            ))
        } else {
            content
        }
    }
}

// MARK: - Drop Delegate

/// Custom drop delegate for kanban drag-and-drop
private struct KanbanDropDelegate: DropDelegate {
    let columnId: String
    let targetStatus: ResearchQuestionStatus
    @Binding var currentTargetColumnId: String?
    @Binding var draggingQuestion: ResearchQuestion?
    
    func dropEntered(info: DropInfo) {
        currentTargetColumnId = columnId
    }
    
    func dropExited(info: DropInfo) {
        if currentTargetColumnId == columnId {
            currentTargetColumnId = nil
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        guard let question = draggingQuestion else { return false }
        
        if question.status != targetStatus {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                question.status = targetStatus
            }
        }
        
        draggingQuestion = nil
        currentTargetColumnId = nil
        return true
    }
}

// MARK: - Preview

#Preview {
    let active1 = ResearchQuestion(
        questionText: "Can AAPL sustain services revenue growth?",
        context: "Services now represent 20% of revenue",
        confidence: 4
    )
    
    let active2 = ResearchQuestion(
        questionText: "Will iPhone growth continue in emerging markets?",
        context: "India and Southeast Asia expansion",
        confidence: 3
    )
    
    let onHold = ResearchQuestion(
        questionText: "What's the potential for Apple Car?",
        context: "Project Titan status unclear",
        confidence: 2
    )
    onHold.status = .onHold
    
    return RecordKanbanView(
        questions: [active1, active2, onHold],
        navigationPath: .constant(NavigationPath()),
        config: ViewConfiguration.shared
    )
    .frame(width: 1000, height: 600)
}
