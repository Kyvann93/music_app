import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingLogoutAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                // User Information
                Section(header: Text("Personal Information")) {
                    if let user = appState.currentUser {
                        HStack {
                            Text("Username")
                            Spacer()
                            Text(user.username)
                                .foregroundColor(.gray)
                        }
                        
                        HStack {
                            Text("Email")
                            Spacer()
                            Text(user.email)
                                .foregroundColor(.gray)
                        }
                    } else {
                        Text("User information not available")
                            .foregroundColor(.red)
                    }
                }
                
                // Skill Level
                Section(header: Text("Skill Level")) {
                    HStack {
                        Text("Current Level")
                        Spacer()
                        Text(appState.currentUser?.skillLevel ?? "Intermediate")
                            .foregroundColor(.gray)
                    }
                }
                
                // Preferred Genres
                Section(header: Text("Preferred Genres")) {
                    ForEach(appState.currentUser?.preferredGenres ?? ["Rock", "Blues", "Jazz"], id: \.self) { genre in
                        Text(genre)
                    }
                }
                
                // Practice Statistics
                Section(header: Text("Practice Statistics")) {
                    HStack {
                        Text("Songs Practiced")
                        Spacer()
                        Text("42")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Total Practice Time")
                        Spacer()
                        Text("24 hours")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Longest Streak")
                        Spacer()
                        Text("7 days")
                            .foregroundColor(.gray)
                    }
                }
                
                // Account
                Section(header: Text("Account")) {
                    Button(action: {
                        showingLogoutAlert = true
                    }) {
                        Text("Log Out")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Your Profile")
            .alert(isPresented: $showingLogoutAlert) {
                Alert(
                    title: Text("Log Out"),
                    message: Text("Are you sure you want to log out?"),
                    primaryButton: .destructive(Text("Log Out")) {
                        appState.logout()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppState())
}