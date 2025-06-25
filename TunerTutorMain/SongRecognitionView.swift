import SwiftUI
import ShazamKit // Import ShazamKit

// Make SongRecognitionView an ObservableObject to manage state and service
class SongRecognitionViewModel: ObservableObject {
    @Published var isSearching = false
    @Published var funFactText = "Tap the button to start identifying a song!"
    @Published var identifiedSongTitle: String?
    @Published var identifiedSongArtist: String?
    @Published var artworkURL: URL? // To store artwork URL
    @Published var displayResults = false // To show/hide results block
    @Published var guitarTabURL: URL?
    @Published var pianoTabURL: URL?
    @Published var showMicPermissionAlert = false // For microphone permission alert

    private var shazamService = ShazamRecognitionService()
    private var funFactTimer: Timer?

    // Placeholder for actual fun facts
    private let funFacts = [
        "The longest song ever recorded is 13 hours, 23 minutes, and 32 seconds long.",
        "The most expensive musical instrument ever sold was a Stradivarius violin, for $15.9 million.",
        "Beethoven was deaf when he composed some of his most famous works.",
        "The first music video aired on MTV was 'Video Killed the Radio Star' by The Buggles.",
        "A 'jiffy' is an actual unit of time: 1/100th of a second."
    ]

    init() {
        shazamService.delegate = self
    }

    func toggleSearch() {
        isSearching.toggle()
        if isSearching {
            startRecognition()
        } else {
            stopRecognition()
            // Reset UI elements if needed
            funFactText = "Tap the button to start identifying a song!"
            identifiedSongTitle = nil
            identifiedSongArtist = nil
            displayResults = false
        }
    }

    private func startRecognition() {
        shazamService.startRecognition()
        // Fun facts will start when didStartListening delegate is called
    }

    private func stopRecognition() {
        shazamService.stopRecognition()
        funFactTimer?.invalidate()
        funFactTimer = nil
    }

    private func startFunFactTimer() {
        funFactTimer?.invalidate() // Invalidate existing timer
        funFactText = funFacts.randomElement() ?? "Keep listening!" // Show one immediately
        funFactTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
            guard let self = self, self.isSearching else {
                self?.funFactTimer?.invalidate()
                return
            }
            self.funFactText = self.funFacts.randomElement() ?? "Identifying your song..."
        }
    }

    deinit {
        stopRecognition() // Ensure service is stopped when view model deinitializes
    }
}

// Conforming SongRecognitionViewModel to ShazamRecognitionServiceDelegate
extension SongRecognitionViewModel: ShazamRecognitionServiceDelegate {
    func didStartListening() {
        DispatchQueue.main.async {
            self.funFactText = "Listening..."
            self.startFunFactTimer()
            self.displayResults = false // Hide previous results
            self.identifiedSongTitle = nil
            self.identifiedSongArtist = nil
            self.artworkURL = nil // Reset artwork URL
            self.guitarTabURL = nil
            self.pianoTabURL = nil
        }
    }

    func didFindMatch(mediaItem: SHMatchedMediaItem) {
        DispatchQueue.main.async {
            self.isSearching = false // Stop animation
            self.shazamService.stopRecognition() // Stop service
            self.funFactTimer?.invalidate()

            self.identifiedSongTitle = mediaItem.title
            self.identifiedSongArtist = mediaItem.artist
            self.artworkURL = mediaItem.artworkURL // Store artwork URL
            self.funFactText = "Song Found!" // Or display song title directly
            self.displayResults = true

            // Construct search URLs for tabs
            self.constructTabSearchURLs(title: mediaItem.title, artist: mediaItem.artist)
        }
    }

    private func constructTabSearchURLs(title: String?, artist: String?) {
        guard let title = title, let artist = artist else { return }

        let query = "\(title) \(artist)"
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }

        // Ultimate Guitar search URL structure
        if let guitarURL = URL(string: "https://www.ultimate-guitar.com/search.php?search_type=title&value=\(encodedQuery)") {
            self.guitarTabURL = guitarURL
        }

