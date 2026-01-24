/**
 SwiftDataStoreReset provides safe helpers for locating and deleting the on-disk SwiftData store.
 
 This project intentionally **does not attempt to migrate** when the store fails to load
 (e.g., schema changes or partially-applied migrations). Instead, we delete the local store
 and recreate it so the app can start fresh.
 */
 
import Foundation

/// Helpers for resetting the SwiftData SQLite-backed store on load issues.
enum SwiftDataStoreReset {
    // MARK: - Store Location
    
    /**
     Returns the app-scoped Application Support URL for the given SwiftData store name, ensuring
     the directory exists.
     
     SwiftData’s default SQLite-backed store filename convention is `<storeName>.store`.
     
     - Parameter storeName: Store name (e.g., "default").
     - Returns: A fully-qualified file URL within Application Support.
     - Throws: Any file system error encountered while creating the directory.
     */
    static func defaultStoreURL(storeName: String) throws -> URL {
        let fileManager = FileManager.default
        let appSupportDir = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        
        return appSupportDir.appendingPathComponent("\(storeName).store", isDirectory: false)
    }
    
    // MARK: - Deletion
    
    /**
     Deletes the main SQLite store file as well as its WAL and SHM sidecar files, if present.
     
     - Parameter storeURL: URL to the main store file (e.g., ".../default.store").
     - Throws: Any file system error encountered while deleting existing files.
     */
    static func deleteStoreFiles(storeURL: URL) throws {
        let fileManager = FileManager.default
        
        let basePath = storeURL.path
        let candidatePaths = [
            basePath,
            "\(basePath)-wal",
            "\(basePath)-shm"
        ]
        
        var deletionErrors: [Error] = []
        
        for path in candidatePaths {
            let url = URL(fileURLWithPath: path)
            guard fileManager.fileExists(atPath: url.path) else { continue }
            
            do {
                try fileManager.removeItem(at: url)
            } catch {
                deletionErrors.append(error)
            }
        }
        
        if let firstError = deletionErrors.first {
            throw firstError
        }
    }
}


