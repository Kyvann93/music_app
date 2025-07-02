import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var appState: AppState // Access AppState for active profile
    @State private var historyRecords: [RecognitionHistoryRecord] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading History...")
                } else if let errorMsg = errorMessage {
                    VStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text("Error Loading History")
                            .font(.title2)
                        Text(errorMsg)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding()
                        Button("Retry") {
                            fetchHistory()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if historyRecords.isEmpty {
                    VStack {
                        Image(systemName: "music.mic.circle") // Changed icon
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                            .padding()
                        Text("No Recognition History")
                            .font(.title2)
                        Text("Songs you identify will appear here.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .padding()
                } else {
                    List {
                        ForEach(historyRecords) { record in // RecognitionHistoryRecord is Identifiable
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(record.songTitle)
                                        .font(.headline)
                                    if let artist = record.artist, !artist.isEmpty {
                                        Text(artist)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    Text("Recognized: \(record.recognizedDate, formatter: Self.dateFormatter)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                // Optionally display album art if URL is present and we want to load it
                                if let artworkUrlString = record.artworkURL, let url = URL(string: artworkUrlString) {
                                   AsyncImage(url: url) { phase in
                                       if let image = phase.image {
                                           image.resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 44, height: 44)
                                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                       } else if phase.error != nil {
                                           Image(systemName: "photo")
                                               .frame(width: 44, height: 44)
                                       } else {
                                           ProgressView()
                                               .frame(width: 44, height: 44)
                                       }
                                   }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: deleteHistoryItems)
                    }
                }
            }
            .navigationTitle("Recognition History")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !historyRecords.isEmpty { EditButton() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: fetchHistory) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            }
            .onAppear(perform: fetchHistory)
            .onChange(of: appState.activeLocalProfile?.id) { _ in // Refresh if profile changes
                fetchHistory()
            }
        }
    }

    private func fetchHistory() {
        guard let profileId = appState.activeLocalProfile?.id else {
            historyRecords = []
            errorMessage = "No active profile. Please create or select a profile."
            isLoading = false
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            historyRecords = try LocalDatabaseService.shared.getRecognitionHistory(forUserProfileId: profileId)
        } catch {
            print("Error fetching history: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            historyRecords = [] // Clear on error
        }
        isLoading = false
    }

    private func deleteHistoryItems(offsets: IndexSet) {
        guard let profileId = appState.activeLocalProfile?.id else { return }

        let idsToDelete = offsets.map { historyRecords[$0].id }.compactMap { $0 }
        if idsToDelete.isEmpty { return }

        do {
            for id in idsToDelete {
                try LocalDatabaseService.shared.deleteRecognitionHistory(id: id)
            }
            // Refresh the list from the database after deletion
            fetchHistory()
        } catch {
            print("Error deleting history items: \(error.localizedDescription)")
            errorMessage = "Failed to delete history: \(error.localizedDescription)"
            // Optionally, re-fetch or handle UI update for partial success
        }
    }
}

struct HistoryView_Previews: PreviewProvider { // Renamed for consistency
    static var previews: some View {
        let appState = AppState()
        // For preview, simulate an active profile
        // In a real preview, you might want to populate mock data into a mock DB service
        // or set up a temporary in-memory DB for GRDB.
        // For now, we just ensure AppState has an active profile ID.
        // appState.setActiveProfile(UserProfileRecord(id: "previewUser", name: "Preview User"))

        HistoryView()
            .environmentObject(appState)
            // .environmentObject(LocalDatabaseService.shared) // If service needed directly by view
    }
}