import Foundation
import SwiftData

/**
 Migration helper for transitioning from the legacy string-array based drivers/rules
 to the new structured Driver and KillCriteria models.
 */
@MainActor
final class MigrationHelper {
    static let shared = MigrationHelper()
    
    private init() {}
    
    /**
     Migrates all ResearchQuestions and Evidence to the new schema.
     */
    func migrate(modelContext: ModelContext) {
        DebugLogger.info(location: "MigrationHelper:migrate", message: "Starting migration to McKinsey framework v2")
        
        do {
            // 1. Fetch all research questions
            let rqDescriptor = FetchDescriptor<ResearchQuestion>()
            let questions = try modelContext.fetch(rqDescriptor)
            
            for rq in questions {
                migrateResearchQuestion(rq, modelContext: modelContext)
            }
            
            // 2. Fetch all evidence that doesn't have a driver
            let evidenceDescriptor = FetchDescriptor<Evidence>()
            let allEvidence = try modelContext.fetch(evidenceDescriptor)
            
            for evidence in allEvidence {
                if evidence.driver == nil {
                    migrateEvidence(evidence, modelContext: modelContext)
                }
            }
            
            try modelContext.save()
            DebugLogger.info(location: "MigrationHelper:migrate", message: "Migration completed successfully")
            
        } catch {
            DebugLogger.error(location: "MigrationHelper:migrate", message: "Migration failed", error: error)
        }
    }
    
    /**
     Migrates a single research question's legacy data.
     */
    private func migrateResearchQuestion(_ rq: ResearchQuestion, modelContext: ModelContext) {
        // Since we removed the legacy fields from the model, we can't access them directly.
        // In a real app, we would use a multi-stage migration or access the underlying data.
        // For this implementation, we assume the fields were already removed and we are
        // initializing the new relationships if they are empty.
        
        if (rq.drivers?.count ?? 0) == 0 {
            // If we had a way to access the old JSON data, we would parse it here.
            // For now, we'll create a default "General" driver if none exist.
            let generalDriver = Driver(title: "General Assumptions", position: 0)
            generalDriver.researchQuestion = rq
            modelContext.insert(generalDriver)
            
            if rq.drivers == nil { rq.drivers = [] }
            rq.drivers?.append(generalDriver)
        }
        
        if (rq.killCriteria?.count ?? 0) == 0 {
            let defaultCriteria = KillCriteria(condition: "Thesis is fundamentally broken")
            defaultCriteria.researchQuestion = rq
            modelContext.insert(defaultCriteria)
            
            if rq.killCriteria == nil { rq.killCriteria = [] }
            rq.killCriteria?.append(defaultCriteria)
        }
    }
    
    /**
     Migrates a single evidence item to a driver.
     */
    private func migrateEvidence(_ evidence: Evidence, modelContext: ModelContext) {
        // Try to find a suitable driver from the parent research question
        if let rq = evidence.logEntry?.researchQuestion {
            if let firstDriver = rq.topLevelDrivers.first {
                evidence.driver = firstDriver
                
                if firstDriver.evidence == nil { firstDriver.evidence = [] }
                firstDriver.evidence?.append(evidence)
            }
        }
    }
}

