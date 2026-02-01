/**
 Driver model representing an assumption or key driver in the investment thesis.
 
 Drivers are organized in a 2-level hierarchy (Top-level Drivers and Sub-drivers).
 Evidence and ResearchTasks are attached directly to Drivers.
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
    
    /// Ordering among siblings
    var position: Int
    
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
    
    /// Research tasks for this driver
    @Relationship(deleteRule: .cascade, inverse: \ResearchTask.driver)
    var tasks: [ResearchTask]?
    
    // MARK: - Initialization
    
    init(
        title: String,
        driverDescription: String? = nil,
        position: Int = 0,
        parentDriver: Driver? = nil
    ) {
        self.driverId = UUID()
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.driverDescription = driverDescription?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.position = position
        self.parentDriver = parentDriver
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
    
    // MARK: - Task Progress
    
    /// Count of tasks directly attached to this driver
    var taskCount: Int {
        tasks?.count ?? 0
    }
    
    /// Count of completed tasks
    var completedTaskCount: Int {
        tasks?.filter { $0.isCompleted }.count ?? 0
    }
    
    /// Tasks sorted by position
    var sortedTasks: [ResearchTask] {
        tasks?.sorted { $0.position < $1.position } ?? []
    }
}

