/**
 RecordCardGridView displays research questions in a responsive card grid.
 
 Supports dynamic grouping by various properties with section headers:
 - Status: Active, On Hold, Invalidated, Archived
 - Asset: Grouped by ticker
 - Confidence: Grouped by confidence level
 - Tags: Grouped by tag name
 - Created/Updated Date: Grouped by month
 
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
    
    // MARK: - Layout Constants
    
    private let maxContentWidth: CGFloat = 1000
    
    // MARK: - Body
    
    var body: some View {
        if questions.isEmpty {
            emptyState
        } else {
            GeometryReader { geometry in
                ScrollView {
                    HStack {
                        Spacer(minLength: 0)
                        VStack(spacing: 24) {
                            if config.groupByColumn == .none {
                                // No grouping - flat grid
                                flatCardGrid
                            } else {
                                // Grouped with section headers
                                groupedCardGrid
                            }
                        }
                        .frame(maxWidth: maxContentWidth)
                        Spacer(minLength: 0)
                    }
                    .padding()
                    .frame(minWidth: geometry.size.width)
                }
            }
        }
    }
    
    // MARK: - Flat Grid (No Grouping)
    
    private var flatCardGrid: some View {
        LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(sortedQuestions) { question in
                cardView(for: question)
            }
        }
    }
    
    // MARK: - Grouped Grid
    
    private var groupedCardGrid: some View {
        ForEach(groupedSections, id: \.id) { section in
            VStack(alignment: .leading, spacing: 12) {
                // Section header
                sectionHeader(section)
                
                // Cards in section
                LazyVGrid(columns: columns, spacing: spacing) {
                    ForEach(section.questions) { question in
                        cardView(for: question)
                    }
                }
            }
        }
    }
    
    // MARK: - Section Header
    
    private func sectionHeader(_ section: CardSection) -> some View {
        HStack(spacing: 10) {
            Image(systemName: section.icon)
                .font(.title3)
                .foregroundStyle(section.color)
            
            Text(section.title)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("\(section.questions.count)")
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(section.color.opacity(0.15))
                .foregroundStyle(section.color)
                .clipShape(Capsule())
            
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)
    }
    
    // MARK: - Card View
    
    private func cardView(for question: ResearchQuestion) -> some View {
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
    
    // MARK: - Grouped Sections
    
    /// Represents a section with a grouping key and questions
    struct CardSection: Identifiable {
        let id: String
        let title: String
        let icon: String
        let color: Color
        let questions: [ResearchQuestion]
    }
    
    /// Generates sections based on the current groupBy setting
    private var groupedSections: [CardSection] {
        switch config.groupByColumn {
        case .none:
            return []
        case .status:
            return statusGroupedSections
        case .asset:
            return assetGroupedSections
        case .confidence:
            return confidenceGroupedSections
        case .tags:
            return tagGroupedSections
        case .createdDate:
            return dateGroupedSections(keyPath: \.createdAt, label: "Created")
        case .updatedDate:
            return dateGroupedSections(keyPath: \.updatedAt, label: "Updated")
        }
    }
    
    private var statusGroupedSections: [CardSection] {
        ResearchQuestionStatus.allCases.compactMap { status in
            let sectionQuestions = sortedQuestions.filter { $0.status == status }
            guard !sectionQuestions.isEmpty else { return nil }
            return CardSection(
                id: status.rawValue,
                title: status.displayName,
                icon: status.iconName,
                color: statusColor(for: status),
                questions: sectionQuestions
            )
        }
    }
    
    private var assetGroupedSections: [CardSection] {
        var groups: [String: [ResearchQuestion]] = [:]
        var noAssetQuestions: [ResearchQuestion] = []
        
        for question in sortedQuestions {
            if let asset = question.asset {
                let key = asset.ticker
                groups[key, default: []].append(question)
            } else {
                noAssetQuestions.append(question)
            }
        }
        
        var sections = groups.keys.sorted().compactMap { ticker -> CardSection? in
            guard let questions = groups[ticker], !questions.isEmpty else { return nil }
            return CardSection(
                id: ticker,
                title: ticker,
                icon: "building.2",
                color: Color.accentColor,
                questions: questions
            )
        }
        
        if !noAssetQuestions.isEmpty {
            sections.append(CardSection(
                id: "_no_asset",
                title: "No Asset",
                icon: "folder",
                color: Color.statusArchived,
                questions: noAssetQuestions
            ))
        }
        
        return sections
    }
    
    private var confidenceGroupedSections: [CardSection] {
        var sections = ConfidenceLevel.allCases.compactMap { level -> CardSection? in
            let sectionQuestions = sortedQuestions.filter { $0.confidenceCurrent == level.rawValue }
            guard !sectionQuestions.isEmpty else { return nil }
            return CardSection(
                id: "confidence_\(level.rawValue)",
                title: level.displayName,
                icon: "gauge",
                color: confidenceColor(for: level),
                questions: sectionQuestions
            )
        }
        
        let notSetQuestions = sortedQuestions.filter { $0.confidenceCurrent == nil }
        if !notSetQuestions.isEmpty {
            sections.append(CardSection(
                id: "confidence_none",
                title: "Not Set",
                icon: "gauge",
                color: Color.statusArchived,
                questions: notSetQuestions
            ))
        }
        
        return sections
    }
    
    private var tagGroupedSections: [CardSection] {
        var tagQuestions: [String: (tag: Tag, questions: [ResearchQuestion])] = [:]
        var untaggedQuestions: [ResearchQuestion] = []
        
        for question in sortedQuestions {
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
        
        var sections = tagQuestions.values.sorted { $0.tag.name < $1.tag.name }.compactMap { item -> CardSection? in
            guard !item.questions.isEmpty else { return nil }
            return CardSection(
                id: item.tag.tagId.uuidString,
                title: item.tag.name,
                icon: "tag",
                color: tagColor(for: item.tag),
                questions: item.questions
            )
        }
        
        if !untaggedQuestions.isEmpty {
            sections.append(CardSection(
                id: "_untagged",
                title: "Untagged",
                icon: "tag.slash",
                color: Color.statusArchived,
                questions: untaggedQuestions
            ))
        }
        
        return sections
    }
    
    private func dateGroupedSections(keyPath: KeyPath<ResearchQuestion, Date>, label: String) -> [CardSection] {
        let calendar = Calendar.current
        var groups: [String: (date: Date, questions: [ResearchQuestion])] = [:]
        
        for question in sortedQuestions {
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
        
        return groups.keys.sorted().reversed().compactMap { key -> CardSection? in
            guard let item = groups[key], !item.questions.isEmpty else { return nil }
            return CardSection(
                id: key,
                title: dateFormatter.string(from: item.date),
                icon: "calendar",
                color: .purple,
                questions: item.questions
            )
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
                
            case .drivers, .logEntries, .tags:
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
    
    // MARK: - Colors
    
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
