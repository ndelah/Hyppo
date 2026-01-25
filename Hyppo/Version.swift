/**
 * Version.swift
 *
 * Central location for app version information.
 * Update this file when releasing new versions.
 */

import Foundation

/// App version constants and metadata
struct AppVersion {
    /// Current semantic version (Major.Minor.Patch)
    static let current = "1.0.0"
    
    /// Major version number
    static let major = 1
    
    /// Minor version number
    static let minor = 0
    
    /// Patch version number
    static let patch = 0
    
    /// Build number (increment for each build)
    static let build = 1
    
    /// Version name for display (e.g., "v1.0")
    static let displayName = "v1.0"
    
    /// Full version string including build number
    static var fullVersion: String {
        "\(current) (\(build))"
    }
    
    /// Release date of this version
    static let releaseDate = "2026-01-25"
    
    /// Brief description of this version
    static let releaseNotes = """
        v1.0 - Initial Release
        
        Core features:
        - Asset and Research Question management
        - Evidence tracking with sentiment analysis
        - Quick capture from clipboard
        - Tag organization
        - Review reminders and wizard
        - Export/Import functionality
        - Global search
        """
}

