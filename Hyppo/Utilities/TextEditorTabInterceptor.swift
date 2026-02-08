/**
 KeyEventInterceptor provides ViewModifiers that intercept key events at the
 AppKit NSEvent level — before the Cocoa responder chain can consume them.
 
 macOS's NSTextField and NSTextView swallow certain keys (Tab, Return, Escape)
 at the AppKit responder-chain level before SwiftUI's `.onKeyPress` sees them.
 These modifiers install a local NSEvent monitor (scoped to the view's
 lifecycle) that catches those key-down events and fires the provided
 callbacks instead.
 
 Usage — TextEditor (Tab / Shift+Tab / Escape):
     TextEditor(text: $text)
         .interceptTab(
             isActive: focusedField == .whyThisMatters,
             onTab: { focusedField = nil },
             onShiftTab: { focusedField = .investmentThesis },
             onEscape: { focusedField = nil }
         )
 
 Usage — TextField (Return / Escape):
     TextField("Title", text: $title)
         .interceptKeys(
             isActive: isEditing,
             onReturn: { processAndSubmit() },
             onEscape: { cancelEditing() }
         )
 */

import SwiftUI
import AppKit

// MARK: - Tab Interceptor Modifier (TextEditor)

/// Intercepts Tab and Shift+Tab at the NSEvent level for TextEditor views
/// that would otherwise swallow these events in the AppKit responder chain.
struct TextEditorTabInterceptor: ViewModifier {
    /// Whether this interceptor is currently active (only intercept when the TextEditor is focused)
    let isActive: Bool
    /// Called when the user presses Tab (no Shift)
    let onTab: () -> Void
    /// Called when the user presses Shift+Tab
    let onShiftTab: () -> Void
    /// Called when the user presses Escape
    let onEscape: (() -> Void)?

    @State private var monitor: Any?

    func body(content: Content) -> some View {
        content
            .onChange(of: isActive) { _, active in
                if active {
                    installMonitor()
                } else {
                    removeMonitor()
                }
            }
            .onAppear {
                if isActive {
                    installMonitor()
                }
            }
            .onDisappear {
                removeMonitor()
            }
    }

    // MARK: - Monitor Lifecycle

    private func installMonitor() {
        guard monitor == nil else { return }

        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard isActive else { return event }

            // Tab key (keyCode 48)
            if event.keyCode == 48 {
                if event.modifierFlags.contains(.shift) {
                    DispatchQueue.main.async { onShiftTab() }
                } else {
                    DispatchQueue.main.async { onTab() }
                }
                return nil
            }

            // Escape key (keyCode 53)
            if event.keyCode == 53, let onEscape {
                DispatchQueue.main.async { onEscape() }
                return nil
            }

            return event
        }
    }

    private func removeMonitor() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
    }
}

// MARK: - General Key Interceptor Modifier (TextField / any view)

/// Intercepts Return, Escape, Tab, and Shift+Tab at the NSEvent level.
/// Useful for TextField views where `.onKeyPress(.return)` doesn't fire
/// because NSTextField handles it at the Cocoa level first.
struct KeyEventInterceptor: ViewModifier {
    let isActive: Bool
    let onReturn: (() -> Void)?
    let onEscape: (() -> Void)?
    let onTab: (() -> Void)?
    let onShiftTab: (() -> Void)?

    @State private var monitor: Any?

    func body(content: Content) -> some View {
        content
            .onChange(of: isActive) { _, active in
                if active {
                    installMonitor()
                } else {
                    removeMonitor()
                }
            }
            .onAppear {
                if isActive {
                    installMonitor()
                }
            }
            .onDisappear {
                removeMonitor()
            }
    }

    private func installMonitor() {
        guard monitor == nil else { return }

        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard isActive else { return event }

            // Return key (keyCode 36)
            if event.keyCode == 36, let onReturn {
                DispatchQueue.main.async { onReturn() }
                return nil
            }

            // Escape key (keyCode 53)
            if event.keyCode == 53, let onEscape {
                DispatchQueue.main.async { onEscape() }
                return nil
            }

            // Tab key (keyCode 48)
            if event.keyCode == 48 {
                if event.modifierFlags.contains(.shift) {
                    if let onShiftTab {
                        DispatchQueue.main.async { onShiftTab() }
                        return nil
                    }
                } else {
                    if let onTab {
                        DispatchQueue.main.async { onTab() }
                        return nil
                    }
                }
            }

            return event
        }
    }

    private func removeMonitor() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
    }
}

// MARK: - View Extensions

extension View {
    /// Intercepts Tab, Shift+Tab, and optionally Escape on a TextEditor.
    func interceptTab(
        isActive: Bool,
        onTab: @escaping () -> Void,
        onShiftTab: @escaping () -> Void,
        onEscape: (() -> Void)? = nil
    ) -> some View {
        modifier(TextEditorTabInterceptor(
            isActive: isActive,
            onTab: onTab,
            onShiftTab: onShiftTab,
            onEscape: onEscape
        ))
    }

    /// Intercepts Return, Escape, Tab, and/or Shift+Tab at the AppKit level.
    /// Use for TextField views where `.onKeyPress(.return)` doesn't fire.
    func interceptKeys(
        isActive: Bool,
        onReturn: (() -> Void)? = nil,
        onEscape: (() -> Void)? = nil,
        onTab: (() -> Void)? = nil,
        onShiftTab: (() -> Void)? = nil
    ) -> some View {
        modifier(KeyEventInterceptor(
            isActive: isActive,
            onReturn: onReturn,
            onEscape: onEscape,
            onTab: onTab,
            onShiftTab: onShiftTab
        ))
    }
}
