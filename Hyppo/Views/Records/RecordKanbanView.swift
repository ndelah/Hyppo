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

/// Kanban board view for research question records
struct RecordKanbanView: View {
    // MARK: - Properties
    
    let questions: [ResearchQuestion]
    @Binding var navigationPath: NavigationPath
    
    // MARK: - State
    
    @State private var draggingQuestion: ResearchQuestion?
    
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
        
        return VStack(alignment: .leading, spacing: 12) {
            // Column header
            columnHeader(status: status, count: columnQuestions.count)
            
            // Column content with drop destination
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    ForEach(columnQuestions) { question in
                        RecordCardView(
                            question: question,
                            isSelected: false,
                            isCompact: true
                        )
                        .draggable(question) {
                            // Drag preview
                            RecordCardView(
                                question: question,
                                isSelected: true,
                                isCompact: true
                            )
                            .frame(width: 250)
                            .opacity(0.8)
                        }
                        .onTapGesture {
                            navigationPath.append(question)
                        }
                        .contextMenu {
                            contextMenu(for: question)
                        }
                    }
                    
                    if columnQuestions.isEmpty {
                        emptyColumnPlaceholder
                    }
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 12)
            }
        }
        .frame(width: 280)
        .background(columnBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .dropDestination(for: ResearchQuestion.self) { droppedQuestions, _ in
            for question in droppedQuestions {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    question.status = status
                }
            }
            return true
        } isTargeted: { isTargeted in
            // Could add visual feedback when targeted
        }
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
    
    private var emptyColumnPlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.title2)
                .foregroundStyle(.tertiary)
            
            Text("Drop here")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color(nsColor: .separatorColor).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                .foregroundStyle(Color(nsColor: .separatorColor).opacity(0.3))
        )
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

// MARK: - ResearchQuestion Transferable Conformance

extension ResearchQuestion: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
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
