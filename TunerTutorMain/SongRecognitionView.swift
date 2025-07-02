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

    @Published var guitarTabSaved: Bool = false
    @Published var pianoTabSaved: Bool = false
    @Published var tabSavingError: String? = nil
    @Published var historySavingError: String? = nil


    // AppState will be injected via init
    private var appState: AppState

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

    init(appState: AppState) {
        self.appState = appState
        // shazamService must be initialized before its delegate is set.
        // If shazamService itself doesn't depend on appState for its own init, this is fine.
        // If it did, appState would need to be passed to shazamService's init too.
        self.shazamService = ShazamRecognitionService() // Ensure it's initialized
        self.shazamService.delegate = self
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
            self.guitarTabSaved = false // Reset saved status
            self.pianoTabSaved = false  // Reset saved status
            self.tabSavingError = nil   // Clear any previous errors
            self.historySavingError = nil // Clear history error
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
            self.guitarTabSaved = false // Reset for new song
            self.pianoTabSaved = false
            self.tabSavingError = nil
            self.historySavingError = nil // Reset history error for new match

            // Construct search URLs for tabs
            self.constructTabSearchURLs(title: mediaItem.title, artist: mediaItem.artist)
            // After constructing URLs, check if they are already saved
            self.checkIfTabsAreSaved()


            // Save to history
            if let profileId = self.appState.activeLocalProfile?.id {
                let historyRecord = RecognitionHistoryRecord(
                    userProfileId: profileId,
                    songTitle: mediaItem.title ?? "Unknown Title",
                    artist: mediaItem.artist,
                    artworkURL: mediaItem.artworkURL?.absoluteString,
                    shazamTrackId: mediaItem.shazamID // Assuming shazamID is available on SHMatchedMediaItem
                    // If shazamID is not directly available, one might need to check specific properties or use another identifier
                )
                do {
                    _ = try LocalDatabaseService.shared.saveRecognitionHistory(historyRecord)
                    self.historySavingError = nil // Clear error on success
                    print("Successfully saved to recognition history.")
                } catch {
                    print("Failed to save recognition history: \(error.localizedDescription)")
                    self.historySavingError = "Couldn't save to history. Please try again later."
                }
            } else {
                print("No active local profile ID found, cannot save to history.")
                self.historySavingError = "No active profile to save history." // Should ideally not happen if user is in this view
            }
        }
    }

    private func constructTabSearchURLs(title: String?, artist: String?) {
        guard let title = title, let artist = artist else { return }
        let query = "\(title) \(artist)"
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        if let guitarURL = URL(string: "https://www.ultimate-guitar.com/search.php?search_type=title&value=\(encodedQuery)") {
            self.guitarTabURL = guitarURL
        }
        if let pianoURL = URL(string: "https://www.ultimate-guitar.com/search.php?search_type=title&value=\(encodedQuery)%20piano") {
            self.pianoTabURL = pianoURL
        }
    }

    func checkIfTabsAreSaved() {
        guard let profileId = appState.activeLocalProfile?.id else { return }
        self.tabSavingError = nil

        if let url = guitarTabURL {
            do {
                if let _ = try LocalDatabaseService.shared.getSavedTab(forUserProfileId: profileId, tabURL: url.absoluteString) {
                    self.guitarTabSaved = true
                } else {
                    self.guitarTabSaved = false
                }
            } catch {
                print("Error checking saved guitar tab: \(error.localizedDescription)")
                // Don't necessarily set guitarTabSaved to false, as it might be a temp DB error
            }
        }
        if let url = pianoTabURL {
            do {
                if let _ = try LocalDatabaseService.shared.getSavedTab(forUserProfileId: profileId, tabURL: url.absoluteString) {
                    self.pianoTabSaved = true
                } else {
                    self.pianoTabSaved = false
                }
            } catch {
                print("Error checking saved piano tab: \(error.localizedDescription)")
            }
        }
    }

    func saveGuitarTab() {
        guard let profileId = appState.activeLocalProfile?.id,
              let url = guitarTabURL,
              let title = identifiedSongTitle else {
            self.tabSavingError = "Missing information to save guitar tab."
            return
        }
        self.tabSavingError = nil

        let savedTab = SavedTabRecord(userProfileId: profileId,
                                      songTitle: title,
                                      artist: identifiedSongArtist,
                                      tabURL: url.absoluteString,
                                      tabType: "guitar")
        do {
            _ = try LocalDatabaseService.shared.saveSavedTab(savedTab)
            self.guitarTabSaved = true
        } catch {
            print("Error saving guitar tab: \(error.localizedDescription)")
            self.tabSavingError = "Failed to save guitar tab."
            self.guitarTabSaved = false // Ensure it's marked as not saved if error occurs
        }
    }

    func savePianoTab() {
        guard let profileId = appState.activeLocalProfile?.id,
              let url = pianoTabURL,
              let title = identifiedSongTitle else {
            self.tabSavingError = "Missing information to save piano tab."
            return
        }
        self.tabSavingError = nil

        let savedTab = SavedTabRecord(userProfileId: profileId,
                                      songTitle: title,
                                      artist: identifiedSongArtist,
                                      tabURL: url.absoluteString,
                                      tabType: "piano")
        do {
            _ = try LocalDatabaseService.shared.saveSavedTab(savedTab)
            self.pianoTabSaved = true
        } catch {
            print("Error saving piano tab: \(error.localizedDescription)")
            self.tabSavingError = "Failed to save piano tab."
            self.pianoTabSaved = false // Ensure it's marked as not saved if error occurs
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
    // ViewModel is now passed in, owned by the parent (MainView) via @StateObject
    @ObservedObject var viewModel: SongRecognitionViewModel
    // We still need AppState here if the View itself needs to react to it,
    // or for the preview. If only the VM needs it, this could be removed.
    // For the .alert, it's cleaner if the viewModel handles the showMicPermissionAlert state.
    // The viewModel already has @Published showMicPermissionAlert.

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
                        VStack(spacing: 8) { // Use VStack for multiple rows of buttons
                            if let url = viewModel.guitarTabURL {
                                HStack {
                                    Link(destination: url) {
                                        Text("Guitar Tabs")
                                            .font(.caption.weight(.semibold))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .frame(maxWidth: .infinity)
                                            .background(Color.blue.opacity(0.7))
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                    }
                                    Button(action: { viewModel.saveGuitarTab() }) {
                                        Image(systemName: viewModel.guitarTabSaved ? "bookmark.fill" : "bookmark")
                                            .foregroundColor(viewModel.guitarTabSaved ? .yellow : .white)
                                    }
                                    .padding(.leading, 5)
                                }
                            }
                            if let url = viewModel.pianoTabURL {
                                HStack {
                                    Link(destination: url) {
                                        Text("Piano Tabs")
                                            .font(.caption.weight(.semibold))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .frame(maxWidth: .infinity)
                                            .background(Color.green.opacity(0.7))
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                    }
                                    Button(action: { viewModel.savePianoTab() }) {
                                        Image(systemName: viewModel.pianoTabSaved ? "bookmark.fill" : "bookmark")
                                            .foregroundColor(viewModel.pianoTabSaved ? .yellow : .white)
                                    }
                                    .padding(.leading, 5)
                                }
                            }
                            if let tabError = viewModel.tabSavingError {
                                Text(tabError)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.top, 5)
                            }
                            if let historyError = viewModel.historySavingError {
                                Text(historyError)
                                    .font(.caption)
                                    .foregroundColor(.orange) // Different color to distinguish
                                    .padding(.top, 5)
                            }
                        }
                        .padding(.top, 10)
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
        // For the preview to work, we need to provide a mock AppState
        // and initialize SongRecognitionViewModel with it.
        let mockAppState = AppState()
        // You might want to set a mock active profile in mockAppState for different preview scenarios
        // e.g., mockAppState.setActiveProfile(UserProfileRecord(name: "Preview User"))

        SongRecognitionView(viewModel: SongRecognitionViewModel(appState: mockAppState))
            .environmentObject(mockAppState) // Also provide it to the view's environment if needed by subviews directly
    }
}
