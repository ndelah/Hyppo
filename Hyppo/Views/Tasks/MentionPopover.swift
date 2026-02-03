/**
 MentionPopover provides a filterable selection list for @ and # mentions.
 
 Features:
 - Keyboard navigation (arrow keys, enter to select, escape to dismiss)
 - Real-time filtering as user types
 - Highlighted matching text
 - Configurable for different mention types (research questions, drivers)
 */

import SwiftUI
import SwiftData

// MARK: - Mention Item Protocol

/// Protocol for items that can be selected in a mention popover
protocol MentionItem: Identifiable, Hashable {
    var mentionDisplayTitle: String { get }
    var mentionSubtitle: String? { get }
    var mentionIcon: String { get }
    var mentionColor: Color { get }
}

// MARK: - Research Question Mention

/// Wrapper for ResearchQuestion to conform to MentionItem
struct ResearchQuestionMention: MentionItem {
    let question: ResearchQuestion
    
    var id: UUID { question.questionId }
    var mentionDisplayTitle: String {
        if let ticker = question.asset?.ticker {
            return "\(ticker): \(question.questionText)"
        }
        return question.questionText
    }
    var mentionSubtitle: String? {
        question.asset?.name
    }
    var mentionIcon: String { "doc.text.magnifyingglass" }
    var mentionColor: Color { .blue }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(question.questionId)
    }
    
    static func == (lhs: ResearchQuestionMention, rhs: ResearchQuestionMention) -> Bool {
        lhs.question.questionId == rhs.question.questionId
    }
}

// MARK: - Driver Mention

/// Wrapper for Driver to conform to MentionItem
struct DriverMention: MentionItem {
    let driver: Driver
    let isSubDriver: Bool
    
    var id: UUID { driver.driverId }
    var mentionDisplayTitle: String {
        isSubDriver ? "  → \(driver.title)" : driver.title
    }
    var mentionSubtitle: String? {
        driver.researchQuestion?.asset?.ticker
    }
    var mentionIcon: String { isSubDriver ? "arrow.turn.down.right" : "target" }
    var mentionColor: Color { .orange }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(driver.driverId)
    }
    
    static func == (lhs: DriverMention, rhs: DriverMention) -> Bool {
        lhs.driver.driverId == rhs.driver.driverId
    }
}

// MARK: - Mention Type

/// Type of mention being selected
enum MentionType {
    case researchQuestion
    case driver
    
    var symbol: String {
        switch self {
        case .researchQuestion: return "@"
        case .driver: return "#"
        }
    }
    
    var placeholder: String {
        switch self {
        case .researchQuestion: return "Search research questions..."
        case .driver: return "Search drivers..."
        }
    }
    
    var emptyMessage: String {
        switch self {
        case .researchQuestion: return "No research questions found"
        case .driver: return "No drivers found"
        }
    }
}

// MARK: - Mention Popover View

/// Generic popover for selecting mention items
struct MentionPopover<Item: MentionItem>: View {
    let mentionType: MentionType
    let items: [Item]
    let filterText: String
    let onSelect: (Item) -> Void
    let onDismiss: () -> Void
    
    @State private var selectedIndex: Int = 0
    @FocusState private var isFocused: Bool
    
