import SwiftUI

struct MainView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var musicService: MusicService
    
    var body: some View {
        TabView {
            HistoryView()
                .environmentObject(musicService)
                .tabItem {
                    Label("History", systemImage: "clock")
                }
            
            SuggestionsView()
                .environmentObject(musicService)
                .tabItem {
                    Label("Suggestions", systemImage: "music.note.list")
                }

            // Create the ViewModel here, injecting appState, and pass it to SongRecognitionView
            SongRecognitionView(viewModel: SongRecognitionViewModel(appState: appState))
                .environmentObject(appState) // Pass appState for view's own environment if direct access is needed
                // .environmentObject(musicService) // Pass musicService if needed by SongRecognitionView or its VM
                .tabItem {
                    Label("Recognize", systemImage: "shazam.logo.fill")
                }
            
            ProfileView()
                .environmentObject(appState)
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
        .accentColor(.blue)
    }
}

#Preview {
    MainView()
        .environmentObject(AppState())
        .environmentObject(MusicService())
}