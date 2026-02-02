/**
 ViewConfiguration manages user preferences for record view display.
 
 Stores view mode (table/kanban/cards), visible columns, and sort preferences
 in UserDefaults for persistence across app sessions.
 */

import Foundation
import SwiftUI

// MARK: - View Mode

/**
 Available view modes for displaying research question records.
 */
enum ViewMode: String, CaseIterable, Identifiable {
    case table = "table"
    case kanban = "kanban"
    case cards = "cards"
    
    var id: String { rawValue }
    
    /// Display name for UI
    var displayName: String {
        switch self {
        case .table: return "Table"
        case .kanban: return "Kanban"
        case .cards: return "Cards"
        }
    }
    
    /// SF Symbol icon name
    var iconName: String {
        switch self {
        case .table: return "tablecells"
        case .kanban: return "rectangle.split.3x1"
        case .cards: return "square.grid.2x2"
        }
    }
}

// MARK: - Record Column

/**
 Available columns for table view display.
 Each column maps to a property on ResearchQuestion.
 */
enum RecordColumn: String, CaseIterable, Identifiable {
    case question = "question"
    case assetName = "assetName"
    case status = "status"
    case confidence = "confidence"
    case drivers = "drivers"
    case scenarios = "scenarios"
    case logEntries = "logEntries"
    case tags = "tags"
    case created = "created"
    case updated = "updated"
    
    var id: String { rawValue }
    
    /// Display name for column header
    var displayName: String {
        switch self {
        case .question: return "Question"
        case .assetName: return "Asset"
        case .status: return "Status"
        case .confidence: return "Confidence"
        case .drivers: return "Drivers"
        case .scenarios: return "Scenarios"
        case .logEntries: return "Logs"
        case .tags: return "Tags"
        case .created: return "Created"
        case .updated: return "Updated"
        }
    }
    
    /// SF Symbol icon for column
    var iconName: String {
        switch self {
        case .question: return "questionmark.circle"
        case .assetName: return "building.2"
        case .status: return "flag"
        case .confidence: return "gauge"
        case .drivers: return "target"
        case .scenarios: return "arrow.up.arrow.down"
        case .logEntries: return "note.text"
        case .tags: return "tag"
        case .created: return "calendar.badge.plus"
        case .updated: return "calendar"
        }
    }
    
    /// Whether this column is visible by default
    var isDefaultVisible: Bool {
        switch self {
        case .question, .assetName, .status, .confidence, .updated:
            return true
        case .drivers, .scenarios, .logEntries, .tags, .created:
            return false
        }
    }
    
    /// Suggested width for the column
    var suggestedWidth: CGFloat {
        switch self {
        case .question: return 250
        case .assetName: return 80
        case .status: return 100
        case .confidence: return 100
        case .drivers: return 70
        case .scenarios: return 80
        case .logEntries: return 60
        case .tags: return 120
        case .created: return 100
        case .updated: return 100
        }
    }
    
    /// Whether this column is sortable
    var isSortable: Bool {
        switch self {
        case .question, .assetName, .status, .confidence, .created, .updated:
            return true
        case .drivers, .scenarios, .logEntries, .tags:
            return false
        }
    }
}

// MARK: - View Configuration

/**
 Observable class that manages view configuration with UserDefaults persistence.
 */
@Observable
final class ViewConfiguration {
    // MARK: - Singleton
    
    static let shared = ViewConfiguration()
    
    // MARK: - UserDefaults Keys
    
    private enum Keys {
        static let viewMode = "recordViewMode"
        static let visibleColumns = "recordVisibleColumns"
        static let sortColumn = "recordSortColumn"
        static let sortAscending = "recordSortAscending"
    }
    
    // MARK: - Properties
    
    /// Current view mode (table, kanban, or cards)
    var viewMode: ViewMode {
        didSet {
            UserDefaults.standard.set(viewMode.rawValue, forKey: Keys.viewMode)
        }
    }
    
    /// Set of visible columns for table view
    var visibleColumns: Set<RecordColumn> {
        didSet {
            let rawValues = visibleColumns.map { $0.rawValue }
            UserDefaults.standard.set(rawValues, forKey: Keys.visibleColumns)
        }
    }
    
    /// Column to sort by
    var sortColumn: RecordColumn {
        didSet {
            UserDefaults.standard.set(sortColumn.rawValue, forKey: Keys.sortColumn)
        }
    }
    
    /// Sort direction (true = ascending, false = descending)
    var sortAscending: Bool {
        didSet {
            UserDefaults.standard.set(sortAscending, forKey: Keys.sortAscending)
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        // Load view mode
        if let rawMode = UserDefaults.standard.string(forKey: Keys.viewMode),
           let mode = ViewMode(rawValue: rawMode) {
            self.viewMode = mode
        } else {
            self.viewMode = .table
        }
        
        // Load visible columns
        if let rawColumns = UserDefaults.standard.array(forKey: Keys.visibleColumns) as? [String] {
            self.visibleColumns = Set(rawColumns.compactMap { RecordColumn(rawValue: $0) })
        } else {
            // Default visible columns
            self.visibleColumns = Set(RecordColumn.allCases.filter { $0.isDefaultVisible })
        }
        
        // Load sort column
        if let rawSort = UserDefaults.standard.string(forKey: Keys.sortColumn),
           let column = RecordColumn(rawValue: rawSort) {
            self.sortColumn = column
        } else {
            self.sortColumn = .updated
        }
        
        // Load sort direction
        if UserDefaults.standard.object(forKey: Keys.sortAscending) != nil {
            self.sortAscending = UserDefaults.standard.bool(forKey: Keys.sortAscending)
        } else {
            self.sortAscending = false // Default: newest first
        }
    }
    
    // MARK: - Methods
    
    /**
     Toggles visibility of a column.
     
     - Parameter column: The column to toggle
     */
    func toggleColumn(_ column: RecordColumn) {
        if visibleColumns.contains(column) {
            // Don't allow hiding the question column
            if column != .question {
                visibleColumns.remove(column)
            }
        } else {
            visibleColumns.insert(column)
        }
    }
    
    /**
     Sets the sort column and toggles direction if already sorted by this column.
     
     - Parameter column: The column to sort by
     */
    func setSortColumn(_ column: RecordColumn) {
        if sortColumn == column {
            sortAscending.toggle()
        } else {
            sortColumn = column
            sortAscending = column == .updated || column == .created ? false : true
        }
    }
    
    /**
     Resets all settings to defaults.
     */
    func resetToDefaults() {
        viewMode = .table
        visibleColumns = Set(RecordColumn.allCases.filter { $0.isDefaultVisible })
        sortColumn = .updated
        sortAscending = false
    }
    
    /**
     Returns columns in display order (visible columns sorted by their enum order).
     */
    var orderedVisibleColumns: [RecordColumn] {
        RecordColumn.allCases.filter { visibleColumns.contains($0) }
    }
}

