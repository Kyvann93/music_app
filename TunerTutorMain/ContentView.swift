import SwiftUI
import Foundation

// Import local modules if they're in separate modules
// If these types are defined in the same module but different files, 
// you don't need to import them specifically

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var authService: AuthenticationService
    @EnvironmentObject private var musicService: MusicService
    
    var body: some View {
        if appState.isLoggedIn {
            MainView()
        } else {
            LoginView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppState())
            .environmentObject(AuthenticationService())
            .environmentObject(MusicService())
    }
}