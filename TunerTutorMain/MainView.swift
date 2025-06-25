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

            SongRecognitionView()
                // .environmentObject(musicService) // If needed later for API calls
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