/**
 AccessibilityHelper provides utilities for accessibility throughout the app.
 
 Features:
 - ScaledValue property wrapper for text size multiplier support
 - Environment key for app-wide text size multiplier
 - Helper functions for accessibility checks
 */

import SwiftUI

// MARK: - Text Size Multiplier Environment Key

/**
 Environment key for the app's custom text size multiplier.
 
 This works alongside the system's Dynamic Type settings to provide
 additional in-app control over text sizing.
 */
struct TextSizeMultiplierKey: EnvironmentKey {
    static let defaultValue: Double = 1.0
}

extension EnvironmentValues {
    /// The app's custom text size multiplier (0.85 to 1.5)
    var textSizeMultiplier: Double {
        get { self[TextSizeMultiplierKey.self] }
        set { self[TextSizeMultiplierKey.self] = newValue }
    }
}

// MARK: - Scaled Value Property Wrapper

/**
 A property wrapper that scales a base value by the app's text size multiplier.
 
 Usage:
 ```swift
 @ScaledValue(baseValue: 14) var fontSize: CGFloat
 ```
 
 The value automatically updates when the text size multiplier changes.
 */
@propertyWrapper
struct ScaledValue: DynamicProperty {
    @AppStorage("textSizeMultiplier") private var multiplier: Double = 1.0
    
    private let baseValue: CGFloat
    
    /// Creates a scaled value with the given base value
    /// - Parameter baseValue: The base value to scale
    init(baseValue: CGFloat) {
        self.baseValue = baseValue
    }
    
    var wrappedValue: CGFloat {
        baseValue * CGFloat(multiplier)
    }
}

// MARK: - Scaled Font Modifier

/**
 A view modifier that applies a scaled font based on the text size multiplier.
 */
struct ScaledFontModifier: ViewModifier {
    @AppStorage("textSizeMultiplier") private var multiplier: Double = 1.0
    
    let baseSize: CGFloat
    let weight: Font.Weight
    let design: Font.Design
    
    func body(content: Content) -> some View {
        content
            .font(.system(size: baseSize * CGFloat(multiplier), weight: weight, design: design))
    }
}

extension View {
    /// Applies a scaled font that respects the app's text size multiplier
    /// - Parameters:
    ///   - baseSize: The base font size
    ///   - weight: The font weight (default: .regular)
    ///   - design: The font design (default: .default)
    /// - Returns: A view with the scaled font applied
    func scaledFont(
        baseSize: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = .default
    ) -> some View {
        modifier(ScaledFontModifier(baseSize: baseSize, weight: weight, design: design))
    }
}

// MARK: - Accessibility Settings Observer

/**
 Observable object that provides access to accessibility settings.
 
 Use this to observe and react to accessibility preference changes.
 */
@Observable
final class AccessibilitySettings {
    /// Shared instance for app-wide access
    static let shared = AccessibilitySettings()
    
    /// The current text size multiplier from AppStorage
    var textSizeMultiplier: Double {
        UserDefaults.standard.double(forKey: "textSizeMultiplier").clamped(to: 0.85...1.5, defaultValue: 1.0)
    }
    
    /// Whether reduce motion is enabled in app settings
    var appReduceMotionEnabled: Bool {
        UserDefaults.standard.bool(forKey: "reduceMotionEnabled")
    }
    
    /// Whether high contrast is enabled in app settings
    var appHighContrastEnabled: Bool {
        UserDefaults.standard.bool(forKey: "highContrastEnabled")
    }
    
    private init() {}
}

// MARK: - Double Extension for Clamping

