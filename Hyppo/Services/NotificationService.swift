/**
 NotificationService manages local macOS notifications for review reminders.
 
 Handles permission requests, scheduling notifications for scenario reviews,
 and responding to notification actions like snooze.
 */

import Foundation
import UserNotifications
import SwiftData
import Combine

/// Service for managing local review reminder notifications
final class NotificationService: NSObject, ObservableObject {
    // MARK: - Singleton
    
    static let shared = NotificationService()
    
    // MARK: - Published State
    
    @Published var isAuthorized: Bool = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    // MARK: - Constants
    
    private let notificationCategoryId = "SCENARIO_REVIEW"
    private let snoozeActionId = "SNOOZE_ACTION"
    private let reviewActionId = "REVIEW_ACTION"
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkAuthorizationStatus()
        registerNotificationCategories()
    }
    
    // MARK: - Authorization
    
    /**
     Requests notification authorization from the user.
     
     - Parameter completion: Called with the authorization result
     */
    func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        let center = UNUserNotificationCenter.current()
        
        center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                self?.checkAuthorizationStatus()
                
                if let error = error {
                    DebugLogger.error(
                        location: "NotificationService:requestAuthorization",
                        message: "Failed to request authorization",
                        error: error
                    )
                }
                
                completion?(granted)
            }
        }
    }
    
    /**
     Checks the current authorization status.
     */
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.authorizationStatus = settings.authorizationStatus
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Notification Categories
    
    /**
     Registers notification action categories.
     */
    private func registerNotificationCategories() {
        let snoozeAction = UNNotificationAction(
            identifier: snoozeActionId,
            title: "Snooze (1 day)",
            options: []
        )
        
        let reviewAction = UNNotificationAction(
            identifier: reviewActionId,
            title: "Review Now",
            options: [.foreground]
        )
        
        let category = UNNotificationCategory(
            identifier: notificationCategoryId,
            actions: [reviewAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
    // MARK: - Scheduling Notifications
    
    /**
     Schedules a notification for a scenario review reminder.
     
     - Parameters:
       - reminder: The review reminder to schedule
       - scenario: The scenario being reminded about
     */
    func scheduleNotification(for reminder: ReviewReminder, scenario: Scenario) {
        guard isAuthorized else {
            DebugLogger.warning(
                location: "NotificationService:scheduleNotification",
                message: "Notifications not authorized"
            )
            return
        }
        
        guard reminder.isEnabled, let dueDate = reminder.nextReviewDueAt else {
            return
        }
        
        // Don't schedule if already past
        guard dueDate > Date() else {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Scenario Review Due"
        content.body = "Time to review your \(scenario.scenarioType.displayName.lowercased()) scenario: \"\(scenario.title)\""
        content.sound = .default
        content.categoryIdentifier = notificationCategoryId
        content.userInfo = [
            "scenarioId": scenario.scenarioId.uuidString,
            "reminderId": reminder.reminderId.uuidString
        ]
        
        // Create trigger for the due date
        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: dueDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: reminder.reminderId.uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                DebugLogger.error(
                    location: "NotificationService:scheduleNotification",
                    message: "Failed to schedule notification",
                    error: error
                )
            } else {
                DebugLogger.info(
                    location: "NotificationService:scheduleNotification",
                    message: "Scheduled notification for scenario review",
                    data: ["scenarioTitle": scenario.title, "dueDate": dueDate.description]
                )
            }
        }
    }
    
    /**
     Cancels a scheduled notification for a reminder.
     
     - Parameter reminder: The reminder whose notification should be cancelled
     */
    func cancelNotification(for reminder: ReviewReminder) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [reminder.reminderId.uuidString]
        )
        
        DebugLogger.info(
            location: "NotificationService:cancelNotification",
            message: "Cancelled notification",
            data: ["reminderId": reminder.reminderId.uuidString]
        )
    }
    
    /**
     Cancels all pending notifications.
     */
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    /**
     Reschedules notification after a reminder is updated.
     
     - Parameters:
       - reminder: The updated reminder
       - scenario: The scenario being reminded about
     */
    func rescheduleNotification(for reminder: ReviewReminder, scenario: Scenario) {
        cancelNotification(for: reminder)
        scheduleNotification(for: reminder, scenario: scenario)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    /// Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }
    
    /// Handle notification action responses
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        guard let reminderIdString = userInfo["reminderId"] as? String,
              let reminderId = UUID(uuidString: reminderIdString) else {
            completionHandler()
            return
        }
        
        DebugLogger.info(
            location: "NotificationService:didReceive",
            message: "Notification action received",
            data: ["action": response.actionIdentifier, "reminderId": reminderIdString]
        )
        
        switch response.actionIdentifier {
        case snoozeActionId:
            // Post notification for app to handle snooze
            NotificationCenter.default.post(
                name: .snoozeReviewReminder,
                object: nil,
                userInfo: ["reminderId": reminderId]
            )
            
        case reviewActionId, UNNotificationDefaultActionIdentifier:
            // Post notification for app to open the scenario
            if let scenarioIdString = userInfo["scenarioId"] as? String,
               let scenarioId = UUID(uuidString: scenarioIdString) {
                NotificationCenter.default.post(
                    name: .openScenarioForReview,
                    object: nil,
                    userInfo: ["scenarioId": scenarioId, "reminderId": reminderId]
                )
            }
            
        default:
            break
        }
        
        completionHandler()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when user taps snooze on a review notification
    static let snoozeReviewReminder = Notification.Name("snoozeReviewReminder")
    
    /// Posted when user taps to open scenario for review
    static let openScenarioForReview = Notification.Name("openScenarioForReview")
}

