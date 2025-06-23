import SwiftUI

@main
struct TuneTutorApp: App {
    // Using @StateObject for app state management to ensure these objects
    // live for the entire lifetime of the app
    @StateObject private var appState = AppState()
    @StateObject private var authService = AuthenticationService()
    @StateObject private var musicService = MusicService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(authService)
                .environmentObject(musicService)
        }
    }
}