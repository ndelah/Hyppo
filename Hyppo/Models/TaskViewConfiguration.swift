/**
 TaskViewConfiguration manages user preferences for task view display.
 
 Stores group by settings, saved searches, and filter state in UserDefaults
 for persistence across app sessions. Similar to ViewConfiguration but
 specific to the Tasks view.
 */

import Foundation
import SwiftUI

// MARK: - Task Saved Search

/**
 Represents a saved search configuration for tasks that can be persisted and reapplied.
 */
struct TaskSavedSearch: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var showInboxOnly: Bool
    var showCompletedTasks: Bool
    var researchQuestionIds: [UUID]
    var tagIds: [UUID]
    var groupByColumn: String?
    var searchText: String
    
    init(
        id: UUID = UUID(),
        name: String,
        showInboxOnly: Bool = false,
        showCompletedTasks: Bool = false,
        researchQuestionIds: [UUID] = [],
        tagIds: [UUID] = [],
        groupByColumn: String? = nil,
        searchText: String = ""
    ) {
        self.id = id
        self.name = name
        self.showInboxOnly = showInboxOnly
        self.showCompletedTasks = showCompletedTasks
        self.researchQuestionIds = researchQuestionIds
        self.tagIds = tagIds
        self.groupByColumn = groupByColumn
        self.searchText = searchText
    }
}

// MARK: - Task Group By Column

/**
 Available columns for grouping tasks in the list view.
 */
enum TaskGroupByColumn: String, CaseIterable, Identifiable {
    case none = "none"
    case researchQuestion = "researchQuestion"
    case driver = "driver"
    case tags = "tags"
    case status = "status"
    case createdDate = "createdDate"
    
    var id: String { rawValue }
    
    /// Display name for UI
    var displayName: String {
        switch self {
        case .none: return "None"
        case .researchQuestion: return "Research Project"
        case .driver: return "Driver"
        case .tags: return "Tags"
        case .status: return "Completion Status"
        case .createdDate: return "Created Date"
        }
    }
    
    /// SF Symbol icon name
    var iconName: String {
        switch self {
        case .none: return "list.bullet"
        case .researchQuestion: return "doc.text.magnifyingglass"
        case .driver: return "target"
        case .tags: return "tag"
        case .status: return "checkmark.circle"
        case .createdDate: return "calendar.badge.plus"
        }
    }
}

// MARK: - Task View Configuration

/**
 Observable class that manages task view configuration with UserDefaults persistence.
 */
@Observable
final class TaskViewConfiguration {
    // MARK: - Singleton
    
    static let shared = TaskViewConfiguration()
    
    // MARK: - UserDefaults Keys
    
    private enum Keys {
        static let groupByColumn = "taskGroupByColumn"
        static let savedSearches = "taskSavedSearches"
    }
    
    // MARK: - Persisted Properties
    
    /// Current group by column for task list
    var groupByColumn: TaskGroupByColumn {
        didSet {
            UserDefaults.standard.set(groupByColumn.rawValue, forKey: Keys.groupByColumn)
        }
    }
    
    /// Saved search configurations
    var savedSearches: [TaskSavedSearch] {
        didSet {
            if let encoded = try? JSONEncoder().encode(savedSearches) {
                UserDefaults.standard.set(encoded, forKey: Keys.savedSearches)
            }
        }
    }
    
    // MARK: - Active Filter State (not persisted)
    
    /// Filter to show inbox tasks only
    var activeShowInboxOnly: Bool = false
    
    /// Filter to show completed tasks
    var activeShowCompletedTasks: Bool = false
    
    /// Filter by research question IDs
    var activeResearchQuestionIds: Set<UUID> = []
    
    /// Filter by tag IDs (from research question tags)
    var activeTagIds: Set<UUID> = []
    
    /// Current search text
    var activeSearchText: String = ""
    
    // MARK: - Initialization
    
    private init() {
        // Load group by column
        if let rawGroupBy = UserDefaults.standard.string(forKey: Keys.groupByColumn),
           let groupBy = TaskGroupByColumn(rawValue: rawGroupBy) {
            self.groupByColumn = groupBy
        } else {
            self.groupByColumn = .none
        }
        
        // Load saved searches
        if let data = UserDefaults.standard.data(forKey: Keys.savedSearches),
           let decoded = try? JSONDecoder().decode([TaskSavedSearch].self, from: data) {
            self.savedSearches = decoded
        } else {
            self.savedSearches = []
        }
    }
    
    // MARK: - Methods
    
    /**
     Resets all settings to defaults.
     */
    func resetToDefaults() {
        groupByColumn = .none
        clearActiveFilters()
    }
    
    // MARK: - Saved Search Methods
    
    /**
     Saves the current filter configuration as a new saved search.
     
     - Parameter name: The name for the saved search
     - Returns: The newly created TaskSavedSearch
     */
    @discardableResult
    func saveCurrentSearch(name: String) -> TaskSavedSearch {
        let search = TaskSavedSearch(
            name: name,
            showInboxOnly: activeShowInboxOnly,
            showCompletedTasks: activeShowCompletedTasks,
            researchQuestionIds: Array(activeResearchQuestionIds),
            tagIds: Array(activeTagIds),
            groupByColumn: groupByColumn.rawValue,
            searchText: activeSearchText
        )
        savedSearches.append(search)
        return search
    }
    
    /**
     Deletes a saved search by ID.
     
     - Parameter id: The ID of the saved search to delete
     */
    func deleteSavedSearch(id: UUID) {
        savedSearches.removeAll { $0.id == id }
    }
    
    /**
     Applies a saved search configuration to the active filters.
     
     - Parameter search: The saved search to apply
     */
    func applySavedSearch(_ search: TaskSavedSearch) {
        activeShowInboxOnly = search.showInboxOnly
        activeShowCompletedTasks = search.showCompletedTasks
        activeResearchQuestionIds = Set(search.researchQuestionIds)
        activeTagIds = Set(search.tagIds)
        activeSearchText = search.searchText
        
        if let rawGroupBy = search.groupByColumn,
           let groupBy = TaskGroupByColumn(rawValue: rawGroupBy) {
            groupByColumn = groupBy
        }
    }
    
    /**
     Clears all active filters.
     */
    func clearActiveFilters() {
        activeShowInboxOnly = false
        activeShowCompletedTasks = false
        activeResearchQuestionIds = []
        activeTagIds = []
        activeSearchText = ""
    }
    
    /**
     Checks if any filters are currently active.
     */
    var hasActiveFilters: Bool {
        activeShowInboxOnly ||
        activeShowCompletedTasks ||
        !activeResearchQuestionIds.isEmpty ||
        !activeTagIds.isEmpty
    }
    
    /**
     Returns the active filter count for badge display.
     */
    var activeFilterCount: Int {
        var count = 0
        if activeShowInboxOnly { count += 1 }
        if activeShowCompletedTasks { count += 1 }
        count += activeResearchQuestionIds.count
        count += activeTagIds.count
        return count
    }
}



