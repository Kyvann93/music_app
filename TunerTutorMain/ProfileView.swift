import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingLogoutAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                // User Information
                Section(header: Text("Profile Information")) {
                    if let profile = appState.activeLocalProfile {
                        HStack {
                            Text("Profile Name")
                            Spacer()
                            Text(profile.name)
                                .foregroundColor(.gray)
                        }
                        HStack {
                            Text("Profile ID") // For debug or info
                            Spacer()
                            Text(profile.id.prefix(8) + "...") // Show partial ID
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        HStack {
                            Text("Profile Created")
                            Spacer()
                            Text(profile.creationDate, style: .date)
                                .foregroundColor(.gray)
                        }
                    } else {
                        Text("No active profile.")
                            .foregroundColor(.red)
                    }
                }

                // My Content Section
                Section(header: Text("My Content")) {
                    NavigationLink("Saved Tabs", destination: SavedTabsView().environmentObject(appState))
                    // We can add a link to Recognition History here too if desired,
                    // though it's also a main tab.
                    // NavigationLink("Recognition History", destination: HistoryView().environmentObject(appState))
                }
                
                // Preferences Section (placeholder for now)
                Section(header: Text("Preferences")) {
                    Text("User preferences will go here.")
                        .foregroundColor(.gray)
                    // Example:
                    // NavigationLink("Edit Preferences", destination: PreferencesEditView())
                }
                
                // Account Actions
                Section(header: Text("Account Actions")) {
                    Button(action: {
                        showingLogoutAlert = true
                    }) {
                        Text("Clear Active Profile") // Changed label
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle(appState.activeLocalProfile?.name ?? "Profile")
            .alert(isPresented: $showingLogoutAlert) {
                Alert(
                    title: Text("Clear Profile"),
                    message: Text("Are you sure you want to clear the active profile? This will require you to create a new profile on next app start if no other profiles exist."),
                    primaryButton: .destructive(Text("Clear Profile")) {
                        appState.clearActiveProfile() // Use the new method
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider { // Renamed for consistency
    static var previews: some View {
        let appState = AppState()
        // Simulate an active profile for preview
        // appState.setActiveProfile(UserProfileRecord(id: "previewUser", name: "Preview User"))
        ProfileView()
            .environmentObject(appState)
    }
}