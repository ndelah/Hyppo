import Foundation
import SwiftData

// MARK: - Migration Status

/**
 Tracks the status of data migration operations.
 */
struct MigrationStatus {
    var questionsProcessed: Int = 0
    var driversCreated: Int = 0
    var evidenceMigrated: Int = 0
    var errors: [String] = []
    
    var summary: String {
        """
        Migration completed:
        - Research questions processed: \(questionsProcessed)
        - Drivers created: \(driversCreated)
        - Evidence migrated: \(evidenceMigrated)
        - Errors: \(errors.count)
        """
    }
}

// MARK: - Migration Helper

/**
 Migration helper for transitioning from legacy data structures to the McKinsey Mind framework.
 
 Handles:
 - Converting old string-array based key drivers to structured Driver models
 - Linking orphaned evidence to appropriate drivers
 - Setting default sentiment values for legacy evidence
 */
@MainActor
final class MigrationHelper {
    // MARK: - Singleton
    
    static let shared = MigrationHelper()
    
    // MARK: - Properties
    
    /// Key for tracking migration version in UserDefaults
    private let migrationVersionKey = "com.hyppo.migrationVersion"
    
    /// Current migration version
    private let currentMigrationVersion = 2
    
    private init() {}
    
    // MARK: - Public Methods
    
    /**
     Checks if migration is needed and performs it if necessary.
     
     - Parameter modelContext: The SwiftData model context
     - Returns: True if migration was performed, false if already up to date
     */
    @discardableResult
    func migrateIfNeeded(modelContext: ModelContext) -> Bool {
        let lastVersion = UserDefaults.standard.integer(forKey: migrationVersionKey)
        
        if lastVersion < currentMigrationVersion {
            DebugLogger.info(
                location: "MigrationHelper:migrateIfNeeded",
                message: "Migration needed from v\(lastVersion) to v\(currentMigrationVersion)"
            )
            
            let status = performMigration(modelContext: modelContext)
            
            if status.errors.isEmpty {
                UserDefaults.standard.set(currentMigrationVersion, forKey: migrationVersionKey)
                DebugLogger.info(
                    location: "MigrationHelper:migrateIfNeeded",
                    message: status.summary
                )
                return true
            } else {
                DebugLogger.error(
                    location: "MigrationHelper:migrateIfNeeded",
                    message: "Migration completed with errors: \(status.errors.joined(separator: "; "))",
                    error: nil
                )
                return true
            }
        }
        
        return false
    }
    
    /**
     Performs the full migration regardless of version status.
     
     Useful for manual migration triggers from settings.
     
     - Parameter modelContext: The SwiftData model context
     - Returns: Migration status with statistics
     */
    func performMigration(modelContext: ModelContext) -> MigrationStatus {
        var status = MigrationStatus()
        
        DebugLogger.info(
            location: "MigrationHelper:performMigration",
            message: "Starting migration to McKinsey framework v\(currentMigrationVersion)"
        )
        
        do {
            // Step 1: Migrate all research questions
            let rqDescriptor = FetchDescriptor<ResearchQuestion>()
            let questions = try modelContext.fetch(rqDescriptor)
            
            for rq in questions {
                let result = migrateResearchQuestion(rq, modelContext: modelContext)
                status.questionsProcessed += 1
                status.driversCreated += result.driversCreated
                status.errors.append(contentsOf: result.errors)
            }
            
            // Step 2: Migrate orphaned evidence
            let evidenceDescriptor = FetchDescriptor<Evidence>()
            let allEvidence = try modelContext.fetch(evidenceDescriptor)
            
            for evidence in allEvidence {
                if evidence.driver == nil {
                    if migrateEvidence(evidence, modelContext: modelContext) {
                        status.evidenceMigrated += 1
                    }
                }
            }
            
            // Save all changes
            try modelContext.save()
            
            DebugLogger.info(
                location: "MigrationHelper:performMigration",
                message: "Migration completed successfully"
            )
            
        } catch {
            status.errors.append("Failed to complete migration: \(error.localizedDescription)")
            DebugLogger.error(
                location: "MigrationHelper:performMigration",
                message: "Migration failed",
                error: error
            )
        }
        
        return status
    }
    
    /**
     Resets migration status to force re-migration on next check.
     
     Useful for debugging or recovering from failed migrations.
     */
    func resetMigrationStatus() {
        UserDefaults.standard.removeObject(forKey: migrationVersionKey)
        DebugLogger.info(
            location: "MigrationHelper:resetMigrationStatus",
            message: "Migration status reset"
        )
    }
    
    // MARK: - Private Migration Methods
    
    /**
     Result of migrating a single research question.
     */
    private struct ResearchQuestionMigrationResult {
        var driversCreated: Int = 0
        var errors: [String] = []
    }
    
