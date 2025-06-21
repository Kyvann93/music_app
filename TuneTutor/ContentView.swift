import SwiftUI
import ShazamKit

struct ContentView: View {
    @StateObject private var musicRecognitionService = MusicRecognitionService()
    @State private var isListening = false

    var body: some View {
        NavigationView {
            VStack {
                Text("TuneTutor")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 50)

                Spacer()

                if let song = musicRecognitionService.matchedSong {
                    VStack(spacing: 10) {
                        Text(song.title ?? "Unknown Title")
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        Text(song.artist ?? "Unknown Artist")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        NavigationLink(destination: TabsView(tabs: musicRecognitionService.fetchedTabs)) {
                            Text("View Tabs")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.top)
                    }
                } else if musicRecognitionService.error != nil {
                    Text("Could not recognize the song. Please try again.")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                } else {
                    Button(action: {
                        if self.isListening {
                            self.musicRecognitionService.stopListening()
                            self.isListening = false
                        } else {
                            self.musicRecognitionService.matchedSong = nil
                            self.musicRecognitionService.error = nil
                            self.musicRecognitionService.startListening()
                            self.isListening = true
                        }
                    }) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 100))
                            .foregroundColor(.white)
                            .padding(40)
                            .background(isListening ? Color.red : Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 10)
                    }

                    Text(isListening ? "Listening..." : "Tap to find a song")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .padding(.top, 20)
                }

                Spacer()
            }
            .padding()
            .onReceive(musicRecognitionService.$matchedSong) { matchedSong in
                if matchedSong != nil {
                    handleResult()
                }
            }
            .onReceive(musicRecognitionService.$error) { error in
                if error != nil {
                    handleResult()
                }
            }
            .navigationBarHidden(true)
        }
    }

    private func handleResult() {
        if isListening {
            musicRecognitionService.stopListening()
            isListening = false
        }
        
        // After 5 seconds, reset to the initial state
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            musicRecognitionService.matchedSong = nil
            musicRecognitionService.error = nil
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}