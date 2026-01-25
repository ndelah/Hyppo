/**
 ClipboardDetector service for Quick Capture HUD.
 
 Monitors the system clipboard and auto-detects URLs vs. text snippets.
 Provides URL validation and optional page title fetching.
 */

import Foundation
import AppKit
import Combine

// MARK: - Clipboard Content Type

/**
 Represents the detected type of clipboard content.
 */
enum ClipboardContentType: Equatable {
    case url(URL)
    case text(String)
    case mixed(url: URL, text: String)
    case empty
    
    /// Returns true if the content includes a URL
    var hasURL: Bool {
        switch self {
        case .url, .mixed:
            return true
        default:
            return false
        }
    }
    
    /// Returns the URL if present
    var extractedURL: URL? {
        switch self {
        case .url(let url):
            return url
        case .mixed(let url, _):
            return url
        default:
            return nil
        }
    }
    
    /// Returns the text content if present
    var extractedText: String? {
        switch self {
        case .text(let text):
            return text
        case .mixed(_, let text):
            return text
        default:
            return nil
        }
    }
}

// MARK: - Clipboard Detector

/**
 Service for detecting and processing clipboard content.
 
 Provides functionality to:
 - Read current clipboard content
 - Detect URLs using regex patterns
 - Fetch page titles asynchronously (non-blocking)
 - Truncate snippets for copyright compliance
 */
final class ClipboardDetector: ObservableObject {
    // MARK: - Published Properties
    
    /// The detected content type from the clipboard
    @Published private(set) var detectedContent: ClipboardContentType = .empty
    
    /// The raw clipboard string
    @Published private(set) var rawContent: String = ""
    
    /// Fetched page title (async)
    @Published private(set) var fetchedTitle: String?
    
    /// Whether title fetch is in progress
    @Published private(set) var isFetchingTitle: Bool = false
    
    // MARK: - Private Properties
    
    /// Last known clipboard change count
    private var lastChangeCount: Int = 0
    
    /// URL detection regex pattern
    private static let urlPattern = #"https?://[^\s<>\[\]{}|\\^`\"\']+"#
    
    /// Maximum snippet length for copyright compliance
    static let maxSnippetLength = 500
    
    // MARK: - Initialization
    
    init() {
        // Initialize with current clipboard state
        refreshClipboard()
    }
    
    // MARK: - Public Methods
    
    /**
     Refreshes the clipboard content detection.
     
     Reads the current clipboard and determines if it contains
     a URL, text snippet, or mixed content.
     */
    func refreshClipboard() {
        let pasteboard = NSPasteboard.general
        
        // Check if clipboard has changed
        let currentChangeCount = pasteboard.changeCount
        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount
        
        // Reset state
        fetchedTitle = nil
        isFetchingTitle = false
        
        // Get clipboard string
        guard let clipboardString = pasteboard.string(forType: .string),
              !clipboardString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            rawContent = ""
            detectedContent = .empty
            return
        }
        
        rawContent = clipboardString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Detect content type
        detectedContent = detectContentType(from: rawContent)
        
        // Auto-fetch title if URL detected
        if let url = detectedContent.extractedURL {
            fetchTitle(for: url)
        }
    }
    
    /**
     Forces a clipboard refresh regardless of change count.
     
     Useful when the HUD is first shown to ensure current state.
     */
    func forceRefresh() {
        lastChangeCount = -1
        refreshClipboard()
    }
    
    /**
     Validates whether a string is a valid URL.
     
     - Parameter string: The string to validate
     - Returns: The URL if valid, nil otherwise
     */
    static func validateURL(_ string: String) -> URL? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed),
              let scheme = url.scheme,
              ["http", "https"].contains(scheme.lowercased()),
              url.host != nil else {
            return nil
        }
        return url
    }
    
    /**
     Extracts the domain from a URL.
     
     - Parameter url: The URL to extract from
     - Returns: The domain string (e.g., "example.com")
     */
    static func extractDomain(from url: URL) -> String? {
        return url.host
    }
    
    /**
     Truncates text to the maximum allowed snippet length.
     
     - Parameter text: The text to truncate
     - Returns: Truncated text with ellipsis if needed
     */
    static func truncateSnippet(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= maxSnippetLength {
            return trimmed
        }
        return String(trimmed.prefix(maxSnippetLength)) + "..."
    }
    
    // MARK: - Private Methods
    
    /**
     Detects the content type from a string.
     
     - Parameter content: The string to analyze
     - Returns: The detected content type
     */
    private func detectContentType(from content: String) -> ClipboardContentType {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            return .empty
        }
        
        // Check if the entire content is a URL
        if let url = ClipboardDetector.validateURL(trimmed) {
            return .url(url)
        }
        
        // Try to extract a URL from the content
        if let extractedURL = extractURL(from: trimmed) {
            // Remove the URL from the text to get the remaining content
            let textWithoutURL = trimmed
                .replacingOccurrences(of: extractedURL.absoluteString, with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            if textWithoutURL.isEmpty {
                return .url(extractedURL)
            } else {
                return .mixed(url: extractedURL, text: textWithoutURL)
            }
        }
        
        // Plain text content
        return .text(trimmed)
    }
    
    /**
     Extracts the first URL from a string using regex.
     
     - Parameter text: The text to search
     - Returns: The first URL found, or nil
     */
    private func extractURL(from text: String) -> URL? {
        guard let regex = try? NSRegularExpression(
            pattern: Self.urlPattern,
            options: [.caseInsensitive]
        ) else {
            return nil
        }
        
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              let matchRange = Range(match.range, in: text) else {
            return nil
        }
        
        let urlString = String(text[matchRange])
        return ClipboardDetector.validateURL(urlString)
    }
    
    /**
     Fetches the page title for a URL asynchronously.
     
     - Parameter url: The URL to fetch the title for
     */
    private func fetchTitle(for url: URL) {
        isFetchingTitle = true
        
        Task { @MainActor in
            defer { isFetchingTitle = false }
            
            do {
                let title = try await fetchPageTitle(url: url)
                // Only update if still relevant (clipboard hasn't changed)
                if self.detectedContent.extractedURL == url {
                    self.fetchedTitle = title
                }
            } catch {
                // Silently fail - use URL as fallback
                DebugLogger.warning(
                    location: "ClipboardDetector:fetchTitle",
                    message: "Failed to fetch page title",
                    data: ["url": url.absoluteString, "error": error.localizedDescription]
                )
            }
        }
    }
    
    /**
     Fetches the HTML page title from a URL.
     
     - Parameter url: The URL to fetch
     - Returns: The page title if found
     - Throws: Network or parsing errors
     */
    private func fetchPageTitle(url: URL) async throws -> String? {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5
        request.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)",
            forHTTPHeaderField: "User-Agent"
        )
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            return nil
        }
        
        // Parse HTML for title tag
        guard let html = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return extractHTMLTitle(from: html)
    }
    
    /**
     Extracts the title from HTML content.
     
     - Parameter html: The HTML string to parse
     - Returns: The title text if found
     */
    private func extractHTMLTitle(from html: String) -> String? {
        // Simple regex-based title extraction
        let pattern = #"<title[^>]*>([^<]+)</title>"#
        
        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ) else {
            return nil
        }
        
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        
        guard let match = regex.firstMatch(in: html, options: [], range: range),
              match.numberOfRanges > 1,
              let titleRange = Range(match.range(at: 1), in: html) else {
            return nil
        }
        
        let title = String(html[titleRange])
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
        
        return title.isEmpty ? nil : title
    }
}

