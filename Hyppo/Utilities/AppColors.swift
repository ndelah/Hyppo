/**
 AppColors defines consistent color constants used throughout the app.
 
 Centralizing colors here ensures visual consistency and makes
 global color changes easier to manage.
 */

import SwiftUI

extension Color {
    // MARK: - Asset Colors
    
    /// Primary asset color - a medium-dark blue for asset badges, pills, and highlights
    /// Used consistently across table views, detail views, and creation flows
    static let assetColor = Color(red: 0.2, green: 0.5, blue: 0.8)
    
    /// Light background for asset-related UI elements
    static let assetBackgroundColor = Color.assetColor.opacity(0.15)
    
    // MARK: - Color Name Helper
    
    /// Converts a color name string to a SwiftUI Color
    /// Used for enum-based colorName properties (DecisionAction, InvestmentPhase, etc.)
    static func fromName(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        case "gray", "grey": return .gray
        default: return .blue // Default fallback
        }
    }
}

