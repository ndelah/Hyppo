/**
 ViewConfiguration manages user preferences for record view display.
 
 Stores view mode (table/kanban/cards), visible columns, sort preferences,
 saved searches, group by settings, and column widths in UserDefaults
 for persistence across app sessions.
 */

import Foundation
import SwiftUI

// MARK: - Saved Search

/**
 Represents a saved search configuration that can be persisted and reapplied.
 */
struct SavedSearch: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var statusFilters: [String]
    var confidenceFilter: Int?
    var tagIds: [UUID]
    var startDate: Date?
    var endDate: Date?
    var groupByColumn: String?
    var searchText: String
    
    init(
        id: UUID = UUID(),
        name: String,
        statusFilters: [String] = [],
        confidenceFilter: Int? = nil,
        tagIds: [UUID] = [],
        startDate: Date? = nil,
        endDate: Date? = nil,
        groupByColumn: String? = nil,
        searchText: String = ""
    ) {
        self.id = id
        self.name = name
        self.statusFilters = statusFilters
        self.confidenceFilter = confidenceFilter
        self.tagIds = tagIds
        self.startDate = startDate
        self.endDate = endDate
        self.groupByColumn = groupByColumn
        self.searchText = searchText
    }
}

// MARK: - Group By Column

/**
 Available columns for grouping records in kanban and card views.
 */
enum GroupByColumn: String, CaseIterable, Identifiable {
    case none = "none"
    case status = "status"
    case asset = "asset"
    case confidence = "confidence"
    case tags = "tags"
    case createdDate = "createdDate"
    case updatedDate = "updatedDate"
    
    var id: String { rawValue }
    
    /// Display name for UI
    var displayName: String {
        switch self {
        case .none: return "None"
        case .status: return "Status"
        case .asset: return "Asset"
        case .confidence: return "Confidence"
        case .tags: return "Tags"
        case .createdDate: return "Created Date"
        case .updatedDate: return "Updated Date"
        }
    }
    
