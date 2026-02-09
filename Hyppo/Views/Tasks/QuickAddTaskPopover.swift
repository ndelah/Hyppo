/**
 QuickAddTaskPopover provides a floating popup for quick task creation.
 
 Features:
 - Triggered via keyboard shortcut (Cmd+Shift+T)
 - Contains TaskInputField with @ and # mention support
 - Auto-dismisses after task creation
 - Appears centered on screen
 */

import SwiftUI
import SwiftData
import Combine

/// Quick add task popup overlay
struct QuickAddTaskPopover: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var isAnimatingIn = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                
                Text("Quick Add Task")
                    .font(.headline)
                
                Spacer()
                
                Text("⌘⇧T")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape, modifiers: [])
            }
            .padding()
            .background(Color.surface)
            
            Divider()
            
            // Task input
            TaskInputField(
                onTaskCreated: { _ in
                    // Dismiss after a short delay to show the task was created
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        dismiss()
                    }
                },
                placeholder: "What do you need to do? (@ for project, # for driver)"
            )
            .padding()
            .background(Color.surface)
            
            // Tips
            HStack(spacing: 24) {
                HStack(spacing: 4) {
                    Text("@")
                        .font(.caption.bold())
                        .foregroundStyle(Color.accentColor)
                    Text("assign to project")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 4) {
                    Text("#")
                        .font(.caption.bold())
                        .foregroundStyle(Color.statusOnHold)
                    Text("assign to driver")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text("⏎ to save")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color.surface)
        }
        .frame(width: 500)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.appBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
        .scaleEffect(isAnimatingIn ? 1 : 0.9)
        .opacity(isAnimatingIn ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                isAnimatingIn = true
            }
        }
    }
}

/// Service to manage quick add task state
class QuickAddTaskService: ObservableObject {
    static let shared = QuickAddTaskService()
    
    @Published var isPopoverVisible = false
    
    private init() {}
    
    func showPopover() {
        isPopoverVisible = true
    }
    
    func hidePopover() {
        isPopoverVisible = false
    }
    
    func togglePopover() {
        isPopoverVisible.toggle()
    }
}

// MARK: - Preview

#Preview {
    QuickAddTaskPopover()
        .padding(40)
        .background(Color.black.opacity(0.3))
        .modelContainer(for: [ResearchTask.self, ResearchQuestion.self, Driver.self, Asset.self], inMemory: true)
}

