/**
 ResearchTask model representing an actionable research item linked to a Driver.
 
 Tasks are lightweight, iterative research actions that can be added incrementally.
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
    
    /// Parent driver this task belongs to
    var driver: Driver?
    
    // MARK: - Metadata
    
    var createdAt: Date
    var completedAt: Date?
    
    // MARK: - Initialization
    
    init(
        text: String,
        position: Int = 0,
        isCompleted: Bool = false,
        driver: Driver? = nil
    ) {
        self.taskId = UUID()
        self.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        self.position = position
        self.isCompleted = isCompleted
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

