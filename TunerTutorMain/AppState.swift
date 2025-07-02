import SwiftUI
import Combine

import SwiftUI
import Combine

// AppState will now use UserProfileRecord from LocalDatabaseService
// No need for a separate LocalProfile struct here.

class AppState: ObservableObject {
    @Published var isLocalProfileActive: Bool = false
    @Published var activeLocalProfile: UserProfileRecord? = nil // Use UserProfileRecord
    
    private let activeProfileIDKey = "activeLocalProfileID_v1" // Key for UserDefaults, stores only the ID

    init() {
        loadActiveProfileFromDB()
    }
    
    // Called when a profile is created or selected
    func setActiveProfile(_ profile: UserProfileRecord) {
        self.activeLocalProfile = profile
        self.isLocalProfileActive = true
        // Save only the ID to UserDefaults
        UserDefaults.standard.set(profile.id, forKey: activeProfileIDKey)
        print("AppState: Active local profile set and ID saved to UserDefaults - ID: \(profile.id), Name: \(profile.name)")
    }

    // Called to "log out" of the local profile
    func clearActiveProfile() { // Renamed for clarity
        self.activeLocalProfile = nil
        self.isLocalProfileActive = false
        UserDefaults.standard.removeObject(forKey: activeProfileIDKey)
        print("AppState: Active local profile cleared from AppState and UserDefaults.")
    }

    // Load active profile ID from UserDefaults and then fetch from DB
    private func loadActiveProfileFromDB() {
        guard let activeID = UserDefaults.standard.string(forKey: activeProfileIDKey) else {
            print("AppState: No active profile ID found in UserDefaults.")
            self.isLocalProfileActive = false
            self.activeLocalProfile = nil
            return
        }

        do {
            if let profile = try LocalDatabaseService.shared.getUserProfile(id: activeID) {
                self.activeLocalProfile = profile
                self.isLocalProfileActive = true
                print("AppState: Loaded active local profile from DB - ID: \(profile.id), Name: \(profile.name)")
            } else {
                print("AppState: Active profile ID \(activeID) found in UserDefaults, but profile not found in DB. Clearing.")
                clearActiveProfile() // Profile ID exists but profile doesn't, so clear.
            }
        } catch {
            print("AppState: Error loading profile from DB: \(error.localizedDescription)")
            // Potentially corrupted DB or other issue, treat as no active profile
            clearActiveProfile()
        }
    }
    
    // Method to be called if the profile name is updated in the database elsewhere
    // and AppState needs to reflect that change.
    func refreshActiveProfile() {
        guard let currentId = activeLocalProfile?.id else { return }
        do {
            if let refreshedProfile = try LocalDatabaseService.shared.getUserProfile(id: currentId) {
                self.activeLocalProfile = refreshedProfile
                print("AppState: Refreshed active profile from DB.")
            } else {
                // Profile mysteriously deleted from DB while active
                print("AppState: Failed to refresh active profile, it might have been deleted. Clearing.")
                clearActiveProfile()
            }
        } catch {
            print("AppState: Error refreshing active profile: \(error.localizedDescription)")
        }
    }
}