    /// Filtered items based on search text
    private var filteredItems: [Item] {
        if filterText.isEmpty {
            return items
        }
        let searchText = filterText.lowercased()
        return items.filter { item in
            item.mentionDisplayTitle.lowercased().contains(searchText) ||
            (item.mentionSubtitle?.lowercased().contains(searchText) ?? false)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 6) {
                Text(mentionType.symbol)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Text(mentionType.placeholder)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                
                Spacer()
                
                Text("↑↓ navigate • ⏎/⇥ select • esc dismiss")
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            // Items list
            if filteredItems.isEmpty {
                emptyState
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                                MentionItemRow(
                                    item: item,
                                    filterText: filterText,
                                    isSelected: index == selectedIndex
                                )
                                .id(index)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    onSelect(item)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 250)
                    .onChange(of: selectedIndex) { _, newIndex in
                        withAnimation(.easeOut(duration: 0.1)) {
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                }
            }
        }
        .frame(width: 350)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        .focusable()
        .focused($isFocused)
        .onKeyPress(.upArrow) {
            moveSelection(by: -1)
            return .handled
        }
        .onKeyPress(.downArrow) {
            moveSelection(by: 1)
            return .handled
        }
        .onKeyPress(.return) {
            selectCurrentItem()
            return .handled
        }
        .onKeyPress(.tab) {
            selectCurrentItem()
            return .handled
        }
        .onKeyPress(.escape) {
            onDismiss()
            return .handled
        }
        .onChange(of: filterText) { _, _ in
            // Reset selection when filter changes
            selectedIndex = 0
        }
        .onAppear {
            // Request focus when popover appears so keyboard navigation works
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFocused = true
            }
        }
    }
    
    /// Selects the currently highlighted item
    private func selectCurrentItem() {
        if !filteredItems.isEmpty && selectedIndex < filteredItems.count {
            onSelect(filteredItems[selectedIndex])
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.title2)
                .foregroundStyle(.tertiary)
            
            Text(mentionType.emptyMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
    
    private func moveSelection(by delta: Int) {
        let newIndex = selectedIndex + delta
        if newIndex >= 0 && newIndex < filteredItems.count {
            selectedIndex = newIndex
        }
    }
}

// MARK: - Mention Item Row

/// Row view for displaying a mention item
struct MentionItemRow<Item: MentionItem>: View {
    let item: Item
    let filterText: String
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 10) {
            // Icon
            Image(systemName: item.mentionIcon)
                .font(.caption)
                .foregroundStyle(item.mentionColor)
                .frame(width: 20)
            
            // Title and subtitle
            VStack(alignment: .leading, spacing: 2) {
                highlightedText(item.mentionDisplayTitle)
                    .font(.subheadline)
                    .lineLimit(1)
                
                if let subtitle = item.mentionSubtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        .contentShape(Rectangle())
    }
    
    /// Creates text with highlighted matching portions
    @ViewBuilder
    private func highlightedText(_ text: String) -> some View {
        if filterText.isEmpty {
            Text(text)
        } else {
            Text(buildHighlightedAttributedString(text: text, filter: filterText))
        }
    }
    
    /// Builds an attributed string with the filter text highlighted in bold
    private func buildHighlightedAttributedString(text: String, filter: String) -> AttributedString {
        let lowercasedText = text.lowercased()
        let lowercasedFilter = filter.lowercased()
        
        guard let range = lowercasedText.range(of: lowercasedFilter) else {
            return AttributedString(text)
        }
        
        let startIndex = text.index(text.startIndex, offsetBy: lowercasedText.distance(from: lowercasedText.startIndex, to: range.lowerBound))
        let endIndex = text.index(text.startIndex, offsetBy: lowercasedText.distance(from: lowercasedText.startIndex, to: range.upperBound))
        
        let before = String(text[..<startIndex])
        let match = String(text[startIndex..<endIndex])
        let after = String(text[endIndex...])
        
        var attributed = AttributedString(before)
        var matchPart = AttributedString(match)
        matchPart.font = .body.bold()
        attributed.append(matchPart)
        attributed.append(AttributedString(after))
        return attributed
    }
}

// MARK: - Preview

#Preview("Research Question Mention") {
    let questions = [
        ResearchQuestionMention(question: {
            let q = ResearchQuestion(questionText: "Can NVDA sustain AI growth?")
            return q
        }()),
        ResearchQuestionMention(question: {
            let q = ResearchQuestion(questionText: "Is AAPL services growing?")
            return q
        }())
    ]
    
    return MentionPopover(
        mentionType: .researchQuestion,
        items: questions,
        filterText: "",
        onSelect: { _ in },
        onDismiss: { }
    )
    .padding()
}

#Preview("Driver Mention") {
    let drivers = [
        DriverMention(driver: Driver(title: "AI demand continues", position: 0), isSubDriver: false),
        DriverMention(driver: Driver(title: "H100 performance lead", position: 1), isSubDriver: true)
    ]
    
    return MentionPopover(
        mentionType: .driver,
        items: drivers,
        filterText: "AI",
        onSelect: { _ in },
        onDismiss: { }
    )
    .padding()
}