        // For piano, we can use a similar query. Many sites might show piano versions or chords.
        // You might want to refine this if you find a better piano-specific search or site.
        // Example: searching for "chords" might be more relevant for piano sometimes.
        if let pianoURL = URL(string: "https://www.ultimate-guitar.com/search.php?search_type=title&value=\(encodedQuery)%20piano") {
            self.pianoTabURL = pianoURL
        }
    }
    func didNotFindMatch(error: Error?) {
        DispatchQueue.main.async {
            self.isSearching = false
            self.shazamService.stopRecognition()
            self.funFactTimer?.invalidate()
            if let error = error {
                self.funFactText = "No match found. Error: \(error.localizedDescription)"
            } else {
                self.funFactText = "Sorry, I couldn't identify that song. Try again!"
            }
            self.displayResults = false
        }
    }

    func didFailWithError(serviceError: Error) {
        DispatchQueue.main.async {
            self.isSearching = false
            self.shazamService.stopRecognition()
            self.funFactTimer?.invalidate()

            if let shazamError = serviceError as? ShazamRecognitionError, shazamError == .microphoneAccessDenied {
                self.funFactText = "Microphone access needed to identify songs."
                self.showMicPermissionAlert = true
            } else {
                self.funFactText = "Error: \(serviceError.localizedDescription)"
            }
            self.displayResults = false
        }
    }
}


struct SongRecognitionView: View {
    @StateObject private var viewModel = SongRecognitionViewModel()

    var body: some View {
        ZStack {
            Color.blue.ignoresSafeArea()

            VStack {
                Spacer()

                Text(viewModel.funFactText)
                    .font(.title3)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(minHeight: 100)

                Spacer()

                Button(action: {
                    viewModel.toggleSearch()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 200, height: 200)

                        Circle()
                            .fill(Color.white)
                            .frame(width: 180, height: 180)
                            .shadow(radius: 10)

                        Image(systemName: "shazam.logo.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.blue)
                            .rotationEffect(.degrees(viewModel.isSearching ? 360 : 0)) // Use viewModel.isSearching
                            .animation(viewModel.isSearching ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: viewModel.isSearching) // Use viewModel.isSearching
                    }
                }

                Spacer()
                Spacer()

                // Results Section
                if viewModel.displayResults {
                    VStack(spacing: 12) { // Added spacing
                        if let artworkURL = viewModel.artworkURL {
                            AsyncImage(url: artworkURL) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 120, height: 120) // Adjusted size
                                        .cornerRadius(8)
                                        .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                                } else if phase.error != nil {
                                    Image(systemName: "photo.fill") // More distinct error placeholder
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 100, height: 100) // Adjusted size
                                        .foregroundColor(.gray.opacity(0.5))
                                        .padding(10)
                                        .background(Circle().fill(Color.gray.opacity(0.2)))
                                } else {
                                    ProgressView() // Placeholder while loading
                                        .frame(width: 120, height: 120)
                                }
                            }
                            .padding(.bottom, 5)
                        }

                        Text(viewModel.identifiedSongTitle ?? "Song Title Not Available")
                            .font(.title2.weight(.semibold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Text(viewModel.identifiedSongArtist ?? "Artist Not Available")
                            .font(.headline.weight(.medium))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)

                        // Buttons for finding tabs
                        if viewModel.guitarTabURL != nil || viewModel.pianoTabURL != nil {
                            HStack(spacing: 15) {
                                if let url = viewModel.guitarTabURL {
                                    Link(destination: url) {
                                        Text("Guitar Tabs")
                                            .font(.caption.weight(.semibold))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(Color.blue.opacity(0.7))
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                    }
                                }
                                if let url = viewModel.pianoTabURL {
                                    Link(destination: url) {
                                        Text("Piano Tabs")
                                            .font(.caption.weight(.semibold))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(Color.green.opacity(0.7))
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                    }
                                }
                            }
                            .padding(.top, 10)
                        }
                    }
                    .padding(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(.ultraThinMaterial) // Using material for background
                            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                    )
                    .padding(.horizontal, 30) // Give some horizontal space to the results card
                    .transition(.opacity.combined(with: .scale(scale: 0.9))) // Nice transition
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.displayResults)

                } else {
                    // Placeholder to maintain layout space and allow smooth transition
                    // Make it effectively invisible and non-interactive
                    VStack(spacing: 12) {
                        Rectangle().fill(Color.clear).frame(width:120, height: 120)
                        Text("").font(.title2.weight(.semibold))
                        Text("").font(.headline.weight(.medium))
                    }
                    .padding(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
                    .frame(maxWidth: .infinity)
                    .background(Color.clear)
                    .padding(.horizontal, 30)
                }

                Spacer()
            }
        }
        .onDisappear {
            viewModel.stopRecognition()
        }
        .alert("Microphone Access Required", isPresented: $viewModel.showMicPermissionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Settings") {
                // Open app settings
                if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("This app needs access to your microphone to identify songs. Please enable microphone access in Settings.")
        }
    }
}


struct SongRecognitionView_Previews: PreviewProvider {
    static var previews: some View {
        SongRecognitionView()
    }
}
