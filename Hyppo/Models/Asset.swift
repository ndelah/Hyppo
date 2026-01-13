/**
 Asset model representing a tracked company or security.
 
 An asset is the top-level entity in the data hierarchy.
 Users track companies by creating assets and then attaching
 one or more theses to record their investment hypotheses.
 */

import Foundation
import SwiftData

@Model
final class Asset {
    // MARK: - Properties
    
    /// Unique identifier for the asset
    @Attribute(.unique) var assetId: UUID
    
    /// Stock ticker symbol (e.g., "AAPL", "MSFT")
    var ticker: String
    
    /// Normalized ticker for search and deduplication (uppercase, trimmed)
    var tickerNormalized: String
    
    /// Company or security name
    var name: String
    
    /// Optional stock exchange (e.g., "NYSE", "NASDAQ")
    var exchange: String?
    
    /// Optional currency code (e.g., "USD", "EUR")
    var currency: String?
    
    /// Timestamp when the asset was created
    var createdAt: Date
    
    /// Timestamp when the asset was last updated
    var updatedAt: Date
    
    /// Optional timestamp when the asset was archived
    var archivedAt: Date?
    
    // MARK: - Relationships
    
    /// Theses associated with this asset
    @Relationship(deleteRule: .cascade) var theses: [Thesis]?
    
    /// Tags associated with this asset
    var tags: [Tag]?
    
    // MARK: - Initialization
    
    /**
     Creates a new asset with the required ticker and name.
     
     - Parameters:
       - ticker: The stock ticker symbol
       - name: The company or security name
       - exchange: Optional stock exchange
       - currency: Optional currency code
     */
    init(
        ticker: String,
        name: String,
        exchange: String? = nil,
        currency: String? = nil
    ) {
        self.assetId = UUID()
        self.ticker = ticker.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        self.tickerNormalized = ticker.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.exchange = exchange?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.currency = currency?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - Computed Properties
    
    /// Returns true if the asset is archived
    var isArchived: Bool {
        archivedAt != nil
    }
    
    /// Returns the count of theses for this asset
    var thesesCount: Int {
        theses?.count ?? 0
    }
    
    /// Returns only active theses
    var activeTheses: [Thesis] {
        theses?.filter { $0.status == .active } ?? []
    }
    
    /// Display string combining ticker and name
    var displayTitle: String {
        "\(ticker) - \(name)"
    }
    
    // MARK: - Methods
    
    /**
     Archives the asset by setting the archivedAt timestamp.
     */
    func archive() {
        archivedAt = Date()
        updatedAt = Date()
    }
    
    /**
     Unarchives the asset by clearing the archivedAt timestamp.
     */
    func unarchive() {
        archivedAt = nil
        updatedAt = Date()
    }
    
    /**
     Updates the asset's properties and refreshes the updatedAt timestamp.
     
     - Parameters:
       - ticker: New ticker symbol
       - name: New company name
       - exchange: New exchange (optional)
       - currency: New currency (optional)
     */
    func update(
        ticker: String,
        name: String,
        exchange: String?,
        currency: String?
    ) {
        self.ticker = ticker.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        self.tickerNormalized = ticker.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.exchange = exchange?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.currency = currency?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        self.updatedAt = Date()
    }
}

// MARK: - Validation

extension Asset {
    /// Validates that the asset has all required fields populated
    var isValid: Bool {
        !ticker.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Returns validation errors if any
    var validationErrors: [String] {
        var errors: [String] = []
        
        if ticker.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Ticker is required")
        }
        
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Name is required")
        }
        
        return errors
    }
}
