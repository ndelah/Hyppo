/**
 Driver model representing an assumption or key driver in the investment thesis.
 
 Drivers are organized in a 2-level hierarchy (Top-level Drivers and Sub-drivers).
 Evidence is attached directly to Drivers.
 */

import Foundation
import SwiftData

@Model
final class Driver {
    // MARK: - Properties
    
    /// Unique identifier for the driver
    @Attribute(.unique) var driverId: UUID
    
    /// Title of the assumption/driver (e.g., "AI demand growth")
    var title: String
    
    /// Optional longer explanation
    var driverDescription: String?
    
    /// The logic or reasoning behind this driver/assumption (e.g., "Why must this be true?")
    var logic: String?
    
    /// Ordering among siblings
    var position: Int
    
    /// Raw status value for persistence
    var statusRaw: String
    
    // MARK: - Relationships
    
    /// Parent research question
    var researchQuestion: ResearchQuestion?
    
    /// Parent driver if this is a sub-driver
    var parentDriver: Driver?
    
    /// Child drivers if this is a top-level driver
    @Relationship(deleteRule: .cascade, inverse: \Driver.parentDriver)
    var subDrivers: [Driver]?
    
    /// Evidence associated with this driver
    @Relationship(deleteRule: .cascade)
    var evidence: [Evidence]?
    
    // MARK: - Initialization
    
    init(
        title: String,
        driverDescription: String? = nil,
        logic: String? = nil,
        position: Int = 0,
        parentDriver: Driver? = nil
    ) {
        self.driverId = UUID()
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.driverDescription = driverDescription?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.logic = logic?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.position = position
        self.parentDriver = parentDriver
        self.statusRaw = DriverStatus.pending.rawValue
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - Metadata
    
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - Computed Properties
    
    /// Returns true if this is a top-level driver (no parent)
    var isTopLevel: Bool {
        parentDriver == nil
    }
    
    /// Status as enum (confirmed, discarded, needs revision, or pending)
    var status: DriverStatus {
        get { DriverStatus(rawValue: statusRaw) ?? .pending }
        set {
            statusRaw = newValue.rawValue
            updatedAt = Date()
        }
    }
    
    /// Returns true if the driver has been resolved (not pending)
    var isResolved: Bool {
        status.isResolved
    }
    
    /// Count of evidence items directly attached to this driver
    var directEvidenceCount: Int {
        evidence?.count ?? 0
    }
    
    /**
     Calculates the total evidence balance (supporting - contradicting).
     Includes evidence from sub-drivers (roll-up).
     */
    var totalEvidenceBalance: Int {
        let directBalance = evidence?.reduce(0) { count, item in
            switch item.sentiment {
            case .supporting: return count + 1
            case .contradicting: return count - 1
            case .neutral: return count
            }
        } ?? 0
        
        let subBalance = subDrivers?.reduce(0) { $0 + $1.totalEvidenceBalance } ?? 0
        
        return directBalance + subBalance
    }
    
    /**
     Returns true if there is no evidence at this level or below.
     */
    var hasBlindSpot: Bool {
        if directEvidenceCount > 0 { return false }
        return subDrivers?.allSatisfy { $0.hasBlindSpot } ?? true
    }
    
}

