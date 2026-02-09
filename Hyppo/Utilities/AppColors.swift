/**
 AppColors defines the app-wide color system using the 60-30-10 rule.
 
 Inspired by Claude's warm aesthetic:
 - 60% — Primary background (warm cream / dark warm)
 - 30% — Surface colors (white / dark elevated)
 - 10% — Accent (terracotta) + semantic status colors
 
 Light mode: creamy, warm, paper-like feel
 Dark mode: deep warm brown-olive tones
 
 All theme colors adapt automatically to light/dark appearance.
 */

import SwiftUI
import AppKit

// MARK: - Adaptive Color Helper

extension Color {
    
    /// Creates an NSColor-backed adaptive color that switches with system appearance
    fileprivate static func adaptive(
        light: (r: CGFloat, g: CGFloat, b: CGFloat),
        dark: (r: CGFloat, g: CGFloat, b: CGFloat)
    ) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            let c = isDark ? dark : light
            return NSColor(red: c.r, green: c.g, blue: c.b, alpha: 1)
        })
    }
    
    /// Adaptive color with alpha channel support
    fileprivate static func adaptive(
        light: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat),
        dark: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)
    ) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            let c = isDark ? dark : light
            return NSColor(red: c.r, green: c.g, blue: c.b, alpha: c.a)
        })
    }
}

// MARK: - 60-30-10 Theme Colors

extension Color {
    
    // MARK: 60% — Background
    
    /// Primary app background — warm cream (light) / deep warm dark (dark)
    static let appBackground = adaptive(
        light: (0.976, 0.969, 0.953),   // #F9F7F3
        dark:  (0.110, 0.106, 0.094)    // #1C1B18
    )
    
    // MARK: 30% — Surfaces
    
    /// Card, panel, and input field background — white (light) / elevated dark (dark)
    static let surface = adaptive(
        light: (1.0, 1.0, 1.0),         // #FFFFFF
        dark:  (0.165, 0.157, 0.145)    // #2A2825
    )
    
    /// Toolbar, header, and navigation bar background
    static let surfaceSecondary = adaptive(
        light: (0.953, 0.945, 0.929),   // #F3F1ED
        dark:  (0.137, 0.133, 0.122)    // #232220
    )
    
    /// Slightly raised surface for hover states and grouped content
    static let surfaceHover = adaptive(
        light: (0.941, 0.933, 0.914),   // #F0EEE9
        dark:  (0.184, 0.176, 0.161)    // #2F2D29
    )
    
    // MARK: 10% — Accent
    
    /// Primary accent — warm terracotta
    /// Also mirrored in AccentColor.colorset so SwiftUI controls pick it up automatically
    static let appAccent = adaptive(
        light: (0.769, 0.439, 0.294),   // #C4704B
        dark:  (0.831, 0.518, 0.353)    // #D4845A
    )
    
    /// Subtle accent background for selected tabs, highlights, badges
    static let appAccentSubtle = adaptive(
        light: (0.769, 0.439, 0.294, 0.10),
        dark:  (0.831, 0.518, 0.353, 0.12)
    )
    
    // MARK: — Borders & Dividers
    
    /// Border / separator color — warm and subtle
    static let appBorder = adaptive(
        light: (0.867, 0.847, 0.812),   // #DDD8CF
        dark:  (0.243, 0.231, 0.216)    // #3E3B37
    )
    
    // MARK: - Asset Colors
    
    /// Primary asset color — warm teal for asset badges, pills, and highlights
    static let assetColor = adaptive(
        light: (0.18, 0.52, 0.58),      // #2E8594
        dark:  (0.30, 0.64, 0.70)       // #4DA3B3
    )
    
    /// Light background for asset-related UI elements
    static let assetBackgroundColor = adaptive(
        light: (0.18, 0.52, 0.58, 0.12),
        dark:  (0.30, 0.64, 0.70, 0.15)
    )
    
    // MARK: - Semantic Status Colors (Muted for Warm Palette)
    
    /// Active status — muted green
    static let statusActive = adaptive(
        light: (0.20, 0.65, 0.45),      // #33A673
        dark:  (0.30, 0.75, 0.55)       // #4DBF8C
    )
    
    /// On Hold status — warm amber
    static let statusOnHold = adaptive(
        light: (0.80, 0.58, 0.20),      // #CC9433
        dark:  (0.90, 0.68, 0.30)       // #E6AD4D
    )
    
    /// Invalidated status — muted red
    static let statusInvalidated = adaptive(
        light: (0.78, 0.30, 0.28),      // #C74D47
        dark:  (0.88, 0.40, 0.38)       // #E06661
    )
    
    /// Archived status — warm gray
    static let statusArchived = adaptive(
        light: (0.58, 0.56, 0.53),      // #948F87
        dark:  (0.55, 0.53, 0.50)       // #8C8780
    )
    
    // MARK: - Confidence Level Colors
    
    /// Very Low confidence
    static let confidenceVeryLow = adaptive(
        light: (0.78, 0.30, 0.28),      // same as invalidated
        dark:  (0.88, 0.40, 0.38)
    )
    
    /// Low confidence
    static let confidenceLow = adaptive(
        light: (0.80, 0.58, 0.20),      // same as on hold
        dark:  (0.90, 0.68, 0.30)
    )
    
    /// Medium confidence
    static let confidenceMedium = adaptive(
        light: (0.75, 0.65, 0.25),      // warm gold
        dark:  (0.85, 0.75, 0.35)
    )
    
    /// High confidence
    static let confidenceHigh = adaptive(
        light: (0.20, 0.65, 0.45),      // same as active
        dark:  (0.30, 0.75, 0.55)
    )
    
    /// Very High confidence — uses accent terracotta
    static let confidenceVeryHigh = adaptive(
        light: (0.22, 0.50, 0.72),      // warm blue
        dark:  (0.35, 0.62, 0.82)
    )
    
    // MARK: - Color Name Helper
    
    /// Converts a color name string to a SwiftUI Color (for enum-based colorName properties)
    static func fromName(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "red": return .statusInvalidated
        case "orange": return .statusOnHold
        case "yellow": return .confidenceMedium
        case "green": return .statusActive
        case "blue": return .confidenceVeryHigh
        case "purple": return .purple
        case "pink": return .pink
        case "gray", "grey": return .statusArchived
        default: return .appAccent
        }
    }
    
    // MARK: - Status Color Helper
    
    /// Returns the theme color for a research question status
    static func forStatus(_ status: ResearchQuestionStatus) -> Color {
        switch status {
        case .active: return .statusActive
        case .onHold: return .statusOnHold
        case .invalidated: return .statusInvalidated
        case .archived: return .statusArchived
        }
    }
    
    // MARK: - Confidence Color Helper
    
    /// Returns the theme color for a confidence level
    static func forConfidence(_ level: ConfidenceLevel) -> Color {
        switch level {
        case .veryLow: return .confidenceVeryLow
        case .low: return .confidenceLow
        case .medium: return .confidenceMedium
        case .high: return .confidenceHigh
        case .veryHigh: return .confidenceVeryHigh
        }
    }
    
    // MARK: - Driver Status Color Helper
    
    /// Returns the theme color for a driver status
    static func forDriverStatus(_ status: DriverStatus) -> Color {
        switch status {
        case .pending: return .statusArchived
        case .confirmed: return .statusActive
        case .discarded: return .statusInvalidated
        case .needsRevision: return .statusOnHold
        }
    }
}
