/**
 OdooStyleNavigationView provides the main app navigation with an Odoo-inspired layout.
 
 Features:
 - Top menu bar with app name and navigation tabs
 - Research Questions, Tasks, Reporting, Configuration menu items
 - Consistent styling across all sections
 */

import SwiftUI
import SwiftData

/// App-wide navigation tabs
enum AppNavigationTab: String, CaseIterable, Identifiable {
    case researchQuestions = "Research Questions"
    case tasks = "Tasks"
    case reporting = "Reporting"
    case configuration = "Configuration"
    
    var id: String { rawValue }
    
    /// SF Symbol icon for the tab
    var iconName: String {
        switch self {
        case .researchQuestions: return "questionmark.circle"
        case .tasks: return "checklist"
        case .reporting: return "chart.bar"
        case .configuration: return "gearshape"
        }
    }
}

/// Root navigation view with Odoo-style header and tab navigation
struct OdooStyleNavigationView: View {
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.sizeCategory) private var sizeCategory
    @Environment(\.colorSchemeContrast) private var colorContrast
    
    // MARK: - State
    
    @State private var selectedTab: AppNavigationTab = .researchQuestions
    @State private var navigationPath = NavigationPath()
    @State private var showingGlobalSearch = false
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Top navigation bar (Odoo-style)
            topNavigationBar
            
            // Content area
            NavigationStack(path: $navigationPath) {
                contentView
                    .navigationDestination(for: ResearchQuestion.self) { question in
                        ResearchQuestionDetailView(researchQuestion: question)
                    }
            }
        }
        // Handle menu shortcut notifications
        .onReceive(NotificationCenter.default.publisher(for: .showGlobalSearch)) { _ in
            showingGlobalSearch = true
        }
        .sheet(isPresented: $showingGlobalSearch) {
            GlobalSearchView(
                selectedAsset: .constant(nil),
                selectedResearchQuestion: .constant(nil),
                onSelectQuestion: { question in
                    selectedTab = .researchQuestions
                    navigationPath.append(question)
                }
            )
        }
    }
    
    // MARK: - Top Navigation Bar
    
    private var topNavigationBar: some View {
        HStack(spacing: 0) {
            // Navigation tabs
            HStack(spacing: 4) {
                ForEach(AppNavigationTab.allCases) { tab in
                    tabButton(for: tab)
                }
            }
            .padding(.leading, 16)
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color(nsColor: .windowBackgroundColor))
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
    
    /// Individual navigation tab button
    private func tabButton(for tab: AppNavigationTab) -> some View {
        Button {
            // Clear navigation path to pop back to root when switching tabs
            navigationPath = NavigationPath()
            
            // Respect reduce motion preference
            if reduceMotion {
                selectedTab = tab
            } else {
                withAnimation(.easeInOut(duration: 0.15)) {
                    selectedTab = tab
                }
            }
        } label: {
            Text(tab.rawValue)
                .font(.subheadline)
                .fontWeight(selectedTab == tab ? .medium : .regular)
                .foregroundStyle(selectedTab == tab ? .primary : .secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    selectedTab == tab
                        ? Color.accentColor.opacity(colorContrast == .increased ? 0.2 : 0.1)
                        : Color.clear
                )
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.rawValue)
        .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
        .accessibilityHint("Switch to \(tab.rawValue) section")
    }
    
    // MARK: - Content View
    
    @ViewBuilder
    private var contentView: some View {
        switch selectedTab {
        case .researchQuestions:
            RecordListView(navigationPath: $navigationPath)
            
        case .tasks:
            AllTasksListView(navigationPath: $navigationPath)
            
        case .reporting:
            ComingSoonView(title: "Reporting", description: "Analytics and reporting features coming soon")
            
        case .configuration:
            ComingSoonView(title: "Configuration", description: "Settings and configuration options coming soon")
        }
    }
}

// MARK: - Coming Soon View

/// Placeholder view for unimplemented sections
struct ComingSoonView: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "hammer.circle")
                .font(.system(size: 64))
                .foregroundStyle(.tertiary)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

// MARK: - Preview

#Preview {
    OdooStyleNavigationView()
        .modelContainer(for: [Asset.self, ResearchQuestion.self, LogEntry.self, Evidence.self, Tag.self, ReviewReminder.self, Driver.self, ResearchTask.self], inMemory: true)
}

