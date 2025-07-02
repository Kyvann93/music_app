import SwiftUI

struct SavedTabsView: View {
    @EnvironmentObject var appState: AppState
    @State private var savedTabRecords: [SavedTabRecord] = []
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
                    ProgressView("Loading Saved Tabs...")
                } else if let errorMsg = errorMessage {
                    VStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text("Error Loading Saved Tabs")
                            .font(.title2)
                        Text(errorMsg)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding()
                        Button("Retry") {
                            fetchSavedTabs()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if savedTabRecords.isEmpty {
                    VStack {
                        Image(systemName: "bookmark.slash.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                            .padding()
                        Text("No Saved Tabs")
                            .font(.title2)
                        Text("Tabs you save will appear here.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .padding()
                } else {
                    List {
                        ForEach(savedTabRecords) { record in
                            VStack(alignment: .leading) {
                                Text(record.songTitle)
                                    .font(.headline)
                                if let artist = record.artist, !artist.isEmpty {
                                    Text(artist)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                Text("Type: \(record.tabType.capitalized)")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                Link(destination: URL(string: record.tabURL) ?? URL(string: "https://www.ultimate-guitar.com")!) {
                                    Text(record.tabURL)
                                        .font(.caption)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                                Text("Saved: \(record.savedDate, formatter: Self.dateFormatter)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: deleteSavedTabs)
                    }
                }
            }
            .navigationTitle("Saved Tabs")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !savedTabRecords.isEmpty { EditButton() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: fetchSavedTabs) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            }
            .onAppear(perform: fetchSavedTabs)
            .onChange(of: appState.activeLocalProfile?.id) { _ in
                fetchSavedTabs()
            }
        }
    }

    private func fetchSavedTabs() {
        guard let profileId = appState.activeLocalProfile?.id else {
            savedTabRecords = []
            errorMessage = "No active profile. Please create or select a profile to see saved tabs."
            isLoading = false
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            savedTabRecords = try LocalDatabaseService.shared.getSavedTabs(forUserProfileId: profileId)
        } catch {
            print("Error fetching saved tabs: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            savedTabRecords = []
        }
        isLoading = false
    }

    private func deleteSavedTabs(offsets: IndexSet) {
        let idsToDelete = offsets.map { savedTabRecords[$0].id }.compactMap { $0 }
        if idsToDelete.isEmpty { return }

        do {
            for id in idsToDelete {
                try LocalDatabaseService.shared.deleteSavedTab(id: id)
            }
            fetchSavedTabs() // Refresh list
        } catch {
            print("Error deleting saved tabs: \(error.localizedDescription)")
            errorMessage = "Failed to delete saved tabs: \(error.localizedDescription)"
        }
    }
}

struct SavedTabsView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState()
        // For preview, consider setting an active profile in appState
        // and potentially mocking LocalDatabaseService or pre-filling data.
        // appState.setActiveProfile(UserProfileRecord(id: "previewUser", name: "Preview User"))
        SavedTabsView().environmentObject(appState)
    }
}
