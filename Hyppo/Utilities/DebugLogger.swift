/**
 DebugLogger provides structured logging for development and debugging.
 
 This utility captures application events with context information
 to help diagnose issues during development. Logging is disabled
 in release builds for performance and privacy.
 */

import Foundation
import os.log

/// Structured debug logging utility for development
enum DebugLogger {
    // MARK: - Configuration
    
    /// Enable or disable debug logging
    #if DEBUG
    private static let isEnabled = true
    #else
    private static let isEnabled = false
    #endif
    
    /// OSLog subsystem identifier
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.footnote.app"
    
    /// Default log category
    private static let defaultCategory = "General"
    
    // MARK: - Logging Methods
    
    /**
     Logs a debug message with structured context.
     
     - Parameters:
       - sessionId: Identifier for the current session
       - runId: Identifier for the current run/operation
       - hypothesisId: Identifier for tracking specific hypotheses
       - location: Source location (e.g., "FileName.swift:methodName")
       - message: The log message
       - data: Optional dictionary of additional context data
       - category: Log category (defaults to "General")
     */
    static func log(
        sessionId: String = "default",
        runId: String = "default",
        hypothesisId: String = "default",
        location: String,
        message: String,
        data: [String: Any]? = nil,
        category: String = defaultCategory
    ) {
        guard isEnabled else { return }
        
        let logger = Logger(subsystem: subsystem, category: category)
        
        var logParts: [String] = []
        logParts.append("[\(location)]")
        logParts.append(message)
        
        if let data = data, !data.isEmpty {
            let dataString = data.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            logParts.append("{\(dataString)}")
        }
        
        let fullMessage = logParts.joined(separator: " ")
        logger.debug("\(fullMessage, privacy: .public)")
        
        // Also print to console for easier development debugging
        #if DEBUG
        let timestamp = ISO8601DateFormatter().string(from: Date())
        print("[\(timestamp)] \(fullMessage)")
        #endif
    }
    
    /**
     Logs an info-level message.
     
     - Parameters:
       - location: Source location
       - message: The log message
       - data: Optional context data
     */
    static func info(
        location: String,
        message: String,
        data: [String: Any]? = nil
    ) {
        guard isEnabled else { return }
        
        let logger = Logger(subsystem: subsystem, category: "Info")
        
        var logParts: [String] = []
        logParts.append("[\(location)]")
        logParts.append(message)
        
        if let data = data, !data.isEmpty {
            let dataString = data.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            logParts.append("{\(dataString)}")
        }
        
        let fullMessage = logParts.joined(separator: " ")
        logger.info("\(fullMessage, privacy: .public)")
        
        #if DEBUG
        print("[INFO] \(fullMessage)")
        #endif
    }
    
    /**
     Logs a warning-level message.
     
     - Parameters:
       - location: Source location
       - message: The warning message
       - data: Optional context data
     */
    static func warning(
        location: String,
        message: String,
        data: [String: Any]? = nil
    ) {
        guard isEnabled else { return }
        
        let logger = Logger(subsystem: subsystem, category: "Warning")
        
        var logParts: [String] = []
        logParts.append("[\(location)]")
        logParts.append("⚠️ \(message)")
        
        if let data = data, !data.isEmpty {
            let dataString = data.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            logParts.append("{\(dataString)}")
        }
        
        let fullMessage = logParts.joined(separator: " ")
        logger.warning("\(fullMessage, privacy: .public)")
        
        #if DEBUG
        print("[WARNING] \(fullMessage)")
        #endif
    }
    
    /**
     Logs an error-level message.
     
     - Parameters:
       - location: Source location
       - message: The error message
       - error: Optional Error object
       - data: Optional context data
     */
    static func error(
        location: String,
        message: String,
        error: Error? = nil,
        data: [String: Any]? = nil
    ) {
        // Errors are always logged, even in release builds
        let logger = Logger(subsystem: subsystem, category: "Error")
        
        var logParts: [String] = []
        logParts.append("[\(location)]")
        logParts.append("❌ \(message)")
        
        if let error = error {
            logParts.append("Error: \(error.localizedDescription)")
        }
        
        if let data = data, !data.isEmpty {
            let dataString = data.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            logParts.append("{\(dataString)}")
        }
        
        let fullMessage = logParts.joined(separator: " ")
        logger.error("\(fullMessage, privacy: .public)")
        
        #if DEBUG
        print("[ERROR] \(fullMessage)")
        #endif
    }
    
    /**
     Logs a performance measurement.
     
     - Parameters:
       - location: Source location
       - operation: Name of the operation being measured
       - duration: Duration in seconds
       - data: Optional context data
     */
    static func performance(
        location: String,
        operation: String,
        duration: TimeInterval,
        data: [String: Any]? = nil
    ) {
        guard isEnabled else { return }
        
        let logger = Logger(subsystem: subsystem, category: "Performance")
        
        let durationMs = String(format: "%.2f", duration * 1000)
        var logParts: [String] = []
        logParts.append("[\(location)]")
        logParts.append("⏱ \(operation): \(durationMs)ms")
        
        if let data = data, !data.isEmpty {
            let dataString = data.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            logParts.append("{\(dataString)}")
        }
        
        let fullMessage = logParts.joined(separator: " ")
        logger.debug("\(fullMessage, privacy: .public)")
        
        #if DEBUG
        print("[PERF] \(fullMessage)")
        #endif
    }
}

// MARK: - Performance Measurement Helper

/**
 Helper class for measuring operation duration.
 
 Usage:
 ```
 let timer = PerformanceTimer()
 // ... perform operation ...
 timer.log(location: "MyView:loadData", operation: "Data fetch")
 ```
 */
final class PerformanceTimer {
    private let startTime: Date
    
    init() {
        self.startTime = Date()
    }
    
    /// Returns elapsed time in seconds
    var elapsed: TimeInterval {
        Date().timeIntervalSince(startTime)
    }
    
    /// Logs the elapsed time
    func log(location: String, operation: String, data: [String: Any]? = nil) {
        DebugLogger.performance(
            location: location,
            operation: operation,
            duration: elapsed,
            data: data
        )
    }
}
