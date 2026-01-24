/**
 ReviewReminder model for scheduling scenario review reminders.
 
 Tracks when a scenario should be reviewed next, the review cadence,
 and notification state. Supports snoozing and disabling reminders.
 */

import Foundation
import SwiftData

// MARK: - Review Cadence Enum

/**
 Represents the frequency of scenario reviews.
 
 Users can set how often they want to be reminded to review
 a particular scenario.
 */
enum ReviewCadence: String, Codable, CaseIterable, Identifiable {
    case daily = "Daily"
    case weekly = "Weekly"
    case biweekly = "Bi-weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case custom = "Custom"
    
    var id: String { rawValue }
    
    /// Display label for the cadence
    var displayName: String { rawValue }
    
    /// Number of days between reviews for this cadence
    var defaultDays: Int {
        switch self {
        case .daily: return 1
        case .weekly: return 7
        case .biweekly: return 14
        case .monthly: return 30
        case .quarterly: return 90
        case .custom: return 7 // Default for custom
        }
    }
    
    /// Icon name for visual representation
    var iconName: String {
        switch self {
        case .daily: return "sun.max"
        case .weekly: return "calendar.badge.clock"
        case .biweekly: return "calendar"
        case .monthly: return "calendar.circle"
        case .quarterly: return "calendar.badge.exclamationmark"
        case .custom: return "slider.horizontal.3"
        }
    }
}

// MARK: - Review Reminder Model

@Model
final class ReviewReminder {
    // MARK: - Properties
    
    /// Unique identifier for the reminder
    @Attribute(.unique) var reminderId: UUID
    
    /// Review cadence setting
    var cadenceRaw: String
    
    /// Custom interval in days (used when cadence is .custom)
    var customIntervalDays: Int?
    
    /// Next scheduled review date
    var nextReviewDueAt: Date?
    
    /// Timestamp when last notification was sent
    var lastNotifiedAt: Date?
    
    /// Whether reminders are enabled for this scenario
    var isEnabled: Bool
    
    /// Number of times this reminder has been snoozed
    var snoozeCount: Int
    
    /// If snoozed, when the snooze expires
    var snoozedUntil: Date?
    
    /// Timestamp when the reminder was created
    var createdAt: Date
    
    /// Timestamp when the reminder was last updated
    var updatedAt: Date
    
    // MARK: - Relationships
    
    /// The scenario this reminder belongs to
    @Relationship(inverse: \Scenario.reviewReminder) var scenario: Scenario?
    
    // MARK: - Initialization
    
    /**
     Creates a new review reminder with the specified cadence.
     
     - Parameters:
       - cadence: How frequently to remind (defaults to weekly)
       - customIntervalDays: Custom interval for .custom cadence
       - isEnabled: Whether the reminder is active (defaults to true)
     */
    init(
        cadence: ReviewCadence = .weekly,
        customIntervalDays: Int? = nil,
        isEnabled: Bool = true
    ) {
        self.reminderId = UUID()
        self.cadenceRaw = cadence.rawValue
        self.customIntervalDays = customIntervalDays
        self.isEnabled = isEnabled
        self.snoozeCount = 0
        self.createdAt = Date()
        self.updatedAt = Date()
        
        // Calculate initial next review date
        self.nextReviewDueAt = Self.calculateNextReviewDate(
            from: Date(),
            cadence: cadence,
            customDays: customIntervalDays
        )
    }
    
    // MARK: - Computed Properties
    
    /// Review cadence as enum
    var cadence: ReviewCadence {
        get { ReviewCadence(rawValue: cadenceRaw) ?? .weekly }
        set {
            cadenceRaw = newValue.rawValue
            updatedAt = Date()
        }
    }
    
    /// Effective interval in days (considering custom setting)
    var effectiveIntervalDays: Int {
        if cadence == .custom, let custom = customIntervalDays {
            return custom
        }
        return cadence.defaultDays
    }
    
    /// Whether the review is currently due
    var isDue: Bool {
        guard isEnabled, let dueDate = nextReviewDueAt else { return false }
        
        // Check if snoozed
        if let snoozedUntil = snoozedUntil, Date() < snoozedUntil {
            return false
        }
        
        return Date() >= dueDate
    }
    
    /// Whether the reminder is currently snoozed
    var isSnoozed: Bool {
        guard let snoozedUntil = snoozedUntil else { return false }
        return Date() < snoozedUntil
    }
    