private extension Double {
    /// Clamps a value to a range, using a default if the value is invalid (zero)
    func clamped(to range: ClosedRange<Double>, defaultValue: Double) -> Double {
        if self == 0 {
            return defaultValue
        }
        return Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Accessibility View Modifiers

/**
 A view modifier that applies accessibility enhancements based on user settings.
 */
struct AccessibilityEnhancedModifier: ViewModifier {
    @AppStorage("reduceMotionEnabled") private var appReduceMotion: Bool = false
    @AppStorage("highContrastEnabled") private var appHighContrast: Bool = false
    
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.colorSchemeContrast) private var systemContrast
    
    /// Whether to reduce motion (app or system setting)
    var shouldReduceMotion: Bool {
        appReduceMotion || systemReduceMotion
    }
    
    /// Whether to use high contrast (app or system setting)
    var shouldUseHighContrast: Bool {
        appHighContrast || systemContrast == .increased
    }
    
    func body(content: Content) -> some View {
        content
            .transaction { transaction in
                // Disable animations when reduce motion is preferred
                if shouldReduceMotion {
                    transaction.animation = nil
                }
            }
    }
}

extension View {
    /// Applies accessibility enhancements that respect both app and system settings
    func accessibilityEnhanced() -> some View {
        modifier(AccessibilityEnhancedModifier())
    }
}

// MARK: - Scaled Spacing

/**
 Provides spacing values that scale with the text size multiplier.
 */
struct ScaledSpacing {
    @AppStorage("textSizeMultiplier") private var multiplier: Double = 1.0
    
    /// Extra small spacing (4pt base)
    var xs: CGFloat { 4 * CGFloat(multiplier) }
    
    /// Small spacing (8pt base)
    var sm: CGFloat { 8 * CGFloat(multiplier) }
    
    /// Medium spacing (12pt base)
    var md: CGFloat { 12 * CGFloat(multiplier) }
    
    /// Large spacing (16pt base)
    var lg: CGFloat { 16 * CGFloat(multiplier) }
    
    /// Extra large spacing (24pt base)
    var xl: CGFloat { 24 * CGFloat(multiplier) }
}

// MARK: - Minimum Touch Target Modifier

/**
 Ensures a view meets minimum touch target size requirements.
 
 Apple's HIG recommends a minimum of 44x44 points for touch targets.
 */
struct MinimumTouchTargetModifier: ViewModifier {
    let minWidth: CGFloat
    let minHeight: CGFloat
    
    init(minWidth: CGFloat = 44, minHeight: CGFloat = 44) {
        self.minWidth = minWidth
        self.minHeight = minHeight
    }
    
    func body(content: Content) -> some View {
        content
            .frame(minWidth: minWidth, minHeight: minHeight)
            .contentShape(Rectangle())
    }
}

extension View {
    /// Ensures the view meets minimum touch target size (44x44 by default)
    func minimumTouchTarget(width: CGFloat = 44, height: CGFloat = 44) -> some View {
        modifier(MinimumTouchTargetModifier(minWidth: width, minHeight: height))
    }
}

// MARK: - Accessibility Aware Root View

/**
 Root wrapper view that provides accessibility environment values to all child views.
 
 Use this at the app root to ensure all views have access to accessibility settings.
 It monitors both system and app-level accessibility preferences and propagates them
 through the environment.
 */
struct AccessibilityAwareRootView<Content: View>: View {
    @ViewBuilder let content: Content
    
    // App-level settings
    @AppStorage("textSizeMultiplier") private var textSizeMultiplier: Double = 1.0
    @AppStorage("reduceMotionEnabled") private var appReduceMotion: Bool = false
    @AppStorage("highContrastEnabled") private var appHighContrast: Bool = false
    
    // System accessibility settings
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.colorSchemeContrast) private var systemContrast
    @Environment(\.sizeCategory) private var sizeCategory
    
    /// Combined reduce motion preference (app OR system)
    private var shouldReduceMotion: Bool {
        appReduceMotion || systemReduceMotion
    }
    
    /// Combined high contrast preference (app OR system)
    private var shouldUseHighContrast: Bool {
        appHighContrast || systemContrast == .increased
    }
    
    var body: some View {
        content
            .environment(\.textSizeMultiplier, textSizeMultiplier)
            .transaction { transaction in
                // Disable animations when reduce motion is enabled
                if shouldReduceMotion {
                    transaction.animation = nil
                }
            }
    }
}

// MARK: - Preview

#Preview("Accessibility Settings") {
    VStack(spacing: 20) {
        Text("Scaled Font Example")
            .scaledFont(baseSize: 16, weight: .semibold)
        
        Text("Regular Text")
            .font(.body)
        
        Button("Touch Target Button") {
            print("Tapped")
        }
        .minimumTouchTarget()
    }
    .padding()
    .accessibilityEnhanced()
}