    /**
     Migrates a single research question's legacy data to the new schema.
     
     - Parameters:
       - rq: The research question to migrate
       - modelContext: The SwiftData model context
     - Returns: Migration result with statistics
     */
    private func migrateResearchQuestion(_ rq: ResearchQuestion, modelContext: ModelContext) -> ResearchQuestionMigrationResult {
        var result = ResearchQuestionMigrationResult()
        
        // Ensure drivers array exists
        if rq.drivers == nil {
            rq.drivers = []
        }
        
        // Check if this research question needs driver migration
        let needsDrivers = (rq.drivers?.isEmpty ?? true)
        
        // If research question has a thesis but no drivers, create a general driver
        if needsDrivers {
            let generalDriver = createDefaultDriver(for: rq, modelContext: modelContext)
            result.driversCreated += 1
            
            DebugLogger.info(
                location: "MigrationHelper:migrateResearchQuestion",
                message: "Created default driver for question: \(rq.questionText.prefix(50))..."
            )
        }
        
        return result
    }
    
    /**
     Creates a default driver for a research question that has none.
     
     - Parameters:
       - rq: The research question
       - modelContext: The SwiftData model context
     - Returns: The created driver
     */
    @discardableResult
    private func createDefaultDriver(for rq: ResearchQuestion, modelContext: ModelContext) -> Driver {
        // Create a general driver with context from the thesis if available
        let title: String
        let description: String?
        
        if let thesis = rq.thesisStatement, !thesis.isEmpty {
            title = "Core Thesis Assumption"
            description = "Primary assumptions underlying the thesis: \(thesis)"
        } else {
            title = "General Assumptions"
            description = "Key assumptions for this research question. Add specific drivers to track evidence more granularly."
        }
        
        let driver = Driver(
            title: title,
            driverDescription: description,
            position: 0
        )
        
        driver.researchQuestion = rq
        modelContext.insert(driver)
        
        // Update the relationship
        rq.drivers?.append(driver)
        
        return driver
    }
    
    /**
     Migrates a single evidence item to link it to a driver.
     
     - Parameters:
       - evidence: The evidence to migrate
       - modelContext: The SwiftData model context
     - Returns: True if migration was successful
     */
    private func migrateEvidence(_ evidence: Evidence, modelContext: ModelContext) -> Bool {
        // Try to find a suitable driver from the parent log entry's research question
        guard let logEntry = evidence.logEntry,
              let rq = logEntry.researchQuestion else {
            DebugLogger.info(
                location: "MigrationHelper:migrateEvidence",
                message: "Evidence has no parent research question, skipping"
            )
            return false
        }
        
        // Get or create a default driver for this research question
        let targetDriver: Driver
        
        if let firstDriver = rq.topLevelDrivers.first {
            targetDriver = firstDriver
        } else {
            // Need to create a driver first
            targetDriver = createDefaultDriver(for: rq, modelContext: modelContext)
        }
        
        // Link the evidence to the driver
        evidence.driver = targetDriver
        
        // Update the driver's evidence array
        if targetDriver.evidence == nil {
            targetDriver.evidence = []
        }
        targetDriver.evidence?.append(evidence)
        
        // Set default sentiment if not already set
        if evidence.sentimentRaw.isEmpty {
            evidence.sentiment = .neutral
        }
        
        // Set default source type if not already set
        if evidence.sourceTypeRaw.isEmpty {
            // Try to infer source type from evidence type
            switch evidence.evidenceType {
            case .filing:
                evidence.sourceType = .secFiling
            case .article:
                evidence.sourceType = .newsArticle
            case .quote:
                evidence.sourceType = .managementCommentary
            case .note:
                evidence.sourceType = .personalNote
            case .kpi:
                evidence.sourceType = .dataProvider
            }
        }
        
        DebugLogger.info(
            location: "MigrationHelper:migrateEvidence",
            message: "Migrated evidence '\(evidence.effectiveTitle)' to driver '\(targetDriver.title)'"
        )
        
        return true
    }
}

// MARK: - Migration Validation

extension MigrationHelper {
    /**
     Validates that all research questions have the required structure.
     
     - Parameter modelContext: The SwiftData model context
     - Returns: Array of validation issues found
     */
    func validateDataIntegrity(modelContext: ModelContext) -> [String] {
        var issues: [String] = []
        
        do {
            let rqDescriptor = FetchDescriptor<ResearchQuestion>()
            let questions = try modelContext.fetch(rqDescriptor)
            
            for rq in questions {
                // Check for missing drivers
                if rq.drivers?.isEmpty ?? true {
                    issues.append("Research question '\(rq.questionText.prefix(30))...' has no drivers")
                }
            }
            
            // Check for orphaned evidence
            let evidenceDescriptor = FetchDescriptor<Evidence>()
            let allEvidence = try modelContext.fetch(evidenceDescriptor)
            
            let orphanedCount = allEvidence.filter { $0.driver == nil }.count
            if orphanedCount > 0 {
                issues.append("\(orphanedCount) evidence items have no linked driver")
            }
            
        } catch {
            issues.append("Failed to validate data: \(error.localizedDescription)")
        }
        
        return issues
    }
}

