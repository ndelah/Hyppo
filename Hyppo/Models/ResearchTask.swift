/**
 ResearchTask model representing an actionable research item.
 
 Tasks are lightweight, iterative research actions that can be added incrementally.
 Tasks can exist in three states:
 - Inbox: No research question or driver assigned
 - Question-only: Assigned to a research question without a specific driver
 - Fully assigned: Linked to both a research question and a driver
 
 Designed to be AI-ready: tasks are phrased as actionable research questions
 that could eventually be executed with AI assistance.
 */

import Foundation
import SwiftData

@Model
final class ResearchTask {
    // MARK: - Properties
    
    /// Unique identifier for the task
    @Attribute(.unique) var taskId: UUID
    
    /// The task description (e.g., "Find YoY datacenter revenue growth")
    var text: String
    
    /// Whether the task has been completed
    var isCompleted: Bool
    
    /// Ordering among sibling tasks
    var position: Int
    
    // MARK: - Relationships
    
    /// Direct link to research question (optional - tasks can exist in inbox)
    var researchQuestion: ResearchQuestion?
    
    /// Parent driver this task belongs to (optional)
    var driver: Driver?
    
    // MARK: - Metadata
    
    var createdAt: Date
    var completedAt: Date?
    
    // MARK: - Computed Properties
    
    /// Returns the effective research question (direct link or through driver)
    var effectiveResearchQuestion: ResearchQuestion? {
        researchQuestion ?? driver?.researchQuestion
    }
    
    /// Returns true if the task is in the inbox (no question or driver assigned)
    var isInbox: Bool {
        researchQuestion == nil && driver == nil
    }
    
    /// Returns a display label for the research question
    var questionDisplayLabel: String? {
        guard let question = effectiveResearchQuestion else { return nil }
        // Prefer asset ticker if available, otherwise use truncated question text
        if let ticker = question.asset?.ticker {
            return ticker
        }
        let text = question.questionText
        return text.count > 25 ? String(text.prefix(22)) + "..." : text
    }
    
    /// Returns a display label for the driver
    var driverDisplayLabel: String? {
        guard let driver = driver else { return nil }
        let text = driver.title
        return text.count > 20 ? String(text.prefix(17)) + "..." : text
    }
    
    // MARK: - Initialization
    
    init(
        text: String,
        position: Int = 0,
        isCompleted: Bool = false,
        researchQuestion: ResearchQuestion? = nil,
        driver: Driver? = nil
    ) {
        self.taskId = UUID()
        self.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        self.position = position
        self.isCompleted = isCompleted
        self.researchQuestion = researchQuestion
        self.driver = driver
        self.createdAt = Date()
        self.completedAt = nil
    }
    
    // MARK: - Methods
    
    /// Marks the task as completed
    func complete() {
        isCompleted = true
        completedAt = Date()
    }
    
    /// Marks the task as incomplete
    func uncomplete() {
        isCompleted = false
        completedAt = nil
    }
    
    /// Toggles completion status
    func toggleCompletion() {
        if isCompleted {
            uncomplete()
        } else {
            complete()
        }
    }
}

