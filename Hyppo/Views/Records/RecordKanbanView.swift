/**
 RecordKanbanView displays research questions in a Kanban board layout.
 
 Organizes questions into columns based on their status:
 Active, On Hold, Invalidated, Archived.
 
 Features:
 - Drag and drop cards between columns to change status
 - Click card to navigate to detail view
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
    
    // MARK: - State
    
    @State private var draggingQuestion: ResearchQuestion?
    @State private var targetStatus: ResearchQuestionStatus?
    
    // MARK: - Body
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(alignment: .top, spacing: 16) {
                ForEach(ResearchQuestionStatus.allCases) { status in
                    kanbanColumn(for: status)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Kanban Column
    
    private func kanbanColumn(for status: ResearchQuestionStatus) -> some View {
        let columnQuestions = questions.filter { $0.status == status }
            .sorted { $0.updatedAt > $1.updatedAt }
        
        let isDropTarget = targetStatus == status && draggingQuestion?.status != status
        
        return VStack(alignment: .leading, spacing: 12) {
            // Column header
            columnHeader(status: status, count: columnQuestions.count)
            
            // Column content with drop zone
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    ForEach(columnQuestions) { question in
                        kanbanCard(for: question)
                    }
                    
                    if columnQuestions.isEmpty {
                        emptyColumnPlaceholder(isTargeted: isDropTarget)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 12)
            }
        }
        .frame(width: 280)
        .background(isDropTarget ? statusColor(for: status).opacity(0.15) : columnBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isDropTarget ? statusColor(for: status) : Color.clear, lineWidth: 2)
        )
        .animation(.easeInOut(duration: 0.2), value: isDropTarget)
        .onDrop(of: [.text], delegate: KanbanDropDelegate(
            targetStatus: status,
            currentTargetStatus: $targetStatus,
            draggingQuestion: $draggingQuestion,
            onDrop: { handleDrop(to: status) }
        ))
    }
    
    // MARK: - Kanban Card
    
    private func kanbanCard(for question: ResearchQuestion) -> some View {
        RecordCardView(
            question: question,
            isSelected: draggingQuestion == question,
            isCompact: true
        )
        .opacity(draggingQuestion == question ? 0.5 : 1.0)
        .onDrag {
            self.draggingQuestion = question
            return NSItemProvider(object: question.questionId.uuidString as NSString)
        }
        .onTapGesture {
            navigationPath.append(question)
        }
        .contextMenu {
            contextMenu(for: question)
        }
    }
    
    // MARK: - Drop Handling
    
    private func handleDrop(to status: ResearchQuestionStatus) {
        guard let question = draggingQuestion else { return }
        
        if question.status != status {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                question.status = status
            }
        }
        
        // Reset state
        draggingQuestion = nil
        targetStatus = nil
    }
    
    // MARK: - Column Header
    
    private func columnHeader(status: ResearchQuestionStatus, count: Int) -> some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: status.iconName)
                    .font(.subheadline)
                    .foregroundStyle(statusColor(for: status))
                
                Text(status.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            Text("\(count)")
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(columnHeaderBackground(for: status))
    }
    
    // MARK: - Empty State
    
    private func emptyColumnPlaceholder(isTargeted: Bool) -> some View {
        VStack(spacing: 8) {
            Image(systemName: isTargeted ? "arrow.down.circle.fill" : "tray")
                .font(.title2)
                .foregroundStyle(isTargeted ? Color.blue : Color.gray.opacity(0.5))
            
            Text(isTargeted ? "Drop here" : "No questions")
                .font(.caption)
                .foregroundStyle(isTargeted ? Color.blue : Color.gray.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(isTargeted ? Color.blue.opacity(0.1) : Color(nsColor: .separatorColor).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(style: StrokeStyle(lineWidth: 2, dash: isTargeted ? [] : [6, 4]))
                .foregroundStyle(isTargeted ? Color.blue : Color(nsColor: .separatorColor).opacity(0.3))
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
        Color(nsColor: .windowBackgroundColor).opacity(0.5)
    }
    
    private func columnHeaderBackground(for status: ResearchQuestionStatus) -> some View {
        statusColor(for: status).opacity(0.1)
    }
    
    private func statusColor(for status: ResearchQuestionStatus) -> Color {
        switch status {
        case .active: return .green
        case .onHold: return .orange
        case .invalidated: return .red
        case .archived: return .gray
        }
    }
}

// MARK: - Drop Delegate

/// Custom drop delegate for kanban drag-and-drop
private struct KanbanDropDelegate: DropDelegate {
    let targetStatus: ResearchQuestionStatus
    @Binding var currentTargetStatus: ResearchQuestionStatus?
    @Binding var draggingQuestion: ResearchQuestion?
    let onDrop: () -> Void
    
    func dropEntered(info: DropInfo) {
        currentTargetStatus = targetStatus
    }
    
    func dropExited(info: DropInfo) {
        if currentTargetStatus == targetStatus {
            currentTargetStatus = nil
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        onDrop()
        currentTargetStatus = nil
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
        navigationPath: .constant(NavigationPath())
    )
    .frame(width: 1000, height: 600)
}
