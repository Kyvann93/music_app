import GRDB
import Foundation // For UUID, Date, JSONEncoder/Decoder

// MARK: - Database Records (Model Structs)

struct UserProfileRecord: Identifiable, Codable, PersistableRecord, FetchableRecord {
    var id: String // UUID().uuidString
    var name: String
    var creationDate: Date
    var preferencesJson: String?

    // GRDB Table mapping
    static let databaseTableName = "userProfile"

    // Default initializer
    init(id: String = UUID().uuidString, name: String, creationDate: Date = Date(), preferencesJson: String? = nil) {
        self.id = id
        self.name = name
        self.creationDate = creationDate
        self.preferencesJson = preferencesJson
    }

    // TODO: Add methods to get/set specific preferences from preferencesJson
}

struct RecognitionHistoryRecord: Identifiable, PersistableRecord, FetchableRecord {
    var id: Int64? // Autoincremented by SQLite
    var userProfileId: String
    var songTitle: String
    var artist: String?
    var artworkURL: String?
    var recognizedDate: Date
    var shazamTrackId: String? // Optional: if available from ShazamKit
    var notes: String?

    static let databaseTableName = "recognitionHistory"

    // Initializer
    init(id: Int64? = nil, userProfileId: String, songTitle: String, artist: String? = nil,
         artworkURL: String? = nil, recognizedDate: Date = Date(),
         shazamTrackId: String? = nil, notes: String? = nil) {
        self.id = id
        self.userProfileId = userProfileId
        self.songTitle = songTitle
        self.artist = artist
        self.artworkURL = artworkURL
        self.recognizedDate = recognizedDate
        self.shazamTrackId = shazamTrackId
        self.notes = notes
    }
}

struct SavedTabRecord: Identifiable, PersistableRecord, FetchableRecord {
    var id: Int64? // Autoincremented
    var userProfileId: String
    var songTitle: String
    var artist: String?
    var tabURL: String
    var tabType: String // "guitar", "piano", "chords"
    var savedDate: Date
    var notes: String?

    static let databaseTableName = "savedTab"

    // Initializer
    init(id: Int64? = nil, userProfileId: String, songTitle: String, artist: String? = nil,
         tabURL: String, tabType: String, savedDate: Date = Date(), notes: String? = nil) {
        self.id = id
        self.userProfileId = userProfileId
        self.songTitle = songTitle
        self.artist = artist
        self.tabURL = tabURL
        self.tabType = tabType
        self.savedDate = savedDate
        self.notes = notes
    }
}


// MARK: - LocalDatabaseService

class LocalDatabaseService {
    // Shared instance for singleton pattern
    static let shared = LocalDatabaseService()

    private var dbQueue: DatabaseQueue

    private init() {
        do {
            let fileManager = FileManager.default
            let dbPath = try fileManager
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("tunerTutor.sqlite")
                .path

            print("Database path: \(dbPath)")
            dbQueue = try DatabaseQueue(path: dbPath)
            try setupDatabaseSchema(dbQueue)
        } catch {
            // TODO: More robust error handling for production
            fatalError("Failed to initialize database: \(error)")
        }
    }

    private func setupDatabaseSchema(_ db: DatabaseQueue) throws {
        try db.write { database in
            // UserProfile Table
            try database.create(table: UserProfileRecord.databaseTableName, ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("name", .text).notNull()
                t.column("creationDate", .datetime).notNull().defaults(to: Date())
                t.column("preferencesJson", .text)
            }

            // RecognitionHistory Table
            try database.create(table: RecognitionHistoryRecord.databaseTableName, ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("userProfileId", .text).notNull().indexed()
                    .references(UserProfileRecord.databaseTableName, onDelete: .cascade)
                t.column("songTitle", .text).notNull()
                t.column("artist", .text)
                t.column("artworkURL", .text)
                t.column("recognizedDate", .datetime).notNull().defaults(to: Date())
                t.column("shazamTrackId", .text)
                t.column("notes", .text)
            }

            // SavedTab Table
            try database.create(table: SavedTabRecord.databaseTableName, ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("userProfileId", .text).notNull().indexed()
                    .references(UserProfileRecord.databaseTableName, onDelete: .cascade)
                t.column("songTitle", .text).notNull()
                t.column("artist", .text)
                t.column("tabURL", .text).notNull()
                t.column("tabType", .text).notNull() // "guitar", "piano"
                t.column("savedDate", .datetime).notNull().defaults(to: Date())
                t.column("notes", .text)
            }

            print("Database schema setup complete.")
        }
    }

    // MARK: - User Profile Methods (Example)

    func saveUserProfile(_ profile: UserProfileRecord) throws {
        try dbQueue.write { db in
            try profile.save(db)
        }
        print("Saved profile: \(profile.name)")
    }

    func getUserProfile(id: String) throws -> UserProfileRecord? {
        let profile: UserProfileRecord? = try dbQueue.read { db in
            try UserProfileRecord.filter(Column("id") == id).fetchOne(db)
        }
        return profile
    }

    func getAllUserProfiles() throws -> [UserProfileRecord] {
        let profiles: [UserProfileRecord] = try dbQueue.read { db in
            try UserProfileRecord.fetchAll(db)
        }
        return profiles
    }