    /// Days until next review (negative if overdue)
    var daysUntilDue: Int? {
        guard let dueDate = nextReviewDueAt else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: dueDate)
        return components.day
    }
    
    /// Human-readable status string
    var statusDescription: String {
        if !isEnabled {
            return "Disabled"
        }
        
        if isSnoozed, let until = snoozedUntil {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return "Snoozed until \(formatter.string(from: until))"
        }
        
        guard let days = daysUntilDue else {
            return "Not scheduled"
        }
        
        if days < 0 {
            return "Overdue by \(abs(days)) day\(abs(days) == 1 ? "" : "s")"
        } else if days == 0 {
            return "Due today"
        } else if days == 1 {
            return "Due tomorrow"
        } else {
            return "Due in \(days) days"
        }
    }
    
    // MARK: - Methods
    
    /**
     Updates the cadence and recalculates the next review date.
     
     - Parameters:
       - newCadence: The new review cadence
       - customDays: Custom interval for .custom cadence
     */
    func updateCadence(_ newCadence: ReviewCadence, customDays: Int? = nil) {
        self.cadence = newCadence
        self.customIntervalDays = customDays
        
        // Recalculate next review from now
        self.nextReviewDueAt = Self.calculateNextReviewDate(
            from: Date(),
            cadence: newCadence,
            customDays: customDays
        )
        self.updatedAt = Date()
    }
    
    /**
     Marks the review as completed and schedules the next one.
     */
    func completeReview() {
        self.lastNotifiedAt = nil
        self.snoozeCount = 0
        self.snoozedUntil = nil
        
        // Schedule next review from now
        self.nextReviewDueAt = Self.calculateNextReviewDate(
            from: Date(),
            cadence: cadence,
            customDays: customIntervalDays
        )
        self.updatedAt = Date()
        
        // Also update the scenario's lastReviewedAt
        scenario?.markReviewed()
    }
    
    /**
     Snoozes the reminder for the specified number of days.
     
     - Parameter days: Number of days to snooze (defaults to 1)
     */
    func snooze(days: Int = 1) {
        let calendar = Calendar.current
        self.snoozedUntil = calendar.date(byAdding: .day, value: days, to: Date())
        self.snoozeCount += 1
        self.updatedAt = Date()
    }
    
    /**
     Clears any active snooze.
     */
    func clearSnooze() {
        self.snoozedUntil = nil
        self.updatedAt = Date()
    }
    
    /**
     Enables or disables the reminder.
     
     - Parameter enabled: Whether to enable the reminder
     */
    func setEnabled(_ enabled: Bool) {
        self.isEnabled = enabled
        
        if enabled && nextReviewDueAt == nil {
            // Schedule a review if enabling and none scheduled
            self.nextReviewDueAt = Self.calculateNextReviewDate(
                from: Date(),
                cadence: cadence,
                customDays: customIntervalDays
            )
        }
        
        self.updatedAt = Date()
    }
    
    /**
     Records that a notification was sent.
     */
    func markNotified() {
        self.lastNotifiedAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - Static Helpers
    
    /**
     Calculates the next review date based on cadence.
     
     - Parameters:
       - from: The starting date
       - cadence: The review cadence
       - customDays: Custom interval for .custom cadence
     - Returns: The calculated next review date
     */
    static func calculateNextReviewDate(
        from date: Date,
        cadence: ReviewCadence,
        customDays: Int?
    ) -> Date {
        let calendar = Calendar.current
        let days = cadence == .custom ? (customDays ?? 7) : cadence.defaultDays
        return calendar.date(byAdding: .day, value: days, to: date) ?? date
    }
}

// MARK: - Validation

extension ReviewReminder {
    /// Validates that the reminder has valid settings
    var isValid: Bool {
        if cadence == .custom {
            guard let days = customIntervalDays, days > 0 else {
                return false
            }
        }
        return true
    }
    
    /// Returns validation errors if any
    var validationErrors: [String] {
        var errors: [String] = []
        
        if cadence == .custom {
            if customIntervalDays == nil {
                errors.append("Custom interval is required for custom cadence")
            } else if let days = customIntervalDays, days <= 0 {
                errors.append("Custom interval must be greater than 0")
            }
        }
        
        return errors
    }
}

