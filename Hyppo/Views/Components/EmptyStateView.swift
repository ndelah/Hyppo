/**
 EmptyStateView displays a placeholder when lists or content areas are empty.
 
 Used throughout the app to provide helpful guidance when the user
 hasn't created any content yet (no assets, no theses, no log entries).
 */

import SwiftUI

/// Reusable empty state component with icon, title, description, and optional action
struct EmptyStateView: View {
    // MARK: - Properties
    
    /// SF Symbol name for the icon
    let iconName: String
    
    /// Main title text
    let title: String
    
    /// Descriptive text explaining the empty state
    let description: String
    
    /// Optional action button title
    let actionTitle: String?
    
    /// Optional action to perform when button is tapped
    let action: (() -> Void)?
    
    // MARK: - Initialization
    
    /**
     Creates an empty state view.
     
     - Parameters:
       - iconName: SF Symbol name for the icon
       - title: Main title text
       - description: Descriptive text
       - actionTitle: Optional button title
       - action: Optional action closure
     */
    init(
        iconName: String,
        title: String,
        description: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.iconName = iconName
        self.title = title
        self.description = description
        self.actionTitle = actionTitle
        self.action = action
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Icon
            Image(systemName: iconName)
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(.secondary)
            
            // Text content
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }
            
            // Optional action button
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text(actionTitle)
                    }
                    .font(.body.weight(.medium))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.top, 8)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Preset Empty States

extension EmptyStateView {
    /// Empty state for the assets list
    static func noAssets(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            iconName: "building.2",
            title: "No Assets Yet",
            description: "Start tracking a company by adding your first asset. You can then create theses and log your research.",
            actionTitle: "Add Asset",
            action: action
        )
    }
    
    /// Empty state for the theses list
    static func noTheses(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            iconName: "doc.text",
            title: "No Theses Yet",
            description: "Create a thesis to document your investment hypothesis. Add key drivers, risks, and invalidation rules.",
            actionTitle: "Add Thesis",
            action: action
        )
    }
    
    /// Empty state for the log entries list
    static func noLogEntries(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            iconName: "note.text",
            title: "No Log Entries Yet",
            description: "Record your observations, updates, and evidence as log entries to build a timeline of your research.",
            actionTitle: "Add Log Entry",
            action: action
        )
    }
    
    /// Empty state for the evidence list
    static func noEvidence(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            iconName: "link",
            title: "No Evidence Yet",
            description: "Attach evidence to support your log entry. Add URLs, snippets, KPIs, or notes.",
            actionTitle: "Add Evidence",
            action: action
        )
    }
    
    /// Empty state for search results
    static var noSearchResults: EmptyStateView {
        EmptyStateView(
            iconName: "magnifyingglass",
            title: "No Results Found",
            description: "Try adjusting your search terms or filters to find what you're looking for."
        )
    }
    
    /// Empty state for detail view when nothing is selected
    static var noSelection: EmptyStateView {
        EmptyStateView(
            iconName: "sidebar.left",
            title: "Select an Item",
            description: "Choose an asset from the sidebar to view its details and theses."
        )
    }
}

// MARK: - Preview

#Preview("No Assets") {
    EmptyStateView.noAssets(action: {})
}

#Preview("No Theses") {
    EmptyStateView.noTheses(action: {})
}

#Preview("No Selection") {
    EmptyStateView.noSelection
}

