/**
 ReviewReminderView displays and manages the review reminder for a research question.
 
 Shows the current reminder status, allows configuring cadence,
 and provides actions for snoozing and completing reviews.
 */

import SwiftUI
import SwiftData

/// View for displaying and managing a research question review reminder
struct ReviewReminderView: View {
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Properties
    
    @Bindable var researchQuestion: ResearchQuestion
    
    // MARK: - State
    
    @State private var showingCadenceSheet = false
    @State private var showingReviewWizard = false
    @StateObject private var notificationService = NotificationService.shared
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Label("Review Reminder", systemImage: "bell")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                // Enable/disable toggle
                Toggle("", isOn: reminderEnabledBinding)
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }
            
            if let reminder = researchQuestion.reviewReminder, reminder.isEnabled {
                // Status and actions
                reminderContent(reminder)
            } else if researchQuestion.reviewReminder == nil {
                // No reminder set up yet
                noReminderView
            } else {
                // Reminder exists but is disabled
                disabledReminderView
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .sheet(isPresented: $showingCadenceSheet) {
            CadenceConfigSheet(researchQuestion: researchQuestion)
        }
    }
    
    // MARK: - Bindings
    
    private var reminderEnabledBinding: Binding<Bool> {
        Binding(
            get: { researchQuestion.reviewReminder?.isEnabled ?? false },
            set: { newValue in
                if newValue {
                    enableReminder()
                } else {
                    disableReminder()
                }
            }
        )
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func reminderContent(_ reminder: ReviewReminder) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Status indicator
            statusView(reminder)
            
            // Cadence info
            HStack {
                Label(reminder.cadence.displayName, systemImage: reminder.cadence.iconName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button("Change") {
                    showingCadenceSheet = true
                }
                .font(.caption)
                .buttonStyle(.borderless)
            }
            
            // Action buttons when due
            if reminder.isDue {
                dueActionsView(reminder)
            }
        }
    }
    
    @ViewBuilder
    private func statusView(_ reminder: ReviewReminder) -> some View {
        HStack(spacing: 8) {
            // Status icon
            Image(systemName: statusIconName(for: reminder))
                .font(.title3)
                .foregroundStyle(statusColor(for: reminder))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.statusDescription)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let dueDate = reminder.nextReviewDueAt {
                    Text("Next: \(dueDate.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(10)
        .background(statusColor(for: reminder).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    @ViewBuilder
    private func dueActionsView(_ reminder: ReviewReminder) -> some View {
        HStack(spacing: 12) {
            // Start review wizard button
            Button {
                showingReviewWizard = true
            } label: {
                Label("Start Review", systemImage: "wand.and.stars")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            
            // Quick complete (skip wizard)
            Button {
                quickCompleteReview(reminder)
            } label: {
                Label("Quick Complete", systemImage: "checkmark.circle")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            
            // Snooze button
            Menu {
                Button("1 day") { snooze(reminder, days: 1) }
                Button("3 days") { snooze(reminder, days: 3) }
                Button("1 week") { snooze(reminder, days: 7) }
            } label: {
                Label("Snooze", systemImage: "moon.zzz")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .sheet(isPresented: $showingReviewWizard) {
            ReviewWizardView(researchQuestion: researchQuestion) {
                // Wizard handles everything, just reschedule notification
                if let r = researchQuestion.reviewReminder {
                    notificationService.rescheduleNotification(for: r, researchQuestion: researchQuestion)
                }
            }
        }
    }
    
    private var noReminderView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No reminder configured")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Button("Set Up Reminder") {
                enableReminder()
                showingCadenceSheet = true
            }
            .font(.caption)
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }
    
    private var disabledReminderView: some View {
        Text("Reminder disabled")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    
    // MARK: - Helpers
    
    private func statusIconName(for reminder: ReviewReminder) -> String {
        if reminder.isSnoozed {
            return "moon.zzz.fill"
        } else if reminder.isDue {
            return "exclamationmark.circle.fill"
        } else {
            return "clock"
        }
    }
    
    private func statusColor(for reminder: ReviewReminder) -> Color {
        if reminder.isSnoozed {
            return .orange
        } else if reminder.isDue {
            if let days = reminder.daysUntilDue, days < 0 {
                return .red // Overdue
            }
            return .yellow // Due today
        } else {
            return .green // Upcoming
        }
    }
    
    // MARK: - Actions
    
    private func enableReminder() {
        if researchQuestion.reviewReminder == nil {
            let reminder = ReviewReminder(cadence: .weekly, isEnabled: true)
            modelContext.insert(reminder)
            researchQuestion.reviewReminder = reminder
            
            // Request notification permission if needed
            notificationService.requestAuthorization { granted in
                if granted {
                    notificationService.scheduleNotification(for: reminder, researchQuestion: researchQuestion)
                }
            }
        } else {
            researchQuestion.reviewReminder?.setEnabled(true)
            if let reminder = researchQuestion.reviewReminder {
                notificationService.scheduleNotification(for: reminder, researchQuestion: researchQuestion)
            }
        }
    }
    
    private func disableReminder() {
        if let reminder = researchQuestion.reviewReminder {
            reminder.setEnabled(false)
            notificationService.cancelNotification(for: reminder)
        }
    }
    
    private func quickCompleteReview(_ reminder: ReviewReminder) {
        reminder.completeReview()
        notificationService.rescheduleNotification(for: reminder, researchQuestion: researchQuestion)
        
        // Create a simple review log entry (for quick complete without wizard)
        let logEntry = LogEntry.createReviewLog(
            outcome: ReviewOutcome.reinforce,
            summary: "Quick review completed - thesis still valid",
            confidence: researchQuestion.confidenceCurrent
        )
        modelContext.insert(logEntry)
        logEntry.researchQuestion = researchQuestion
        
        // Update research question
        researchQuestion.lastReviewedAt = Date()
    }
    
    private func snooze(_ reminder: ReviewReminder, days: Int) {
        reminder.snooze(days: days)
        notificationService.rescheduleNotification(for: reminder, researchQuestion: researchQuestion)
    }
}

// MARK: - Cadence Configuration Sheet

/// Sheet for configuring reminder cadence
struct CadenceConfigSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var researchQuestion: ResearchQuestion
    
    @State private var selectedCadence: ReviewCadence = .weekly
    @State private var customDays: Int = 14
    
    @StateObject private var notificationService = NotificationService.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Review Cadence")
                    .font(.headline)
                Spacer()
            }
            .padding()
            
            Divider()
            
            // Cadence options
            Form {
                Section {
                    Picker("Remind me", selection: $selectedCadence) {
                        ForEach(ReviewCadence.allCases) { cadence in
                            Label(cadence.displayName, systemImage: cadence.iconName)
                                .tag(cadence)
                        }
                    }
                    .pickerStyle(.inline)
                    
                    if selectedCadence == .custom {
                        Stepper("Every \(customDays) days", value: $customDays, in: 1...365)
                    }
                }
                
                Section {
                    if !notificationService.isAuthorized {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(.orange)
                            Text("Notifications are not enabled")
                                .font(.caption)
                            Spacer()
                            Button("Enable") {
                                notificationService.requestAuthorization()
                            }
                            .font(.caption)
                        }
                    } else {
                        Label("Notifications enabled", systemImage: "checkmark.circle")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                } header: {
                    Text("Notifications")
                }
            }
            .formStyle(.grouped)
            
            Divider()
            
            // Footer
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
                
                Spacer()
                
                Button("Save") {
                    saveCadence()
                    dismiss()
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 400, height: 400)
        .onAppear {
            if let reminder = researchQuestion.reviewReminder {
                selectedCadence = reminder.cadence
                customDays = reminder.customIntervalDays ?? 14
            }
        }
    }
    
    private func saveCadence() {
        if let reminder = researchQuestion.reviewReminder {
            reminder.updateCadence(
                selectedCadence,
                customDays: selectedCadence == .custom ? customDays : nil
            )
            notificationService.rescheduleNotification(for: reminder, researchQuestion: researchQuestion)
        } else {
            let reminder = ReviewReminder(
                cadence: selectedCadence,
                customIntervalDays: selectedCadence == .custom ? customDays : nil,
                isEnabled: true
            )
            modelContext.insert(reminder)
            researchQuestion.reviewReminder = reminder
            notificationService.scheduleNotification(for: reminder, researchQuestion: researchQuestion)
        }
    }
}

// MARK: - Due Badge View

/// Small badge indicating a research question review is due
struct ReviewDueBadge: View {
    let reminder: ReviewReminder?
    
    var body: some View {
        if let reminder = reminder, reminder.isEnabled && reminder.isDue {
            HStack(spacing: 4) {
                Image(systemName: "bell.fill")
                    .font(.caption2)
                Text("Review Due")
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(badgeColor.opacity(0.15))
            .foregroundStyle(badgeColor)
            .clipShape(Capsule())
        }
    }
    
    private var badgeColor: Color {
        guard let reminder = reminder, let days = reminder.daysUntilDue else {
            return .yellow
        }
        return days < 0 ? .red : .yellow
    }
}

// MARK: - Preview

#Preview {
    let question = ResearchQuestion(
        questionText: "Can AAPL sustain services revenue growth?",
        thesisStatement: "Apple's services segment will grow 15%+ annually",
        keyDrivers: ["Growing installed base"],
        invalidationRules: ["Services growth below 10%"]
    )
    
    return ReviewReminderView(researchQuestion: question)
        .padding()
        .modelContainer(for: [ResearchQuestion.self, ReviewReminder.self, LogEntry.self], inMemory: true)
}
