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
}