    // MARK: - Recognition History Methods

    func saveRecognitionHistory(_ historyEntry: RecognitionHistoryRecord) throws -> RecognitionHistoryRecord {
        var entryToSave = historyEntry
        try dbQueue.write { db in
            try entryToSave.save(db) // save() handles insert or update and sets the ID if it's an insert.
        }
        print("Saved recognition history for song: \(entryToSave.songTitle), ID: \(entryToSave.id ?? -1)")
        return entryToSave
    }

    func getRecognitionHistory(forUserProfileId profileId: String) throws -> [RecognitionHistoryRecord] {
        let history: [RecognitionHistoryRecord] = try dbQueue.read { db in
            try RecognitionHistoryRecord
                .filter(Column("userProfileId") == profileId)
                .order(Column("recognizedDate").desc) // Show most recent first
                .fetchAll(db)
        }
        return history
    }

    func deleteRecognitionHistory(id: Int64) throws {
        _ = try dbQueue.write { db in
            try RecognitionHistoryRecord.deleteOne(db, key: id)
        }
        print("Deleted recognition history with ID: \(id)")
    }

    func clearRecognitionHistory(forUserProfileId profileId: String) throws {
        _ = try dbQueue.write { db in
            try RecognitionHistoryRecord
                .filter(Column("userProfileId") == profileId)
                .deleteAll(db)
        }
        print("Cleared all recognition history for profile ID: \(profileId)")
    }

    // MARK: - Saved Tab Methods

    func saveSavedTab(_ tabEntry: SavedTabRecord) throws -> SavedTabRecord {
        var entryToSave = tabEntry
        try dbQueue.write { db in
            try entryToSave.save(db)
        }
        print("Saved tab: \(entryToSave.songTitle) - \(entryToSave.tabType), ID: \(entryToSave.id ?? -1)")
        return entryToSave
    }

    func getSavedTabs(forUserProfileId profileId: String) throws -> [SavedTabRecord] {
        let tabs: [SavedTabRecord] = try dbQueue.read { db in
            try SavedTabRecord
                .filter(Column("userProfileId") == profileId)
                .order(Column("savedDate").desc) // Show most recent first
                .fetchAll(db)
        }
        return tabs
    }

    func getSavedTab(forUserProfileId profileId: String, tabURL: String) throws -> SavedTabRecord? {
        let tab: SavedTabRecord? = try dbQueue.read { db in
            try SavedTabRecord
                .filter(Column("userProfileId") == profileId && Column("tabURL") == tabURL)
                .fetchOne(db)
        }
        return tab
    }

    func deleteSavedTab(id: Int64) throws {
        _ = try dbQueue.write { db in
            try SavedTabRecord.deleteOne(db, key: id)
        }
        print("Deleted saved tab with ID: \(id)")
    }

    func clearSavedTabs(forUserProfileId profileId: String) throws {
        _ = try dbQueue.write { db in
            try SavedTabRecord
                .filter(Column("userProfileId") == profileId)
                .deleteAll(db)
        }
        print("Cleared all saved tabs for profile ID: \(profileId)")
    }

    // MARK: - User Preferences Methods

    // Example: Define a Codable struct for preferences
    struct UserPreferences: Codable {
        var defaultTabType: String = "guitar" // e.g., "guitar", "piano"
        var someOtherPreference: Bool = false

        // Add more preferences as needed
    }

    func getUserPreferences(forUserProfileId profileId: String) throws -> UserPreferences {
        guard let profile = try getUserProfile(id: profileId) else {
            throw LocalDatabaseError.profileNotFound
        }

        if let prefsJson = profile.preferencesJson, let data = prefsJson.data(using: .utf8) {
            do {
                let preferences = try JSONDecoder().decode(UserPreferences.self, from: data)
                return preferences
            } catch {
                print("Error decoding preferences JSON for profile \(profileId): \(error). Returning default preferences.")
                // Fallback to default if JSON is corrupted or unparsable
            }
        }
        // Return default preferences if none are stored or if there was an error
        return UserPreferences()
    }

    func updateUserPreferences(forUserProfileId profileId: String, preferences: UserPreferences) throws {
        guard var profile = try getUserProfile(id: profileId) else {
            throw LocalDatabaseError.profileNotFound
        }

        do {
            let data = try JSONEncoder().encode(preferences)
            profile.preferencesJson = String(data: data, encoding: .utf8)
            try saveUserProfile(profile) // This will update the existing profile
            print("Updated preferences for profile ID: \(profileId)")
        } catch {
            print("Error encoding preferences for profile \(profileId): \(error).")
            throw LocalDatabaseError.preferencesUpdateFailed(error)
        }
    }
}

// MARK: - Custom Database Errors
enum LocalDatabaseError: Error, LocalizedError {
    case profileNotFound
    case preferencesUpdateFailed(Error)
    // Add other specific database errors as needed

    var errorDescription: String? {
        switch self {
        case .profileNotFound:
            return "The specified user profile was not found."
        case .preferencesUpdateFailed(let underlyingError):
            return "Failed to update preferences: \(underlyingError.localizedDescription)"
        }
    }
}
