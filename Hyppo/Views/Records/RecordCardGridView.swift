/**
 RecordCardGridView displays research questions in a responsive card grid.
 
 Uses a flexible grid layout that adapts to available width,
 showing cards at a consistent size with proper spacing.
 Click a card to navigate to its detail view.
 */

import SwiftUI
import SwiftData

/// Card grid view for research question records
struct RecordCardGridView: View {
    // MARK: - Properties
    
    let questions: [ResearchQuestion]
    @Binding var navigationPath: NavigationPath
    @Bindable var config: ViewConfiguration
    
    // MARK: - Layout
    
    private let cardMinWidth: CGFloat = 280
    private let cardMaxWidth: CGFloat = 350
    private let spacing: CGFloat = 16
    
    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: cardMinWidth, maximum: cardMaxWidth), spacing: spacing)]
    }
    
    // MARK: - Body
    
    var body: some View {
        if questions.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: spacing) {
                    ForEach(sortedQuestions) { question in
                        RecordCardView(
                            question: question,
                            isSelected: false,
                            isCompact: false
                        )
                        .onTapGesture {
                            navigationPath.append(question)
                        }
                        .contextMenu {
                            contextMenu(for: question)
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.grid.2x2")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            
            Text("No Research Questions")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text("Create a research question to get started")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Sorting
    
    private var sortedQuestions: [ResearchQuestion] {
        questions.sorted { lhs, rhs in
            let result: Bool
            
            switch config.sortColumn {
            case .question:
                result = lhs.questionText.localizedCaseInsensitiveCompare(rhs.questionText) == .orderedAscending
                
            case .assetName:
                let lhsTicker = lhs.asset?.ticker ?? ""
                let rhsTicker = rhs.asset?.ticker ?? ""
                result = lhsTicker.localizedCaseInsensitiveCompare(rhsTicker) == .orderedAscending
                
            case .status:
                result = lhs.statusRaw.localizedCaseInsensitiveCompare(rhs.statusRaw) == .orderedAscending
                
            case .confidence:
                let lhsConf = lhs.confidenceCurrent ?? 0
                let rhsConf = rhs.confidenceCurrent ?? 0
                result = lhsConf < rhsConf
                
            case .created:
                result = lhs.createdAt < rhs.createdAt
                
            case .updated:
                result = lhs.updatedAt < rhs.updatedAt
                
            case .drivers, .scenarios, .logEntries, .tags:
                // Non-sortable columns default to updated date
                result = lhs.updatedAt < rhs.updatedAt
            }
            
            return config.sortAscending ? result : !result
        }
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
        
        Menu("Change Status") {
            ForEach(ResearchQuestionStatus.allCases) { status in
                Button {
                    question.status = status
                } label: {
                    if question.status == status {
                        Label(status.displayName, systemImage: "checkmark")
                    } else {
                        Text(status.displayName)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let question1 = ResearchQuestion(
        questionText: "Can AAPL sustain services revenue growth?",
        context: "Services now represent 20% of revenue",
        confidence: 4
    )
    
    let question2 = ResearchQuestion(
        questionText: "Will AI demand drive semiconductor growth?",
        context: "Data center spending accelerating",
        confidence: 3
    )
    
    let question3 = ResearchQuestion(
        questionText: "Is MSFT's cloud position defensible?",
        context: "Azure growth vs AWS competition",
        confidence: 4
    )
    
    return RecordCardGridView(
        questions: [question1, question2, question3],
        navigationPath: .constant(NavigationPath()),
        config: ViewConfiguration.shared
    )
    .frame(width: 800, height: 600)
}