    /// SF Symbol icon name
    var iconName: String {
        switch self {
        case .none: return "square.grid.2x2"
        case .status: return "flag"
        case .asset: return "building.2"
        case .confidence: return "gauge"
        case .tags: return "tag"
        case .createdDate: return "calendar.badge.plus"
        case .updatedDate: return "calendar"
        }
    }
}

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
    
    /// Content alignment for this column
    var alignment: Alignment {
        switch self {
        case .question:
            return .leading
        case .assetName, .status, .confidence, .drivers, .scenarios, .logEntries, .tags, .created, .updated:
            return .center
        }
    }
    
    /// Display priority for responsive hiding (lower = higher priority, won't be hidden first)
    /// Columns with higher priority numbers are hidden first when space is tight
    var displayPriority: Int {
        switch self {
        case .question: return 0      // Never hidden
        case .status: return 1        // Critical info
        case .assetName: return 2     // Important context
        case .confidence: return 3    // Key metric
        case .updated: return 4       // Useful timestamp
        case .created: return 5       // Less critical timestamp
        case .tags: return 6          // Nice to have
        case .drivers: return 7       // Count info
        case .logEntries: return 8    // Count info
        case .scenarios: return 9     // Least critical
        }
    }
    
    /// Minimum width for this column (cannot be compressed below this)
    /// These are set aggressively small to allow more columns to fit at medium widths
    var minWidth: CGFloat {
        switch self {
        case .question: return 150
        case .assetName: return 50
        case .status: return 70
        case .confidence: return 70
        case .drivers: return 40
        case .scenarios: return 50
        case .logEntries: return 40
        case .tags: return 60
        case .created: return 70
        case .updated: return 70
        }
    }
    
    /// Flex grow factor for proportional expansion (higher = takes more extra space)
    var flexGrow: CGFloat {
        switch self {
        case .question: return 3.0    // Takes most extra space
        case .tags: return 1.5        // Tags can benefit from extra space
        case .assetName, .status, .confidence, .created, .updated: return 1.0
        case .drivers, .scenarios, .logEntries: return 0.5  // Compact columns grow less
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
        static let savedSearches = "recordSavedSearches"
        static let groupByColumn = "recordGroupByColumn"
        static let columnWidths = "recordColumnWidths"
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
    
    /// Saved search configurations
    var savedSearches: [SavedSearch] {
        didSet {
            if let encoded = try? JSONEncoder().encode(savedSearches) {
                UserDefaults.standard.set(encoded, forKey: Keys.savedSearches)
            }
        }
    }
    
    /// Current group by column for kanban/cards view
    var groupByColumn: GroupByColumn {
        didSet {
            UserDefaults.standard.set(groupByColumn.rawValue, forKey: Keys.groupByColumn)
        }
    }
    
    /// Custom column widths (column rawValue -> width)
    var columnWidths: [String: CGFloat] {
        didSet {
            UserDefaults.standard.set(columnWidths, forKey: Keys.columnWidths)
        }
    }
    
    // MARK: - Active Filter State (not persisted)
    
    /// Current status filters (multi-select)
    var activeStatusFilters: Set<String> = []
    
    /// Current confidence filter
    var activeConfidenceFilter: Int?
    
    /// Current tag IDs filter
    var activeTagIds: Set<UUID> = []
    
    /// Current date range start
    var activeStartDate: Date?
    
    /// Current date range end
    var activeEndDate: Date?
    
    /// Current search text
    var activeSearchText: String = ""
    
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
        
        // Load saved searches
        if let data = UserDefaults.standard.data(forKey: Keys.savedSearches),
           let decoded = try? JSONDecoder().decode([SavedSearch].self, from: data) {
            self.savedSearches = decoded
        } else {
            self.savedSearches = []
        }
        
        // Load group by column
        if let rawGroupBy = UserDefaults.standard.string(forKey: Keys.groupByColumn),
           let groupBy = GroupByColumn(rawValue: rawGroupBy) {
            self.groupByColumn = groupBy
        } else {
            self.groupByColumn = .status // Default: group by status for kanban
        }
        
        // Load column widths
        if let widths = UserDefaults.standard.dictionary(forKey: Keys.columnWidths) as? [String: CGFloat] {
            self.columnWidths = widths
        } else {
            self.columnWidths = [:]
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
        groupByColumn = .status
        columnWidths = [:]
        clearActiveFilters()
    }
    
    /**
     Returns columns in display order (visible columns sorted by their enum order).
     */
    var orderedVisibleColumns: [RecordColumn] {
        RecordColumn.allCases.filter { visibleColumns.contains($0) }
    }
    
    // MARK: - Column Width Methods
    
    /**
     Gets the width for a column, using custom width if set, otherwise the suggested width.
     
     - Parameter column: The column to get width for
     - Returns: The column width
     */
    func widthForColumn(_ column: RecordColumn) -> CGFloat {
        columnWidths[column.rawValue] ?? column.suggestedWidth
    }
    
    /**
     Sets a custom width for a column.
     
     - Parameters:
       - column: The column to set width for
       - width: The new width
     */
    func setWidthForColumn(_ column: RecordColumn, width: CGFloat) {
        // Enforce minimum width
        let minWidth: CGFloat = 50
        columnWidths[column.rawValue] = max(width, minWidth)
    }
    
    /**
     Resets a column width to its default suggested width.
     
     - Parameter column: The column to reset
     */
    func resetColumnWidth(_ column: RecordColumn) {
        columnWidths.removeValue(forKey: column.rawValue)
    }
    
    // MARK: - Responsive Width Methods
    
    /**
     Calculates which columns should be visible based on available width.
     Columns are hidden in order of their displayPriority (highest priority number hidden first).
     
     - Parameters:
       - availableWidth: The total available width for the table
       - horizontalPadding: Additional horizontal padding to account for (margins, settings button, etc.)
     - Returns: Array of columns that fit within the available width, sorted by enum order
     */
    func responsiveVisibleColumns(for availableWidth: CGFloat, horizontalPadding: CGFloat = 44) -> [RecordColumn] {
        let usableWidth = availableWidth - horizontalPadding
        
        // Start with all visible columns, sorted by display priority (lowest first = keep)
        var candidateColumns = orderedVisibleColumns.sorted { $0.displayPriority < $1.displayPriority }
        
        // Calculate total minimum width needed
        var totalMinWidth = candidateColumns.reduce(CGFloat(0)) { $0 + $1.minWidth }
        
        // Remove columns (highest priority number first) until we fit
        while totalMinWidth > usableWidth && candidateColumns.count > 1 {
            // Remove the last column (highest displayPriority)
            if let removed = candidateColumns.popLast() {
                totalMinWidth -= removed.minWidth
            }
        }
        
        // Return columns in their original enum order for consistent display
        return RecordColumn.allCases.filter { candidateColumns.contains($0) }
    }
    
    /**
     Calculates proportional widths for columns based on available space.
     Columns get their minimum width plus a proportional share of extra space based on flexGrow.
     
     - Parameters:
       - columns: The columns to calculate widths for
       - availableWidth: The total available width
       - horizontalPadding: Additional horizontal padding to account for
     - Returns: Dictionary mapping each column to its calculated width
     */
    func responsiveWidths(for columns: [RecordColumn], availableWidth: CGFloat, horizontalPadding: CGFloat = 44) -> [RecordColumn: CGFloat] {
        let usableWidth = availableWidth - horizontalPadding
        
        // Calculate total minimum width and total flex grow
        let totalMinWidth = columns.reduce(CGFloat(0)) { $0 + $1.minWidth }
        let totalFlexGrow = columns.reduce(CGFloat(0)) { $0 + $1.flexGrow }
        
        // Calculate extra space to distribute
        let extraSpace = max(0, usableWidth - totalMinWidth)
        
        var widths: [RecordColumn: CGFloat] = [:]
        
        for column in columns {
            // Base width is minimum, plus proportional share of extra space
            let flexShare = totalFlexGrow > 0 ? (column.flexGrow / totalFlexGrow) : 0
            let columnWidth = column.minWidth + (extraSpace * flexShare)
            
            // Apply any user-customized width if it's larger than calculated
            // This respects manual column resizing while still being responsive
            if let customWidth = columnWidths[column.rawValue], customWidth > columnWidth {
                widths[column] = customWidth
            } else {
                widths[column] = columnWidth
            }
        }
        
        return widths
    }
    
    // MARK: - Saved Search Methods
    
    /**
     Saves the current filter configuration as a new saved search.
     
     - Parameter name: The name for the saved search
     - Returns: The newly created SavedSearch
     */
    @discardableResult
    func saveCurrentSearch(name: String) -> SavedSearch {
        let search = SavedSearch(
            name: name,
            statusFilters: Array(activeStatusFilters),
            confidenceFilter: activeConfidenceFilter,
            tagIds: Array(activeTagIds),
            startDate: activeStartDate,
            endDate: activeEndDate,
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
    func applySavedSearch(_ search: SavedSearch) {
        activeStatusFilters = Set(search.statusFilters)
        activeConfidenceFilter = search.confidenceFilter
        activeTagIds = Set(search.tagIds)
        activeStartDate = search.startDate
        activeEndDate = search.endDate
        activeSearchText = search.searchText
        
        if let rawGroupBy = search.groupByColumn,
           let groupBy = GroupByColumn(rawValue: rawGroupBy) {
            groupByColumn = groupBy
        }
    }
    
    /**
     Clears all active filters.
     */
    func clearActiveFilters() {
        activeStatusFilters = []
        activeConfidenceFilter = nil
        activeTagIds = []
        activeStartDate = nil
        activeEndDate = nil
        activeSearchText = ""
    }
    
    /**
     Checks if any filters are currently active.
     */
    var hasActiveFilters: Bool {
        !activeStatusFilters.isEmpty ||
        activeConfidenceFilter != nil ||
        !activeTagIds.isEmpty ||
        activeStartDate != nil ||
        activeEndDate != nil
    }
}

